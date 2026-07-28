# Skill: atom_flt Codebase

Reusable knowledge about the `atom_flt` Flutter codebase — architecture, key files, patterns, and conventions.

---

## 1. PROJECT OVERVIEW

**Name:** atom_flt
**Type:** Flutter source code editor (minimalist, Atom-inspired)
**Platforms:** Android (primary, tested on Android 16/MIUI)
**SDK:** Dart ^3.12.2, Flutter 3.44.7, Kotlin
**Build:** `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 flutter build apk --debug`
**Deploy:** `adb -s <device> install -r build/app/outputs/flutter-apk/app-debug.apk`

**Purpose:** A lightweight, portable code editor with SAF file browser, syntax highlighting, search, and multi-platform support.

---

## 2. DIRECTORY STRUCTURE

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp with theme
├── editor/
│   ├── editor_screen.dart             # Main screen (menu, CodeField, file panel, status bar)
│   └── editor_controller.dart         # State: file path, content, undo/redo, syntax
├── services/
│   ├── file_browser_service.dart      # SAF + File API abstraction (FileEntry, list, navigate, getDisplayPath)
│   ├── file_service.dart              # Read/write files via native channel or dart:io
│   └── config_service.dart            # SharedPreferences: directory path, tree URI, onboarding
├── widgets/
│   ├── file_panel.dart                # Always-visible sidebar file browser (uses FileBrowserService)
│   └── config_screen.dart             # SAF picker + directory config dialog + welcome onboarding
├── models/
│   └── syntax_language.dart           # Extension → highlight language map
└── theme/
    ├── app_theme.dart                 # Light/dark ThemeData definitions
    └── theme_provider.dart            # ChangeNotifier for theme toggle
```

**Dead code (not imported):** `file_browser.dart`, `status_bar.dart`, `search_bar.dart`, `preferences_service.dart`, `file_model.dart`

---

## 3. ARCHITECTURE & STATE MANAGEMENT

### 3.1 Current flow

```
main.dart
└── AtomFlApp
    └── EditorScreen (StatefulWidget)
         ├── _editor = EditorController()   ← LOCAL instance
         ├── _fileService = FileService()
         ├── _browserService = FileBrowserService()
         └── FilePanel (width: 200)
              └── FileBrowserService()      ← Direct use (no Provider)
```

**Note:** `EditorController` is instantiated locally in `EditorScreen`, NOT from Provider. `ThemeProvider` is the only Provider consumed.

### 3.2 Data flow

```
User taps file in FilePanel
  → FilePanel.onFileSelected(uri)
    → EditorScreen calls _editor.openFile(uri)
      → FileService.readFile(uri)  [native channel]
        → CodeController.text = content (suppress notifications during load)
          → CodeField renders with syntax highlighting
          → UI rebuild via setState()
```

### 3.3 EditorController key methods

```dart
// editor_controller.dart
Future<void> openFile({required String uri, String? filePath})
  // Uses _suppressNotifications flag to avoid RangeError during text assignment
  // Sets codeController.text, then selection to 0, then language detection

Future<void> saveFile()     // Prefers fileUri (content://) over filePath
Future<void> saveFileAs(path)
void newFile()               // Resets controller, uses _suppressNotifications
```

**Important:** `_suppressNotifications` flag replaces `removeListener`/`addListener` pattern to avoid RangeError with CodeController.

---

## 4. EDITOR SYSTEM

### 4.1 CodeField (flutter_code_editor)

The editor uses `CodeField` from `flutter_code_editor` which provides:
- **Syntax highlighting** via `CodeController` with language detection
- **Line numbers** via `GutterStyle` (linked_scroll_controller for scroll sync)
- **Keyboard shortcuts** (Ctrl+Z undo, Ctrl+Y redo, Tab indent built-in)

```dart
CodeField(
  controller: _editor.codeController,
  expands: true,
  wrap: false,
  background: bgColor,
  gutterStyle: GutterStyle(
    width: 48,
    showLineNumbers: true,
    showErrors: false,
    showFoldingHandles: false,
    margin: 8,
    textStyle: TextStyle(...),
  ),
  textStyle: TextStyle(fontFamily: 'monospace', fontSize: 14, ...),
  cursorColor: Color(0xFF007ACC),
  padding: EdgeInsets.symmetric(horizontal: 16),
  onChanged: (value) { /* do NOT reassign codeController.text here */ },
)
```

**Critical:** Do NOT set `codeController.text = value` in `onChanged` — CodeField updates the controller internally. Re-assigning resets scroll position and causes line number desync.

### 4.2 Syntax detection

```dart
// models/syntax_language.dart
SyntaxLanguage.detect(path)  // Returns highlight language key from extension map
// Supports: dart, python, javascript, typescript, cpp, c, java, html, css,
//           json, xml, yaml, md, sh, rb, php, rs, go, kt, swift, sql, etc.
```

---

## 5. FILE BROWSER SYSTEM

### 5.1 Components

```
FilePanel (sidebar widget, width: 200)
  └── FileBrowserService (logic)
       ├── SAF path: MethodChannel('com.atom_flt/file_browser') → MainActivity.kt
       │    ├── openFolder → getRootDocId (native)
       │    ├── listDirectory → DocumentsContract query
       │    ├── navigateTo → update _currentDocId
       │    └── goUp → strip docId to parent
       └── File API path: dart:io (blocked on API ≥33)
