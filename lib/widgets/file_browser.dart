import 'package:flutter/material.dart';
import '../services/file_browser_service.dart';

class FileBrowser extends StatefulWidget {
  final FileBrowserService service;
  final String rootTreeUri;
  final ValueChanged<String> onFileSelected;

  const FileBrowser({
    super.key,
    required this.service,
    required this.rootTreeUri,
    required this.onFileSelected,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  List<FileEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.service.ping().then((r) {
      debugPrint('[FileBrowser] ping response: $r');
    }).catchError((e) {
      debugPrint('[FileBrowser] ping error: $e');
    });
    _openFolder();
  }

  @override
  void didUpdateWidget(FileBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootTreeUri != widget.rootTreeUri) {
      _openFolder();
    }
  }

  Future<void> _openFolder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.openFolder(widget.rootTreeUri);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await widget.service.listDirectory();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _navigateTo(String docId) async {
    await widget.service.navigateTo(docId);
    await _load();
  }

  Future<void> _goUp() async {
    if (!widget.service.canGoUp) return;
    await widget.service.goUp();
    await _load();
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
          _buildHeader(fg, borderColor),
          Divider(height: 1, color: borderColor),
          Expanded(child: _buildBody(fg, borderColor, isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(Color fg, Color borderColor) {
    final name = widget.service.currentDisplayName.isNotEmpty
        ? widget.service.currentDisplayName
        : 'Explorador';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (widget.service.canGoUp)
            GestureDetector(
              onTap: _goUp,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back, size: 18, color: fg),
              ),
            ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 13, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.refresh, size: 16, color: fg),
            ),
          ),
        ],
      ),
    );
  }

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
                onTap: _load,
                child: Icon(Icons.refresh, size: 24, color: fg),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 40,
                  color: isDark ? Color(0xFF666666) : Color(0xFF999999)),
              const SizedBox(height: 12),
              Text(
                'Carpeta vacía',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Color(0xFF999999) : Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La carpeta no contiene archivos\naccesibles o no se pudieron listar',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Color(0xFF666666) : Color(0xFF999999),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (_, i) => _buildEntry(_entries[i], fg),
    );
  }

  Widget _buildEntry(FileEntry entry, Color fg) {
    final isDir = entry.isDirectory;
    final icon = isDir ? Icons.folder : Icons.insert_drive_file;
    final iconColor = isDir ? Colors.amber[300] : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isDir) {
            _navigateTo(entry.docId);
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
