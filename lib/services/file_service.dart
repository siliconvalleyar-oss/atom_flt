import 'dart:io';
import 'package:flutter/services.dart';

class FileService {
  static const _channel = MethodChannel('com.atom_flt/file_browser');

  Future<String> readFile(String path) async {
    if (path.startsWith('content://')) {
      return await _channel.invokeMethod<String>('readFile', {'uri': path}) ?? '';
    }
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<String>('readFilePath', {'path': path}) ?? '';
    }
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }
    return await file.readAsString();
  }

  Future<void> writeFile(String path, String content) async {
    if (path.startsWith('content://')) {
      await _channel.invokeMethod<bool>('writeFile', {
        'uri': path,
        'content': content,
      });
      return;
    }
    if (Platform.isAndroid) {
      await _channel.invokeMethod<bool>('writeFilePath', {
        'path': path,
        'content': content,
      });
      return;
    }
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
