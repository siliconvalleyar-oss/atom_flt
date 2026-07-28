# Skill: atom_flt Codebase

Reusable knowledge about the `atom_flt` Flutter codebase — architecture, key files, patterns, and conventions.

---

## 1. PROJECT OVERVIEW

**Name:** atom_flt  
**Type:** Flutter source code editor (minimalist, Atom-inspired)  
**Platforms:** Android (primary), iOS, Linux, macOS, Windows  
**SDK:** Dart ^3.12.2, Flutter stable  

**Purpose:** A lightweight, portable code editor with file browser, syntax highlighting, search, and multi-platform support.

---

## 2. DIRECTORY STRUCTURE

```
lib/
├── main.dart                          # Entry point, Provider setup
├── app.dart                           # MaterialApp with theme
├── editor/
│   ├── editor_screen.dart             # Main screen (menu, editor, file panel, status bar)
│   └── editor_controller.dart         # State: file path, content, undo/redo, syntax
├── services/
│   ├── file_browser_service.dart      # SAF + File API abstraction (FileEntry, list, navigate)
│   ├── file_service.dart              # Read/write files via native channel or dart:io
│   ├── config_service.dart            # SharedPreferences: directory path, tree URI
│   ├── preferences_service.dart       # [⚠️ DEAD CODE] Generic SharedPreferences wrapper
│   └── version_service.dart           # Load VERSION file asset
├── widgets/
│   ├── file_panel.dart                # Active sidebar file browser (uses FileBrowserService)
│   ├── file_browser.dart              # [⚠️ DEAD CODE] Old drawer-based file browser
│   ├── config_screen.dart             # SAF picker + directory config dialog
│   ├── status_bar.dart                # [⚠️ DEAD CODE] Old status bar widget
│   └── search_bar.dart                # [⚠️ DEAD CODE] Old search widget
├── models/
│   ├── syntax_language.dart           # Extension → highlight language map
│   └── file_model.dart                # [⚠️ DEAD CODE] Unused data model
└── theme/
    ├── app_theme.dart                 # Light/dark ThemeData definitions
    └── theme_provider.dart            # ChangeNotifier for theme toggle
```

**Dead code summary:** `file_browser.dart`, `status_bar.dart`, `search_bar.dart`, `preferences_service.dart`, `file_model.dart` — these files exist but are NOT imported anywhere.

---

## 3. ARCHITECTURE & STATE MANAGEMENT

### 3.1 Current state (mixed architecture)

```
main.dart (MultiProvider)
├── ThemeProvider (ChangeNotifier)     ← USED by MaterialApp themeMode
├── EditorController (ChangeNotifier)  ← NOT USED by editor_screen.dart
└── AtomFlApp
    └── EditorScreen (StatefulWidget)
         ├── _editor = EditorController()  ← LOCAL instance (DUPLICATE)
         ├── _fileService = FileService()  ← Direct use
         └── FilePanel
              └── FileBrowserService()     ← Direct use (no Provider)
```

**Critical issue:** Two `EditorController` instances exist:
- One in `MultiProvider` (created in `main.dart`) — never receives events
- One local in `EditorScreen` (created inline) — not accessible from other widgets

### 3.2 Provider usage

```dart
// main.dart — providers configured but inconsistently consumed
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: themeProvider),
    ChangeNotifierProvider.value(value: editorController),
  ],
  child: const AtomFlApp(),
)
```

| Provider | Created in | Consumed by | Status |
|----------|-----------|-------------|--------|
| ThemeProvider | `main.dart` | `app.dart` (Consumer), `status_bar.dart` (watch) | ✅ Works |
| EditorController | `main.dart` | **Nobody** | ❌ Unused |

### 3.3 Data flow

```
User taps file in FilePanel
  → FilePanel.onFileSelected callback
    → EditorScreen calls _editor.openFile(uri)
      → FileService.readFile(path)  [native channel or dart:io]
        → EditorController updates codeController.text
          → UI rebuild via setState() in EditorScreen
```

---

## 4. FILE BROWSER SYSTEM

### 4.1 Components

