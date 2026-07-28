# Skill: Atom Editor Original — Análisis para implementación en Flutter

**Ruta del código fuente analizado:** `/mnt/disk/src/flutter_src/atom/atom/`  
**Versión de Atom:** 1.65.0-dev (Electron 11.5.0)  
**Fecha del análisis:** 27 Julio 2026  
**Propósito:** Documentar la arquitectura, componentes, temas, keymaps, menús y sistema de paquetes del Atom Editor original, para guiar la implementación de features equivalentes en Flutter (atom_flt).

---

## 1. ARQUITECTURA GENERAL DE ATOM

### 1.1 Stack tecnológico original

| Capa | Tecnología |
|------|-----------|
| Shell | Electron 11.5.0 (Chromium + Node.js) |
| UI | HTML + LESS/CSS + Custom Elements (Web Components) |
| Lenguaje | JavaScript (ES6), CoffeeScript |
| Editor Base | CodeMirror (primera versión), luego Tree-sitter + propio |
| Paquetes | npm + `apm` (Atom Package Manager) |

### 1.2 Procesos

```
Main Process (Electron)
├── atom-application.js      → Manejo de ventanas, menú nativo
├── atom-window.js           → Creación de ventanas del editor
├── application-menu.js       → Menú nativo del SO
└── auto-updater             → Actualizaciones

Renderer Process (por ventana)
├── src/workspace.js          → Orquestador principal
├── src/text-editor.js        → Editor de texto
├── src/package-manager.js    → Carga de paquetes
├── src/config.js             → Configuración
├── src/theme-manager.js      → Temas
├── src/pane.js / pane-container.js  → Sistema de paneles
├── src/dock.js               → Docks (left, right, bottom)
└── src/project.js            → Proyecto/archivos
```

### 1.3 Sistema de paquetes (extensible)

```
package.json → Declara dependencias de paquetes built-in
packages/    → ~28 paquetes core instalados localmente
├── tree-view/          → Árbol de archivos (sidebar)
├── tabs/               → Pestañas de archivos
├── status-bar/         → Barra de estado inferior
├── fuzzy-finder/       → Buscador de archivos (Ctrl+P)
├── find-and-replace/   → Buscar y reemplazar (Ctrl+F)
├── command-palette/    → Paleta de comandos (Ctrl+Shift+P)
├── settings-view/      → Panel de configuración
├── snippets/           → Snippets de código
├── spell-check/        → Corrector ortográfico
├── bookmarks/          → Marcadores
├── bracket-matcher/    → Resaltado de pares
├── autocomplete-plus/  → Autocompletado
├── git-diff/           → Gutter de diferencias git
├── github/             → Integración GitHub
├── markdown-preview/   → Vista previa Markdown
├── notifications/      → Notificaciones
└── ... (lenguajes: language-c, language-python, etc.)
```

---

## 2. SISTEMA DE WORKSPACE (atom/workspace.js)

### 2.1 Estructura del workspace

```
Workspace
├── PanelContainers
│   ├── top        → Panel superior
│   ├── left       → Dock izquierdo + Panel izquierdo
│   ├── right      → Dock derecho + Panel derecho
│   ├── bottom     → Dock inferior + Panel inferior
│   ├── header     → Header
│   ├── footer     → Footer
│   └── modal      → Modales (autocomplete, command palette)
├── PaneContainers
│   ├── center     → WorkspaceCenter (área principal)
│   ├── left       → Left Dock
│   ├── right      → Right Dock
│   └── bottom     → Bottom Dock
└── Items (TextEditor, etc.)
```

### 2.2 Para implementar en Flutter

```dart
// Estructura equivalente en Flutter
Scaffold(
  body: Column(
    children: [
      if (showHeader) HeaderPanel(),
      Expanded(
        child: Row(
          children: [
            if (showLeftDock) LeftDock(),
            Expanded(
              child: WorkspaceCenter(
                child: PaneContainer(
                  child: TextEditor(),
                ),
              ),
            ),
            if (showRightDock) RightDock(),
          ],
        ),
      ),
      if (showBottomDock) BottomDock(),
      if (showFooter) FooterPanel(),
    ],
  ),
)
```

### 2.3 Contrato de items (WorkspaceItem interface)

