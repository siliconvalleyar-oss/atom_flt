# LEARNINGS — atom_flt

Registro de decisiones técnicas, restricciones y lecciones aprendidas durante el desarrollo.

## Arquitectura

- Provider + ChangeNotifier es suficiente; BLoC sería sobreingeniería para este alcance.
- `flutter_code_editor` ya incluye virtualización, line numbers y resaltado vía `highlight`. No implementar desde cero.
- El resaltado de ocurrencias se implementa mediante `searchController.settingsController.patternController` (API interna, requiere `// ignore: invalid_use_of_internal_member`).
- No existe `backend.addHighlight` en flutter_code_editor 0.3.5. La API cambió.

## Compilación Android

- **compileSdk 36**: necesario porque `flutter_plugin_android_lifecycle` 2.0.35 lo exige. Se configura en `android/app/build.gradle.kts` y se fuerza globalmente via `android/gradle/compile_sdk.gradle` incluido desde `android/build.gradle.kts`.
- **jni 1.0.1** tiene un bug con Gradle 9+: el bloque `kotlin { compilerOptions { ... } }` se ejecuta aunque el plugin kotlin no se aplique en AGP ≥9. Solución: `dependency_overrides: jni: 1.0.0` en `pubspec.yaml`.
- **Java 25** no es compatible con AGP actual. Usar `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`.
- **SafeArea**: necesario para evitar que la barra de navegación de Android superponga el contenido. Envolver `Column` del `Scaffold.body` con `SafeArea`.

## Resaltado de palabras (word highlighting)

- Al hacer clic en una palabra, se usa `searchController` para resaltar todas las ocurrencias. El resaltado aplica fondo amarillo sin mostrar la UI de búsqueda.
- El patrón se limpia al hacer clic en espacio vacío o palabra de 1 carácter.

## Atajos de teclado

- `CodeField` de flutter_code_editor ya maneja Ctrl+Z, Ctrl+Y, Ctrl+C, Ctrl+V internamente.
- No es necesario `CallbackShortcuts` adicional; el menú muestra los atajos como referencia.

## Persistencia

- Tema: `shared_preferences` con un booleano es suficiente.
- Cargar preferencias en `main.dart` antes de `runApp()` para evitar flash de tema incorrecto.

## Multiplataforma

- `file_picker` requiere macOS entitlements y `libfilepicker` en Linux.
- `path_provider` en Linux necesita el paquete del sistema.

## Archivos grandes

- Límite práctico: ~100k líneas con `flutter_code_editor`.
- Más allá de eso, considerar carga diferida y `TextRange`.

## Tests

- `FileService`: usar `Directory.systemTemp` para pruebas de I/O.
- `ThemeProvider`: constructor de prueba sin `SharedPreferences` real.
- Mockear `file_picker` devolviendo rutas prefijadas en widget tests.

## Flujo de documentación

- La documentación debe escribirse completa **antes** del código (por especificación).
- Los archivos en `docs/` siguen la estructura: README, architecture, design, development_plan, TODO, api_reference, contributing, user_guide, syntax_themes, testing, faq.

## Git: versionado con tags

- Cada commit en main debe tener un tag semver (v1.0.0, v1.0.1, ...).
- Los tags se asignan cronológicamente: el commit más antiguo recibe el tag más bajo.
- No pushear sin tag. Siempre `git push origin main --tags`.
- Para reasignar tags: borrar local y remoto, recrear en orden, pushear. Ej: `git tag -d v1.0.0 && git push origin --delete v1.0.0`.
