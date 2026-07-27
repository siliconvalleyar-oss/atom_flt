# Testing — atom_flt

## Cómo ejecutar los tests

```bash
# Todos los tests
flutter test

# Tests unitarios específicos
flutter test test/unit/editor_controller_test.dart
flutter test test/unit/file_service_test.dart
flutter test test/unit/theme_provider_test.dart

# Tests de widgets
flutter test test/widget/editor_screen_test.dart
flutter test test/widget/code_editor_widget_test.dart

# Con cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
```

## Estructura de tests

```
test/
├── unit/
│   ├── editor_controller_test.dart
│   ├── file_service_test.dart
│   ├── theme_provider_test.dart
│   └── syntax_language_test.dart
└── widget/
    ├── editor_screen_test.dart
    └── code_editor_widget_test.dart
```

## Convenciones

- Usar `flutter_test` (no paquetes externos como mockito, a menos que sea necesario).
- Nombrar tests en formato: `"debería [comportamiento esperado]"`.
- Un test por comportamiento. Usar `group` para agrupar casos relacionados.
- Mockear servicios de archivos y preferencias con clases `Fake` simples.

## Ejemplo de test unitario

```dart
void main() {
  group('EditorController', () {
    test('debería deshacer la última edición', () {
      final controller = EditorController();
      controller.setContent('Hola mundo');
      controller.setContent('Hola Flutter');
      controller.undo();
      expect(controller.content, 'Hola mundo');
    });
  });
}
```

## Cobertura objetivo

| Módulo | Cobertura mínima |
|--------|-----------------|
| EditorController | 90% |
| FileService | 85% |
| ThemeProvider | 90% |
| SyntaxLanguage | 100% |
| Widgets principales | 75% |

## CI (GitHub Actions)

```yaml
name: test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - run: flutter pub get
      - run: dart analyze
      - run: flutter test --coverage
```

## Notas

- Los tests no deben depender del sistema de archivos real. Usar archivos temporales en `/tmp` o mocks.
- Para tests de widgets que usan `file_picker`, inyectar un `FileService` mockeado que devuelva rutas controladas.
- El cambio de tema no debe requerir `SharedPreferences` real en tests; usar un `FakePreferencesService`.
