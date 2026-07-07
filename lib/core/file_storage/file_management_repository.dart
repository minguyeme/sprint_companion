import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'file_service.dart';
import 'managed_file_data.dart';

enum FileManagementError { alreadyActive, unknownFile }

enum FileManagementStatus { inactive, initialising, active }

class FileManagementRepository {
  final _fileService = FileService();
  final _managedFilesController = BehaviorSubject<List<ManagedFileData>>();
  final _statusController = BehaviorSubject<FileManagementStatus>.seeded(
    FileManagementStatus.inactive,
  );
  StreamSubscription<FileType>? _fileChangedSubscription;

  Stream<List<ManagedFileData>> get managedFilesStream =>
      _managedFilesController.stream;
  Stream<FileManagementStatus> get statusStream => _statusController.stream;

  Future<void> initialiseFor(
    FileType type, {
    required void Function(FileManagementError) onError,
  }) async {
    try {
      if (_statusController.value != FileManagementStatus.inactive) {
        onError(FileManagementError.alreadyActive);
        return;
      }
      _statusController.add(FileManagementStatus.initialising);
      Future<List<ManagedFileData>> fetchList() async => type.isSupportDir
          ? _fileService.getAppDataFiles(type: type)
          : _fileService.getUserDataFiles(type: type);
      _managedFilesController.add(await fetchList());
      _fileChangedSubscription = _fileService.fileChangedStream
          .where((typeChanged) => typeChanged == type)
          .listen((_) async => _managedFilesController.add(await fetchList()));
      _statusController.add(FileManagementStatus.active);
    } on FileException catch (exception) {
      switch (exception) {
        case OutOfStorageException():
          onError(FileManagementError.unknownFile);
        case FileNotFoundException():
        case UnknownStorageException():
          onError(FileManagementError.unknownFile);
      }
    }
  }

  Future<void> delete(
    ManagedFileData file, {
    required void Function(FileManagementError) onError,
  }) async {
    try {
      await _fileService.deleteFile(file);
    } on FileException catch (exception) {
      switch (exception) {
        case OutOfStorageException():
          onError(FileManagementError.unknownFile);
        case FileNotFoundException():
        case UnknownStorageException():
          onError(FileManagementError.unknownFile);
      }
    }
  }

  Future<void> share(
    ManagedFileData file, {
    required void Function(bool) onResult,
  }) async {
    try {
      final params = ShareParams(text: file.name, files: [XFile(file.path)]);
      final result = await SharePlus.instance.share(params);
      onResult(result.status == ShareResultStatus.success);
    } catch (_) {
      onResult(false);
      return;
    }
  }

  Future<void> dispose() async {
    await _fileChangedSubscription?.cancel();
    _fileChangedSubscription = null;
    await _statusController.close();
    await _managedFilesController.close();
  }
}
