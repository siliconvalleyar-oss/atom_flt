# 🧾 DIAGNÓSTICO — FileBrowser/FilePanel no muestra archivos en Android

**App:** atom_flt — Editor de código Flutter  
**Fecha:** 27 Julio 2026  
**Proyecto:** `/mnt/disk/src/flutter_src/atom_flt`  
**Versión del reporte:** 2.0

---

## 📋 REGLAS PARA REVISIÓN POR AI

Este reporte está diseñado para que **cualquier AI** pueda examinar el código fuente, verificar cada ítem de la checklist y marcarlo como completado o pendiente.

### 🎯 Instrucciones para la AI revisora

1. **Leer los archivos fuente indicados** en cada tarea para verificar el estado actual.
2. **Marcar `[x]`** si el código verifica la condición descrita en "Cómo verificar".
3. **Marcar `[ ]`** si la condición NO se cumple.
4. **Marcar `[-]`** si la tarea no aplica (ej: se eliminó el método).
5. **No asumir nada.** Verificar siempre en el código con herramientas como `read_files`, `code_searcher`, `glob`.
6. **Actualizar el contador de progreso** al final del reporte después de cada visita.

### 🔍 Comportamiento esperado después de todas las correcciones

Cuando todas las tareas están completadas, la app debe:
- Al primer inicio: mostrar un diálogo de bienvenida para seleccionar carpeta via SAF
- Al seleccionar carpeta: mostrar sus archivos en el FilePanel
- Poder navegar dentro de subcarpetas (tap para entrar, botón "atrás" para salir)
- Poder abrir archivos desde el FilePanel al editor
- Funcionar en Android 11+ (API 30+) sin errores de permisos
- Si se usa File API (solo Android < 11), solicitar `MANAGE_EXTERNAL_STORAGE`
- Guardar la configuración de carpeta entre reinicios de la app

---

## 📊 PROGRESO GENERAL

| Sección | Tareas | Hechas | % |
|---------|--------|--------|---|
| **A — Bloqueantes** | 21 | 14 | **67%** |
| **B — Estructurales** | 17 | 14 | **82%** |
| **C — UX/Menores** | 13 | 9 | **69%** |
| **TOTAL** | **51** | **37** | **73%** |

**Última verificación:** 27 Julio 2026 por AI Buffy

---

## 🔴 SECCIÓN A — Causas Raíz (BLOQUEANTES)

---

### A.1 — Ruta por defecto `/sdcard/Documents/src` inexistente

**Archivo:** `lib/editor/editor_screen.dart`  
**Propósito:** Eliminar la dependencia de una ruta hardcodeada que no existe en la mayoría de dispositivos.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| A.1.1 | `_directoryPath` por defecto = `''` en vez de `/sdcard/Documents/src` | Leer `editor_screen.dart`: buscar `_directoryPath = `. Debe ser `''` o cadena vacía | [x] |
| A.1.2 | FilePanel muestra pantalla de onboarding cuando `directoryPath` está vacío | Leer `file_panel.dart`: debe tener un método que retorne un widget con texto "Selecciona una carpeta" y un botón cuando `directoryPath.isEmpty && treeUri == null` | [x] |
| A.1.3 | Auto-abrir ConfigScreen al primer inicio si no hay path configurado | Leer `editor_screen.dart` dentro de `_loadConfig()`: debe tener un `if (path.isEmpty && treeUri == null) { _openConfig(); }` | [x] |
| A.1.4 | Botón "Seleccionar carpeta" dentro del FilePanel vacío | Leer `file_panel.dart`: el widget de onboarding debe tener un `OutlinedButton.icon` con `onPressed: widget.onConfig` y texto "Seleccionar carpeta" | [x] |
| A.1.5 | `ConfigService.getDefaultDirectory()` retorna `''` por defecto | Leer `config_service.dart`: `prefs.getString(_keyDirectory) ?? ''` debe ser cadena vacía | [x] |

---

### A.2 — `MANAGE_EXTERNAL_STORAGE` no se solicita en runtime

**Archivos:** `android/app/src/main/kotlin/.../MainActivity.kt` + `lib/services/file_browser_service.dart`  
**Propósito:** Solicitar el permiso `MANAGE_EXTERNAL_STORAGE` apropiadamente en Android 11+ (API 30+) antes de usar `File` API.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| A.2.1 | Método `isExternalStorageManager` expuesto en MethodChannel nativo | Leer `MainActivity.kt`: buscar `isExternalStorageManager` en el `when` del MethodChannel. Debe retornar `Environment.isExternalStorageManager()` | [x] |
| A.2.2 | Método `requestManageStorage` que lance `Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` | Leer `MainActivity.kt`: buscar `requestManageStorage` en el `when`. Debe crear `Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)` con data `Uri.parse("package:$packageName")` y llamar `startActivityForResult` con código único | [x] |
| A.2.3 | Método Dart `requestManageStorage()` y `isExternalStorageManager()` en `FileBrowserService` | Leer `file_browser_service.dart`: buscar métodos `requestManageStorage()` y `isExternalStorageManager()` que invoquen el canal nativo | [x] |
| A.2.4 | FilePanel o `FileBrowserService` **verifica** permisos antes de usar File API y llama `requestManageStorage` si no los tiene | Leer `file_panel.dart` o `file_browser_service.dart`: ANTES de llamar a `_listDirectoryFallback` o `listDirectoryPath`, debe llamar a `isExternalStorageManager()` y si retorna `false`, llamar `requestManageStorage()` y detenerse | [ ] |
| A.2.5 | `onActivityResult` para `MANAGE_STORAGE_REQUEST` que retorna resultado | Leer `MainActivity.kt`: en `onActivityResult()`, debe haber un `when` o `if` que maneje `MANAGE_STORAGE_REQUEST` y retorne `Environment.isExternalStorageManager()` al pending result | [x] |

---

### A.3 — `tryFallbackSAF` construye URI SAF sin permiso de usuario

**Archivo:** `android/app/src/main/kotlin/.../MainActivity.kt`  
**Propósito:** Eliminar el hack que construye URIs SAF sin permisos de usuario.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| A.3.1 | Método `tryFallbackSAF` eliminado completamente | Buscar `tryFallbackSAF` en `MainActivity.kt` con `code_searcher`. No debe existir | [x] |
| A.3.2 | Handler `listDirectoryPath` ya no llama a `tryFallbackSAF` | Leer `listDirectoryPath` en `MainActivity.kt`: debe retornar inmediatamente sin invocar ningún método de fallback. Solo debe existir el código que usa `File(path).listFiles()` | [x] |
| A.3.3 | `listDirectoryPath` retorna errores **claros** en vez de lista vacía | Leer `listDirectoryPath`: si `dir.exists()` es false → error `NOT_A_DIRECTORY`. Si `listFiles()` es null → error `ACCESS_DENIED`. Buscar `result.error(` en el handler | [x] |
| A.3.4 | FilePanel captura `ACCESS_DENIED` y muestra mensaje amigable en español | Leer `file_panel.dart`: buscar método `_friendlyError()`. Debe contener: `"Acceso denegado por scoped storage"` y sugerencia de ir a Configuración | [x] |
| A.3.5 | Método `pathToDocId` eliminado | Buscar `pathToDocId` en `MainActivity.kt`. No debe existir | [x] |