```
FilePanel (sidebar widget)
  └── FileBrowserService (logic)
       ├── SAF path: MethodChannel('com.atom_flt/file_browser') → MainActivity.kt
       │    ├── listDirectory → DocumentsContract query
       │    ├── readFile/writeFile → ContentResolver streams
       │    └── pickDirectory → Intent.ACTION_OPEN_DOCUMENT_TREE
       └── File API path: dart:io → Directory(path).list()
            ├── listDirectoryPath → File(path).listFiles() (native)
            └── readFilePath/writeFilePath → File(path).read/write (native)
```

### 4.2 SAF vs File API decision

```dart
// In FilePanel._loadFiles():
if (widget.treeUri != null) {
  // SAF path — uses content:// URI from Storage Access Framework picker
  await _service.openFolder(widget.treeUri!);
  final entries = await _service.listDirectory();
} else if (widget.directoryPath.isNotEmpty) {
  // File API path — uses direct file system access
  await _service.openFolder(widget.directoryPath);
  final entries = await _service.listDirectory();
}
```

### 4.3 Key behavior

- **First launch**: `_directoryPath = ''`, `_treeUri = null` → FilePanel shows onboarding → auto-opens ConfigScreen
- **SAF picker**: User selects folder → `treeUri` saved to SharedPreferences → all browsing uses SAF
- **File API**: Falls back to dart:io `Directory.list()` — **will fail on Android 11+** without `MANAGE_EXTERNAL_STORAGE`
- `tryFallbackSAF` was **removed** from native code
- `pathToDocId` was **removed** from native code
- `listDirectoryPath` returns `ACCESS_DENIED` error on scoped-storage-blocked directories

---

## 5. NATIVE CHANNEL (Android)

**Channel name:** `com.atom_flt/file_browser`  
**File:** `android/app/src/main/kotlin/.../MainActivity.kt`

### Methods exposed:

