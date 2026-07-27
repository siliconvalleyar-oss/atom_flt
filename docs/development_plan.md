# Plan de desarrollo

## Fases de desarrollo

### Fase 1: Base del proyecto (Días 1–2)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 1.1 | Crear proyecto Flutter `atom_flt` | 30 min | — |
| 1.2 | Configurar `pubspec.yaml` con dependencias | 30 min | 1.1 |
| 1.3 | Estructurar carpetas `lib/` | 15 min | 1.1 |
| 1.4 | Implementar temas claro/oscuro (`app_theme.dart`) | 1 h | 1.2 |
| 1.5 | Implementar `ThemeProvider` con persistencia | 1 h | 1.4 |
| 1.6 | Crear `main.dart` y `app.dart` básicos | 30 min | 1.3, 1.5 |
| 1.7 | Implementar `PreferencesService` | 30 min | 1.2 |
| 1.8 | **Hito**: app se ejecuta con cambio de tema funcional | — | 1.1–1.7 |

### Fase 2: Editor básico (Días 3–5)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 2.1 | Configurar `flutter_code_editor` + `highlight` | 1 h | 1.2 |
| 2.2 | Crear `CodeEditorWidget` | 2 h | 2.1 |
| 2.3 | Crear `LineNumberGutter` personalizado | 1 h | 2.2 |
| 2.4 | Implementar `EditorController` (ChangeNotifier) | 2 h | 2.1 |
| 2.5 | Integrar editor en `EditorScreen` | 1 h | 2.2, 2.4 |
| 2.6 | Crear `StatusBar` con línea/columna | 1 h | 2.5 |
| 2.7 | **Hito**: editor funcional con numeración y barra de estado | — | 2.1–2.6 |

### Fase 3: Operaciones con archivos (Días 6–7)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 3.1 | Implementar `FileService` | 1.5 h | 2.4 |
| 3.2 | Nuevo archivo (Ctrl+N) | 30 min | 3.1 |
| 3.3 | Abrir archivo (Ctrl+O) con `file_picker` | 1 h | 3.1 |
| 3.4 | Guardar (Ctrl+S) y Guardar como (Ctrl+Shift+S) | 1.5 h | 3.1 |
| 3.5 | Confirmación al cerrar sin guardar | 1 h | 3.4 |
| 3.6 | Atajos de teclado (mapeo global) | 2 h | 3.2–3.5 |
| 3.7 | **Hito**: apertura, edición y guardado de archivos | — | 3.1–3.6 |

### Fase 4: Resaltado avanzado (Días 8–9)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 4.1 | Configurar lenguajes de resaltado por extensión | 1 h | 2.1 |
| 4.2 | Implementar `SyntaxLanguage` (mapa extensión → lenguaje) | 1 h | 4.1 |
| 4.3 | Resaltado de ocurrencias (`WordHighlighter`) | 2 h | 2.4 |
| 4.4 | Soporte para archivos grandes (virtualización) | 1 h | 2.1 (ya incluido) |
| 4.5 | **Hito**: resaltado completo y ocurrencias funcionales | — | 4.1–4.4 |

### Fase 5: Búsqueda y refinamiento (Días 10–11)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 5.1 | Implementar `SearchBar` (Ctrl+F) | 2 h | 2.5 |
| 5.2 | Navegación entre resultados (siguiente/anterior) | 1 h | 5.1 |
| 5.3 | Reemplazar texto (opcional, Ctrl+H) | 1.5 h | 5.1 |
| 5.4 | Tests unitarios (editor, servicios, tema) | 3 h | 2.4, 3.1, 1.5 |
| 5.5 | Tests de widgets (pantallas principales) | 2 h | 2.5, 5.1 |
| 5.6 | **Hito**: versión beta con búsqueda y tests | — | 5.1–5.5 |

### Fase 6: Pulido y distribución (Días 12–14)

| # | Tarea | Duración | Dependencias |
|---|-------|----------|--------------|
| 6.1 | Icono de lanzador (SVG + generación de tamaños) | 1 h | — |
| 6.2 | Configuración específica por plataforma | 2 h | 6.1 |
| 6.3 | Pruebas en Android y Linux | 3 h | 5.6 |
| 6.4 | Corrección de bugs | 4 h | 6.3 |
| 6.5 | Documentación final en `docs/` | 2 h | — |
| 6.6 | **Hito**: v1.0 lista para distribución | — | 6.1–6.5 |

## Hitos resumen

| Hito | Fecha estimada | Entregable |
|------|---------------|------------|
| Fase 1 | Día 2 | App con cambio de tema |
| Fase 2 | Día 5 | Editor funcional |
| Fase 3 | Día 7 | Operaciones de archivo |
| Fase 4 | Día 9 | Resaltado completo |
| Fase 5 | Día 11 | Beta con búsqueda |
| Fase 6 | Día 14 | v1.0 |

## Pruebas

### Unitarias
- `EditorController`: deshacer/rehacer, contenido, selección, ocurrencias.
- `FileService`: lectura/escritura, manejo de errores (archivo no existe, permisos).
- `ThemeProvider`: cambio de tema, persistencia.
- `SyntaxLanguage`: detección correcta de lenguaje por extensión.

### De integración
- Apertura de archivo → resaltado correcto.
- Guardado → contenido escrito correctamente en disco.
- Cambio de tema → persistencia al reiniciar.

### Widget
- `EditorScreen` se renderiza sin errores.
- Búsqueda muestra resultados correctos.
- Barra de estado refleja línea/columna.

### Manuales (por plataforma)
- Apertura de archivos grandes (>10 000 líneas).
- Cambio de tema en tiempo real.
- Atajos de teclado en escritorio.
