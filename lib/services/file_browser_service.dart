import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FileEntry {
  final String name;
  final String uri;
  final String docId;
  final bool isDirectory;
  final bool isFile;
  final int lastModified;
  final int length;

  FileEntry({
    required this.name,
    required this.uri,
    required this.docId,
    required this.isDirectory,
    required this.isFile,
    this.lastModified = 0,
    this.length = 0,
  });

  factory FileEntry.fromMap(Map<dynamic, dynamic> map) {
    return FileEntry(
      name: map['name'] as String? ?? '',
      uri: map['uri'] as String? ?? '',
      docId: map['docId'] as String? ?? '',
      isDirectory: map['isDirectory'] as bool? ?? false,
      isFile: map['isFile'] as bool? ?? true,
      lastModified: map['lastModified'] as int? ?? 0,
      length: map['length'] as int? ?? 0,
    );
  }
}

class FileBrowserService {
  static const _channel = MethodChannel('com.atom_flt/file_browser');

  String? _rootTreeUri;
  String _currentDocId = '';
  String _rootDocId = '';
  int _apiLevel = 0;

  bool get canGoUp => _currentDocId != _rootDocId;
  String? get rootTreeUri => _rootTreeUri;
  String get currentDocId => _currentDocId;
  int get apiLevel => _apiLevel;

  Future<void> openFolder(String treeUri) async {
    _rootTreeUri = treeUri;
    if (Platform.isAndroid && treeUri.startsWith('content://')) {
      try {
        final id = await _channel.invokeMethod<String>('getRootDocId', {
          'treeUri': treeUri,
        });
        _rootDocId = id ?? treeUri;
      } catch (e) {
        _rootDocId = _extractRootDocIdFallback(treeUri);
      }
      _currentDocId = _rootDocId;
    } else {
      _currentDocId = treeUri;
      _rootDocId = treeUri;
    }
  }

  String _extractRootDocIdFallback(String treeUri) {
    final treePrefix = '/tree/';
    final idx = treeUri.indexOf(treePrefix);
    if (idx >= 0) {
      final docId = Uri.decodeComponent(treeUri.substring(idx + treePrefix.length));
      return docId;
    }
    return treeUri;
  }

  Future<List<FileEntry>> listDirectory() async {
    if (_rootTreeUri == null) return [];

    if (Platform.isAndroid && _rootTreeUri!.startsWith('content://')) {
      try {
        final result = await _channel.invokeMethod<List>('listDirectory', {
          'treeUri': _rootTreeUri,
          'docId': _currentDocId,
        });
        if (result == null) return [];
        return result
            .map((e) => FileEntry.fromMap(e as Map<dynamic, dynamic>))
            .toList();
      } catch (e) {
        throw Exception('$e');
      }
    } else {
      return _listDirectoryFallback(_currentDocId);
    }
  }

  Future<void> navigateTo(String docId) async {
    _currentDocId = docId;
  }

  Future<void> goUp() async {
    if (!canGoUp) return;
    if (Platform.isAndroid && _rootTreeUri != null && _rootTreeUri!.startsWith('content://')) {
      final idx = _currentDocId.lastIndexOf('/');
      if (idx > 0) {
        _currentDocId = _currentDocId.substring(0, idx);
      } else {
        _currentDocId = _rootDocId;
      }
    } else {
      final parent = Directory(_currentDocId).parent.path;
      _currentDocId = parent;
    }
  }

  Future<List<FileEntry>> _listDirectoryFallback(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception('Directory not found: $path');
    }
    final entities = await dir.list().toList();
    entities.sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return a.path.split(Platform.pathSeparator).last
          .compareTo(b.path.split(Platform.pathSeparator).last);
    });
    return entities.map((e) {
      if (e is Directory) {
        return FileEntry(
          name: e.path.split(Platform.pathSeparator).last,
          uri: e.path,
          docId: e.path,
          isDirectory: true,
          isFile: false,
        );
      } else {
        return FileEntry(
          name: e.path.split(Platform.pathSeparator).last,
          uri: e.path,
          docId: e.path,
          isDirectory: false,
          isFile: true,
        );
      }
    }).toList();
  }

  Future<int> getApiLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getApiLevel') ?? 0;
      _apiLevel = level;
      return level;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> requestManageStorage() async {
    try {
      return await _channel.invokeMethod<bool>('requestManageStorage') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isExternalStorageManager() async {
    try {
      return await _channel.invokeMethod<bool>('isExternalStorageManager') ?? false;
    } catch (_) {
      return false;
    }
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