| Method | Args | Returns | Description |
|--------|------|---------|-------------|
| `ping` | — | `"pong"` | Health check |
| `getApiLevel` | — | `int` | `Build.VERSION.SDK_INT` |
| `pickDirectory` | — | `String?` | SAF ACTION_OPEN_DOCUMENT_TREE, returns tree URI |
| `isExternalStorageManager` | — | `bool` | Android 11+ full storage permission check |
| `requestManageStorage` | — | `bool` | Opens system settings for MANAGE_EXTERNAL_STORAGE |
| `listDirectory` | treeUri, docId | `List<Map>` | SAF query via DocumentsContract |
| `listDirectoryPath` | path | `List<Map>` or error | `File(path).listFiles()`, returns ACCESS_DENIED if null |
| `readFile` | uri | `String` | Read via ContentResolver (content:// URIs) |
| `readFilePath` | path | `String` | Read via `File(path).readText()` |
| `writeFile` | uri, content | `bool` | Write via ContentResolver |
| `writeFilePath` | path, content | `bool` | Write via `File(path).writeText()` |

### SAF permission handling:
```kotlin
override fun onActivityResult(requestCode, resultCode, data) {
    when (requestCode) {
        PICK_DIRECTORY_REQUEST -> takePersistableUriPermission(...)
        MANAGE_STORAGE_REQUEST -> result = Environment.isExternalStorageManager()
    }
}
```

---

## 6. CRITICAL BUGS & REFACTORING NEEDED

### 🔴 Bug 1: EditorController duplicado
- `main.dart` creates EditorController in Provider
- `editor_screen.dart` creates **separate** EditorController local instance
- Fix: Remove local instance, use `context.read<EditorController>()`

### 🔴 Bug 2: undoCount/redoCount desincronizados
- `_onCodeChanged()` only sets `_isModified = true`, never updates undo/redo counts
- Actual history changes happen inside CodeController but counters aren't synced
- Fix: Subscribe to CodeController history changes, or remove manual counters

### 🔴 Bug 3: Search arrows no funcionales
- Both `onPressed: () {}` — empty callbacks
- Fix: Implement or remove buttons

### 🟡 Feature gap: Missing Ctrl+Z / Ctrl+Y
- KeyboardListener handles Ctrl+S, Ctrl+O, Ctrl+N, Ctrl+B, Ctrl+F
- But NOT Ctrl+Z (undo) and Ctrl+Y (redo)

### 🟡 Code duplication: FilePanel sort + try/catch repeated 3x
- `entries.sort(...)` block appears in `_loadFiles()`, `_enterDir()`, `_goUp()`
- Same `try/on PlatformException/catch` pattern appears 3 times
- Fix: Extract helper methods

---

## 7. EDITOR SYSTEM

### 7.1 Current implementation

```dart
// editor_screen.dart — uses plain TextField, NOT CodeField
TextField(
  controller: _editor.codeController,   // CodeController from flutter_code_editor
  maxLines: null,
  expands: true,
  // NO syntax highlighting — plain monospace text
)
```

**Note:** `EditorController` wraps `CodeController` (from `flutter_code_editor`), but the UI only uses it as a plain `TextField`. The language detection, syntax highlighting, and CodeField are NOT used.

### 7.2 Line numbers (custom implementation)

```dart
_buildLineNumbers(fgColor) {
  final lineCount = _editor.code.split('\n').length;
  return ListView.builder(
    itemCount: lineCount,
    itemBuilder: (_, index) => Text('${index + 1}'),
  );
}
```
Simple but functional. Line count recalculated on every change.

---

## 8. THEME SYSTEM

### 8.1 ThemeProvider (ChangeNotifier)

```dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;     // persisted via SharedPreferences
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
```

### 8.2 ThemeData (AppTheme)

```dart
static final light = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Color(0xFFFAFAFA),
  colorScheme: ColorScheme.light(primary: Color(0xFF4A90D9), ...),
);

static final dark = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF1E1E1E),
  ...
);
```

### 8.3 Theme usage in editor_screen.dart

**Does NOT use Provider** — instead reads `Theme.of(context).brightness`:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

There is **no theme toggle button** in the current `editor_screen.dart` (the original had one in StatusBar).

---

## 9. FILE PANEL WIDGET TREE

```
FilePanel (StatefulWidget, width: 200)
├── Header bar (32px)
│   ├── Arrow back icon (if canGoUp)
│   │   └── onTap: _goUp()
│   ├── Folder icon (if root)
│   ├── Current directory name
│   └── Settings icon
│       └── onTap: widget.onConfig
└── Body (Expanded)
    ├── [Onboarding] — if no path + no treeUri
    │   ├── Icon(Icons.folder_open, size: 40)
    │   ├── Text("Selecciona una carpeta para comenzar")
    │   └── OutlinedButton("Seleccionar carpeta")
    ├── [Loading] — CircularProgressIndicator
    ├── [Error] — error message + "Configurar" button
    ├── [Empty] — "(carpeta vacía)"
    └── [List] — ListView of FileEntryTile
         ├── Folder icon (amber) → onTap: _enterDir()
         └── File icon (dim) → onTap: onFileSelected(uri)
```

---

## 10. ERROR HANDLING

### 10.1 Friendly error mapping (file_panel.dart)

```dart
String _friendlyError(String msg) {
  if (msg.contains('ACCESS_DENIED') || msg.contains('Permission denial'))
    → "Acceso denegado por scoped storage. Usa Configuración..."
  if (msg.contains('NOT_A_DIRECTORY'))
    → "La ruta seleccionada no es un directorio."
  if (msg.contains('No root for content') || msg.contains('Failed to determine'))
    → "Error de permisos SAF. Re-selecciona la carpeta en Configuración."
  if (msg.contains('not implemented') || msg.contains('MissingPlugin'))
    → "Canal nativo no disponible. Reinicia la app."
}
```

### 10.2 Error display (file_panel.dart)

```
[Error State]
  Icon(Icons.folder_off, orange)
  Text(_error)                          // friendly message
  OutlinedButton("Configurar")          // opens ConfigScreen
```

---

## 11. KEYBOARD SHORTCUTS (editor_screen.dart)

| Shortcut | Action | Implemented? |
|----------|--------|-------------|
| Ctrl+S | Save | ✅ |
| Ctrl+Shift+S | Save As | ✅ |
| Ctrl+O | Open file | ✅ |
| Ctrl+N | New file | ✅ |
| Ctrl+B | Toggle file panel | ✅ |
| Ctrl+F | Toggle search | ✅ |
| Ctrl+Z | Undo | ❌ Missing |
| Ctrl+Y | Redo | ❌ Missing |
| Ctrl+A | Select all | ❌ Missing |

---

## 12. DEPENDENCIES (pubspec.yaml)

| Package | Version | Used? | Purpose |
|---------|---------|-------|---------|
| flutter | SDK | ✅ | Core framework |
| cupertino_icons | ^1.0.8 | ❌ | Not used |
| provider | ^6.1.0 | ⚠️ | Only ThemeProvider consumed |
| shared_preferences | ^2.2.0 | ✅ | Config + theme persistence |
| file_picker | ^8.0.0 | ⚠️ | Only for Save As dialog |
| path_provider | ^2.1.0 | ❌ | Not used |
| flutter_code_editor | ^0.3.2 | ⚠️ | Only CodeController, not CodeField |
| highlight | ^0.7.0 | ⚠️ | Syntax detection, but not rendered |
| flutter_lints | ^6.0.0 | ✅ | Dev dependency for linting |

**Dependency override:** `jni: 1.0.0` (workaround for Gradle 9+ compatibility)

---

## 13. CONFIGURATION & PERSISTENCE

**Key:** SharedPreferences (`ConfigService`)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `default_directory` | String | `''` | Last used directory path |
| `tree_uri` | String? | `null` | SAF tree URI for scoped storage |
| `dark_mode` | Bool | `false` | Theme preference (used by ThemeProvider) |

**ConfigScreen flow:**
1. User taps "Seleccionar carpeta"
2. `pickDirectory` MethodChannel → `ACTION_OPEN_DOCUMENT_TREE` SAF intent
3. User picks folder → `takePersistableUriPermission` saves permission
4. URI saved to `ConfigService.setDirectory(uri, treeUri: uri)`
5. `EditorScreen._loadConfig()` reloads → FilePanel re-renders

---

## 14. COMMON TASKS

### Add a new file type for syntax highlighting
Edit `lib/models/syntax_language.dart`:
```dart
static const Map<String, String> _extensionMap = {
  '.newlang': 'newlang',  // Add entry
  ...
};
```

### Add a new native method
1. Add `methodName` to `when` block in `MainActivity.kt`
2. Add invoke method in `FileBrowserService` or `FileService`
3. Call from Dart widget

### Debug file browser issues
1. Check `debugPrint` / `Log.i` output for "atom_flt" tag
2. Verify `_treeUri` content in SharedPreferences
3. On Android, check Logcat for `atom_flt` tag messages
4. Test with explicit SAF picker (not File API)

### Fix onboarding flow
- `EditorScreen._loadConfig()` auto-opens ConfigScreen if path empty
- `ConfigScreen` reads saved config via `ConfigService`
- After save, `EditorScreen._loadConfig()` re-reads config

---

## 15. TESTING

**Test file:** `test/widget_test.dart`  
**Run:** `flutter test` or `dart analyze`

No unit tests exist for:
- `EditorController` (undo/redo, open/save, word highlighting)
- `FileService` (read/write, content:// vs file://)
- `FileBrowserService` (listDirectory, navigate, goUp)
- `ConfigService` (read/write config)
- `ThemeProvider` (toggle, persist)

---

## 16. STATE VERIFICATION CHECKLIST FOR AI

When an AI visits this codebase, it should verify:

- [ ] Does `editor_screen.dart` use the Provider's `EditorController` or a local one?
- [ ] Is `file_browser.dart` imported anywhere? If not, delete it.
- [ ] Is `status_bar.dart` imported anywhere? If not, delete it.
- [ ] Is `search_bar.dart` imported anywhere? If not, delete it.
- [ ] Is `preferences_service.dart` imported anywhere? If not, delete it.
- [ ] Is `file_model.dart` imported anywhere? If not, delete it.
- [ ] Do Ctrl+Z and Ctrl+Y shortcuts exist in `editor_screen.dart`?
- [ ] Do the search arrows have non-empty `onPressed` callbacks?
- [ ] Does `FilePanel` have duplicated `sort` blocks (check count)?
- [ ] Does the app build without errors: `flutter analyze`?
- [ ] Is `path_provider` used anywhere? If not, remove from pubspec.

---

## 17. QUICK REFERENCE

```
Project root: /mnt/disk/src/flutter_src/atom_flt
Main entry:   lib/main.dart
Editor UI:    lib/editor/editor_screen.dart
Native code:  android/app/src/main/kotlin/.../MainActivity.kt
Diagnostics:  docs/DIAGNOSTICO_FILE_BROWSER.md
Checklist:    docs/TODO.md
```

---

*Skill version: 1.0 — Created 27 July 2026*
*Load with: `skill tool name: atom_flt_codebase`*