```javascript
// Todo item en el workspace DEBE implementar:
{
  getTitle()          → String (título del tab)
  getElement()        → DOM Element (o ser DOM element)
  destroy()           → void
  serialize()         → Object (para restaurar estado)
  getURI()            → String (URI del item)
  getLongTitle()      → String (título extendido)
  onDidChangeTitle()  → Disposable
  isModified()        → bool
  onDidChangeModified() → Disposable
  getPath()           → String? (ruta de archivo)
  save(), saveAs()    → void
  getDefaultLocation() → String ('center', 'left', 'right', 'bottom')
  getAllowedLocations() → String[]
}
```

---

## 3. SISTEMA DE TEXT EDITOR (atom/text-editor.js)

### 3.1 Características del editor original

| Feature | Implementación |
|---------|---------------|
| Syntax highlighting | Tree-sitter + TextMate grammars |
| Virtualización | Solo líneas visibles renderizadas |
| Gutter | Números de línea, git diff, folding |
| Cursor | Multiple cursors (Ctrl+Click) |
| Selection | Multiple selections |
| Folding | Por indent level y syntax node |
| Autocomplete | Autocomplete-plus package |
| Snippets | Snippets package |
| Bracket matcher | Bracket-matcher package |
| Word highlight | Selección → resalta ocurrencias |

### 3.2 Arquitectura del TextEditor

```javascript
TextEditor
├── Buffer (TextBuffer)    → Contenido del archivo
│   ├── Text (String)
│   ├── History (undo/redo)
│   └── Language mode
├── DisplayLayer           → Renderizado de líneas
│   ├── Line objects
│   ├── Tokens (syntax)
│   └── Folds
├── Cursors                → Array de cursors
├── Selections             → Array de selecciones
├── Gutter                 → Números + decoraciones
├── DecorationManager      → Resaltados, marcas
└── Element (DOM)          → Representación visual
```

### 3.3 Implementación en Flutter (atom_flt)

```dart
// Arquitectura propuesta para Flutter
class TextEditor {
  final TextBuffer buffer;         // Contenido + historial
  final DisplayLayer display;      // Líneas virtualizadas
  final CursorSet cursors;         // Múltiples cursores
  final SelectionSet selections;   // Múltiples selecciones
  final GutterConfig gutter;        // Números, git, folding
  final DecorationManager decorations; // Resaltados
}

// UI Widget
class TextEditorWidget extends StatefulWidget {
  final TextEditor editor;
}

// Virtualización (para archivos grandes):
ListView.builder(
  itemCount: editor.display.lineCount,
  itemBuilder: (_, i) => LineWidget(
    line: editor.display.getLine(i),
    decorations: editor.decorations.forLine(i),
  ),
)
```

---

## 4. SISTEMA DE TEMAS

### 4.1 Temas de UI (Atom original)

**Variables LESS de UI** (`static/variables/ui-variables.less`):

```less
// Colores base
@text-color: #333;
@text-color-subtle: #777;
@text-color-highlight: #111;
@text-color-selected: @text-color-highlight;
@app-background-color: #fff;
@base-background-color: #fff;
@base-border-color: #eee;

// Componentes específicos
@pane-item-background-color: @base-background-color;
@input-background-color: #fff;
@tool-panel-background-color: #f4f4f4;
@tab-bar-background-color: #fff;
@tab-background-color: #f4f4f4;
@tab-background-color-active: #fff;
@tab-border-color: @base-border-color;
@tree-view-background-color: @tool-panel-background-color;

// Sizes
@font-size: 13px;
@input-font-size: 14px;
@component-padding: 10px;
@component-icon-size: 16px;
@component-line-height: 25px;
@tab-height: 30px;
@font-family: system-ui;

// UI site colors (marcas en gutter, etc)
@ui-site-color-1: #17ca65;  // verde (added)
@ui-site-color-2: #0098ff;  // azul (modified)
@ui-site-color-3: #ff4800;  // naranja (warning)
@ui-site-color-4: #db2ff4;  // púrpura
@ui-site-color-5: #f5e11d;  // amarillo
```

**Paquetes de tema UI built-in:**
- `one-dark-ui` — Tema oscuro predeterminado
- `one-light-ui` — Tema claro
- `atom-dark-ui` / `atom-light-ui` — Temas Atom clásicos

### 4.2 Temas de Syntax (Atom original)

**Variables LESS de Syntax** (`static/variables/syntax-variables.less`):