```

### 5.2 SAF routing (FilePanel._loadFiles)

```dart
final isSAF = widget.treeUri != null && widget.treeUri!.startsWith('content://');
if (isSAF) {
  await _service.openFolder(widget.treeUri!);
  final entries = await _service.listDirectory();
} else {
  final apiLevel = await _service.getApiLevel();
  if (apiLevel >= 33) {
    // Show error: "Android 13+ requiere SAF"
    return;
  }
  // File API path with permission checks
}
```

### 5.3 FilePanel states

```
[Onboarding]  — no path + no treeUri → shows "Selecciona una carpeta"
[Loading]     — CircularProgressIndicator
[Error]       — orange icon + error message + "Configurar" button
[Empty]       — "(carpeta vacía)"
[List]        — ListView of _FileEntryTile (InkWell + Material)
  ├── Folder icon (amber) → _enterDir(entry)
  └── File icon (dim)     → onFileSelected(entry.uri)
```

### 5.4 Key behaviors

- **Panel toggle:** Tap "atom" text (blue) in menu bar, or Ctrl+B
- **Back arrow:** InkWell with padding(6) for touch target, calls `_goUp()`
- **Navigation:** `_enterDir` → `navigateTo(entry.docId)` → `listDirectory()`
- **File display:** `getDisplayPath(uri)` decodes `%20` etc. via `Uri.decodeComponent`

---

## 6. NATIVE CHANNEL (Android)

**Channel name:** `com.atom_flt/file_browser`
**File:** `android/app/src/main/kotlin/.../MainActivity.kt`

### Methods exposed:

| Method | Args | Returns | Description |
|--------|------|---------|-------------|
| `ping` | — | `"pong"` | Health check |
| `getApiLevel` | — | `int` | `Build.VERSION.SDK_INT` |
| `pickDirectory` | — | `String?` | SAF ACTION_OPEN_DOCUMENT_TREE |
| `isExternalStorageManager` | — | `bool` | Android 11+ full storage permission |
| `requestManageStorage` | — | `bool` | Opens system settings |
| `getRootDocId` | treeUri | `String` | `DocumentsContract.getTreeDocumentId()` |
| `listDirectory` | treeUri, docId | `List<Map>` | SAF query via DocumentsContract |
| `listDirectoryPath` | path | `List<Map>` or error | Blocked on API ≥33 |
| `readFile` | uri | `String` | ContentResolver input stream |
| `readFilePath` | path | `String` | `File(path).readText()` |
| `writeFile` | uri, content | `bool` | ContentResolver output stream |
| `writeFilePath` | path, content | `bool` | `File(path).writeText()` |

---

## 7. LAYOUT & UI

### 7.1 Main layout (editor_screen.dart)

```
Scaffold
└── SafeArea (handles Android 16 edge-to-edge system bars)
    └── Column
        ├── Menu bar (height: 32)
        │   ├── "atom" (GestureDetector → toggle panel)
        │   ├── SingleChildScrollView(Row) — Archivo, Edición menus
        │   └── PopupMenuButton (more_vert — Abrir carpeta, Recargar)
        ├── Search field (conditional)
        ├── Expanded(Row)
        │   ├── FilePanel (width: 200, conditional)
        │   └── CodeField (Expanded)
        └── Status bar (blue bar)
            ├── File name (getDisplayPath, ellipsis)
            ├── Ln/Col cursor position
            └── UTF-8
