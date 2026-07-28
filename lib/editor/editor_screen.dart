import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/file_service.dart';
import '../services/config_service.dart';
import '../widgets/file_panel.dart';
import '../widgets/config_screen.dart';
import 'editor_controller.dart';
import 'package:file_picker/file_picker.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorController _editor = EditorController();
  final TextEditingController _searchController = TextEditingController();
  final FileService _fileService = FileService();
  bool _showFilePanel = true;
  bool _isSearchVisible = false;
  int _currentLine = 1;
  int _currentCol = 1;
  String _directoryPath = '';
  String? _treeUri;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final path = await ConfigService.getDefaultDirectory();
    final treeUri = await ConfigService.getTreeUri();
    setState(() {
      _directoryPath = path;
      _treeUri = treeUri;
      _configLoaded = true;
    });
    if (path.isEmpty && treeUri == null && mounted) {
      final onboardingDone = await ConfigService.isOnboardingDone();
      if (!onboardingDone) {
        _openConfig();
      }
    }
  }

  void _saveFile() async {
    if (_editor.currentFilePath == null) return;

    try {
      if (_editor.fileUri != null) {
        await _fileService.writeFile(
          _editor.fileUri!,
          _editor.code,
        );
      } else {
        await _fileService.writeFile(
          _editor.currentFilePath!,
          _editor.code,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveFileAs() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar como...',
        fileName: _editor.currentFileName ?? 'untitled',
        bytes: Uint8List.fromList(_editor.code.codeUnits),
      );
      if (result != null) {
        _editor.saveFileAs(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar como: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.identifier != null && file.identifier!.startsWith('content://')) {
          await _editor.openFile(
            uri: file.identifier!,
            filePath: file.path,
          );
        } else if (file.path != null) {
          await _editor.openFile(uri: file.path!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _newFile() {
    _editor.newFile();
  }

  void _openConfig() {
    showDialog(
      context: context,
      builder: (_) => const ConfigScreen(),
    ).then((_) => _loadConfig());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fgColor = isDark ? const Color(0xFFD4D4D4) : Colors.black87;
    final topInset = MediaQuery.of(context).viewPadding.top;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          SizedBox(height: topInset),
          _buildMenu(fgColor),
          _isSearchVisible ? _buildSearchField(isDark, fgColor) : const SizedBox.shrink(),
          Expanded(
            child: Row(
              children: [
                if (_showFilePanel)
                  FilePanel(
                    directoryPath: _directoryPath,
                    treeUri: _treeUri,
                    onFileSelected: (uri) async {
                      try {
                        if (uri.startsWith('content://')) {
                          await _editor.openFile(uri: uri);
                        } else {
                          await _editor.openFile(uri: uri);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al abrir: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    onConfig: _openConfig,
                  ),
                _buildEditor(fgColor, isDark),
              ],
            ),
          ),
          _buildStatusBar(fgColor),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }

  Widget _buildStatusBar(Color fgColor) {
    return Container(
      color: const Color(0xFF007ACC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            _editor.currentFilePath ?? 'Sin archivo',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const Spacer(),
          Text(
            'Ln ${_currentLine}, Col ${_currentCol}',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 16),
          Text(
            'UTF-8',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(Color fgColor, bool isDark) {
    return Expanded(
      child: _editor.code.isEmpty && _editor.currentFilePath == null
          ? _buildWelcomeScreen(isDark)
          : _buildCodeEditor(fgColor, isDark),
    );
  }

  Widget _buildWelcomeScreen(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 300;
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code,
                  size: compact ? 40 : 64,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                SizedBox(height: compact ? 12 : 24),
                Text(
                  'atom',
                  style: TextStyle(
                    fontSize: compact ? 24 : 32,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ),
                SizedBox(height: compact ? 4 : 8),
                Text(
                  'Flutter Code Editor',
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
                SizedBox(height: compact ? 16 : 32),
                Text(
                  'Ctrl+N  Nuevo archivo\nCtrl+O  Abrir archivo\nCtrl+S  Guardar\nCtrl+B  Panel de archivos\nCtrl+F  Buscar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeEditor(Color fgColor, bool isDark) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final ctrl = HardwareKeyboard.instance.isControlPressed;
          final shift = HardwareKeyboard.instance.isShiftPressed;
          if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
            if (shift) {
              _saveFileAs();
            } else {
              _saveFile();
            }
          } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyO) {
            _openFile();
          } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyN) {
            _newFile();
          } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyB) {
            setState(() => _showFilePanel = !_showFilePanel);
          } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyF) {
            setState(() => _isSearchVisible = !_isSearchVisible);
          }
        }
      },
      child: Column(
        children: [
          if (_isSearchVisible) _buildSearchField(isDark, fgColor),
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  _buildLineNumbers(fgColor),
                  Expanded(
                    child: TextField(
                      controller: _editor.codeController,
                      onChanged: (value) {
                        _editor.code = value;
                        _updateCursorInfo();
                      },
                      onTap: _updateCursorInfo,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: fgColor,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Escribe tu código aquí...',
                        contentPadding: const EdgeInsets.all(16),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers(Color fgColor) {
    final lineCount = _editor.code.split('\n').length;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: fgColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        itemCount: lineCount,
        itemBuilder: (context, index) {
          return Text(
            '${index + 1}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: fgColor.withOpacity(0.3),
            ),
            textAlign: TextAlign.right,
          );
        },
      ),
    );
  }

  Widget _buildMenu(Color fgColor) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: fgColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            'atom',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF007ACC),
            ),
          ),
          const SizedBox(width: 16),
          _buildMenuItem('Archivo', [
            PopupMenuItem(
              child: _menuItemContent(Icons.add, 'Nuevo', 'Ctrl+N'),
              onTap: _newFile,
            ),
            PopupMenuItem(
              child: _menuItemContent(Icons.open_in_new, 'Abrir...', 'Ctrl+O'),
              onTap: _openFile,
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              child: _menuItemContent(Icons.save, 'Guardar', 'Ctrl+S'),
              onTap: _saveFile,
            ),
            PopupMenuItem(
              child: _menuItemContent(Icons.save_as, 'Guardar como...', 'Ctrl+Shift+S'),
              onTap: _saveFileAs,
            ),
          ]),
          _buildMenuItem('Edición', [
            PopupMenuItem(
              child: _menuItemContent(Icons.search, 'Buscar', 'Ctrl+F'),
              onTap: () {
                setState(() => _isSearchVisible = !_isSearchVisible);
              },
            ),
            PopupMenuItem(
              child: _menuItemContent(Icons.find_replace, 'Reemplazar'),
              onTap: () {},
            ),
          ]),
          _buildMenuItem('Ver', [
            PopupMenuItem(
              child: _menuItemContent(
                _showFilePanel ? Icons.check_box : Icons.check_box_outline_blank,
                'Panel de archivos',
                'Ctrl+B',
              ),
              onTap: () {
                setState(() => _showFilePanel = !_showFilePanel);
              },
            ),
          ]),
          const Spacer(),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, size: 18, color: fgColor),
            itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
              PopupMenuItem(
                child: _menuItemContent(Icons.folder_open, 'Abrir carpeta'),
                onTap: _openConfig,
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: _menuItemContent(Icons.refresh, 'Recargar'),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String label, List<PopupMenuEntry<dynamic>> items) {
    return PopupMenuButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ),
      itemBuilder: (_) => items,
    );
  }

  Widget _buildSearchField(bool isDark, Color fgColor) {
    return Container(
      color: isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      onPressed: () {},
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      onPressed: () {},
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: fgColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() => _isSearchVisible = false);
              _searchController.clear();
            },
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  void _updateCursorInfo() {
    final text = _editor.codeController.text;
    final selection = _editor.codeController.selection;
    if (!selection.isValid) return;

    final textBeforeCursor = text.substring(0, selection.start);
    final lines = textBeforeCursor.split('\n');
    setState(() {
      _currentLine = lines.length;
      _currentCol = lines.last.length + 1;
    });
  }

  Widget _menuItemContent(IconData icon, String text, [String? shortcut]) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
        if (shortcut != null)
          Text(
            shortcut,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
      ],
    );
  }
}