---

### A.4 — `pathToDocId` incompatible con `/sdcard` vs `/storage/emulated/0`

**Archivo:** `android/app/src/main/kotlin/.../MainActivity.kt`  
**Propósito:** Resolver el mismatch entre rutas simbólicas.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| A.4.1 | Si se mantiene, agregar `File(path).canonicalPath` para resolver symlinks | Buscar `pathToDocId`: si existe, debe usar `File(path).canonicalPath`. Si NO existe, marcar `[-]` | [-] |
| A.4.2 | Normalizar también `externalStorageDirectory` con `canonicalPath` | Idem. Si `pathToDocId` no existe, marcar `[-]` | [-] |
| A.4.3 | Fallback adicional para `/sdcard` → `/storage/emulated/0` | Idem. Si `pathToDocId` no existe, marcar `[-]` | [-] |
| A.4.4 | **Eliminar `pathToDocId` completamente** | Buscar `pathToDocId` en `MainActivity.kt`: NO debe existir. Si no existe, marcar `[x]` | [x] |

---

### A.5 — Sin permiso alternativo para API 33+ (Android 13+)

**Archivo:** `android/app/src/main/AndroidManifest.xml` + código Dart  
**Propósito:** Proveer acceso a archivos en Android 13+ donde `READ_EXTERNAL_STORAGE` ya no funciona.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| A.5.1 | Agregar `<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />` | Leer `AndroidManifest.xml`: buscar `READ_MEDIA_IMAGES` | [ ] |
| A.5.2 | Agregar `<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />` | Leer `AndroidManifest.xml`: buscar `READ_MEDIA_VIDEO` | [ ] |
| A.5.3 | Agregar `<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />` | Leer `AndroidManifest.xml`: buscar `READ_MEDIA_AUDIO` | [ ] |
| A.5.4 | **Forzar SAF como único método en API 33+**, eliminar `listDirectoryPath` para API >= 33 | Leer `MainActivity.kt`: `listDirectoryPath` debe tener un chequeo `if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { result.error("USE_SAF", "Usa SAF picker"); return }` | [ ] |
| A.5.5 | Método `getApiLevel` expuesto y usado para decidir ruta en Dart | Leer `file_browser_service.dart`: debe existir `getApiLevel()`. Luego ver si se usa en `FilePanel._loadFiles()` para decidir SAF vs File API. Buscar llamadas a `getApiLevel()` | [ ] |

---

## 🟡 SECCIÓN B — Problemas Estructurales (Media Prioridad)

---

### B.1 — `FileEntry` duplicado y sin `docId` en `file_panel.dart`

**Archivos:** `lib/widgets/file_panel.dart`, `lib/services/file_browser_service.dart`  
**Propósito:** Unificar la definición de `FileEntry` y agregar `docId` al `FilePanel`.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| B.1.1 | Eliminar clase `FileEntry` de `file_panel.dart` | Buscar `class FileEntry` en `file_panel.dart`: no debe existir ninguna definición de clase `FileEntry` | [x] |
| B.1.2 | Importar `file_browser_service.dart` en `file_panel.dart` | Leer imports de `file_panel.dart`: debe tener `import '../services/file_browser_service.dart'` | [x] |
| B.1.3 | `FileEntry.fromMap` en `file_browser_service.dart` tiene todos los campos que `FilePanel` necesita (`name`, `uri`, `docId`, `isDirectory`, `length`) | Leer `file_browser_service.dart`: `FileEntry` debe tener constructor con campos: `name`, `uri`, `docId`, `isDirectory`, `isFile`, `lastModified`, `length`. Y `fromMap` debe parsear todos. Buscar referencias a esos campos en `file_panel.dart` | [x] |
| B.1.4 | `FilePanel` usa `docId` para navegar a subdirectorios | Leer `file_panel.dart` método `_enterDir`: debe recibir `FileEntry entry` y usar `entry.docId` en `_service.navigateTo(entry.docId)` | [x] |

---

### B.2 — `_buildDocId()` construye IDs inválidos al navegar

**Archivo:** `lib/widgets/file_panel.dart`  
**Propósito:** Corregir la construcción de document IDs para SAF.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| B.2.1 | FilePanel **no** usa `_pathStack` con nombres de carpetas | Buscar `_pathStack` en `file_panel.dart`: no debe existir variable `_pathStack` | [x] |
| B.2.2 | `_enterDir(String name)` cambiado a `_enterDir(FileEntry entry)` o similar que recibe docId real | Leer método `_enterDir` en `file_panel.dart`: debe recibir `FileEntry entry` (o similar) y usar `entry.docId` | [x] |
| B.2.3 | Métodos `_buildDocId`, `_buildDocIdBase`, `_buildPath` eliminados | Buscar esos nombres en `file_panel.dart`: no deben existir | [x] |
| B.2.4 | `FileBrowserService` maneja `_currentDocId` y `_rootDocId` internamente | Leer `file_browser_service.dart`: debe tener `_currentDocId` y `_rootDocId` como miembros privados, y `goUp()` debe modificar `_currentDocId` correctamente | [x] |

---

### B.3 — `FilePanel` duplica la lógica de `FileBrowserService`

