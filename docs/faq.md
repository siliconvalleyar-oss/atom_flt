# FAQ — atom_flt

## Generales

### ¿Qué es atom_flt?
Un editor de código fuente multiplataforma (Android, iOS, Windows, macOS, Linux) construido con Flutter, de estilo minimalista inspirado en Atom Editor.

### ¿Es gratuito?
Sí, código abierto bajo licencia MIT.

### ¿Para quién está pensado?
Para desarrolladores que necesitan un editor ligero y portátil, especialmente en dispositivos móviles o tablets donde los editores tradicionales no funcionan.

## Técnicas

### ¿Qué lenguajes de programación soporta?
C, C++, C#, Dart, Python, JavaScript, TypeScript, HTML, CSS, Java, JSON, XML, YAML, Markdown, Shell y texto plano. La lista se amplía fácilmente.

### ¿Puedo abrir archivos muy grandes?
Sí, hasta ~100 000 líneas sin problemas gracias a la virtualización. Archivos mayores pueden experimentar ralentizaciones.

### ¿Cómo cambio el tema?
`Ctrl + T` (Windows/Linux) o `Cmd + T` (macOS), o menú Ver → Alternar tema.

### ¿Los cambios se guardan automáticamente?
No, debes guardar manualmente con `Ctrl + S`. El editor muestra un indicador cuando hay cambios sin guardar.

### ¿Puedo tener varios archivos abiertos a la vez?
En la versión actual no. Es una funcionalidad planificada para futuras versiones.

### ¿Funciona sin conexión?
Sí, completamente. No requiere conexión a internet.

## Plataformas

### ¿En qué plataformas está disponible?
Android, iOS, Windows, macOS y Linux.

### ¿Por qué Flutter?
Para mantener un solo código base que funcione de forma nativa en todas las plataformas con rendimiento fluido.

### ¿Hay versión web?
No está planificada. El acceso al sistema de archivos nativo es esencial y las limitaciones del navegador lo hacen inviable.

## Solución de problemas

### El archivo no se abre
- Verifica que los permisos de lectura estén concedidos.
- Asegúrate de que el archivo no esté dañado o sea binario.
- Comprueba que la extensión esté en la lista de formatos soportados.

### El resaltado de sintaxis no funciona
- El archivo debe tener una extensión reconocida (`.py`, `.js`, etc.).
- Si es un archivo sin extensión, se mostrará como texto plano.

### No puedo guardar
- Verifica los permisos de escritura en el directorio destino.
- En Android/iOS, asegúrate de que la app tenga permiso de almacenamiento.

### La app se cierra inesperadamente
- Reporta el bug en https://github.com/tu-usuario/atom_flt/issues
- Incluye: plataforma, versión de SO, pasos para reproducir, y el archivo que estabas editando (si es posible).
