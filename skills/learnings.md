# Learnings — atom_flt

**Versión consolidada:** Merge de `docs/LEARNINGS.md` (mayúscula) y `docs/learnings.md` (minúscula)  
**Fecha:** 27 Julio 2026  
**Propósito:** Registro unificado de decisiones técnicas, restricciones, lecciones aprendidas y configuración de compilación.

---

## 📋 Resumen de Contradicciones Resueltas

| Conflicto | Resolución |
|-----------|-----------|
| `backend.addHighlight` vs `searchController.settingsController.patternController` | Usar `patternController`. `backend.addHighlight` **no existe** en flutter_code_editor 0.3.5, la API cambió |
| CodeField maneja atajos internamente vs usar KeyboardListener | El código actual usa `KeyboardListener` + `HardwareKeyboard`. Preferir esta opción por control más fino |
| SafeArea vs SizedBox(height: topInset) | El código actual usa `SizedBox(height: topInset)` para respetar notch. SafeArea también funciona pero da menos control |

---

## 1. Arquitectura

### Provider vs BLoC
Se eligió **Provider + ChangeNotifier** porque la aplicación tiene un estado relativamente simple (tema, contenido del editor, historial). BLoC introduciría sobreingeniería con eventos y streams innecesarios. Para una app de este tamaño, Provider + ChangeNotifier es el punto óptimo entre simplicidad y separación de responsabilidades.

### flutter_code_editor
`flutter_code_editor` ya incluye virtualización, numeración de líneas y resaltado de sintaxis basado en `highlight`. No es necesario implementar un editor desde cero ni usar paquetes separados para cada funcionalidad. La integración es directa:

```dart
CodeController controller = CodeController(text: '...', language: dart);
CodeField(controller: controller);
CodeTheme(data: CodeThemeData(styles: ...));
```

**⚠️ Estado actual (Julio 2026):** El código actual (`editor_screen.dart`) **no usa `CodeField`** sino un `TextField` plano. Esto significa que la virtualización, el resaltado de sintaxis y las funciones del `CodeController` (historial, search) están infrautilizados.

---

## 2. Resaltado de palabras (Word Highlighting)

### API correcta (flutter_code_editor 0.3.5)
`backend.addHighlight` **no existe** en flutter_code_editor 0.3.5. La API cambió. La implementación correcta es:

```dart
// Escuchar cambios de selección → extraer palabra bajo cursor
final patternCtrl =
    codeController.searchController.settingsController.patternController;
patternCtrl.text = word;  // Resalta todas las ocurrencias de la palabra
```

### Comportamiento
- Al hacer clic en una palabra, se resaltan todas las ocurrencias con fondo amarillo.
- El patrón se limpia al hacer clic en espacio vacío o palabra de 1 carácter.
- No muestra la UI de búsqueda.

### Implementación actual (editor_controller.dart)
```dart
void highlightWord(String? word) {
    final patternCtrl = codeController.searchController
        .settingsController.patternController;
    if (word == null || word.isEmpty) {
      patternCtrl.text = '';
      return;
    }
    patternCtrl.text = word;
}
```

**⚠️ Nota:** Esta funcionalidad solo funciona si se usa `CodeController` + `CodeField`. Con `TextField` plano no hay resaltado visual.

---

## 3. Compilación Android

### compileSdk
- **compileSdk 36**: necesario porque `flutter_plugin_android_lifecycle` 2.0.35 lo exige.
- Se configura en `android/app/build.gradle.kts` y se fuerza globalmente vía `android/gradle/compile_sdk.gradle` incluido desde `android/build.gradle.kts`.

### jni bug con Gradle 9+
- `jni 1.0.1` tiene un bug con Gradle 9+: el bloque `kotlin { compilerOptions { ... } }` se ejecuta aunque el plugin kotlin no se aplique en AGP ≥9.
- **Solución:** `dependency_overrides: jni: 1.0.0` en `pubspec.yaml`.