```less
// Colores de syntax
@syntax-text-color: #333;
@syntax-cursor-color: #333;
@syntax-selection-color: #69c;
@syntax-background-color: #fff;

// Gutter
@syntax-gutter-text-color: #333;
@syntax-gutter-text-color-selected: #000;
@syntax-gutter-background-color: #ccc;
@syntax-gutter-background-color-selected: #eee;

// Git diff colors
@syntax-color-added: green;
@syntax-color-modified: orange;
@syntax-color-removed: red;
@syntax-color-renamed: blue;

// Token colors (por tipo semántico)
@syntax-color-variable: #DF6A73;
@syntax-color-constant: #DF6A73;
@syntax-color-property: #DF6A73;
@syntax-color-value: #D29B67;
@syntax-color-function: #61AEEF;
@syntax-color-method: @syntax-color-function;
@syntax-color-class: #E5C17C;
@syntax-color-keyword: #a431c4;
@syntax-color-tag: #b72424;
@syntax-color-attribute: #87400d;
@syntax-color-import: #97C378;
@syntax-color-snippet: #97C378;
```

**Paquetes de tema syntax built-in:**
- `one-dark-syntax` — Tema oscuro (One Dark)
- `one-light-syntax` — Tema claro
- `solarized-dark-syntax` / `solarized-light-syntax`
- `base16-tomorrow-dark-theme` / `base16-tomorrow-light-theme`
- `atom-dark-syntax` / `atom-light-syntax`

### 4.3 Implementación en Flutter

```dart
// Temas UI en Flutter (equivalente)
class UiTheme {
  final Color textColor;
  final Color textSubtle;
  final Color textHighlight;
  final Color appBackground;
  final Color baseBorder;
  final Color tabBackground;
  final Color tabBackgroundActive;
  final Color treeViewBackground;
  final Color toolPanelBackground;
  final double fontSize;
  final double tabHeight;
  final String fontFamily;
}

// Temas Syntax en Flutter (equivalente)
class SyntaxTheme {
  final Color textColor;
  final Color cursorColor;
  final Color selectionColor;
  final Color backgroundColor;
  final Color gutterBackground;
  final Color gutterText;
  final Color gutterTextSelected;
  final Color colorAdded;     // git
  final Color colorModified;  // git
  final Color colorRemoved;   // git
  final Color variable;
  final Color constant;
  final Color function;
  final Color keyword;
  final Color comment;
  final Color string;
  final Color number;
  final Color type;
  final Color tag;
  final Color attribute;
}
```

---

## 5. SISTEMA DE KEYMAPS (Atajos de teclado)

### 5.1 Estructura original

**Archivos:** `keymaps/base.cson`, `keymaps/darwin.cson`, `keymaps/linux.cson`, `keymaps/win32.cson`

```cson
# Formato: selector CSS → atajo → comando
'atom-text-editor':
  'home': 'editor:move-to-first-character-of-line'
  'end': 'editor:move-to-end-of-screen-line'
  'ctrl-shift-c': 'editor:copy-path'

'atom-workspace':
  'ctrl-s': 'core:save'
  'ctrl-z': 'core:undo'
  'ctrl-y': 'core:redo'
  'ctrl-shift-z': 'core:redo'
  'ctrl-f': 'find-and-replace:show'
  'ctrl-p': 'fuzzy-finder:toggle-file-finder'
  'ctrl-shift-p': 'command-palette:toggle'
  'ctrl-n': 'application:new-file'
  'ctrl-o': 'application:open-file'
  'ctrl-w': 'core:close'
  'ctrl-tab': 'pane:show-next-item'
  'ctrl-shift-tab': 'pane:show-previous-item'

'.platform-darwin':
  'cmd-s': 'core:save'
  'cmd-z': 'core:undo'
  'cmd-shift-z': 'core:redo'
```

### 5.2 Sistema de contextos (CSS selectors como contextos)

Los keymaps usan **selectores CSS** como contextos:

```cson
# Contexto: cualquier text-editor
'atom-text-editor':
  'ctrl-d': 'editor:delete-line'

# Contexto: text-editor que NO es mini
'atom-text-editor:not([mini])':
  'alt-up': 'editor:select-larger-syntax-node'

# Contexto: listas de selección
'.select-list atom-text-editor[mini]':
  'enter': 'core:confirm'

# Contexto: input fields nativos
'body .native-key-bindings':
  'tab': 'core:focus-next'
```

