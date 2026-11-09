# Changelog

## [1.5.0] - 2026-11-08

### Añadido
- Logo propio de DiskPilot (anillo de uso de disco sobre degradado violeta-cian) en el `.exe`, la ventana, la barra de tareas, la barra lateral y los accesos directos.
- La ventana tiene identidad propia en la barra de tareas y ya no se agrupa ni se muestra como PowerShell.

## [1.4.0] - 2026-11-08

### Añadido
- El `.exe` funciona como instalador/actualizador: cierra la versión anterior abierta, se instala en `%LOCALAPPDATA%\Programs\DiskPilot` sustituyéndola y borra los archivos de versiones antiguas (scripts extraídos y `DiskPilot*.exe` viejos en Descargas/Escritorio).
- Accesos directos en el menú Inicio y el Escritorio.
- Registro en «Aplicaciones instaladas» de Windows y desinstalación con `--uninstall`.
- Si se abre la misma versión dos veces, se trae al frente la ventana ya abierta.

### Cambiado
- DiskPilot ya no aparece en su propia lista de programas.

## [1.3.0] - 2026-11-08

### Añadido
- Las categorías de la gráfica se pueden pulsar: muestran las carpetas y archivos concretos que las forman (las carpetas dominantes se abren automáticamente), con opciones para abrir, ver el contenido o eliminar.
- Si la unidad no está analizada, al pulsar una categoría se analiza y se abre el detalle al terminar.
- «No visible» muestra el espacio reservado para puntos de restauración (vssadmin) y abre Protección del sistema.

### Corregido
- La gráfica completa no aparecía tras analizar una unidad grande (desbordamiento numérico).

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
