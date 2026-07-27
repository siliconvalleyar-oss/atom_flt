# Diseño de interfaz de usuario

## Filosofía de diseño

Minimalismo funcional. Cada elemento en pantalla tiene un propósito claro. Se evita el adorno innecesario. El contenido (código) es el protagonista; la interfaz es un marco limpio que facilita la concentración.

## Paleta de colores

### Tema claro

| Rol | Color | Hex |
|-----|-------|-----|
| Fondo principal | Blanco hueso | `#FAFAFA` |
| Fondo del editor | Blanco puro | `#FFFFFF` |
| Barra de estado/menú | Gris muy claro | `#F0F0F0` |
| Números de línea | Gris medio | `#999999` |
| Texto del código | Casi negro | `#1E1E1E` |
| Borde | Gris claro | `#E0E0E0` |
| Ocurrencia resaltada | Amarillo pastel | `#FFF3BF` |
| Acento (selección) | Azul | `#4A90D9` |
| Sombra | Negro 10% | `#1A000000` |

### Tema oscuro

| Rol | Color | Hex |
|-----|-------|-----|
| Fondo principal | Gris muy oscuro | `#1E1E1E` |
| Fondo del editor | Casi negro | `#121212` |
| Barra de estado/menú | Gris oscuro | `#252525` |
| Números de línea | Gris medio | `#666666` |
| Texto del código | Gris claro | `#D4D4D4` |
| Borde | Gris oscuro | `#333333` |
| Ocurrencia resaltada | Amarillo oscuro | `#3B3B1F` |
| Acento (selección) | Azul oscuro | `#264F78` |
| Sombra | Negro 40% | `#66000000` |

### Paleta de resaltado de sintaxis (oscuro, estilo One Dark)

| Elemento | Color | Hex |
|----------|-------|-----|
| Palabras clave | Rosa | `#C678DD` |
| Strings | Verde | `#98C379` |
| Comentarios | Gris | `#5C6370` |
| Funciones | Azul | `#61AFEF` |
| Números | Naranja | `#D19A66` |
| Tipos | Amarillo | `#E5C07B` |
| Operadores | Blanco | `#ABB2BF` |

## Tipografía

- **Editor de código**: JetBrains Mono, monospace, peso Regular (400), tamaño 14px.
- **Interfaz (menús, barras, estado)**: Inter o sistema sans-serif, peso Medium (500), tamaño 12–13px.
- **Números de línea**: JetBrains Mono, monospace, peso Light (300), tamaño 12px.

## Layout general

```
┌──────────────────────────────────────────────┐
│  Menú superior (Archivo, Editar, Ver, Tema)  │
├──────────────────────────────────────────────┤
│                                              │
│   1 │ import 'package:flutter/material.dart';│
│   2 │                                        │
│   3 │ void main() {                          │
│   4 │   runApp(App());                       │
│   5 │ }                                      │
│   6 │                                        │
│                                              │
├──────────────────────────────────────────────┤
│  Barra de estado:   Ln 3, Col 10   |  UTF-8  │
└──────────────────────────────────────────────┘
```

## Componentes reutilizables

### 1. `LineNumberGutter`
- Widget independiente alineado a la izquierda del editor.
- Muestra números de línea con fuente monospace pequeña y color tenue.
- La línea actual tiene el número en negrita y color de acento.

### 2. `WordHighlighter`
- Estrategia (no widget visual): recibe la posición del cursor, extrae la palabra bajo el cursor y devuelve las regiones a resaltar.
- Se comunica con el editor para aplicar el resaltado amarillo translúcido.

### 3. `StatusBar`
- Barra inferior de 28px de alto.
- Muestra: línea y columna actual, encoding del archivo, indicador de tema (sol/luna).
- Fondo ligeramente distinto al del editor.

### 4. `SearchBar`
- Overlay en la parte superior del editor.
- Campo de texto con botones de navegación (siguiente/anterior) y contador de resultados.

### 5. `MenuBar`
- Barra superior horizontal con menús desplegables.
- En móvil se convierte en AppBar con iconos y menú overflow.

## Experiencia de usuario: flujo de trabajo

1. **Abrir app**: pantalla en blanco o último archivo abierto (si se guardó la preferencia).
2. **Abrir archivo**: Ctrl+O → file_picker → carga contenido en el editor → resaltado automático según extensión.
3. **Editar**: escritura directa en el editor. Línea y columna se actualizan en la barra de estado. Ctrl+Z deshace.
4. **Resaltar ocurrencias**: clic/toque en una palabra → todas las ocurrencias se iluminan.
5. **Guardar**: Ctrl+S → escribe al disco. Si es nuevo, pide ubicación.
6. **Cambiar tema**: menú Ver → Tema claro/oscuro → cambio instantáneo.
7. **Buscar**: Ctrl+F → barra de búsqueda → escribe → navega entre resultados.

## Responsive design

- **Escritorio**: menú horizontal completo, ventanas redimensionables.
- **Móvil (tablet)**: AppBar con iconos, editor ocupa toda la pantalla.
- **Móvil (teléfono)**: igual que tablet pero la barra de estado es más compacta.
