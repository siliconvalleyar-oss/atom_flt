# Guía de usuario — atom_flt

## Atajos de teclado

| Acción               | Windows/Linux      | macOS            |
|----------------------|--------------------|------------------|
| Nuevo archivo        | `Ctrl + N`         | `Cmd + N`        |
| Abrir archivo        | `Ctrl + O`         | `Cmd + O`        |
| Guardar              | `Ctrl + S`         | `Cmd + S`        |
| Guardar como         | `Ctrl + Shift + S` | `Cmd + Shift + S`|
| Deshacer             | `Ctrl + Z`         | `Cmd + Z`        |
| Rehacer              | `Ctrl + Y`         | `Cmd + Shift + Z`|
| Buscar               | `Ctrl + F`         | `Cmd + F`        |
| Buscar y reemplazar  | `Ctrl + H`         | `Cmd + H`        |
| Alternar tema        | `Ctrl + T`         | `Cmd + T`        |
| Salir                | `Alt + F4`         | `Cmd + Q`        |

## Flujo de trabajo

### Abrir un archivo
1. `Ctrl + O` o menú Archivo → Abrir.
2. Selecciona el archivo en el diálogo nativo.
3. El contenido se carga con resaltado automático según la extensión.

### Editar código
- Escribe directamente en el editor.
- La numeración de líneas se actualiza automáticamente.
- La barra de estado muestra línea y columna actual.

### Resaltar ocurrencias
- Haz clic o toca cualquier palabra.
- Todas las ocurrencias en el archivo se iluminan en amarillo.

### Guardar cambios
- `Ctrl + S` guarda el archivo actual. Si es nuevo, pedirá ubicación.
- Si el archivo se modificó, aparece un indicador en la barra de título.

### Cambiar tema
- `Ctrl + T` o menú Ver → Tema oscuro/claro.
- La preferencia se guarda automáticamente.

### Buscar
- `Ctrl + F` abre la barra de búsqueda en la parte superior.
- Escribe el texto: los resultados se resaltan y puedes navegar con Enter/Shift+Enter.

## Archivos grandes

atom_flt maneja archivos de hasta 100 000 líneas sin problemas gracias a la virtualización. Para archivos excepcionalmente grandes (>500 000 líneas), se recomienda usar un editor de escritorio tradicional.

## Formatos soportados

`.cpp` `.hpp` `.h` `.c` `.dart` `.py` `.js` `.ts` `.css` `.html` `.java` `.json` `.xml` `.yaml` `.yml` `.md` `.sh` `.txt` y cualquier otro archivo UTF-8/ASCII.
