Actúa como un experto arquitecto de software y desarrollador Flutter. Debes generar una aplicación completa llamada "atom_flt" (nombre del proyecto y de la app) que sea un editor de código fuente con estilo minimalista similar a Atom, con numeración de líneas, resaltado de sintaxis, búsqueda al hacer clic en una palabra y todas las funcionalidades descritas más adelante.

**INSTRUCCIÓN FUNDAMENTAL**: En tu respuesta, **PRIMERO** debes proporcionar toda la documentación, arquitectura, diseño y planificación del proyecto. Solo después de haber presentado esa documentación completa, proporcionarás el código fuente completo. No generes código antes de la documentación.

La documentación debe incluir, al menos, los siguientes archivos Markdown (contenido completo y detallado) ubicados en una carpeta `docs/`:

- `docs/README.md` – Visión general del proyecto, propósito, características principales.
- `docs/architecture.md` – Estructura de carpetas, patrones de diseño (ej. BLoC, Provider, MVVM), decisiones técnicas, paquetes a usar y justificación.
- `docs/design.md` – Guía de interfaz de usuario, paleta de colores (claro/oscuro), tipografía, componentes reutilizables, experiencia de usuario (flujo de abrir/guardar).
- `docs/development_plan.md` – Fases de desarrollo, hitos, estimaciones, pruebas.
- `docs/TODO.md` – Lista de tareas pendientes, prioridades, futuras mejoras.
- `docs/api_reference.md` (opcional) – Si usas alguna API o librería externa, documenta su uso.
- Cualquier otro archivo `.md` que consideres necesario para una documentación completa.

Además, debes generar el **icono del lanzador** de la aplicación. Proporciona un archivo SVG (o una imagen en base64) con diseño minimalista que represente un átomo estilizado, y colócalo en `assets/icon/` (indica las resoluciones necesarias para Android e iOS). También debes describir cómo generar los distintos tamaños a partir del SVG.

**Requisitos de la aplicación `atom_flt`** (a implementar en la fase de código):

- Editor de texto con soporte para archivos de código: `.cpp`, `.hpp`, `.h`, `.c`, `.txt`, `.md`, `.js`, `.css`, `.html`, `.py`, `.java`, `.json`, `.xml`, `.yaml`, `.sh` y cualquier otro ASCII/UTF-8.
- Numeración de líneas en el margen izquierdo, actualización dinámica.
- Resaltado de sintaxis específico por extensión (similar a gedit/Atom).
- Al hacer clic/toque sobre una palabra, se resaltan todas las ocurrencias en el archivo (como en VS Code).
- Soporte para archivos grandes con virtualización.
- Abrir, guardar, guardar como, nuevo, deshacer/rehacer, atajos de teclado (Ctrl+S, Ctrl+Z, Ctrl+Y, Ctrl+F, etc.).
- Tema claro/oscuro intercambiable.
- Diseño minimalista, limpio, con bordes sutiles y espaciado generoso.

**Detalles técnicos**:
- Usa Flutter (última versión estable) con soporte para móvil (Android/iOS) y escritorio (Windows/macOS/Linux).
- Paquetes sugeridos: `file_picker`, `path_provider`, `flutter_code_editor` (o `highlight`), `provider` para estado, `shared_preferences` para preferencias de tema.
- La arquitectura debe ser mantenible y escalable.

**Formato de salida**:
Comienza tu respuesta con la documentación completa (todos los archivos `.md`). Luego, después de una separación clara (ej. "--- FIN DE DOCUMENTACIÓN ---"), proporciona el código fuente completo de la aplicación, incluyendo `pubspec.yaml`, `main.dart`, las pantallas, widgets, lógica de resaltado, etc. Todo en bloques de código con el nombre del archivo correspondiente.

Asegúrate de que la documentación sea exhaustiva, clara y bien estructurada, y que el código final sea funcional, bien comentado y siga las mejores prácticas de Flutter.

**Importante**: No omitas ningún paso. El proyecto debe llamarse `atom_flt` en todo lugar (nombre de la app, carpeta, etc.).
