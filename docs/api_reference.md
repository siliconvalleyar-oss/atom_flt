# API Reference — atom_flt

## Dependencias externas

### provider ^6.1.0

Gestión de estado declarativa para Flutter.

**Uso principal**:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => EditorController()),
  ],
  child: App(),
)
```

**Referencia**: https://pub.dev/packages/provider

### shared_preferences ^2.2.0

Almacenamiento persistente de pares clave-valor para preferencias del usuario.

**Uso principal**:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('dark_mode', true);
final isDark = prefs.getBool('dark_mode') ?? false;
```

**Referencia**: https://pub.dev/packages/shared_preferences

### file_picker ^8.0.0

Diálogo nativo de selección de archivos multiplataforma.

**Uso principal**:
```dart
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['dart', 'py', 'js', 'cpp', 'h', 'txt'],
);
if (result != null) {
  final path = result.files.single.path;
}
```

**Referencia**: https://pub.dev/packages/file_picker

### path_provider ^2.1.0

Obtiene rutas de directorios comunes del sistema (documentos, temporal, etc.).

**Uso principal**:
```dart
final dir = await getApplicationDocumentsDirectory();
final file = File('${dir.path}/ejemplo.txt');
```

**Referencia**: https://pub.dev/packages/path_provider

### flutter_code_editor ^0.3.0 + highlight ^0.7.0

Widget de editor de código con resaltado de sintaxis, numeración de líneas y virtualización.

**Uso principal**:
```dart
CodeController controller = CodeController(
  text: 'código fuente',
  language: dart,
);
CodeTheme(
  data: CodeThemeData(styles: monokaiSublimeTheme),
  child: CodeField(controller: controller),
)
```

**Referencia**:
- https://pub.dev/packages/flutter_code_editor
- https://pub.dev/packages/highlight

### google_fonts ^6.1.0

Carga dinámica de fuentes de Google Fonts.

**Uso principal**:
```dart
GoogleFonts.jetBrainsMono(),
```

**Referencia**: https://pub.dev/packages/google_fonts

---

## API interna

### ThemeProvider (lib/theme/theme_provider.dart)

```dart
class ThemeProvider extends ChangeNotifier {
  bool get isDarkMode;
  ThemeData get currentTheme;
  Future<void> toggleTheme();
  Future<void> loadPreferences();
}
```

### EditorController (lib/editor/editor_controller.dart)

```dart
class EditorController extends ChangeNotifier {
  String get content;
  String? get filePath;
  String? get fileName;
  int get currentLine;
  int get currentColumn;
  bool get isModified;
  bool get canUndo;
  bool get canRedo;

  void setContent(String text);
  void undo();
  void redo();
  Future<void> openFile(String path);
  Future<void> saveFile();
  Future<void> saveFileAs(String path);
  void newFile();
  void updateCursorPosition(int line, int column);
  String? getWordAtCursor();
  List<int> findOccurrences(String word);
}
```

### FileService (lib/services/file_service.dart)

```dart
class FileService {
  Future<String> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<bool> fileExists(String path);
  String getFileExtension(String path);
  String getFileName(String path);
}
```

### SyntaxLanguage (lib/models/syntax_language.dart)

```dart
class SyntaxLanguage {
  static final Map<String, String> extensionMap = {
    '.dart': 'dart',
    '.py': 'python',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.cpp': 'cpp',
    '.hpp': 'cpp',
    '.h': 'c',
    '.c': 'c',
    '.java': 'java',
    '.html': 'html',
    '.css': 'css',
    '.json': 'json',
    '.xml': 'xml',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.md': 'markdown',
    '.sh': 'bash',
    '.txt': 'plaintext',
  };

  static String? detect(String path);
}
```
