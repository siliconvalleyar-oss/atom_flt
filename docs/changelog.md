# Changelog — atom_flt

All notable changes to the `atom_flt` project.

---

## v1.1.0 — 28 Jul 2026

### Fixed
- **Gutter width (line numbers clipped):** Library internally subtracts 32px for disabled features. `GutterStyle(width: 48)` → only 16px effective. Changed to `width: 80` → 48px effective
- **Line number/scroll desync:** Added `height: 1.5` to gutter and code `textStyle` for identical line heights
- **Removed CodeField `padding`/`decoration`:** These interfered with internal `LinkedScrollControllerGroup` scroll calculations

### Changed
- Version bumped to 1.1.0 (major UI stability milestone)

---

## v1.0.14 — 28 Jul 2026

### Fixed
- **Gutter width too narrow:** `GutterStyle(width: 48)` was internally calculated as `48 - 16 - 16 = 16px` because the library subtracts disabled feature column widths. Changed to `width: 80` → effective 48px for line numbers
- **Line number/scroll desync:** Added explicit `height: 1.5` to both gutter and code `textStyle` to ensure identical line heights between the Table-based gutter and TextField rendering
- **Removed interfering padding/decoration:** Removed `padding: EdgeInsets.symmetric(horizontal: 16)` and custom `decoration` from CodeField that could interfere with internal scroll calculations

---

## v1.0.13 (latest)

### Added
- Skill file updated to reflect CodeField, menu changes, Android 16 support
- This changelog document

---

## v1.0.12 — 28 Jul 2026

### Fixed
- **RangeError on openFile:** Replaced `removeListener`/`addListener` pattern with `_suppressNotifications` flag — eliminates `-1` index error when loading file content into CodeController
- **Line number desync:** Removed `_editor.code = value` from CodeField `onChanged` — CodeField updates the controller internally; re-assigning was resetting scroll position
- **Back arrow not responding:** Replaced tiny `GestureDetector(14px icon)` with `InkWell` + `Padding(6)` for adequate touch target with ripple feedback
- **Gutter alignment:** Changed CodeField padding from `EdgeInsets.all(16)` to `EdgeInsets.symmetric(horizontal: 16)` to align line numbers with code text

---

## v1.0.11 — 28 Jul 2026

### Changed
- **Replaced manual TextField + line numbers with CodeField** from `flutter_code_editor`
- Uses `linked_scroll_controller` for native scroll sync between gutter and code
- `GutterStyle(width: 48, showErrors: false, showFoldingHandles: false)`

### Removed
- `_buildLineNumbers()` method — now handled by CodeField
- `_lineScrollController` — no longer needed
- Manual `NotificationListener<ScrollNotification>` scroll sync hack

---

## v1.0.10 — 28 Jul 2026

### Changed
- **Menu "Ver" removed** — panel toggle now via tap on blue "atom" text (GestureDetector)
- Status bar file name: added `Uri.decodeComponent()` to fix `%20` → space display

### Removed
- "Ver" menu item with "Panel de archivos" option

---

## v1.0.9 — 28 Jul 2026

### Fixed
- **Status bar overflow (770px portrait):** Now uses `getDisplayPath()` instead of raw content URI
- **Menu overflow (378px landscape):** Wrapped menu items in `SingleChildScrollView` + `Expanded`
- **Duplicate search field:** Was in both `build()` and `_buildCodeEditor()`, removed from `_buildCodeEditor()`
- **File tap not working:** Added `Material` ancestor to `InkWell`, increased padding to `vertical: 6`
- **Status bar updates:** Added `EditorController` listener (`_onEditorUpdate`) so status bar rebuilds when file opens

---

## v1.0.8 — 28 Jul 2026

### Fixed
- **SAF "No root for content" error:** Added `getRootDocId` method in `MainActivity.kt` using `DocumentsContract.getTreeDocumentId()`
- **Android 16 edge-to-edge:** Added `SafeArea` wrapper (later refined in v1.0.9)
- **System insets:** Replaced manual `SizedBox(height: topInset/bottomInset)` with `SafeArea`

### Added
- `getRootDocId` native method for proper SAF root document ID extraction
- `debugPrint` logging in `FilePanel._loadFiles()` for SAF debugging

---

## v1.0.7 — 27 Jul 2026

### Added
- **File browser sidebar** with SAF support (always-visible, 200px width)
- `FileBrowserService` with `openFolder`, `listDirectory`, `navigateTo`, `goUp`
- `FileEntry` model (name, uri, docId, isDirectory, isFile, length)
- Config screen with SAF picker + welcome onboarding text
- `ConfigService` with `onboarding_done` flag
- 38 diagnostic tasks completed (permissions, SAF routing, error handling)

### Changed
- Removed drawer-based file browser
- `EditorController.openFile({uri, filePath})` signature change

---

## v1.0.6 — 27 Jul 2026

### Fixed
- Bottom overflow on landscape mode
- Added folder loading support

### Added
- Launcher PNG icons (generated from SVG)
- `AESTHETICS.md` design document

---

## v1.0.5 — 27 Jul 2026

### Added
- Minimalistic atom SVG icon for launcher

---

## v1.0.4 — 27 Jul 2026

### Added
- Version display from VERSION file in status bar and app title

---

## v1.0.3 — 27 Jul 2026

### Added
- Safe area handling
- Overflow menu with file explorer
- Sample C++/Dart code files
- `LEARNINGS.md` documentation

---

## v1.0.2 — 27 Jul 2026

### Added
- Full source code implementation with editor, syntax highlighting, file operations, and theme switching

---

## v1.0.1 — 27 Jul 2026

### Added
- Initial project structure with docs and assets

---

## v1.0.0 — 27 Jul 2026

### Added
- Initial commit

---

*Last updated: 28 July 2026*