**Archivos:** `lib/services/file_browser_service.dart`, `lib/widgets/file_panel.dart`  
**Propósito:** Refactorizar `FilePanel` para usar `FileBrowserService`.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| B.3.1 | FilePanel usa `FileBrowserService _service` en vez de `MethodChannel` directo | Leer `file_panel.dart`: debe tener `final FileBrowserService _service = FileBrowserService();` y NO `static const _channel = MethodChannel(...)` | [x] |
| B.3.2 | Reemplazar `_loadSAF()` y `_loadPath()` con `service.openFolder()` + `service.listDirectory()` | Leer `_loadFiles()` en `file_panel.dart`: debe llamar `_service.openFolder(widget.treeUri!)` y `_service.listDirectory()`. No debe haber `_channel.invokeMethod` en el file | [x] |
| B.3.3 | `_enterDir` usa `service.navigateTo(docId)` | Leer `_enterDir` en `file_panel.dart`: debe llamar `_service.navigateTo(entry.docId)` | [x] |
| B.3.4 | `_goUp` usa `service.goUp()` | Leer `_goUp` en `file_panel.dart`: debe llamar `_service.goUp()` | [x] |
| B.3.5 | Eliminar `_channel`, `_loadSAF`, `_loadPath`, `_buildDocId`, `_buildDocIdBase`, `_buildPath` de `FilePanel` | Buscar esas palabras en `file_panel.dart`: no deben existir. La clase `_FilePanelState` debe ser mucho más corta (solo `_loadFiles()`, `_enterDir()`, `_goUp()`) | [x] |
| B.3.6 | `FileBrowserService.openFolder` funciona correctamente con cualquier URI | Leer `openFolder` en `file_browser_service.dart`: debe extraer rootDocId de `content://.../tree/...` correctamente y también aceptar paths de archivo. Verificar que `_extractRootDocId` funcione | [x] |

---

### B.4 — `openFile` recibe URI sin `contentUri` extra

**Archivo:** `lib/editor/editor_controller.dart` y `lib/editor/editor_screen.dart`  
**Propósito:** Clarificar la interfaz de `openFile` para content URIs.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| B.4.1 | Renombrar `openFile(String path, {String? contentUri})` a `openFile({required String uri, String? filePath})` | Leer `editor_controller.dart`: buscar `openFile`. La firma debe usar named parameters. Buscar `required String uri` en la firma | [ ] |
| B.4.2 | Todas las llamadas a `openFile` actualizadas al nuevo named parameter | Buscar todas las ocurrencias de `openFile(` en el proyecto. Verificar que usen el nuevo formato. Marcar `[x]` si todas están actualizadas | [ ] |
| B.4.3 | Lógica interna detecta `content://` y usa el canal correcto | Leer `editor_controller.dart` → `openFile`: debe pasar la URI/Path a `_fileService.readFile()`. Verificar que `_fileService.readFile()` en `file_service.dart` detecte `content://` y use `readFile` en lugar de `readFilePath` | [x] |

---

## 🟢 SECCIÓN C — UX y Mejoras Menores (Baja Prioridad)

---

### C.1 — Sin feedback si `pickDirectory` falla o se cancela

**Archivo:** `lib/widgets/config_screen.dart`  
**Propósito:** Agregar feedback visual cuando el SAF picker falla o es cancelado.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| C.1.1 | SnackBar informativo cuando el usuario **cancela** el picker (resultado null) | Leer `config_screen.dart` método `_pickDirectory()`. Después de `invokeMethod('pickDirectory')`, si `uri == null` debe mostrar un `SnackBar` con texto como "Selección cancelada" | [ ] |
| C.1.2 | SnackBar con error si `pickDirectory` lanza excepción | Leer `config_screen.dart` `_pickDirectory()`: debe tener `try/catch` alrededor del invokeMethod y mostrar `ScaffoldMessenger.of(context).showSnackBar(...)` en caso de `PlatformException` | [x] |
| C.1.3 | Texto de ayuda debajo del botón "Seleccionar carpeta" explicando qué hace | Leer `config_screen.dart` widget tree: debajo del `OutlinedButton` debe haber un `Text` o similar que explique que debe elegir una carpeta raíz del proyecto | [x] |

---

### C.2 — Sin onboarding de carpeta al primer inicio

**Archivos:** `lib/editor/editor_screen.dart`, `lib/services/config_service.dart`  
**Propósito:** Guiar al usuario a seleccionar una carpeta cuando la app se inicia por primera vez.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| C.2.1 | Auto-abrir `_openConfig()` cuando no hay path ni treeUri configurados | Leer `editor_screen.dart` método `_loadConfig()`: después de cargar, debe tener `if (path.isEmpty && treeUri == null && mounted) { _openConfig(); }` | [x] |
| C.2.2 | Texto de bienvenida en ConfigScreen en el primer inicio | Leer `config_screen.dart`: buscar texto como "Bienvenido" o similar. Si el diálogo se abre por primera vez sin datos guardados, debe mostrar un mensaje de bienvenida | [ ] |
| C.2.3 | FilePanel vacío muestra icono grande + texto "Selecciona una carpeta para comenzar" + botón | Leer `file_panel.dart` método `_buildOnboarding()`: debe retornar un widget con `Icon(folder_open, size: 40)`, `Text("Selecciona una carpeta para comenzar")`, y `OutlinedButton.icon(onPressed: widget.onConfig, ...)` | [x] |
| C.2.4 | Flag `onboarding_done` en SharedPreferences para no repetir el diálogo | Leer `config_service.dart`: debe tener una constante `_keyOnboardingDone` y métodos get/set. Leer `editor_screen.dart`: `_loadConfig()` debe verificar esta flag antes de auto-abrir Config | [ ] |

---

### C.3 — Mejoras en mensajes de error

**Archivo:** `lib/widgets/file_panel.dart`  
**Propósito:** Mejorar los mensajes de error que ve el usuario ante fallos de permisos o accesos.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| C.3.1 | Método `_friendlyError()` que traduce errores técnicos a español | Leer `file_panel.dart`: debe existir método `_friendlyError(String msg)` que retorne String traducido | [x] |
| C.3.2 | Mapeo de errores: `ACCESS_DENIED` → "Acceso denegado..." con sugerencia de ir a Configuración | Leer `_friendlyError()`: debe contener case/if para `"ACCESS_DENIED"`, `"Permission denial"`, `"NOT_A_DIRECTORY"` etc. | [x] |
| C.3.3 | Si lista está vacía pero hay treeUri, mostrar "carpeta vacía" | Leer `file_panel.dart` `_buildBody()`: cuando `_entries.isEmpty && !_loading && _error == null`, debe retornar widget con texto "carpeta vacía" o "(carpeta vacía)" | [x] |

---

### C.4 — Logging y depuración

**Archivos:** `android/app/src/main/kotlin/.../MainActivity.kt`, `lib/widgets/file_panel.dart`  
**Propósito:** Agregar logging para facilitar diagnóstico futuro.