```

### 7.2 Menu items

| Menu | Items |
|------|-------|
| Archivo | Nuevo (Ctrl+N), Abrir... (Ctrl+O), Guardar (Ctrl+S), Guardar como... (Ctrl+Shift+S) |
| Edición | Buscar (Ctrl+F), Reemplazar (placeholder) |
| PopupMenu | Abrir carpeta (opens ConfigScreen), Recargar |

**No "Ver" menu** — panel toggle is via "atom" tap or Ctrl+B.

### 7.3 Status bar

- Uses `FileBrowserService.getDisplayPath()` to decode URI → friendly filename
- `TextOverflow.ellipsis` + `Expanded` for long file names
- Shows cursor position (Ln, Col) and encoding (UTF-8)

---

## 8. ANDROID 16 EDGE-TO-EDGE

- `SafeArea` wraps the body Column to handle status bar + navigation bar insets
- `SystemChrome.setSystemUIOverlayStyle` NOT yet configured (bars may not have proper colors)
- Status bar and nav bar overlap is handled by `SafeArea` padding

---

## 9. CONFIGURATION & PERSISTENCE

**SharedPreferences via `ConfigService`**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `default_directory` | String | `''` | Last used directory path |
| `tree_uri` | String? | `null` | SAF tree URI |
| `dark_mode` | Bool | `false` | Theme preference |
| `onboarding_done` | Bool | `false` | Whether welcome screen shown |

---

## 10. BUILD & DEPLOY

### Quick build
```bash
cd /mnt/disk/src/flutter_src/atom_flt
rm -rf android/app/build build
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 flutter build apk --debug
```

### Deploy to device
```bash
adb -s <device_ip>:<port> install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Git workflow
```bash
git add -A && git commit -m "v1.0.X: description"
git tag v1.0.X
git push --tags
```

---

## 11. KEYBOARD SHORTCUTS

| Shortcut | Action | Source |
|----------|--------|--------|
| Ctrl+S | Save | KeyboardListener |
| Ctrl+Shift+S | Save As | KeyboardListener |
| Ctrl+O | Open file | KeyboardListener |
| Ctrl+N | New file | KeyboardListener |
| Ctrl+B | Toggle file panel | KeyboardListener |
| Ctrl+F | Toggle search | KeyboardListener |
| Ctrl+Z | Undo | CodeField (built-in) |
| Ctrl+Y | Redo | CodeField (built-in) |
| Tab | Indent | CodeField (built-in) |
| Shift+Tab | Outdent | CodeField (built-in) |

---

## 12. KNOWN ISSUES & TODO

### 🔴 Critical
- **EditorController duplicado:** `main.dart` creates one via Provider, `editor_screen.dart` creates a local one — Provider instance never used
- **Search arrows no funcionales:** Both `onPressed: () {}` — empty callbacks

### 🟡 Improvements needed
- **System UI overlay:** Need `SystemChrome.setSystemUIOverlayStyle` for proper status/nav bar colors
- **Theme toggle missing:** No UI button to switch light/dark theme
- **No tests:** No unit tests for EditorController, FileService, FileBrowserService, ConfigService

### 🟢 Resolved (v1.0.12)
- ~~Line numbers desynced~~ → CodeField with linked_scroll_controller
- ~~RangeError on openFile~~ → _suppressNotifications flag
- ~~File panel overflow~~ → SingleChildScrollView on menu
- ~~Status bar raw URI~~ → getDisplayPath with Uri.decodeComponent
- ~~Back arrow not responding~~ → InkWell with proper padding
- ~~SafeArea for Android 16~~ → Edge-to-edge handling

---

## 13. DEPENDENCIES

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_code_editor | ^0.3.5 | CodeField + CodeController (syntax highlighting, line numbers) |
| highlight | ^0.7.0 | Language syntax definitions |
| provider | ^6.1.0 | ThemeProvider only |
| shared_preferences | ^2.3.4 | Config persistence |
| file_picker | ^8.3.7 | Save As dialog |

**Dependency override:** `jni: 1.0.0` (Gradle 9+ compatibility)

---

## 14. COMMON TASKS

### Add new syntax language
Edit `lib/models/syntax_language.dart` → add to `_extensionMap`

### Add new native method
1. Add `when` case in `MainActivity.kt`
2. Add invoke method in `FileBrowserService` or `FileService`
3. Call from Dart

### Debug file browser
1. Check `adb logcat | grep atom_flt`
2. Check `debugPrint` output in Flutter console
3. Verify `_treeUri` in SharedPreferences

---

## 15. QUICK REFERENCE

```
Project root:   /mnt/disk/src/flutter_src/atom_flt
Main entry:     lib/main.dart
Editor UI:      lib/editor/editor_screen.dart
Editor state:   lib/editor/editor_controller.dart
File browser:   lib/widgets/file_panel.dart + lib/services/file_browser_service.dart
Native code:    android/app/src/main/kotlin/com/example/atom_flt/MainActivity.kt
Docs:           docs/
Skills:         .agents/skills/
```

---

*Skill version: 1.1 — Updated 28 July 2026*
*Last tag: v1.0.12*
*Load with: `skill tool name: atom_flt_codebase`*
