import 'dart:io';
import 'dart:developer' as developer;
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sprint_companion/core/file_storage/managed_file_data.dart';

sealed class FileException implements Exception {}

class OutOfStorageException extends FileException {}

class UnknownStorageException extends FileException {}

enum FileType {
  dataset('datasets', 'csv'),
  metric('metrics', 'csv');

  final String parentPath;
  final String suffix;

  const FileType(this.parentPath, this.suffix);
}

class FileService {
  static final FileService _instance = FileService._internal();

  String? _documentsPath;
  String? _supportPath;

  factory FileService() => _instance;
  FileService._internal();

  Future<void> saveUserData(
    String str, {
    required String fileName,
    required FileType type,
  }) async {
    _documentsPath ??= (await getApplicationDocumentsDirectory()).path;
    final targetPath =
        '$_documentsPath/${type.parentPath}/$fileName.${type.suffix}';

    await _writeStringWorker(targetPath, str);
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
  }

  Future<List<ManagedFileData>> getUserDataFiles({
    required FileType type,
  }) async {
    _documentsPath ??= (await getApplicationDocumentsDirectory()).path;
    final targetPath = '$_documentsPath/${type.parentPath}';

    return await _getFilesWorker(targetPath);
  }

  Future<void> deleteFile(ManagedFileData file) async {
    try {
      await File(file.path).delete();
    } on FileSystemException catch (exception, stackTrace) {
      if (exception.osError?.errorCode == 2) return;
      developer.log(
        'File deletion failure.',
        name: 'FileService',
        error: exception,
        stackTrace: stackTrace,
      );
    } catch (exception, stackTrace) {
      developer.log(
        'Other file deletion failure.',
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
