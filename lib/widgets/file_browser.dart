import 'package:flutter/material.dart';
import '../services/file_browser_service.dart';

class FileBrowser extends StatefulWidget {
  final FileBrowserService service;
  final String? rootTreeUri;
  final ValueChanged<String> onFileSelected;

  const FileBrowser({
    super.key,
    required this.service,
    this.rootTreeUri,
    required this.onFileSelected,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  String? _currentUri;
  List<FileEntry> _entries = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.rootTreeUri != null) {
      _currentUri = widget.rootTreeUri;
      _loadDirectory();
    }
  }

  @override
  void didUpdateWidget(FileBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootTreeUri != widget.rootTreeUri) {
      _currentUri = widget.rootTreeUri;
      if (_currentUri != null) {
        _loadDirectory();
      } else {
        setState(() {
          _entries = [];
          _error = null;
        });
      }
    }
  }

  Future<void> _loadDirectory() async {
    if (_currentUri == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await widget.service.listDirectory(_currentUri!);
      if (!mounted) return;
      entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navigateTo(String uri) {
    _currentUri = uri;
    _loadDirectory();
  }

  void _goUp() {
    if (_currentUri == null) return;
    final treeUri = widget.rootTreeUri;
    if (treeUri == null) return;
    final parent = widget.service.getParentUri(_currentUri!, treeUri);
    if (parent != _currentUri) _navigateTo(parent);
  }

  bool get _canGoUp {
    if (_currentUri == null || widget.rootTreeUri == null) return false;
    return _currentUri != widget.rootTreeUri;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
    final fg = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1E1E1E);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

    return Container(
      color: bg,
      child: Column(
        children: [
          _buildHeader(borderColor, fg, isDark, bg),
          Divider(height: 1, color: borderColor),
          Expanded(child: _buildBody(fg, borderColor, isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(Color borderColor, Color fg, bool isDark, Color bg) {
    final currentName = _currentUri != null
        ? widget.service.getDisplayPath(_currentUri!)
        : 'Explorador';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (_canGoUp)
            GestureDetector(
              onTap: _goUp,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back, size: 18, color: fg),
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: _reload,
              child: Text(
                currentName,
                style: TextStyle(fontSize: 13, color: fg),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: _reload,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.refresh, size: 16, color: fg),
            ),
          ),
        ],
      ),
    );
  }

  void _reload() => _loadDirectory();

  Widget _buildBody(Color fg, Color borderColor, bool isDark) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 32,
                  color: isDark ? Color(0xFFE06C75) : Color(0xFFD73A49)),
              const SizedBox(height: 8),
              Text(
                'Error al cargar',
                style: TextStyle(fontSize: 13, color: fg),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Color(0xFF999999) : Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _reload,
                child: Icon(Icons.refresh, size: 24, color: fg),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text(
          'Carpeta vacía',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Color(0xFF666666) : Color(0xFF999999),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (_, i) => _buildEntry(_entries[i], fg, borderColor),
    );
  }

  Widget _buildEntry(FileEntry entry, Color fg, Color borderColor) {
    final isDir = entry.isDirectory;
    final icon = isDir ? Icons.folder : Icons.insert_drive_file;
    final iconColor = isDir ? Colors.amber[300] : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isDir) {
            _navigateTo(entry.uri);
          } else {
            widget.onFileSelected(entry.uri);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: fg,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyFileBrowser extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onSelectFolder;

  const EmptyFileBrowser({
    super.key,
    required this.isDark,
    this.onSelectFolder,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
    final fg = isDark ? const Color(0xFF999999) : const Color(0xFF666666);

    return Container(
      color: bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 40, color: fg),
              const SizedBox(height: 12),
              Text(
                'Ninguna carpeta abierta',
                style: TextStyle(fontSize: 14, color: fg),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Usa "Abrir carpeta..." en el menú File\npara comenzar a explorar',
                style: TextStyle(fontSize: 12, color: fg),
                textAlign: TextAlign.center,
              ),
              if (onSelectFolder != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onSelectFolder,
                  icon: const Icon(Icons.create_new_folder, size: 16),
                  label: const Text('Abrir carpeta...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