### 5.3 Implementación en Flutter

```dart
class KeymapManager {
  final Map<String, KeyBinding> bindings = {};
  
  void bind(String selector, LogicalKeyboardKey key, 
            bool control, bool shift, bool alt, 
            VoidCallback action) {
    // selector → contexto en que aplica
    // ej: 'atom-text-editor:not([mini])'
  }
}

// Uso:
keymapManager.bind(
  'atom-text-editor', 
  LogicalKeyboardKey.keyS, 
  control: true,
  action: () => saveFile(),
);
```

---

## 6. SISTEMA DE MENÚS

### 6.1 Estructura original

**Archivos:** `menus/darwin.cson`, `menus/linux.cson`, `menus/win32.cson`

```cson
'menu': [
  {
    label: '&File'
    submenu: [
      { label: '&New File', command: 'application:new-file' }
      { label: '&Open File…', command: 'application:open-file' }
      { type: 'separator' }
      { label: '&Save', command: 'core:save' }
      { label: 'Save &As…', command: 'core:save-as' }
      { type: 'separator' }
      { label: '&Close Tab', command: 'core:close' }
      { label: 'Clos&e Window', command: 'window:close' }
    ]
  }
  {
    label: '&Edit'
    submenu: [
      { label: '&Undo', command: 'core:undo' }
      { label: '&Redo', command: 'core:redo' }
      { type: 'separator' }
      { label: '&Cut', command: 'core:cut' }
      { label: 'C&opy', command: 'core:copy' }
      { label: '&Paste', command: 'core:paste' }
      { type: 'separator' }
      { label: '&Toggle Comments', command: 'editor:toggle-line-comments' }
      {
        label: 'Lines',
        submenu: [
          { label: '&Indent', command: 'editor:indent-selected-rows' }
          { label: '&Outdent', command: 'editor:outdent-selected-rows' }
          { label: 'Move Line &Up', command: 'editor:move-line-up' }
          { label: 'Move Line &Down', command: 'editor:move-line-down' }
          { label: 'Du&plicate Lines', command: 'editor:duplicate-lines' }
          { label: 'D&elete Line', command: 'editor:delete-line' }
        ]
      }
    ]
  }
]
```

### 6.2 Context menu (menú contextual)

```cson
'context-menu':
  'atom-text-editor, .overlayer': [
    {label: 'Undo', command: 'core:undo'}
    {label: 'Redo', command: 'core:redo'}
    {type: 'separator'}
    {label: 'Cut', command: 'core:cut'}
    {label: 'Copy', command: 'core:copy'}
    {label: 'Paste', command: 'core:paste'}
    {type: 'separator'}
    {label: 'Split Up', command: 'pane:split-up-and-copy-active-item'}
    {label: 'Split Down', command: 'pane:split-down-and-copy-active-item'}
    {label: 'Close Pane', command: 'pane:close'}
  ]
```

---

## 7. SISTEMA DE CSS/LESS — ESTÉTICA

### 7.1 Jerarquía de estilos

```
atom.less (entry point)
├── variables/syntax-variables.less  ← Fallback del tema syntax
├── variables/ui-variables.less      ← Fallback del tema UI
├── icons/octicons                   ← Iconos (Octicons)
├── normalize                        ← Reset CSS
├── scaffolding                      ← Layout básico
└── core-ui/
    ├── _index.less                  ← Importa todo core-ui
    ├── workspace-view.less          ← Layout workspace
    ├── text-editor.less             ← Estilos del editor
    ├── panes.less                   ← Estilos de paneles
    ├── docks.less                   ← Estilos de docks
    ├── panels.less                  ← Estilos de paneles
    ├── title-bar.less               ← Barra de título
    ├── cursors.less                 ← Cursores
    └── syntax.less                  ← Resaltado syntax
```

### 7.2 Principios de diseño visual (del CSS original)

