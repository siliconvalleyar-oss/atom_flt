import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/all.dart';
import '../models/syntax_language.dart';
import '../services/file_service.dart';

class EditorController extends ChangeNotifier {
  final CodeController codeController;
  final FileService _fileService = FileService();

  String? _filePath;
  String? _fileUri;
  String _fileName = 'Untitled';
  bool _isModified = false;
  int _currentLine = 1;
  int _currentColumn = 1;
  int _undoCount = 0;
  int _redoCount = 0;

  EditorController()
      : codeController = CodeController(
          text: '',
          language: null,
        ) {
    codeController.addListener(_onCodeChanged);
  }

  String? get filePath => _filePath;
  String? get fileUri => _fileUri;
  String? get currentFilePath => _filePath;
  String? get currentFileName => _fileName;
  String get fileName => _fileName;
  String get code => codeController.text;
  set code(String value) => codeController.text = value;
  bool get isModified => _isModified;
  int get currentLine => _currentLine;
  int get currentColumn => _currentColumn;
  bool get canUndo => _undoCount > 0;
  bool get canRedo => _redoCount > 0;

  bool _suppressNotifications = false;

  void _onCodeChanged() {
    if (_suppressNotifications) return;
    if (!_isModified) {
      _isModified = true;
      notifyListeners();
    }
  }

  void updateCursorPosition(int line, int column) {
    _currentLine = line;
    _currentColumn = column;
    notifyListeners();
  }

  void newFile() {
    _suppressNotifications = true;
    codeController.text = '';
    _suppressNotifications = false;
    codeController.language = null;
    _filePath = null;
    _fileUri = null;
    _fileName = 'Untitled';
    _isModified = false;
    _clearHighlight();
    _undoCount = 0;
    _redoCount = 0;
    notifyListeners();
  }

  Future<void> openFile({required String uri, String? filePath}) async {
    final content = await _fileService.readFile(uri);
    _suppressNotifications = true;
    codeController.text = content;
    _suppressNotifications = false;
    codeController.selection = const TextSelection.collapsed(offset: 0);
    _filePath = filePath ?? uri;
    _fileUri = uri.startsWith('content://') ? uri : null;
    _fileName = _fileService.getFileName(filePath ?? uri);
    _isModified = false;
    _clearHighlight();
    _undoCount = 0;
    _redoCount = 0;

    final path = filePath ?? uri;
    final lang = SyntaxLanguage.detect(path);
    codeController.language = lang != null ? allLanguages[lang] : null;

    notifyListeners();
  }

  Future<void> saveFile() async {
    if (_fileUri != null) {
      await _fileService.writeFile(_fileUri!, codeController.text);
      _isModified = false;
      notifyListeners();
    } else if (_filePath != null) {
      await _fileService.writeFile(_filePath!, codeController.text);
      _isModified = false;
      notifyListeners();
    }
  }

  Future<void> saveFileAs(String path) async {
    await _fileService.writeFile(path, codeController.text);
    _filePath = path;
    _fileUri = null;
    _fileName = _fileService.getFileName(path);
    _isModified = false;

    final lang = SyntaxLanguage.detect(path);
    codeController.language = lang != null ? allLanguages[lang] : null;

    notifyListeners();
  }

  void undo() {
    if (_undoCount > 0) {
      codeController.historyController.undo();
      _undoCount--;
      _redoCount++;
      notifyListeners();
    }
  }

  void redo() {
    if (_redoCount > 0) {
      codeController.historyController.redo();
      _redoCount--;
      _undoCount++;
      notifyListeners();
    }
  }

  String? getWordAtCursor() {
    final text = codeController.text;
    final offset = codeController.selection.baseOffset;
    if (offset < 0 || offset >= text.length) return null;

    int start = offset;
    int end = offset;

    while (start > 0 && _isWordChar(text[start - 1])) { start--; }
    while (end < text.length && _isWordChar(text[end])) { end++; }

    if (start >= end) return null;
    return text.substring(start, end);
  }

  bool _isWordChar(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 97 && c <= 122) ||
        (c >= 65 && c <= 90) ||
        (c >= 48 && c <= 57) ||
        c == 95;
  }

  void highlightWord(String? word) {
    final patternCtrl =
        codeController.searchController.settingsController.patternController;
    if (word == null || word.isEmpty) {
      patternCtrl.text = '';
      return;
    }
    patternCtrl.text = word;
  }

  void _clearHighlight() {
    codeController.searchController.settingsController.patternController.text =
        '';
  }

  List<int> findAllOccurrences(String word) {
    final positions = <int>[];
    final text = codeController.text;
    int start = 0;
    while (true) {
      final index = text.indexOf(word, start);
      if (index == -1) break;
      positions.add(index);
      start = index + word.length;
    }
    return positions;
  }

  @override
  void dispose() {
    codeController.removeListener(_onCodeChanged);
    codeController.dispose();
    super.dispose();
  }
}
