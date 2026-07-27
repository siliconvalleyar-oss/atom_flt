# atom_flt

Editor de código fuente minimalista y multiplataforma construido con Flutter, inspirado en el diseño y la experiencia de uso de Atom Editor.

## Propósito

**atom_flt** nace de la necesidad de un editor de código ligero, moderno y altamente portable que funcione de forma nativa en dispositivos móviles (Android, iOS) y de escritorio (Windows, macOS, Linux). A diferencia de los editores tradicionales, atom_flt aprovecha el motor de renderizado de Flutter para ofrecer una interfaz de usuario consistente y fluida en todas las plataformas con un solo código base.

## Características principales

- **Editor de texto con resaltado de sintaxis** para múltiples lenguajes: C, C++, Python, JavaScript, HTML, CSS, Java, JSON, XML, YAML, Markdown, Shell y más.
- **Numeración dinámica de líneas** en el margen izquierdo, con actualización en tiempo real.
- **Resaltado de ocurrencias**: al hacer clic o tocar una palabra, se iluminan todas sus apariciones en el archivo.
- **Soporte para archivos grandes** mediante virtualización del contenido.
- **Operaciones de archivo**: Nuevo, Abrir, Guardar, Guardar como.
- **Deshacer/Rehacer** con historial ilimitado.
- **Atajos de teclado** estándar (Ctrl+S, Ctrl+Z, Ctrl+Y, Ctrl+F, Ctrl+N, Ctrl+O, etc.).
- **Tema claro/oscuro** intercambiable en tiempo real.
- **Diseño minimalista** con bordes sutiles, espaciado generoso y tipografía limpia.
- **Icono de lanzador** con un átomo estilizado como representación visual de la app.

## Plataformas objetivo

| Plataforma | Soporte |
|-----------|---------|
| Android   | ✅      |
| iOS       | ✅      |
| Windows   | ✅      |
| macOS     | ✅      |
| Linux     | ✅      |

## Stack técnico

- **Framework**: Flutter (última versión estable)
- **Lenguaje**: Dart
- **Gestión de estado**: Provider + ChangeNotifier
- **Almacenamiento local**: shared_preferences
- **Selector de archivos**: file_picker
- **Rutas del sistema**: path_provider
- **Editor de código con resaltado**: flutter_code_editor + highlight

## Licencia

MIT
