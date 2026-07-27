# Learnings — atom_flt

Registro de decisiones, insights y lecciones aprendidas durante el desarrollo del proyecto.

## Arquitectura

### Provider vs BLoC
Se eligió Provider porque la aplicación tiene un estado relativamente simple (tema, contenido del editor, historial). BLoC introduciría sobreingeniería con eventos y streams innecesarios. Para una app de este tamaño, Provider + ChangeNotifier es el punto óptimo entre simplicidad y separación de responsabilidades.

### flutter_code_editor
Este paquete ya incluye virtualización, numeración de líneas y resaltado de sintaxis basado en highlight. No es necesario implementar un editor desde cero ni usar paquetes separados para cada funcionalidad. La integración es directa: `CodeController` + `CodeField` + `CodeTheme`.

## Resaltado de ocurrencias
`flutter_code_editor` no tiene resaltado de ocurrencias nativo. La solución es:
1. Escuchar cambios de selección en el `CodeController`.
2. Extraer la palabra bajo el cursor.
3. Buscar todas las posiciones de esa palabra en el texto.
4. Aplicar `backend.addHighlight` con un estilo personalizado.

Esto es más eficiente que usar un `TextEditingController` personalizado y evita conflictos con el motor de resaltado de sintaxis.

## Persistencia del tema
`shared_preferences` es suficiente para guardar una preferencia booleana (`isDarkMode`). No se necesita SQLite ni archivos de configuración. La carga es asíncrona en `main.dart` antes de lanzar la app para evitar un flash de tema incorrecto.

## Archivos grandes
La virtualización ya viene incluida en `flutter_code_editor`. Sin embargo, para archivos >100k líneas conviene cargar el contenido por fragmentos y usar `TextRange` para no saturar la memoria. Por ahora, el límite práctico es 100k líneas.

## Multiplataforma
- **file_picker** funciona en todas las plataformas pero requiere configuración adicional en macOS (entitlements) y Linux (paquete libfilepicker).
- **path_provider** en Linux requiere `libpath_provider` instalado.
- Los atajos de teclado se manejan con `KeyboardListener` + `HardwareKeyboard` en lugar de `Shortcuts` widget, por tener control más fino sobre combinaciones como Ctrl+Shift+S.

## Atajos de teclado
- Usar `CallbackShortcuts` de Flutter con `SingleActivator` para combinaciones estándar.
- `Ctrl+Shift+S` requiere `LogicalKeyboardKey.keyS` con `shift: true` y `control: true`.
- En macOS, `control` debe reemplazarse por `meta` (Cmd).

## Tests
- `FileService` debe usar `Directory.systemTemp` para pruebas de escritura/lectura sin contaminar el sistema.
- `ThemeProvider` puede inicializarse sin `SharedPreferences` real usando un constructor de prueba.
- Los tests de widgets que usan `file_picker` deben mockear la selección devolviendo una ruta prefijada.