| # | Tarea | Cómo verificar (AI) | Hecho |
|---|-------|----------------------|-------|
| C.4.1 | Log de API level al iniciar el canal (`Log.i("atom_flt", "API_LEVEL=${Build.VERSION.SDK_INT}")`) | Leer `MainActivity.kt` `configureFlutterEngine()`: buscar `Log.i` que imprima el API level | [x] |
| C.4.2 | Log en `listDirectoryPath` del path, `exists`, `isDir`, y cantidad de archivos encontrados | Leer `listDirectoryPath` en `MainActivity.kt`: buscar `Log.i` que imprima `exists=$exists isDir=$isDir` y `found ${list.size}` | [x] |
| C.4.3 | Log en `FilePanel._loadFiles()` indicando si usa SAF o File API | Leer `file_panel.dart` `_loadFiles()`: debe tener `debugPrint` o `Log` indicando qué ruta tomó (treeUri != null → SAF, else → File API) | [ ] |

---

## ✅ TABLERO COMPLETO

| # | Tarea | Hecho |
|---|-------|-------|
| A.1.1 | `_directoryPath = ''` por defecto | [x] |
| A.1.2 | FilePanel onboarding visual | [x] |
| A.1.3 | Auto-abrir Config al primer inicio | [x] |
| A.1.4 | Botón "Seleccionar carpeta" en FilePanel | [x] |
| A.1.5 | ConfigService devuelve `''` | [x] |
| A.2.1 | `isExternalStorageManager` nativo | [x] |
| A.2.2 | `requestManageStorage` nativo | [x] |
| A.2.3 | Métodos Dart `isExternalStorageManager` y `requestManageStorage` | [x] |
| A.2.4 | Verificar permiso antes de File API | [ ] |
| A.2.5 | `onActivityResult` para MANAGE_STORAGE | [x] |
| A.3.1 | `tryFallbackSAF` eliminado | [x] |
| A.3.2 | Llamada a `tryFallbackSAF` eliminada | [x] |
| A.3.3 | Errores claros en `listDirectoryPath` | [x] |
| A.3.4 | `_friendlyError()` captura ACCESS_DENIED | [x] |
| A.3.5 | `pathToDocId` eliminado | [x] |
| A.4.4 | `pathToDocId` eliminado (confirmación) | [x] |
| A.5.1 | `READ_MEDIA_IMAGES` en manifest | [ ] |
| A.5.2 | `READ_MEDIA_VIDEO` en manifest | [ ] |
| A.5.3 | `READ_MEDIA_AUDIO` en manifest | [ ] |
| A.5.4 | SAF forzado en API 33+ | [ ] |
| A.5.5 | `getApiLevel` usado para decidir ruta | [ ] |
| B.1.1 | `FileEntry` eliminado de `file_panel.dart` | [x] |
| B.1.2 | Import de `file_browser_service.dart` | [x] |
| B.1.3 | `FileEntry.fromMap` completo | [x] |
| B.1.4 | FilePanel usa `docId` para navegación | [x] |
| B.2.1 | Sin `_pathStack` | [x] |
| B.2.2 | `_enterDir` recibe `FileEntry` | [x] |
| B.2.3 | `_buildDocId` y familia eliminados | [x] |
| B.2.4 | `FileBrowserService` maneja `_currentDocId` | [x] |
| B.3.1 | `FileBrowserService` en FilePanel | [x] |
| B.3.2 | `_loadFiles` usa service | [x] |
| B.3.3 | `_enterDir` usa `service.navigateTo` | [x] |
| B.3.4 | `_goUp` usa `service.goUp` | [x] |
| B.3.5 | Métodos antiguos eliminados | [x] |
| B.3.6 | `openFolder` funciona | [x] |
| B.4.1 | `openFile` renombrado con named params | [ ] |
| B.4.2 | Llamadas actualizadas | [ ] |
| B.4.3 | `content://` detectado internamente | [x] |
| C.1.1 | SnackBar al cancelar picker | [ ] |
| C.1.2 | SnackBar al fallar picker | [x] |
| C.1.3 | Texto de ayuda en ConfigScreen | [x] |
| C.2.1 | Auto-abrir Config al primer inicio | [x] |
| C.2.2 | Texto de bienvenida en ConfigScreen | [ ] |
| C.2.3 | FilePanel onboarding visual | [x] |
| C.2.4 | Flag `onboarding_done` | [ ] |
| C.3.1 | `_friendlyError()` existe | [x] |
| C.3.2 | Mapeo de errores a español | [x] |
| C.3.3 | "Carpeta vacía" si lista vacía | [x] |
| C.4.1 | Log API level | [x] |
| C.4.2 | Log en `listDirectoryPath` | [x] |
| C.4.3 | Log en `FilePanel._loadFiles()` | [ ] |

---

## 🔢 RESUMEN FINAL

| Estado | Cantidad |
|--------|----------|
| `[x]` Completado | **37** |
| `[ ]` Pendiente | **14** |
| `[-]` No aplica | **0** |
| **Total** | **51** |

---

## 🧪 PRUEBAS DE VERIFICACIÓN

Estas pruebas deben ejecutarse **después** de implementar todas las correcciones.

| # | Prueba | Cómo probar | Resultado esperado | Hecho |
|---|--------|-------------|-------------------|-------|
| T.1 | Primer inicio sin datos | `flutter clean && flutter run` en Android. No abrir Config manualmente | Debe aparecer ConfigScreen automáticamente | [ ] |
| T.2 | SAF picker funciona | En ConfigScreen, tap "Seleccionar carpeta", elegir una carpeta real | FilePanel mustra los archivos de esa carpeta | [ ] |
| T.3 | Navegación subcarpetas | Tap en una carpeta del FilePanel | Muestra contenido de esa subcarpeta. Botón "atrás" vuelve | [ ] |
| T.4 | Abrir archivo desde FilePanel | Tap en un archivo .txt o .dart | Se abre en el editor con su contenido | [ ] |
| T.5 | Archivos con espacios | Crear archivo "mi archivo.txt" en la carpeta | Se muestra y se puede abrir sin errores | [ ] |
| T.6 | Android 11+ (API 30) | Probar en dispositivo/emulador API 30+ | File API bloqueado → error "Acceso denegado" o SAF en su lugar | [ ] |
| T.7 | Android 13+ (API 33) | Probar en dispositivo/emulador API 33+ | Debe forzar SAF, nunca mostrar File API | [ ] |
| T.8 | Persistencia de carpeta | Configurar carpeta, cerrar app, reabrir | FilePanel recuerda la carpeta configurada | [ ] |
| T.9 | Cancelar picker | En ConfigScreen, tap "Seleccionar carpeta", presionar "Atrás" | SnackBar "Selección cancelada" | [ ] |
| T.10 | Tema claro/oscuro | Alternar tema | FilePanel se ve correctamente en ambos temas | [ ] |

---

## 🟣 SECCIÓN D — Sugerencias de Escalabilidad y Mejora General del Código (Análisis Completo del Codebase Dart)

