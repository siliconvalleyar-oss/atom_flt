import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/config_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  static const _channel = MethodChannel('com.atom_flt/file_browser');
  final _pathController = TextEditingController();
  bool _loading = true;
  bool _firstTime = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final path = await ConfigService.getDefaultDirectory();
    final firstTime = await ConfigService.isOnboardingDone() == false;
    setState(() {
      _pathController.text = path;
      _loading = false;
      _firstTime = firstTime;
    });
    if (firstTime) {
      await ConfigService.setOnboardingDone();
    }
  }

  Future<void> _pickDirectory() async {
    try {
      final uri = await _channel.invokeMethod<String>('pickDirectory');
      if (uri != null) {
        await ConfigService.setDirectory(uri, treeUri: uri);
        _pathController.text = uri;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Carpeta configurada correctamente'),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selección cancelada'),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      title: Text(_firstTime ? 'Bienvenido a atom' : 'Configuración'),
      content: _loading
          ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_firstTime)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Para comenzar, selecciona la carpeta raíz de tu proyecto.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                Text(
                  'Carpeta del proyecto',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _pathController.text.isEmpty
                      ? 'No seleccionada'
                      : _pathController.text,
                  style: TextStyle(
                    fontSize: 11,
                    color: _pathController.text.isEmpty
                        ? Colors.orange
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickDirectory,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('Seleccionar carpeta'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona la carpeta raíz de tu proyecto. '
                  'Se usarán permisos SAF para acceder a los archivos.',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
