# Arquitectura del proyecto

## Estructura de carpetas

```
atom_flt/
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
├── assets/
│   ├── icon/
│   │   ├── atom_icon.svg
│   │   └── app_icon.png
│   └── fonts/
├── docs/
│   ├── PROMPT.md
│   ├── README.md
│   ├── architecture.md
│   ├── design.md
│   ├── development_plan.md
│   ├── TODO.md
│   └── api_reference.md
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_provider.dart
│   ├── editor/
│   │   ├── editor_screen.dart
│   │   ├── code_editor_widget.dart
│   │   ├── line_number_gutter.dart
│   │   ├── word_highlighter.dart
│   │   └── editor_controller.dart
│   ├── models/
│   │   ├── file_model.dart
│   │   └── syntax_language.dart
│   ├── services/
│   │   ├── file_service.dart
│   │   └── preferences_service.dart
│   └── widgets/
│       ├── menu_bar.dart
│       ├── status_bar.dart
│       └── search_bar.dart
├── test/
│   ├── unit/
│   │   ├── editor_controller_test.dart
│   │   ├── file_service_test.dart
│   │   └── theme_provider_test.dart
│   └── widget/
│       ├── editor_screen_test.dart
│       └── code_editor_widget_test.dart
├── pubspec.yaml
└── README.md
```

## Patrones de diseño

### 1. Provider + ChangeNotifier (gestión de estado)

Se eligió **Provider** sobre BLoC o Riverpod por su simplicidad y menor curva de aprendizaje, suficiente para una aplicación de este alcance. La gestión de estado se divide en dos providers principales:

- **ThemeProvider**: notifica cambios de tema (claro/oscuro) y persiste la preferencia en `shared_preferences`.
- **EditorController** (ChangeNotifier): maneja el estado del editor: contenido, historial de deshacer/rehacer, archivo abierto, selección, ocurrencias resaltadas.

### 2. Single Responsibility Principle (SRP)

Cada clase tiene una responsabilidad única y bien definida:

| Clase | Responsabilidad |
|-------|----------------|
| `FileService` | Operaciones de lectura/escritura en el sistema de archivos |
| `PreferencesService` | Persistencia y recuperación de preferencias de usuario |
| `EditorController` | Lógica del editor, historial, estado del documento |
| `WordHighlighter` | Lógica de detección y resaltado de ocurrencias |
| `ThemeProvider` | Gestión del tema claro/oscuro |

### 3. Repository Pattern (variante simplificada)

Los servicios actúan como repositorios que abstraen el acceso a datos (archivos, preferencias), permitiendo que el resto de la aplicación ignore los detalles de implementación.

## Flujo de datos

```
Usuario interactúa con UI
        │
        ▼
Widget (Screen/Component)
        │
        ▼
Provider (ChangeNotifier) ← → Service (File/Preferences)
        │
        ▼
UI se reconstruye (Consumer/Selector)
```

## Decisiones técnicas

### ¿Por qué `flutter_code_editor` en lugar de `highlight` solo?
`flutter_code_editor` proporciona un widget completo con resaltado basado en `highlight`, numeración de líneas, plegado de código y virtualización. Esto reduce significativamente el código personalizado necesario.

### ¿Por qué Provider y no BLoC?
BLoC introduce mayor complejidad (eventos, estados, streams) que no es necesaria aquí. Provider con ChangeNotifier es más directo y suficiente para una app con estados simples.

### ¿Virtualización para archivos grandes?
`flutter_code_editor` ya implementa virtualización mediante `ListView.builder` internamente, renderizando solo las líneas visibles. Esto permite manejar archivos de miles de líneas sin degradación del rendimiento.

### Separación de temas
Los temas se definen como objetos `ThemeData` inmutables. El `ThemeProvider` expone el tema actual y alterna entre dos instancias predefinidas, evitando reconstrucciones costosas.

## Paquetes externos

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| provider | ^6.1.0 | Gestión de estado |
| shared_preferences | ^2.2.0 | Persistencia de preferencias |
| file_picker | ^8.0.0 | Diálogo nativo para seleccionar archivos |
| path_provider | ^2.1.0 | Rutas de directorios del sistema |
| flutter_code_editor | ^0.3.0 | Widget editor con resaltado de sintaxis |
| highlight | ^0.7.0 | Motor de resaltado de sintaxis subyacente |
| google_fonts | ^6.1.0 | Tipografía JetBrains Mono para el editor |
