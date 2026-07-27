import 'dart:io';
import 'package:flutter/services.dart';

class FileEntry {
  final String name;
  final String uri;
  final bool isDirectory;
  final bool isFile;
  final int lastModified;
  final int length;

  FileEntry({
    required this.name,
    required this.uri,
    required this.isDirectory,
    required this.isFile,
    this.lastModified = 0,
    this.length = 0,
  });

  factory FileEntry.fromMap(Map<dynamic, dynamic> map) {
    return FileEntry(
      name: map['name'] as String? ?? '',
      uri: map['uri'] as String? ?? '',
      isDirectory: map['isDirectory'] as bool? ?? false,
      isFile: map['isFile'] as bool? ?? true,
      lastModified: map['lastModified'] as int? ?? 0,
      length: map['length'] as int? ?? 0,
    );
  }
}

class FileBrowserService {
  static const _channel = MethodChannel('com.atom_flt/file_browser');

  Future<List<FileEntry>> listDirectory(String uri) async {
    if (Platform.isAndroid && uri.startsWith('content://')) {
      try {
        final result = await _channel.invokeMethod<List>('listDirectory', {
          'uri': uri,
        });
        if (result == null) return [];
        return result
            .map((e) => FileEntry.fromMap(e as Map<dynamic, dynamic>))
            .toList();
      } on MissingPluginException {
        throw UnsupportedError(
          'SAF file browser not available. '
          'Rebuild the app to register the native plugin.',
        );
      } catch (e) {
        throw Exception('Error listing directory: $e');
      }
    } else {
      return _listDirectoryFallback(uri);
    }
  }

  Future<List<FileEntry>> _listDirectoryFallback(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        throw Exception('Directory not found: $path');
      }

      final entities = await dir.list().toList();
      entities.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path
            .split(Platform.pathSeparator)
            .last
            .compareTo(b.path.split(Platform.pathSeparator).last);
      });

      return entities.map((e) {
        if (e is Directory) {
          final parts = e.path.split(Platform.pathSeparator);
          return FileEntry(
            name: parts.last,
            uri: e.path,
            isDirectory: true,
            isFile: false,
          );
        } else {
          final file = File(e.path);
          final parts = e.path.split(Platform.pathSeparator);
          return FileEntry(
            name: parts.last,
            uri: e.path,
            isDirectory: false,
            isFile: true,
            length: file.lengthSync(),
          );
        }
      }).toList();
    } catch (e) {
      throw Exception('Error reading directory: $e');
    }
  }

  String getParentUri(String uri, String rootTreeUri) {
    if (uri.startsWith('content://')) {
      if (uri == rootTreeUri) return uri;
      final documentIdx = uri.indexOf('/document/');
      if (documentIdx < 0) return rootTreeUri;

      final docPart = uri.substring(documentIdx + '/document/'.length);
      final lastSep = docPart.lastIndexOf('%2F');
      if (lastSep <= 0) return rootTreeUri;

      final parentDocId = docPart.substring(0, lastSep);
      return uri.substring(0, documentIdx + '/document/'.length) + parentDocId;
    }
    return Directory(uri).parent.path;
  }

  String getDisplayPath(String uri) {
    if (uri.startsWith('content://')) {
      final documentIdx = uri.indexOf('/document/');
      if (documentIdx < 0) return uri.split('/').last;
      final docPart = uri.substring(documentIdx + '/document/'.length);
      return docPart.split('%2F').last;
    }
    return uri.split(Platform.pathSeparator).last;
  }
}
