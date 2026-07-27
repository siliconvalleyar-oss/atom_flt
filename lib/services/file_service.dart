import 'dart:io';

class FileService {
  Future<String> readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }
    return await file.readAsString();
  }

  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String getFileExtension(String path) {
    final name = getFileName(path);
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot).toLowerCase();
  }
}
