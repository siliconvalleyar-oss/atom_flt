import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/file_browser_service.dart';

class FilePanel extends StatefulWidget {
  final String directoryPath;
  final String? treeUri;
  final void Function(String uri) onFileSelected;
  final VoidCallback onConfig;

  const FilePanel({
    super.key,
    required this.directoryPath,
    this.treeUri,
    required this.onFileSelected,
    required this.onConfig,
  });

  @override
  State<FilePanel> createState() => _FilePanelState();
}

class _FilePanelState extends State<FilePanel> {
  final FileBrowserService _service = FileBrowserService();
  List<FileEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void didUpdateWidget(FilePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.directoryPath != widget.directoryPath ||
        oldWidget.treeUri != widget.treeUri) {
      _loadFiles();
    }
  }

  Future<void> _loadFiles() async {
    if (widget.directoryPath.isEmpty && widget.treeUri == null) {
      setState(() {
        _entries = [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final isSAF = widget.treeUri != null && widget.treeUri!.startsWith('content://');
      debugPrint('[FilePanel] _loadFiles: isSAF=$isSAF treeUri=${widget.treeUri} path=${widget.directoryPath}');

      if (isSAF) {
        await _service.openFolder(widget.treeUri!);
        final entries = await _service.listDirectory();
        entries.sort((a, b) {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        setState(() {
          _entries = entries;
          _loading = false;
        });
      } else {
        final apiLevel = await _service.getApiLevel();
        debugPrint('[FilePanel] apiLevel=$apiLevel');

        if (apiLevel >= 33) {
          setState(() {
            _error = 'Android 13+ requiere SAF.\nUsa Configuración > Seleccionar carpeta.';
            _loading = false;
          });
          return;
        }

        final hasPermission = await _service.isExternalStorageManager();
        debugPrint('[FilePanel] isExternalStorageManager=$hasPermission');

        if (!hasPermission) {
          debugPrint('[FilePanel] requesting MANAGE_EXTERNAL_STORAGE...');
          final granted = await _service.requestManageStorage();
          debugPrint('[FilePanel] requestManageStorage result=$granted');
          if (!granted) {
            setState(() {
              _error = 'Permiso de almacenamiento denegado.\nUsa Configuración > Seleccionar carpeta.';
              _loading = false;
            });
            return;
          }
        }

        await _service.openFolder(widget.directoryPath);
        final entries = await _service.listDirectory();
        entries.sort((a, b) {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } on PlatformException catch (e) {
      final msg = _friendlyError(e.message ?? '$e');
      setState(() {
        _error = msg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _friendlyError(String msg) {
    if (msg.contains('ACCESS_DENIED') || msg.contains('Permission denial')) {
      return 'Acceso denegado por scoped storage.\nUsa Configuración > Seleccionar carpeta para otorgar permisos.';
    }
    if (msg.contains('NOT_A_DIRECTORY')) {
      return 'La ruta seleccionada no es un directorio.';
    }
    if (msg.contains('No root for content') ||
        msg.contains('Failed to determine') ||
        msg.contains('FileNotFoundException')) {
      return 'Error de permisos SAF.\nRe-selecciona la carpeta en Configuración.';
    }
    if (msg.contains('USE_SAF')) {
      return 'Android 13+ requiere SAF.\nUsa Configuración > Seleccionar carpeta.';
    }
    if (msg.contains('not implemented') || msg.contains('MissingPlugin')) {
      return 'Canal nativo no disponible. Reinicia la app.';
    }
    return msg;
  }

  Future<void> _enterDir(FileEntry entry) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.navigateTo(entry.docId);
      final entries = await _service.listDirectory();
      entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on PlatformException catch (e) {
      final msg = _friendlyError(e.message ?? '$e');
      setState(() {
        _error = msg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _goUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.goUp();
      final entries = await _service.listDirectory();
      entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on PlatformException catch (e) {
      final msg = _friendlyError(e.message ?? '$e');
      setState(() {
        _error = msg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final fg = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1E1E1E);
    final dim = isDark ? const Color(0xFF666666) : const Color(0xFF999999);

    return Container(
      width: 200,
      color: bg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE8E8E8),
            child: Row(
              children: [
                if (_service.canGoUp)
                  GestureDetector(
                    onTap: _goUp,
                    child: Icon(Icons.arrow_back, size: 14, color: dim),
                  )
                else
                  Icon(Icons.folder, size: 14, color: dim),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.directoryPath.isEmpty
                        ? 'Archivos'
                        : widget.directoryPath.split('/').where((p) => p.isNotEmpty).lastOrNull ?? 'Archivos',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: dim),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onConfig,
                  child: Icon(Icons.settings, size: 14, color: dim),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(isDark, fg, dim)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, Color fg, Color dim) {
    if (widget.directoryPath.isEmpty && widget.treeUri == null) {
      return _buildOnboarding(isDark, dim);
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_off, size: 32, color: Colors.orange[300]),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.orange[300]),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: widget.onConfig,
                icon: const Icon(Icons.settings, size: 14),
                label: const Text('Configurar', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 32, color: dim),
            const SizedBox(height: 4),
            Text('(carpeta vacía)', style: TextStyle(fontSize: 11, color: dim)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (_, i) {
        final e = _entries[i];
        return _FileEntryTile(
          entry: e,
          isDark: isDark,
          fg: fg,
          dim: dim,
          onTap: () {
            if (e.isDirectory) {
              _enterDir(e);
            } else {
              widget.onFileSelected(e.uri);
            }
          },
        );
      },
    );
  }

  Widget _buildOnboarding(bool isDark, Color dim) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 40, color: dim),
            const SizedBox(height: 8),
            Text(
              'Selecciona una carpeta para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: dim),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onConfig,
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Seleccionar carpeta', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileEntryTile extends StatelessWidget {
  final FileEntry entry;
  final bool isDark;
  final Color fg;
  final Color dim;
  final VoidCallback onTap;

  const _FileEntryTile({
    required this.entry,
    required this.isDark,
    required this.fg,
    required this.dim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            Icon(
              entry.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
              size: 14,
              color: entry.isDirectory ? const Color(0xFFC8A84E) : dim,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                entry.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: fg),
              ),
            ),
            if (!entry.isDirectory)
              Text(
                _formatSize(entry.length),
                style: TextStyle(fontSize: 9, color: dim),
              ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}K';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
  }
}