```less
// workspace-view.less — Flexbox puro
atom-workspace {
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
  position: relative;
}

atom-workspace-axis.horizontal {
  display: flex;
  flex: 1;
}

// text-editor.less — Editor
atom-text-editor {
  display: flex;
  cursor: text;
  font-family: Menlo, Consolas, 'DejaVu Sans Mono', monospace;
  font-size: var(--editor-font-size);
  line-height: var(--editor-line-height);
  
  .gutter-container { width: min-content; }
  .gutter { text-align: right; min-width: 1em; }
  .line-number { padding-left: .5em; opacity: 0.6; }
  .cursor { position: absolute; border-left: 1px solid; }
}

// panes.less — Sistema de paneles
atom-pane-container {
  display: flex;
  flex: 1;
  
  atom-pane {
    display: flex;
    flex: 1;
    flex-direction: column;
    
    .item-views {
      flex: 1;
      display: flex;
    }
  }
}
```

### 7.3 Para Flutter — equivalencia visual

```dart
// Workspace → Column + Row
Column(
  children: [
    HeaderPanel(),
    Expanded(
      child: Row(
        children: [
          if (leftDockVisible) LeftDock(width: 200),
          Expanded(child: EditorArea()),
          if (rightDockVisible) RightDock(width: 300),
        ],
      ),
    ),
    if (bottomDockVisible) BottomDock(height: 200),
    StatusBar(height: 28),
  ],
)

// Gutter → Container with line numbers
Container(
  width: 48,
  child: ListView.builder(
    itemCount: lineCount,
    itemBuilder: (_, i) => Text(
      '${i + 1}',
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 12, color: gutterColor, fontFamily: 'monospace'),
    ),
  ),
)

// Tab → Container with icon + text + close button
Container(
  child: Row(
    children: [
      Icon(icon, size: 14),
      Text(filename, style: TextStyle(fontSize: 13)),
      if (isModified) Text('●'),
      if (!isPermanent) IconButton(icon: Icons.close, size: 14),
    ],
  ),
)
```

---

## 8. SISTEMA DE PAQUETES Y COMANDOS

### 8.1 Command Registry

```javascript
// atom/command-registry.js
// Todos los comandos se registran globalmente
atom.commands.add('atom-workspace', {
  'core:save': () => activeItem.save(),
  'core:undo': () => activeEditor.undo(),
  'core:redo': () => activeEditor.redo(),
});

// Los paquetes pueden agregar comandos
atom.commands.add('atom-text-editor', {
  'editor:toggle-line-comments': () => toggleComments(),
});
```

### 8.2 Service Hub

```javascript
// Los paquetes se comunican via servicios
// Ej: autocomplete-plus consume el servicio 'autocomplete.provider'
serviceHub.consume('autocomplete.provider', '^1.0', provider => {
  // provider puede dar sugerencias
});
```

### 8.3 Para Flutter

```dart
// Equivalente en Flutter: Command pattern
class CommandRegistry {
  final Map<String, List<CommandHandler>> _commands = {};
  
  void add(String selector, String command, VoidCallback handler) {
    _commands.putIfAbsent(command, () => []).add(handler);
  }
  
  void dispatch(String command) {
    _commands[command]?.forEach((h) => h());
  }
}

// ServiceHub → Provider / Dependency Injection
class ServiceHub {
  final Map<String, dynamic> _services = {};
  
  void provide<T>(String name, T service) => _services[name] = service;
  T consume<T>(String name) => _services[name] as T;
}
```

---

## 9. DISTRIBUCIÓN DE PACKAGES CORE (built-in)

| Package | Propósito | Repositorio GitHub |
|---------|-----------|-------------------|
| tree-view | Árbol de archivos sidebar | atom/tree-view |
| tabs | Pestañas de archivos | atom/tabs |
| status-bar | Barra de estado inferior | atom/status-bar |
| fuzzy-finder | Buscador Ctrl+P | atom/fuzzy-finder |
| find-and-replace | Buscar y reemplazar Ctrl+F | atom/find-and-replace |
| command-palette | Paleta de comandos | atom/command-palette |
| settings-view | Panel de configuración | atom/settings-view |
| snippets | Snippets de código | atom/snippets |
| autocomplete-plus | Autocompletado | atom/autocomplete-plus |
| bracket-matcher | Resaltado de pares | atom/bracket-matcher |
| bookmarks | Marcadores en gutter | atom/bookmarks |
| git-diff | Diff en gutter | atom/git-diff |
| spell-check | Corrector ortográfico | atom/spell-check |
| markdown-preview | Vista previa MD | atom/markdown-preview |
| notifications | Notificaciones | atom/notifications |
| welcome | Pantalla de bienvenida | atom/welcome |

