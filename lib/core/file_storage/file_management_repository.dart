import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'file_service.dart';
import 'managed_file_data.dart';

enum FileManagementError { unknownFile }

enum FileManagementState { inactive, active }

class FileManagementRepository {
  final _fileService = FileService();
  final _managedFilesController = BehaviorSubject<List<ManagedFileData>>();
  final _statusController = BehaviorSubject<FileManagementState>.seeded(
    FileManagementState.inactive,
  );
  StreamSubscription<FileType>? _fileChangedSubscription;

  Stream<List<ManagedFileData>> get managedFilesStream =>
      _managedFilesController.stream;
  Stream<FileManagementState> get fileMangementState =>
      _statusController.stream;

  Future<void> initialiseFor(
    FileType type, {
    required void Function(FileManagementError) onError,
  }) async {
    try {
      Future<List<ManagedFileData>> fetch() async => type.isSupportDir
          ? _fileService.getAppDataFiles(type: type)
          : _fileService.getUserDataFiles(type: type);
      _managedFilesController.add(await fetch());
      _statusController.add(FileManagementState.active);
    } on FileException catch (exception) {
      switch (exception) {
        case OutOfStorageException():
          onError(FileManagementError.unknownFile);
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
