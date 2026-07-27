# LEARNINGS — atom_flt

Registro de decisiones técnicas, restricciones y lecciones aprendidas durante el desarrollo.

## Arquitectura

- Provider + ChangeNotifier es suficiente; BLoC sería sobreingeniería para este alcance.
- `flutter_code_editor` ya incluye virtualización, line numbers y resaltado vía `highlight`. No implementar desde cero.
- El resaltado de ocurrencias no es nativo del paquete: hay que usar `backend.addHighlight` con un listener de selección.

## Atajos de teclado

- Usar `CallbackShortcuts` + `SingleActivator`.
- `Ctrl+Shift+S` requiere `LogicalKeyboardKey.keyS` con `shift: true` y `control: true`.
- En macOS, reemplazar `control` por `meta` (Cmd).

## Persistencia

- Tema: `shared_preferences` con un booleano es suficiente.
- Cargar preferencias en `main.dart` antes de `runApp()` para evitar flash de tema incorrecto.

## Multiplataforma

- `file_picker` requiere macOS entitlements y `libfilepicker` en Linux.
- `path_provider` en Linux necesita el paquete del sistema.
- Los shortcuts deben detectar la plataforma para switchear Ctrl/Cmd.

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
- El icono SVG debe generarse y describir cómo producir tamaños para Android/iOS desde él.
