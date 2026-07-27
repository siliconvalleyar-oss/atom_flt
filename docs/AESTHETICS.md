# AESTHETICS — atom_flt

## Filosofía visual

Minimalismo funcional. Cada elemento en pantalla tiene un propósito. El código es el protagonista; la interfaz es un marco limpio que facilita la concentración sin distracciones.

## Icono de lanzador

### Diseño (SVG)

El icono representa un átomo estilizado con 3 órbitas elípticas y un núcleo:

- **3 órbitas**: rotadas a 25°, 115° y 245° con 4px de trazo
- **Gradientes**: azul→púrpura, verde→amarillo y rojo tenue
- **Núcleo**: doble círculo (gris perla exterior 16px, gris oscuro interior 6px)
- **Sin electrones**: se omiten para mantener la estética limpia
- **Fondo transparente**: se integra con cualquier fondo del sistema

### Generación de tamaños

Desde el SVG base (`assets/icon/atom_icon.svg`) se generan los PNG para cada plataforma:

**Android** (sustituir en `android/app/src/main/res/`):
| Tamaño | Resource | DPI |
|--------|----------|-----|
| 48×48  | mipmap-mdpi | 160 |
| 72×72  | mipmap-hdpi | 240 |
| 96×96  | mipmap-xhdpi | 320 |
| 144×144 | mipmap-xxhdpi | 480 |
| 192×192 | mipmap-xxxhdpi | 640 |

**iOS** (sustituir en `ios/Runner/Assets.xcassets/AppIcon.appiconset/`):
| Tamaño | Nombre |
|--------|--------|
| 20×20  | Icon-App-20x20@1x, @2x, @3x |
| 29×29  | Icon-App-29x29@1x, @2x, @3x |
| 40×40  | Icon-App-40x40@1x, @2x, @3x |
| 60×60  | Icon-App-60x60@2x, @3x |
| 1024×1024 | Icon-App-1024x1024@1x |

Comando para generar con Inkscape:
```bash
inkscape assets/icon/atom_icon.svg -w 192 -h 192 \
  --export-filename android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

## Paleta de colores

### Tema oscuro (One Dark)
- Fondo editor: `#121212`
- Fondo UI: `#1E1E1E`
- Barras: `#252525`
- Bordes: `#333333`
- Texto: `#D4D4D4`
- Números línea: `#666666`
- Acento: `#4A90D9`

### Tema claro (GitHub Light)
- Fondo editor: `#FFFFFF`
- Fondo UI: `#FAFAFA`
- Barras: `#F0F0F0`
- Bordes: `#E0E0E0`
- Texto: `#1E1E1E`
- Números línea: `#999999`
- Acento: `#4A90D9`

## Tipografía

- Editor: `JetBrains Mono` / `monospace`, 14px, weight 400
- UI: sistema sans-serif, 12-13px, weight 500
- Números línea: `monospace`, 12px, weight 300

## Layout

```
┌──────────────────────────────────┐
│  Menú bar (File Edit View)  v1.0 │
├──────────────────────────────────┤
│  1 │ código aquí...              │
│  2 │                             │
│  3 │                             │
├──────────────────────────────────┤
│  Ln 3, Col 10  sample.cpp  UTF-8 │
└──────────────────────────────────┘
```

- Barra superior: 32px, menús textuales tipo Atom
- Barra inferior (status): 28px, info sin adornos
- Gutter: 40px, números alineados a la derecha
- Editor: ocupa todo el espacio restante con `expands: true`

## Componentes

- **Menú bar**: minimalista, solo texto, hover highlight sutil
- **Overflow (⋮)**: iconos + texto, sin borde
- **Status bar**: información escencial, versión en color acento
- **Scroll**: invisible hasta interactuar (scrollbar delgado)
- **Sin sombras, sin decoraciones**: bordes planos de 1px
