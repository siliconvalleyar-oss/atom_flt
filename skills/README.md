# 🧠 Skills — atom_flt

**Carpeta exportable de skills y diagnósticos** del proyecto `atom_flt` (editor de código Flutter).

Esta carpeta contiene documentación estructurada para que **AIs y desarrolladores** puedan entender la arquitectura del proyecto, diagnosticar problemas y planificar features.

---

## 📦 Archivos incluidos

| Archivo | Tamaño | Tipo | Descripción |
|---------|--------|------|-------------|
| `atom_flt_codebase.md` | ~16 KB | 🟢 **Skill** | Conocimiento completo del código Dart actual: estructura, bugs críticos, dependencias, atajos, temas, file browser, native channel, y checklist de verificación para AI |
| `atom_original_analysis.md` | ~18 KB | 🟣 **Skill** | Análisis del Atom Editor original (Electron/JS): arquitectura, sistema de paquetes, temas UI/Syntax, keymaps, menús, CSS, y plan de implementación en 5 fases para Flutter |
| `DIAGNOSTICO_FILE_BROWSER.md` | ~25 KB | 🔴 **Diagnóstico** | Checklist de 85 tareas para diagnosticar y corregir el FileBrowser/FilePanel que no muestra archivos en Android. Incluye reglas para revisión por AI y cómo verificar cada tarea |
| `learnings.md` | ~12 KB | 📘 **Lecciones** | Merge consolidado de `docs/LEARNINGS.md` y `docs/learnings.md`. Decisiones técnicas, compilación Android, resaltado de ocurrencias, atajos, tests, git tags |

---

## 🎯 Cómo usar estos archivos

### Para una AI (cargar como skill)

Los skills están diseñados para cargarse con la herramienta `skill` de Codebuff/Freebuff:

```bash
# Cargar el skill del codebase actual
skill tool name: atom_flt_codebase

# Cargar el análisis del Atom original
skill tool name: atom_original_analysis
```

### Para un desarrollador (leer directamente)

Simplemente abre cualquier archivo `.md` en tu editor o visor Markdown preferido.

### Para exportar a otro proyecto

```bash
# Copiar toda la carpeta a otro proyecto Flutter
cp -r skills/ /ruta/de/destino/

# O copiar archivos individuales
cp skills/atom_flt_codebase.md /otro/proyecto/docs/
```

---

## 🔗 Relación entre archivos

```
atom_flt_codebase.md  ←←← (describe el estado actual del código Dart)
      ↑                       ↑
      |                       |
learnings.md ─────────→ DIAGNOSTICO_FILE_BROWSER.md
(decisiones técnicas)    (checklist de correcciones)
      |
      ↓
atom_original_analysis.md
(qué features copiar del Atom original)
```

- **`learnings.md`** → Por qué se tomaron ciertas decisiones técnicas
- **`DIAGNOSTICO_FILE_BROWSER.md`** → Qué falta corregir en el FileBrowser + mejoras generales (Sección D)
- **`atom_flt_codebase.md`** → El estado actual de todo el código
- **`atom_original_analysis.md`** → Hacia dónde ir: features del Atom original para implementar en Flutter

---

## 🚀 Primeros pasos recomendados

1. Leer `atom_flt_codebase.md` para entender el estado actual
2. Revisar `DIAGNOSTICO_FILE_BROWSER.md` para ver las tareas pendientes
3. Consultar `atom_original_analysis.md` para planificar nuevas features
4. Usar `learnings.md` como referencia de decisiones técnicas

---

## 📁 Estructura de exportación

```
skills/
├── README.md                       ← Este archivo
├── atom_flt_codebase.md            ← Skill del codebase actual
├── atom_original_analysis.md       ← Skill del Atom original
├── DIAGNOSTICO_FILE_BROWSER.md     ← Diagnóstico de 85 tareas
└── learnings.md                    ← Lecciones aprendidas
```

**Total: 4 archivos de documentación + 1 README**

---

*Última actualización: 27 Julio 2026*
*Proyecto: `/mnt/disk/src/flutter_src/atom_flt`*