**Lenguajes de syntax (grammars):**
| Package | Lenguaje |
|---------|----------|
| atom/language-c | C, C++, Objective-C |
| atom/language-python | Python |
| atom/language-javascript | JavaScript |
| atom/language-typescript | TypeScript |
| atom/language-html | HTML |
| atom/language-css | CSS, LESS, Sass |
| atom/language-java | Java |
| atom/language-go | Go |
| atom/language-ruby | Ruby |
| atom/language-php | PHP |
| atom/language-sql | SQL |
| atom/language-json | JSON |
| atom/language-yaml | YAML |
| atom/language-xml | XML |
| atom/language-shellscript | Bash/Shell |
| atom/language-toml | TOML |

---

## 10. MAPA DE FEATURES — Atom vs atom_flt (Flutter)

| Feature | Atom (original) | atom_flt (actual) | Prioridad |
|---------|----------------|-------------------|-----------|
| **Workspace layout** | Docks + Panes + Center | Column + Row básico | 🔴 Alta |
| **Tree View** | tree-view package | FilePanel (básico) | 🟡 Media |
| **Tabs** | tabs package | No implementado | 🔴 Alta |
| **Status Bar** | status-bar package | `_buildStatusBar()` inline | 🟡 Media |
| **Multiple cursors** | Nativo (Ctrl+Click) | No implementado | 🟢 Baja |
| **Syntax highlighting** | Tree-sitter + TextMate | `SyntaxLanguage.detect()` + `CodeController` | 🔴 Alta |
| **Autocomplete** | autocomplete-plus | No implementado | 🟢 Baja |
| **Snippets** | snippets package | No implementado | 🟢 Baja |
| **Command Palette** | Ctrl+Shift+P | No implementado | 🟡 Media |
| **Fuzzy Finder** | Ctrl+P | No implementado | 🟡 Media |
| **Find & Replace** | Ctrl+F / Ctrl+H | Búsqueda inline básica (no funcional) | 🔴 Alta |
| **Git integration** | github + git-diff packages | No implementado | 🟢 Baja |
| **Split panes** | Ctrl+K + dirección | No implementado | 🟢 Baja |
| **Themes** | UI + Syntax separados | Tema claro/oscuro básico | 🟡 Media |
| **Folding** | Por indent / syntax node | No implementado | 🟢 Baja |
| **Minimap** | minimap package (comunitario) | No implementado | 🟢 Baja |
| **Settings UI** | settings-view package | ConfigScreen básico | 🟡 Media |
| **Notifications** | notifications package | SnackBar de Material | 🟢 Baja |
| **Spell check** | spell-check package | No implementado | 🟢 Baja |
| **Markdown preview** | markdown-preview | No implementado | 🟢 Baja |
| **Bracket matcher** | bracket-matcher | No implementado | 🟡 Media |
| **Autosave** | autosave package | No implementado | 🟢 Baja |

---

## 11. IMPLEMENTACIÓN RECOMENDADA PARA FLUTTER

### 11.1 Orden de implementación sugerido

```
FASE 1 — Base funcional (ahora)
├── ✅ FilePanel funcional con SAF
├── ✅ Onboarding al primer inicio
├── ❌ SafeArea para Android 16 edge-to-edge
├── ❌ Atajos Ctrl+Z / Ctrl+Y
├── ❌ Búsqueda funcional (next/prev)
└── ❌ Confirmación al descartar cambios

FASE 2 — Editor completo
├── ❌ Migrar a CodeField + CodeTheme (usar flutter_code_editor)
├── ❌ Resaltado de sintaxis funcional
├── ❌ Gutter con números de línea profesional
├── ❌ StatusBar interoperable
└── ❌ Tabs (múltiples archivos abiertos)

FASE 3 — Paquetes esenciales
├── ❌ Command Palette (Ctrl+Shift+P)
├── ❌ Fuzzy Finder (Ctrl+P)
├── ❌ Find & Replace completo (Ctrl+H)
├── ❌ Bracket matcher
├── ❌ Autosave
└── ❌ Split panes (horizontal/vertical)

FASE 4 — Temas y estética
├── ❌ UI Theme system (One Dark, One Light)
├── ❌ Syntax Theme system (One Dark, Solarized, etc.)
├── ❌ Iconos tipo Octicons
└── ❌ Animaciones y transiciones

FASE 5 — Git e integración
├── ❌ Git diff en gutter
├── ❌ Git blame
├── ❌ GitHub integration
└── ❌ Minimap
```

