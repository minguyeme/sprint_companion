import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    final targetPath = '$_documentsPath/${type.parentPath}/$fileName.${type.suffix}';

    await _writeStringWorker(targetPath, str);
  }

  Future<void> logAppData(
    String str, {
    required String fileName,
    required FileType type,
  }) async {
    _supportPath ??= (await getApplicationSupportDirectory()).path;
    final targetPath = '$_supportPath/${type.parentPath}/$fileName.${type.suffix}';

    await _writeStringWorker(targetPath, str);
  }

  Future<void> _writeStringWorker(String path, String content) async {
    final targetFile = File(path);
    await targetFile.create(recursive: true);
    await targetFile.writeAsString(content);
  }
}
