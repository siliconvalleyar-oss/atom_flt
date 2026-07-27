# Temas de resaltado de sintaxis

## Tema oscuro (predeterminado, estilo One Dark)

```dart
final oneDarkTheme = CodeThemeData(
  styles: {
    'root': TextStyle(color: Color(0xFFABB2BF)),
    'keyword': TextStyle(color: Color(0xFFC678DD)),
    'string': TextStyle(color: Color(0xFF98C379)),
    'comment': TextStyle(color: Color(0xFF5C6370), fontStyle: FontStyle.italic),
    'function': TextStyle(color: Color(0xFF61AFEF)),
    'number': TextStyle(color: Color(0xFFD19A66)),
    'type': TextStyle(color: Color(0xFFE5C07B)),
    'operator': TextStyle(color: Color(0xFFABB2BF)),
    'built_in': TextStyle(color: Color(0xFF56B6C2)),
    'attr': TextStyle(color: Color(0xFFE06C75)),
    'variable': TextStyle(color: Color(0xFFE06C75)),
  },
);
```

## Tema claro (estilo GitHub Light)

```dart
final githubLightTheme = CodeThemeData(
  styles: {
    'root': TextStyle(color: Color(0xFF24292E)),
    'keyword': TextStyle(color: Color(0xFFD73A49)),
    'string': TextStyle(color: Color(0xFF032F62)),
    'comment': TextStyle(color: Color(0xFF6A737D), fontStyle: FontStyle.italic),
    'function': TextStyle(color: Color(0xFF6F42C1)),
    'number': TextStyle(color: Color(0xFF005CC5)),
    'type': TextStyle(color: Color(0xFF22863A)),
    'operator': TextStyle(color: Color(0xFF24292E)),
    'built_in': TextStyle(color: Color(0xFF005CC5)),
    'attr': TextStyle(color: Color(0xFFD73A49)),
    'variable': TextStyle(color: Color(0xFFE36209)),
  },
);
```

## Cómo agregar un nuevo tema

1. Crea el mapa de estilos siguiendo los tokens de `highlight` (https://github.com/gitJournal/flutter-highlight).
2. Añádelo a `syntax_themes.dart` como constante.
3. En el menú Ver → Tema de sintaxis, aparecerá como opción.

## Tokens disponibles (de highlight)

| Token | Descripción |
|-------|-------------|
| `root` | Texto base |
| `keyword` | Palabras clave del lenguaje |
| `string` | Cadenas de texto |
| `comment` | Comentarios |
| `function` | Definiciones de funciones |
| `number` | Literales numéricos |
| `type` | Tipos de datos |
| `operator` | Operadores |
| `built_in` | Funciones/objetos built-in |
| `attr` | Atributos/etiquetas |
| `variable` | Variables |

## Temas populares para implementar

- Monokai
- Solarized (claro y oscuro)
- Dracula
- Nord
- Tokyo Night
