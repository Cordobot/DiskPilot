# Changelog

## [1.2.0] - 2026-11-08

### Añadido
- Gráfica de uso por categorías (estilo Steam) en cada unidad: vista rápida al abrir y desglose completo tras «Analizar».
- Icono real de cada programa en las listas.
- Desinstalación múltiple: marca varios programas y se desinstalan uno tras otro, con la lista de restos agrupada por programa.
- Nueva sección «Duplicados»: búsqueda por contenido, agrupación, marcado automático de copias sobrantes y borrado seguro.

### Cambiado
- Las carpetas compartidas solo entre programas del mismo lote ya no se desmarcan (p. ej. Steam junto con sus juegos).
- Se quitó el doble clic para desinstalar, para evitar aperturas accidentales al marcar casillas.

## [1.1.0] - 2026-11-08

### Añadido
- Ejecutable nativo `DiskPilot.exe` con icono propio, información de versión y elevación automática a administrador (UAC).
- Script `build/build.ps1` para compilar el ejecutable sin herramientas externas.
- La versión se muestra en la barra lateral y en el título de la ventana.

## [1.0.0] - 2026-11-08

### Añadido
- Panel de resumen con el uso de cada unidad, programas más pesados y archivos más grandes.
- Lista de programas instalados con tamaño real de carpeta, búsqueda y ordenación.
- Desinstalación a fondo: desinstalador oficial silencioso, cierre de procesos, eliminación de servicios, carpetas residuales, accesos directos y registro.
- Explorador de disco con escaneo rápido Win32 y navegación por carpetas.
- Limpieza rápida de temporales, papelera, cachés de Windows Update, navegadores, Windows.old e hibernación.
- Protección de rutas críticas del sistema y detección de carpetas compartidas.
- Elevación automática a administrador y barra de título oscura.
