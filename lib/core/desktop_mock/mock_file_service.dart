import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../file_storage/managed_file_data.dart';
import '../file_storage/file_service.dart';

class MockFileService implements FileService {
  final _fileChangedController = PublishSubject<FileType>();
  final List<ManagedFileData> _mockList = [];

  @override
  Stream<FileType> get fileChangedStream => _fileChangedController.stream;

  @override
  Future<List<ManagedFileData>> getUserDataFiles({
    required FileType type,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return _mockList;
  }

  @override
  Future<List<ManagedFileData>> getAppDataFiles({
    required FileType type,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return _mockList;
  }

  @override
  Future<void> saveUserData(
    String str, {
    required String fileName,
    required FileType type,
  }) async {
    _mockList.add(
      ManagedFileData(
        path: '${type.parentPath}/$fileName.${type.suffix}',
        name: fileName,
        sizeInBytes: 0,
      ),
    );
    _fileChangedController.add(type);
  }

  @override
  Future<void> logAppData(
    String str, {
    required String fileName,
    required FileType type,
  }) async {
    _mockList.add(
      ManagedFileData(
        path: '${type.parentPath}/$fileName.${type.suffix}',
        name: fileName,
        sizeInBytes: 0,
      ),
    );
    _fileChangedController.add(type);
  }

  @override
  Future<void> deleteFile(ManagedFileData file) async {
    _mockList.remove(file);
    _notifyStreamFromPath(file.path);
  }

  @override
  Future<void> renameFile(ManagedFileData file, {required String name}) async {
    final path = file.path;
    final parentDir = path.substring(0, path.lastIndexOf('/'));
    _mockList[_mockList.indexOf(file)] = ManagedFileData(
      path: '$parentDir/$name${path.substring(path.lastIndexOf('.'))}',
      name: name,
      sizeInBytes: file.sizeInBytes,
    );
    _notifyStreamFromPath(path);
  }

  void _notifyStreamFromPath(String path) {
    final segments = path.split('/');
    _fileChangedController.add(
      FileType.fromString(segments[segments.length - 2]),
    );
  }
}