**Propósito:** Esta sección recoge todas las sugerencias de mejora para el código Dart en general, más allá del FileBrowser. Son problemas de arquitectura, código muerto, duplicación y faltantes que afectan la mantenibilidad y escalabilidad del proyecto.

---

### D.1 — `EditorController` duplicado (Provider vs instancia local)

**Archivos:** `lib/main.dart` (línea 15), `lib/editor/editor_screen.dart` (línea 18)

**Problema:** `main.dart` crea un `EditorController` dentro del `MultiProvider`, pero `editor_screen.dart` crea **otro** `EditorController` local en su estado. Hay dos instancias distintas: una en el árbol de Providers que nunca recibe eventos, y otra local que no es accesible desde otros widgets.

**Impacto en escalabilidad:** Cualquier widget que intente `context.read<EditorController>()` obtendrá el del Provider, que está siempre vacío. El estado real está en la instancia local, pero es inaccesible.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.1.1 | Eliminar `final EditorController _editor = EditorController();` local en `editor_screen.dart` | `editor_screen.dart` | Buscar `final EditorController _editor = EditorController();` — debe ser reemplazado por `final _editor = context.read<EditorController>();` | [ ] |
| D.1.2 | Verificar que `_editor.openFile()` y demás llamadas sigan funcionando con el Provider | `editor_screen.dart` | Después del cambio, compilar con `flutter analyze` y verificar que no haya errores | [ ] |
| D.1.3 | Eliminar `currentFilePath` getter duplicado (es igual a `filePath`) | `editor_controller.dart` | Buscar `currentFilePath` y `filePath`. Son el mismo campo. Debe haber solo **uno** | [ ] |
| D.1.4 | Eliminar `currentFileName` getter (es igual a `fileName`) | `editor_controller.dart` | Buscar `currentFileName` y `fileName`. Son el mismo campo. Debe haber solo **uno** | [ ] |

---

### D.2 — Código muerto: 5 archivos no utilizados

**Archivos:** `lib/widgets/file_browser.dart` (145 líneas), `lib/widgets/status_bar.dart` (83 líneas), `lib/widgets/search_bar.dart` (170 líneas), `lib/services/preferences_service.dart` (27 líneas), `lib/models/file_model.dart` (30 líneas)

**Problema:** Estos archivos existen pero **ninguno es importado** por ningún otro archivo del proyecto. Son reliquias de versiones anteriores que ya no se usan.

**Impacto en escalabilidad:** Aumentan el tamaño del proyecto innecesariamente, confunden a nuevos desarrolladores, y dan falsas señales de funcionalidad existente.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.2.1 | Eliminar `file_browser.dart` completo | `lib/widgets/file_browser.dart` | `code_searcher -g *.dart import.*file_browser` — no debe haber resultados | [ ] |
| D.2.2 | Eliminar `status_bar.dart` completo | `lib/widgets/status_bar.dart` | `code_searcher -g *.dart import.*status_bar` — no debe haber resultados | [ ] |
| D.2.3 | Eliminar `search_bar.dart` completo | `lib/widgets/search_bar.dart` | `code_searcher -g *.dart import.*search_bar` — no debe haber resultados | [ ] |
| D.2.4 | Eliminar `preferences_service.dart` completo | `lib/services/preferences_service.dart` | `code_searcher -g *.dart import.*preferences_service` — no debe haber resultados | [ ] |
| D.2.5 | Eliminar `file_model.dart` completo | `lib/models/file_model.dart` | `code_searcher -g *.dart import.*file_model` — no debe haber resultados | [ ] |
| D.2.6 | Ejecutar `flutter analyze` después de eliminar — debe pasar sin errores | — | `flutter analyze` → 0 errors, 0 warnings | [ ] |

---

### D.3 — Editor: búsqueda inline no funcional (botones next/prev vacíos)

**Archivo:** `lib/editor/editor_screen.dart` — método `_buildSearchField()`

**Problema:** Los botones de flecha arriba/abajo en la barra de búsqueda tienen `onPressed: () {}` — no hacen nada.

**Impacto en escalabilidad:** Funcionalidad a medias que confunde al usuario. Da la impresión de que la app está rota.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.3.1 | Implementar navegación entre resultados de búsqueda (next/prev) | `editor_screen.dart` | Buscar `onPressed: () {}` en los IconButton de search. Deben tener lógica que recorra el texto buscando matches | [ ] |
| D.3.2 | O eliminar los botones si no se implementará la funcionalidad | `editor_screen.dart` | Si se opta por eliminar, los IconButton de flecha no deben existir | [ ] |

---

### D.4 — `undoCount`/`redoCount` nunca se sincronizan con el historial real

**Archivo:** `lib/editor/editor_controller.dart` — métodos `undo()`, `redo()`, `_onCodeChanged()`

**Problema:** Cada vez que el usuario escribe, `CodeController` agrega una entrada al historial interno, pero `_undoCount` nunca se incrementa. Los métodos `undo()` y `redo()` operan sobre contadores que no reflejan el estado real del historial.

**Impacto en escalabilidad:** El botón de deshacer mostrará `canUndo = false` incluso después de escribir, y `undo()` puede no funcionar aunque haya historial.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.4.1 | Suscribirse a cambios del `historyController` del `CodeController` para sincronizar contadores | `editor_controller.dart` | Buscar una suscripción a `codeController.historyController` en el constructor. Debe actualizar `_undoCount` y `_redoCount` automáticamente | [ ] |
| D.4.2 | O eliminar los contadores manuales y usar el API del CodeController (`historyController.canUndo` / `canRedo`) | `editor_controller.dart` | `canUndo` y `canRedo` deben delegar en `codeController.historyController` en vez de usar contadores manuales | [ ] |

---

### D.5 — Faltan atajos de teclado Ctrl+Z (Undo) y Ctrl+Y (Redo)

**Archivo:** `lib/editor/editor_screen.dart` — `KeyboardListener`

**Problema:** Los atajos implementados son Ctrl+S, Ctrl+O, Ctrl+N, Ctrl+B, Ctrl+F. **Faltan Ctrl+Z (deshacer) y Ctrl+Y (rehacer)** que son fundamentales en un editor de texto.

**Impacto en escalabilidad:** Sin estos atajos, el editor es considerablemente menos usable. Usuarios esperan estos atajos universalmente.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.5.1 | Agregar `if (ctrl && key == LogicalKeyboardKey.keyZ) { _editor.undo(); }` | `editor_screen.dart` | Buscar `LogicalKeyboardKey.keyZ` en el `KeyboardListener` | [ ] |
| D.5.2 | Agregar `if (ctrl && key == LogicalKeyboardKey.keyY) { _editor.redo(); }` | `editor_screen.dart` | Buscar `LogicalKeyboardKey.keyY` en el `KeyboardListener` | [ ] |
| D.5.3 | Actualizar pantalla de bienvenida para mostrar los atajos | `editor_screen.dart` | El texto en `_buildWelcomeScreen()` debe listar Ctrl+Z y Ctrl+Y | [ ] |

