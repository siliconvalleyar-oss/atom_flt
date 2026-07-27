import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/all.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/theme_provider.dart';
import '../widgets/status_bar.dart';
import '../widgets/search_bar.dart';
import '../samples/sample_code.dart';
import 'editor_controller.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    final editor = context.read<EditorController>();
    editor.codeController.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    final editor = context.read<EditorController>();
    final selection = editor.codeController.selection;
    if (!selection.isValid || !selection.isCollapsed) return;

    if (selection.baseOffset >= 0) {
      final text = editor.codeController.text;
      final line = text.substring(0, selection.baseOffset).split('\n').length;
      final lastNewline =
          text.substring(0, selection.baseOffset).lastIndexOf('\n');
      final col = selection.baseOffset - lastNewline;
      editor.updateCursorPosition(line, col < 0 ? 1 : col + 1);

      final word = editor.getWordAtCursor();
      if (word != null && word.length >= 2) {
        editor.highlightWord(word);
      } else {
        editor.highlightWord(null);
      }
    }
  }

  Future<void> _openFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      await context.read<EditorController>().openFile(
            result.files.single.path!,
          );
    }
  }

  Future<void> _saveFile() async {
    final editor = context.read<EditorController>();
    if (editor.filePath != null) {
      await editor.saveFile();
    } else {
      await _saveFileAs();
    }
  }

  Future<void> _saveFileAs() async {
    final result = await FilePicker.platform.saveFile(
      type: FileType.any,
    );
    if (result != null) {
      if (!mounted) return;
      await context.read<EditorController>().saveFileAs(result);
    }
  }

  void _loadSample(String code, String lang, String filename) {
    final editor = context.read<EditorController>();
    editor.codeController.removeListener(_onSelectionChanged);
    editor.codeController.text = code;
    editor.codeController.language = allLanguages[lang];
    editor.codeController.addListener(_onSelectionChanged);
  }

  void _loadSampleCpp() => _loadSample(SampleCode.cpp, 'cpp', 'sample.cpp');
  void _loadSampleDart() => _loadSample(SampleCode.dart, 'dart', 'sample.dart');

  @override
  void dispose() {
    final editor = context.read<EditorController>();
    editor.codeController.removeListener(_onSelectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorController>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildMenuBar(context, editor, isDark),
            if (_showSearch)
              SearchBarWidget(
                codeController: editor.codeController,
                onClose: () => setState(() => _showSearch = false),
              ),
            Expanded(child: _buildEditor(context, editor, isDark)),
            const StatusBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBar(
      BuildContext context, EditorController editor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      child: Row(
        children: [
          _menuButton('File', isDark, [
            _MenuItem('New', 'Ctrl+N',
                () => context.read<EditorController>().newFile()),
            _MenuItem('Open...', 'Ctrl+O', _openFile),
            _MenuItem('Save', 'Ctrl+S', _saveFile),
            _MenuItem('Save As...', 'Ctrl+Shift+S', _saveFileAs),
          ]),
          _menuButton('Edit', isDark, [
            _MenuItem('Undo', 'Ctrl+Z',
                () => context.read<EditorController>().undo()),
            _MenuItem('Redo', 'Ctrl+Y',
                () => context.read<EditorController>().redo()),
          ]),
          _menuButton('View', isDark, [
            _MenuItem('Toggle Theme', 'Ctrl+T',
                () => context.read<ThemeProvider>().toggleTheme()),
          ]),
          const Spacer(),
          Text(
            '${editor.fileName}${editor.isModified ? ' ●' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF999999)
                  : const Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_OverflowItem>(
            icon: Icon(
              Icons.more_vert,
              size: 20,
              color: isDark
                  ? const Color(0xFF999999)
                  : const Color(0xFF666666),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem<_OverflowItem>(
                value: _OverflowItem('Explorar...', null),
                child: Row(
                  children: [
                    Icon(Icons.folder_open, size: 18),
                    SizedBox(width: 12),
                    Text('Explorar...'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<_OverflowItem>(
                value: _OverflowItem('Cargar ejemplo C++', null),
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18),
                    SizedBox(width: 12),
                    Text('Cargar ejemplo C++'),
                  ],
                ),
              ),
              const PopupMenuItem<_OverflowItem>(
                value: _OverflowItem('Cargar ejemplo Dart', null),
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18),
                    SizedBox(width: 12),
                    Text('Cargar ejemplo Dart'),
                  ],
                ),
              ),
            ],
            onSelected: (item) {
              switch (item.title) {
                case 'Explorar...':
                  _openFile();
                  break;
                case 'Cargar ejemplo C++':
                  _loadSampleCpp();
                  break;
                case 'Cargar ejemplo Dart':
                  _loadSampleDart();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
      String title, bool isDark, List<_MenuItem> items) {
    return PopupMenuButton<_MenuItem>(
      onSelected: (item) => item.action(),
      itemBuilder: (_) => items.map((item) {
        return PopupMenuItem<_MenuItem>(
          value: item,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.title),
              const SizedBox(width: 24),
              Text(
                item.shortcut,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF666666)
                      : const Color(0xFF999999),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? const Color(0xFFD4D4D4)
                : const Color(0xFF1E1E1E),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(
      BuildContext context, EditorController editor, bool isDark) {
    return CodeTheme(
      data: CodeThemeData(
        styles: isDark ? _oneDarkStyles : _githubLightStyles,
      ),
      child: CodeField(
        controller: editor.codeController,
        textStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
          color: isDark
              ? const Color(0xFFD4D4D4)
              : const Color(0xFF1E1E1E),
        ),
        gutterStyle: GutterStyle(
          showLineNumbers: true,
          showErrors: false,
          showFoldingHandles: false,
          margin: 4,
          textStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: isDark
                ? const Color(0xFF666666)
                : const Color(0xFF999999),
          ),
          background: isDark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFFAFAFA),
        ),
        background: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFFFFFFF),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String shortcut;
  final VoidCallback action;
  _MenuItem(this.title, this.shortcut, this.action);
}

class _OverflowItem {
  final String title;
  final VoidCallback? action;
  const _OverflowItem(this.title, this.action);
}

Map<String, TextStyle> get _oneDarkStyles => {
      'root': const TextStyle(color: Color(0xFFABB2BF)),
      'keyword': const TextStyle(color: Color(0xFFC678DD)),
      'string': const TextStyle(color: Color(0xFF98C379)),
      'comment': TextStyle(
        color: const Color(0xFF5C6370),
        fontStyle: FontStyle.italic,
      ),
      'function': const TextStyle(color: Color(0xFF61AFEF)),
      'number': const TextStyle(color: Color(0xFFD19A66)),
      'type': const TextStyle(color: Color(0xFFE5C07B)),
      'built_in': const TextStyle(color: Color(0xFF56B6C2)),
      'attr': const TextStyle(color: Color(0xFFE06C75)),
    };

Map<String, TextStyle> get _githubLightStyles => {
      'root': const TextStyle(color: Color(0xFF24292E)),
      'keyword': const TextStyle(color: Color(0xFFD73A49)),
      'string': const TextStyle(color: Color(0xFF032F62)),
      'comment': TextStyle(
        color: const Color(0xFF6A737D),
        fontStyle: FontStyle.italic,
      ),
      'function': const TextStyle(color: Color(0xFF6F42C1)),
      'number': const TextStyle(color: Color(0xFF005CC5)),
      'type': const TextStyle(color: Color(0xFF22863A)),
      'built_in': const TextStyle(color: Color(0xFF005CC5)),
      'attr': const TextStyle(color: Color(0xFFD73A49)),
    };