### 11.2 Referencias de repositorios Atom originales

```
Atom Core:
├── https://github.com/atom/atom                    → Editor principal
├── https://github.com/atom/text-buffer              → TextBuffer (contenido)
├── https://github.com/atom/first-mate               → TextMate grammars
├── https://github.com/atom/tree-sitter               → Parsing incremental

Paquetes Core (built-in):
├── https://github.com/atom/tree-view                 → Sidebar archivos
├── https://github.com/atom/tabs                      → Pestañas
├── https://github.com/atom/status-bar                → Barra de estado
├── https://github.com/atom/fuzzy-finder              → Buscador Ctrl+P
├── https://github.com/atom/find-and-replace          → Buscar/reemplazar
├── https://github.com/atom/command-palette           → Paleta comandos
├── https://github.com/atom/settings-view             → Configuración
├── https://github.com/atom/snippets                  → Snippets
├── https://github.com/atom/autocomplete-plus         → Autocompletado
├── https://github.com/atom/bracket-matcher           → Pares brackets
├── https://github.com/atom/git-diff                  → Diff gutter
├── https://github.com/atom/github                    → Integración GitHub
├── https://github.com/atom/notifications             → Notificaciones
├── https://github.com/atom/markdown-preview          → Vista previa MD
├── https://github.com/atom/bookmarks                 → Marcadores
├── https://github.com/atom/spell-check               → Corrector ortográfico

Temas:
├── https://github.com/atom/one-dark-ui               → UI oscuro
├── https://github.com/atom/one-light-ui              → UI claro
├── https://github.com/atom/one-dark-syntax           → Syntax oscuro
├── https://github.com/atom/one-light-syntax          → Syntax claro
├── https://github.com/atom/solarized-dark-syntax     → Syntax Solarized
├── https://github.com/atom/solarized-light-syntax    → Syntax Solarized light

Lenguajes:
├── https://github.com/atom/language-c
├── https://github.com/atom/language-python
├── https://github.com/atom/language-javascript
├── https://github.com/atom/language-typescript
├── https://github.com/atom/language-html
├── https://github.com/atom/language-css
└── ... (todos los atom/language-*)
```

---

## 12. LECCIONES APRENDIDAS DEL ANÁLISIS

### 12.1 Lo que Atom hace bien

1. **Arquitectura basada en paquetes**: cada feature es un package independiente. Se comunican via Service Hub.
2. **Temas separados**: UI theme y Syntax theme son independientes y combinables.
3. **Comandos globales**: todo se maneja via command registry, desacoplando UI de lógica.
4. **Contextos en keymaps**: los atajos dependen del contexto (editor, panel, diálogo).
5. **Serialización**: el workspace guarda y restaura su estado completo.
6. **Virtualización**: solo renderiza las líneas visibles del editor.

### 12.2 Lo que NO replicar

1. **CoffeeScript**: usar Dart moderno, no un lenguaje transpilado.
2. **LESS/CSS complejo**: Flutter usa widget trees, no CSS. Adaptar la filosofía, no los archivos.
3. **npm para paquetes**: usar paquetes Dart/pub, no npm.
4. **Átomos del DOM**: Custom Elements no existen en Flutter. Usar composición de widgets.
5. **Electron**: Flutter es el framework UI, no hay separación main/renderer process.

### 12.3 Adaptación clave para Flutter

| Concepto Atom | Equivalente Flutter |
|---------------|-------------------|
| Custom Elements (`atom-text-editor`) | Widget (`TextEditorWidget`) |
| LESS variables | `UiTheme` / `SyntaxTheme` objects |
| CSS selectors como contextos | Enum + pattern matching |
| `atom.commands.add()` | `CommandRegistry` class |
| Service Hub | Provider / Riverpod |
| `event-kit` (Emitter) | `ChangeNotifier` + `ValueNotifier` |
| `Disposable` | `Closeable` / cancel on dispose |
| `serialize()` / `deserialize()` | `SharedPreferences` / JSON |
| `TextBuffer` | `TextEditingController` o `CodeController` |

---

*Skill version: 1.0 — Creado 27 Julio 2026*
*Cargar con: `skill tool name: atom_original_analysis`*