---

### D.6 — `PreferencesService` es código muerto (no se usa)

**Archivo:** `lib/services/preferences_service.dart`

**Problema:** `ThemeProvider` y `ConfigService` llaman a `SharedPreferences` directamente. `PreferencesService` tiene métodos genéricos `getString`, `setString`, `getBool`, `setBool` pero **nadie lo importa**.

**Impacto en escalabilidad:** Código innecesario que podría intentar usarse en el futuro, creando dos formas de hacer lo mismo.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.6.1 | Eliminar `preferences_service.dart` | `lib/services/preferences_service.dart` | Misma verificación que D.2.4 | [ ] |

---

### D.7 — Dependencia `path_provider` declarada pero no usada

**Archivo:** `pubspec.yaml`

**Problema:** `path_provider: ^2.1.0` está en las dependencias pero no se usa en ningún archivo Dart.

**Impacto en escalabilidad:** Dependencia innecesaria que aumenta el tiempo de compilación y el tamaño del APK.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.7.1 | Eliminar `path_provider: ^2.1.0` de `pubspec.yaml` | `pubspec.yaml` | `code_searcher -g *.dart 'package:path_provider'` — no debe haber resultados | [ ] |
| D.7.2 | Ejecutar `flutter pub get` y `flutter analyze` | — | Sin errores después de remover la dependencia | [ ] |

---

### D.8 — Código duplicado: sort block aparece 3 veces en FilePanel

**Archivo:** `lib/widgets/file_panel.dart` — métodos `_loadFiles()`, `_enterDir()`, `_goUp()`

**Problema:** El mismo bloque de ordenamiento:
```dart
entries.sort((a, b) {
  if (a.isDirectory && !b.isDirectory) return -1;
  if (!a.isDirectory && b.isDirectory) return 1;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
});
```
Aparece **3 veces exactamente igual**.

**Impacto en escalabilidad:** Si se quiere cambiar el criterio de orden, hay que modificarlo en 3 lugares. Alta probabilidad de olvidar uno.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.8.1 | Extraer sort a método helper `_sorted(List<FileEntry> entries)` y llamarlo en los 3 lugares | `file_panel.dart` | Buscar `entries.sort` en el archivo. Debe aparecer solo **1 vez** (dentro del helper) | [ ] |

---

### D.9 — Código duplicado: patrón try/catch aparece 3 veces en FilePanel

**Archivo:** `lib/widgets/file_panel.dart`

**Problema:** El patrón:
```dart
try {
  ...
} on PlatformException catch (e) {
  final msg = _friendlyError(e.message ?? '$e');
  setState(() { _error = msg; _loading = false; });
} catch (e) {
  setState(() { _error = '$e'; _loading = false; });
}
```
Aparece **3 veces**.

**Impacto en escalabilidad:** Código verboso difícil de mantener. Si se agrega un nuevo tipo de error, hay que modificarlo en 3 lugares.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.9.1 | Crear método helper `_safeLoad(Future<List<FileEntry>> Function() loader)` que encapsule el try/catch/setState | `file_panel.dart` | Buscar `on PlatformException` en el archivo. Debe aparecer solo **1 vez** (dentro del helper) | [ ] |

---

### D.10 — Posición del cursor calculada en dos lugares diferentes (inconsistente)

**Archivo:** `lib/editor/editor_screen.dart` + `lib/editor/editor_controller.dart`

**Problema:** `editor_screen.dart` mantiene `_currentLine` y `_currentCol` local (calculados en `_updateCursorInfo()`), mientras que `EditorController` también tiene `currentLine` y `currentColumn`. **Nunca se sincronizan** entre sí.

**Impacto en escalabilidad:** El `EditorController.currentLine` del Provider siempre será 1 (nunca se actualiza), y el estado local de `editor_screen.dart` no es accesible desde otros widgets.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.10.1 | En `_updateCursorInfo()`, llamar a `_editor.updateCursorPosition(line, col)` en vez de mantener `_currentLine`/`_currentCol` local | `editor_screen.dart` | Buscar `_currentLine = ` en el archivo. Debe ser removido y reemplazado por `_editor.updateCursorPosition()` | [ ] |
| D.10.2 | Usar `_editor.currentLine` y `_editor.currentColumn` en la barra de estado en vez de vars locales | `editor_screen.dart` | El `_buildStatusBar()` debe leer de `_editor.currentLine` y `_editor.currentColumn` | [ ] |

---

### D.11 — `flutter_code_editor` infrautilizado: solo se usa el `CodeController`, no el `CodeField`

**Archivo:** `lib/editor/editor_screen.dart` + `pubspec.yaml`

**Problema:** Se instaló `flutter_code_editor` para usar `CodeField` + `CodeTheme` con resaltado de sintaxis. Pero `editor_screen.dart` usa un `TextField` plano. Solo se usa `CodeController` (como sustituto de `TextEditingController`). La dependencia `highlight` (para resaltado) también está infrautilizada.

**Impacto en escalabilidad:** Peso innecesario (~2MB extra en el APK por flutter_code_editor + highlight). Funcionalidad de resaltado de sintaxis no disponible, cuando se instaló específicamente para eso.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.11.1 | **Opción A**: Migrar a `CodeField` + `CodeTheme` y activar el resaltado de sintaxis (recomendado) | `editor_screen.dart` | Buscar `CodeField` en el archivo. Debe reemplazar a `TextField` | [ ] |
| D.11.2 | **Opción B**: Si se mantiene `TextField`, eliminar `flutter_code_editor` y `highlight` de `pubspec.yaml` | `pubspec.yaml` | Si no se usa `CodeField`, remover ambas dependencias | [ ] |
| D.11.3 | Si se opta por Opción A: verificar que el resaltado de sintaxis funcione según `SyntaxLanguage.detect()` | `editor_screen.dart` | `codeController.language` debe setearse al abrir archivos | [x] |

---

### D.12 — Menú "Reemplazar" tiene callback vacío (`onTap: () {}`)

**Archivo:** `lib/editor/editor_screen.dart` — menú Edición

**Problema:** La opción del menú "Reemplazar" no hace nada.

