import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sprint_companion/core/file_storage/managed_file_data.dart';

sealed class FileException implements Exception {}

class FileNotFoundException extends FileException {}

class OutOfStorageException extends FileException {}

class UnknownStorageException extends FileException {}

enum FileType {
  dataset('datasets', 'csv', false),
  result('metrics', 'json', true);

  final String parentPath;
  final String suffix;
  final bool isSupportDir;

  const FileType(this.parentPath, this.suffix, this.isSupportDir);

  static FileType fromString(String str) =>
      values.firstWhere((type) => type.parentPath == str);
}

class FileService {
  static final FileService _instance = FileService._internal();

  String? _documentsPath;
  String? _supportPath;
  final _fileChangedController = PublishSubject<FileType>();

  factory FileService() => _instance;
  FileService._internal();

  Stream<FileType> get fileChangedStream => _fileChangedController.stream;

  Future<void> saveUserData(
    String str, {
    required String fileName,
    required FileType type,
  }) async {
    _documentsPath ??= (await getApplicationDocumentsDirectory()).path;
    final targetPath =
        '$_documentsPath/${type.parentPath}/$fileName.${type.suffix}';

    await _writeStringWorker(targetPath, str);
    _fileChangedController.add(type);
  }

  Future<void> logAppData(
    String str, {
    required String fileName,
    required FileType type,
  }) async {
    _supportPath ??= (await getApplicationSupportDirectory()).path;
    final targetPath =
        '$_supportPath/${type.parentPath}/$fileName.${type.suffix}';

    await _writeStringWorker(targetPath, str);
    _fileChangedController.add(type);
  }

  Future<List<ManagedFileData>> getUserDataFiles({
    required FileType type,
  }) async {
    _documentsPath ??= (await getApplicationDocumentsDirectory()).path;
    final targetPath = '$_documentsPath/${type.parentPath}';

    return await _getFilesWorker(targetPath);
  }

  Future<List<ManagedFileData>> getAppDataFiles({
    required FileType type,
  }) async {
    _supportPath ??= (await getApplicationSupportDirectory()).path;
    final targetPath = '$_supportPath/${type.parentPath}';

    return await _getFilesWorker(targetPath);
  }

  Future<void> deleteFile(ManagedFileData file) async {
    try {
      await File(file.path).delete();
      _notifyStreamFromPath(file.path);
    } on FileSystemException catch (exception, stackTrace) {
      if (exception.osError?.errorCode == 2) {
        _notifyStreamFromPath(file.path);
        return;
      }
      developer.log(
        'File deletion failure.',
        name: 'FileService',
        error: exception,
        stackTrace: stackTrace,
      );
      throw UnknownStorageException();
    } catch (exception, stackTrace) {
      developer.log(
        'Other file deletion failure.',
        name: 'FileService',
        error: exception,
        stackTrace: stackTrace,
      );
      throw UnknownStorageException();
    }
  }

  Future<void> renameFile(ManagedFileData file, {required String name}) async {
    try {
      final path = file.path;
      final parentDir = path.substring(0, path.lastIndexOf('/'));
      await File(
        path,
      ).rename('$parentDir/$name');
      _notifyStreamFromPath(path);
    } on FileSystemException catch (exception, stackTrace) {
      developer.log(
        'File naming failure.',
        name: 'FileService',
        error: exception,
        stackTrace: stackTrace,
      );
      switch (exception.osError?.errorCode) {
        case 2:
          throw FileNotFoundException();
        case 28:
          throw OutOfStorageException();
        default:
          throw UnknownStorageException();
      }
    } catch (exception, stackTrace) {
      developer.log(
        'Other file naming failure.',
        name: 'FileService',
        error: exception,
        stackTrace: stackTrace,
      );
      throw UnknownStorageException();
    }
  }

  void _notifyStreamFromPath(String path) {
    final segments = path.split('/');
    _fileChangedController.add(
      FileType.fromString(segments[segments.length - 2]),
    );
  }

  Future<List<ManagedFileData>> _getFilesWorker(String path) async {
    try {
      final targetDir = Directory(path);
      await targetDir.create(recursive: true);
      final files = (await targetDir.list().toList()).whereType<File>();
      return await Future.wait(
        files.map(
          (file) async => ManagedFileData(
            path: file.path,
            name: file.path.split('/').last,
            sizeInBytes: await file.length(),
          ),
        ),
      );
    } catch (exception, stackTrace) {
      developer.log(
        'Failure to get files.',
        name: 'FileService',
        error: exception,
        stackTrace: stackTrace,
      );
      switch (exception) {
        default:
          throw UnknownStorageException();
      }
    }
  }

  Future<void> _writeStringWorker(String path, String content) async {
    try {
      final targetFile = File(path);
      await targetFile.create(recursive: true);
      await targetFile.writeAsString(content);
    } on FileSystemException catch (fileSystemException, stackTrace) {
      developer.log(
        'File system failure.',
        name: 'FileService',
        error: fileSystemException,
        stackTrace: stackTrace,
      );
      switch (fileSystemException.osError?.errorCode) {
        case 28:
          throw OutOfStorageException();
        default:
          throw UnknownStorageException();
      }
    } catch (exception, stackTrace) {
      developer.log(
        'Other storage failure.',
        name: 'FileService',
        error: exception,
        stackTrace: stackTrace,
      );
      switch (exception) {
        default:
          throw UnknownStorageException();
      }
    }
  }
}
