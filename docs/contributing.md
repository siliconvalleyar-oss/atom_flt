# Contribuyendo a atom_flt

## Cómo contribuir

1. Haz fork del repositorio.
2. Crea una rama descriptiva: `git checkout -b feat/nueva-funcionalidad`.
3. Realiza cambios siguiendo el estilo del proyecto.
4. Asegúrate de que todos los tests pasen: `flutter test`.
5. Ejecuta el linter: `dart analyze` (cero warnings/errors).
6. Envía un Pull Request describiendo los cambios.

## Estilo de código

- **Formato**: `dart format .` antes de cada commit.
- **Naming**: `lowerCamelCase` para variables/funciones, `UpperCamelCase` para clases.
- **Tipado**: siempre explícito en APIs públicas; `var` permitido en locales obvias.
- **Comentarios**: solo cuando explican el *por qué*, no el *qué*.
- **Tests**: toda funcionalidad nueva debe incluir test unitario o de widget.

## Estructura de un PR

- Título en inglés, formato imperativo: "Add search bar navigation", "Fix file picker crash on Linux".
- Cuerpo: descripción del cambio, motivación, capturas (si aplica).
- Enlaza issues relacionados con `Closes #123`.

## Convenciones de commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `docs:` cambios en documentación
- `refactor:` refactorización sin cambio funcional
- `test:` adición o modificación de tests
- `chore:` tareas de mantenimiento

## Revisión

- Mínimo una aprobación de un mantenedor.
- Los checks de CI (analyze + test) deben pasar.