**Impacto en escalabilidad:** Funcionalidad fantasma que da la impresión de app incompleta.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.12.1 | Implementar funcionalidad de buscar y reemplazar | `editor_screen.dart` | La opción debe abrir una UI con campo de texto a reemplazar y botón de reemplazar | [ ] |
| D.12.2 | O eliminar la opción del menú | `editor_screen.dart` | Si no se implementa, el `PopupMenuItem` de "Reemplazar" no debe existir | [ ] |

---

### D.13 — Sin confirmación al descartar cambios sin guardar

**Archivo:** `lib/editor/editor_controller.dart` — `newFile()`

**Problema:** Cuando el usuario modifica un archivo y luego hace Ctrl+N (nuevo) o abre otro archivo, los cambios se pierden sin preguntar.

**Impacto en escalabilidad:** Riesgo de pérdida de trabajo del usuario.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.13.1 | En `newFile()` y `openFile()`, verificar `_isModified` y retornar `false` o lanzar excepción si hay cambios sin guardar | `editor_controller.dart` | Buscar lógica que pregunte antes de descartar cambios | [ ] |
| D.13.2 | En `editor_screen.dart`, capturar el caso y mostrar `showDialog` de confirmación | `editor_screen.dart` | Debe haber un diálogo "¿Guardar cambios?" antes de descartar | [ ] |

---

### D.14 — `config_screen.dart` tiene `TextEditingController` que nunca se usa como campo de texto editable

**Archivo:** `lib/widgets/config_screen.dart`

**Problema:** Se crea `final _pathController = TextEditingController()` pero solo se usa en un widget `Text` (no editable). Se podría reemplazar con un simple `String`.

**Impacto en escalabilidad:** Controller creado pero nunca liberado explícitamente (en `dispose`). Riesgo de memory leak mínimo pero real.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.14.1 | Reemplazar `_pathController` por `String _currentPath` simple | `config_screen.dart` | Buscar `TextEditingController` en el archivo. No debe existir | [ ] |

---

### D.15 — `SyntaxLanguage.detect()` no soporta rutas Windows (backslash)

**Archivo:** `lib/models/syntax_language.dart`