### Java 25
- **Java 25 no es compatible** con AGP actual.
- Usar: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`.

### SafeArea / Notch
- El `Scaffold.body` debe respetar el notch de la pantalla.
- En el código actual se usa: `SizedBox(height: MediaQuery.of(context).viewPadding.top)` y `SizedBox(height: MediaQuery.of(context).viewPadding.bottom)`.
- Alternativa: envolver `Column` con `SafeArea`.

### Permisos Android
- `READ_EXTERNAL_STORAGE` con `android:maxSdkVersion="32"` — solo para Android < 13.
- `MANAGE_EXTERNAL_STORAGE` declarado en manifest. Se solicita en runtime vía `Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION`.
- Para API 33+, los permisos granulares son `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`.
- **Recomendación:** Forzar SAF (`ACTION_OPEN_DOCUMENT_TREE`) como único método en API 33+.

---

## 4. Atajos de teclado

### Implementación actual
```dart
// editor_screen.dart — usa KeyboardListener + HardwareKeyboard
KeyboardListener(
  focusNode: FocusNode(),
  onKeyEvent: (event) {
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      if (shift) { _saveFileAs(); } else { _saveFile(); }
    } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyO) {
      _openFile();
    } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyN) {
      _newFile();
    } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyB) {
      setState(() => _showFilePanel = !_showFilePanel);
    } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyF) {
      setState(() => _isSearchVisible = !_isSearchVisible);
    }
  },
)
```

### Atajos implementados vs faltantes

| Acción | Atajo | Estado |
|--------|-------|--------|
| Guardar | Ctrl+S | ✅ |
| Guardar como | Ctrl+Shift+S | ✅ |
| Abrir archivo | Ctrl+O | ✅ |
| Nuevo archivo | Ctrl+N | ✅ |
| Alternar panel | Ctrl+B | ✅ |
| Buscar | Ctrl+F | ✅ |
| Deshacer | Ctrl+Z | ❌ **Faltante** |
| Rehacer | Ctrl+Y | ❌ **Faltante** |
| Seleccionar todo | Ctrl+A | ❌ **Faltante** |

### Notas sobre macOS
- En macOS, `control` debe reemplazarse por `meta` (Cmd).
- El código actual no discrimina por plataforma, por lo que en macOS los atajos no funcionan correctamente.

### Nota sobre CodeField
- Si se usa `CodeField` de flutter_code_editor, este ya maneja Ctrl+Z, Ctrl+Y, Ctrl+C, Ctrl+V internamente.
- Si se usa `TextField` plano (como actualmente), se debe implementar manualmente.

---

## 5. Persistencia

### Tema
- `shared_preferences` con un booleano `dark_mode` es suficiente.
- No se necesita SQLite ni archivos de configuración.
- Cargar preferencias en `main.dart` **antes** de `runApp()` para evitar flash de tema incorrecto.

```dart
// main.dart
final themeProvider = ThemeProvider();
await themeProvider.loadPreferences();
runApp(MultiProvider(providers: [...], child: App()));
```

### Configuración de carpeta
- `ConfigService` guarda en SharedPreferences:
  - `default_directory` (String) — última ruta usada
  - `tree_uri` (String?) — URI SAF para acceso con scoped storage

---

## 6. Multiplataforma

### file_picker
- Funciona en todas las plataformas.
- **macOS:** requiere entitlements adicionales.
- **Linux:** requiere el paquete del sistema `libfilepicker` instalado.

### path_provider
- **Linux:** requiere `libpath_provider` instalado.
- Actualmente declarado en `pubspec.yaml` pero **no se usa en el código**.

### Atajos de teclado
- Se manejan con `KeyboardListener` + `HardwareKeyboard` (en lugar de `Shortcuts` widget) por tener control más fino sobre combinaciones como Ctrl+Shift+S.
- `Ctrl+Shift+S` requiere `LogicalKeyboardKey.keyS` con `shift: true` y `control: true`.
- En macOS, `control` debe reemplazarse por `meta` (Cmd).

---

## 7. Archivos grandes

- **Límite práctico:** ~100k líneas con `flutter_code_editor`.
- Más allá de eso, considerar carga diferida y `TextRange` para no saturar la memoria.
- La virtualización ya viene incluida en `flutter_code_editor` (usando `ListView.builder` internamente).
- **⚠️ Nota:** Con `TextField` plano (implementación actual), no hay virtualización. Archivos grandes pueden causar ralentizaciones.

---

## 8. Tests

### Convenciones
- Usar `flutter_test` (no paquetes externos como mockito, a menos que sea necesario).
- Nombrar tests en formato: `"debería [comportamiento esperado]"`.
- Un test por comportamiento. Usar `group` para agrupar casos relacionados.

### FileService
- Usar `Directory.systemTemp` para pruebas de I/O sin contaminar el sistema.

### ThemeProvider
- Constructor de prueba sin `SharedPreferences` real (no inicializar la persistencia).

### file_picker
- Mockear `file_picker` devolviendo rutas prefijadas en widget tests.

### Estado actual (Julio 2026)
- **No existen tests unitarios** para `EditorController`, `FileService`, `FileBrowserService`, `ConfigService` ni `ThemeProvider`.
- Solo existe `test/widget_test.dart` (genérico de Flutter).

---

## 9. Flujo de documentación

- La documentación debe escribirse completa **antes** del código (por especificación).
- Los archivos en `docs/` siguen la estructura:
  1. `README.md` — Visión general
  2. `architecture.md` — Estructura y patrones
  3. `design.md` — UI/UX
  4. `development_plan.md` — Fases y hitos
  5. `TODO.md` — Tareas pendientes
  6. `api_reference.md` — APIs externas
  7. `contributing.md` — Cómo contribuir
  8. `user_guide.md` — Guía de usuario
  9. `syntax_themes.md` — Temas de resaltado
  10. `testing.md` — Estrategia de tests
  11. `faq.md` — Preguntas frecuentes
  12. `learnings.md` — **Este archivo** (lecciones aprendidas)

---

## 10. Git: versionado con tags

- Cada commit en main debe tener un tag semver (`v1.0.0`, `v1.0.1`, ...).
- Los tags se asignan cronológicamente: el commit más antiguo recibe el tag más bajo.
- No pushear sin tag. Siempre: `git push origin main --tags`.
- Para reasignar tags: borrar local y remoto, recrear en orden, pushear.
  ```bash
  git tag -d v1.0.0
  git push origin --delete v1.0.0
  git tag v1.0.0 <commit-hash>
  git push origin main --tags
  ```

---

## 11. Lecciones del desarrollo (histórico)

### Lo que funcionó bien
- Provider + ChangeNotifier: simple y suficiente para el alcance.
- flutter_code_editor: reduce drásticamente el código necesario para el editor.
- shared_preferences: ideal para preferencias simples (tema, ruta).
- SAF (Storage Access Framework): la única forma confiable de acceder a archivos en Android 11+.
- Separación del FilePanel en widget independiente: facilita el testing y mantenimiento.

### Lo que no funcionó
- **tryFallbackSAF:** intentar construir URIs SAF sin permisos de usuario es imposible en Android 11+.
- **pathToDocId:** el mismatch entre `/sdcard` y `/storage/emulated/0` rompe la conversión de rutas.
- **Dos instancias de EditorController:** una en Provider y otra local en editor_screen.dart → estado inconsistente.
- **backend.addHighlight:** la API cambió en flutter_code_editor 0.3.5, `backend` ya no existe.
- **CodeField abandonado a mitad de camino:** se refactorizó editor_screen.dart a TextField plano pero se dejó flutter_code_editor como dependencia.

---

## 12. Checklist de verificación (para AI)

Cuando una AI visite este archivo, debe verificar:

- [ ] `docs/LEARNINGS.md` (mayúscula) fue eliminado después del merge
- [ ] `docs/learnings.md` (minúscula) contiene el merge completo
- [ ] El resaltado de ocurrencias usa `patternController` (no `backend.addHighlight`)
- [ ] Los atajos Ctrl+Z y Ctrl+Y están implementados (ver D.5 en DIAGNOSTICO)
- [ ] La compilación Android usa Java 21 (no 25)
- [ ] `dependency_overrides: jni: 1.0.0` existe en `pubspec.yaml`
- [ ] Los tests existen y pasan (ver Sección 8)

---

*Fin del documento consolidado.*
*Reemplaza a `docs/LEARNINGS.md` (mayúscula) y `docs/learnings.md` (minúscula).*