**Problema:** Usa `path.split('/').last` que falla en Windows donde los paths usan `\`.

**Impacto en escalabilidad:** La app está diseñada para ser multiplataforma pero este método falla en Windows.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.15.1 | Usar `Platform.pathSeparator` o `RegExp(r'[/\\]')` en vez de `'/'` hardcodeado | `syntax_language.dart` | Buscar `path.split('/')` — debe usar separador multiplataforma | [ ] |

---

### D.16 — `cupertino_icons` en dependencias sin uso

**Archivo:** `pubspec.yaml`

**Problema:** `cupertino_icons: ^1.0.8` está declarado pero no se usa ningún icono Cupertino.

**Impacto en escalabilidad:** Dependencia innecesaria.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.16.1 | Eliminar `cupertino_icons` de `pubspec.yaml` | `pubspec.yaml` | `code_searcher -g *.dart 'CupertinoIcons'` — no debe haber resultados | [ ] |

---

### D.17 — Tema oscuro: no hay botón de toggle en la UI actual

**Archivo:** `lib/editor/editor_screen.dart`

**Problema:** El `StatusBar` original tenía un botón de sol/luna para cambiar tema. La versión actual de `editor_screen.dart` no tiene ningún botón de toggle de tema.

**Impacto en escalabilidad:** El usuario no puede cambiar el tema desde la UI. `ThemeProvider` está configurado pero inaccesible.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.17.1 | Agregar botón de toggle de tema en la barra de estado o menú Ver | `editor_screen.dart` | Buscar `toggleTheme` en el archivo. Debe haber un `GestureDetector` o `IconButton` que lo invoque | [ ] |
| D.17.2 | Verificar que el cambio de tema se refleje inmediatamente en todos los colores | `editor_screen.dart` | Los colores deben usar `isDark` que se actualiza con `Theme.of(context).brightness` | [ ] |

---

### D.18 — `editor_screen.dart` es demasiado grande (~450 líneas)

**Archivo:** `lib/editor/editor_screen.dart`

**Problema:** El archivo mezcla: menú, editor, barra de estado, panel de archivos, búsqueda, atajos de teclado, línea de números, pantalla de bienvenida, y más. Todo en una sola clase.

**Impacto en escalabilidad:** Difícil de leer, mantener y testear. Cualquier cambio requiere navegar un archivo muy largo.

| # | Tarea | Archivo | Cómo verificar (AI) | Hecho |
|---|-------|---------|----------------------|-------|
| D.18.1 | Extraer `EditorToolbar` en widget separado (menú superior) | `lib/widgets/` | Debe existir archivo `editor_toolbar.dart` | [ ] |
| D.18.2 | Extraer `EditorSearchOverlay` en widget separado (búsqueda) | `lib/widgets/` | Debe existir archivo `editor_search.dart` | [ ] |
| D.18.3 | Extraer `LineNumberGutter` en widget separado (números de línea) | `lib/widgets/` | Debe existir archivo `line_number_gutter.dart` | [ ] |
| D.18.4 | Extraer `StatusBarWidget` en widget separado (barra inferior) | `lib/widgets/` | Debe existir archivo `status_bar_widget.dart` | [ ] |
| D.18.5 | Verificar que `editor_screen.dart` tenga menos de 200 líneas después de la refactorización | `editor_screen.dart` | Contar líneas del archivo. Debe ser < 200 | [ ] |

---

## 📊 TABLERO COMPLETO (incluye Sección D)

| # | Tarea | Hecho |
|---|-------|-------|
| A.1.1 | `_directoryPath = ''` por defecto | [x] |
| A.1.2 | FilePanel onboarding visual | [x] |
| A.1.3 | Auto-abrir Config al primer inicio | [x] |
| A.1.4 | Botón "Seleccionar carpeta" en FilePanel | [x] |
| A.1.5 | ConfigService devuelve `''` | [x] |
| A.2.1 | `isExternalStorageManager` nativo | [x] |
| A.2.2 | `requestManageStorage` nativo | [x] |
| A.2.3 | Métodos Dart `isExternalStorageManager` y `requestManageStorage` | [x] |
| A.2.4 | Verificar permiso antes de File API | [ ] |
| A.2.5 | `onActivityResult` para MANAGE_STORAGE | [x] |
| A.3.1 | `tryFallbackSAF` eliminado | [x] |
| A.3.2 | Llamada a `tryFallbackSAF` eliminada | [x] |
| A.3.3 | Errores claros en `listDirectoryPath` | [x] |
| A.3.4 | `_friendlyError()` captura ACCESS_DENIED | [x] |
| A.3.5 | `pathToDocId` eliminado | [x] |
| A.4.4 | `pathToDocId` eliminado (confirmación) | [x] |
| A.5.1 | `READ_MEDIA_IMAGES` en manifest | [ ] |
| A.5.2 | `READ_MEDIA_VIDEO` en manifest | [ ] |
| A.5.3 | `READ_MEDIA_AUDIO` en manifest | [ ] |
| A.5.4 | SAF forzado en API 33+ | [ ] |
| A.5.5 | `getApiLevel` usado para decidir ruta | [ ] |
| B.1.1 | `FileEntry` eliminado de `file_panel.dart` | [x] |
| B.1.2 | Import de `file_browser_service.dart` | [x] |
| B.1.3 | `FileEntry.fromMap` completo | [x] |
| B.1.4 | FilePanel usa `docId` para navegación | [x] |
| B.2.1 | Sin `_pathStack` | [x] |
| B.2.2 | `_enterDir` recibe `FileEntry` | [x] |
| B.2.3 | `_buildDocId` y familia eliminados | [x] |
| B.2.4 | `FileBrowserService` maneja `_currentDocId` | [x] |
| B.3.1 | `FileBrowserService` en FilePanel | [x] |
| B.3.2 | `_loadFiles` usa service | [x] |
| B.3.3 | `_enterDir` usa `service.navigateTo` | [x] |
| B.3.4 | `_goUp` usa `service.goUp` | [x] |
| B.3.5 | Métodos antiguos eliminados | [x] |
| B.3.6 | `openFolder` funciona | [x] |
| B.4.1 | `openFile` renombrado con named params | [ ] |
| B.4.2 | Llamadas actualizadas | [ ] |
| B.4.3 | `content://` detectado internamente | [x] |
| C.1.1 | SnackBar al cancelar picker | [ ] |
| C.1.2 | SnackBar al fallar picker | [x] |
| C.1.3 | Texto de ayuda en ConfigScreen | [x] |
| C.2.1 | Auto-abrir Config al primer inicio | [x] |
| C.2.2 | Texto de bienvenida en ConfigScreen | [ ] |
| C.2.3 | FilePanel onboarding visual | [x] |
| C.2.4 | Flag `onboarding_done` | [ ] |
| C.3.1 | `_friendlyError()` existe | [x] |
| C.3.2 | Mapeo de errores a español | [x] |
| C.3.3 | "Carpeta vacía" si lista vacía | [x] |
| C.4.1 | Log API level | [x] |
| C.4.2 | Log en `listDirectoryPath` | [x] |
| C.4.3 | Log en `FilePanel._loadFiles()` | [ ] |
| D.1.1 | Eliminar EditorController local en editor_screen.dart | [ ] |
| D.1.2 | Verificar llamadas con Provider | [ ] |
| D.1.3 | Eliminar `currentFilePath` duplicado | [ ] |
| D.1.4 | Eliminar `currentFileName` duplicado | [ ] |
| D.2.1 | Eliminar `file_browser.dart` | [ ] |
| D.2.2 | Eliminar `status_bar.dart` | [ ] |
| D.2.3 | Eliminar `search_bar.dart` | [ ] |
| D.2.4 | Eliminar `preferences_service.dart` | [ ] |
| D.2.5 | Eliminar `file_model.dart` | [ ] |
| D.2.6 | `flutter analyze` sin errores | [ ] |
| D.3.1 | Implementar navegación búsqueda o eliminar botones | [ ] |
| D.4.1 | Sincronizar undoCount/redoCount con historyController | [ ] |
| D.5.1 | Atajo Ctrl+Z (Undo) | [ ] |
| D.5.2 | Atajo Ctrl+Y (Redo) | [ ] |
| D.5.3 | Mostrar atajos en pantalla de bienvenida | [ ] |
| D.7.1 | Eliminar `path_provider` de pubspec | [ ] |
| D.7.2 | `flutter pub get` + analyze OK | [ ] |
| D.8.1 | Helper `_sorted()` para sort único | [ ] |
| D.9.1 | Helper `_safeLoad()` para try/catch único | [ ] |
| D.10.1 | Unificar posición cursor en EditorController | [ ] |
| D.10.2 | StatusBar usa `_editor.currentLine/Col` | [ ] |
| D.11.1 | Migrar a CodeField con resaltado (Opción A) | [ ] |
| D.12.1 | Implementar reemplazar o eliminar del menú | [ ] |
| D.13.1 | Confirmación al descartar cambios sin guardar | [ ] |
| D.14.1 | Eliminar TextEditingController innecesario | [ ] |
| D.15.1 | Soportar backslash (Windows) en SyntaxLanguage | [ ] |
| D.16.1 | Eliminar `cupertino_icons` de pubspec | [ ] |
| D.17.1 | Botón de toggle de tema en UI | [ ] |
| D.18.1 | Extraer EditorToolbar | [ ] |
| D.18.2 | Extraer EditorSearchOverlay | [ ] |
| D.18.3 | Extraer LineNumberGutter | [ ] |
| D.18.4 | Extraer StatusBarWidget | [ ] |
| D.18.5 | editor_screen.dart < 200 líneas | [ ] |

---

## 🔢 RESUMEN FINAL (con Sección D)

| Sección | Tareas | Hechas | % |
|---------|--------|--------|---|
| A — Bloqueantes (FileBrowser) | 21 | 14 | 67% |
| B — Estructurales (FileBrowser) | 17 | 14 | 82% |
| C — UX/Menores (FileBrowser) | 13 | 9 | 69% |
| D — Escalabilidad (Codebase general) | 34 | 1 | 3% |
| **TOTAL** | **85** | **38** | **45%** |

| Estado | Cantidad |
|--------|----------|
| `[x]` Completado | **38** |
| `[ ]` Pendiente | **47** |
| `[-]` No aplica | **0** |
| **Total** | **85** |

---

## 🧠 GUÍA DE USO PARA AI

Cuando una AI visite este archivo:

1. **Leer el archivo DIAGNÓSTICO completo** para entender el contexto.
2. **Para cada tarea con `[ ]`**: leer el archivo indicado y buscar el código descrito en "Cómo verificar".
3. **Si el código coincide**: cambiar `[ ]` a `[x]`.
4. **Si el archivo o método no existe**: marcar `[-]` y anotar por qué.
5. **Actualizar los contadores** en la sección RESUMEN FINAL.
6. **Actualizar la fecha** de la última verificación.
7. **Reportar al usuario**: cuántas se marcaron `[x]`, cuántas quedan `[ ]`.

**Las tareas de código (`[ ]`) son independientes entre sí.** Una AI puede completar una sin afectar las demás, a menos que la descripción indique dependencia.

---
