# DiskPilot

Analizador de almacenamiento y desinstalador a fondo para Windows 10/11, con interfaz moderna en modo oscuro.

**Versión actual:** 1.0.0

## Funciones

- **Resumen** — uso de cada unidad, programas que más ocupan y archivos más grandes (+200 MB).
- **Programas** — todos los programas instalados ordenados por el tamaño real de su carpeta, con búsqueda y orden por nombre o fecha.
- **Desinstalar a fondo** (con permisos de administrador):
  1. Ejecuta el desinstalador oficial (en modo silencioso cuando el programa lo admite: MSI, Inno Setup, NSIS, Squirrel).
  2. Cierra los procesos del programa y detiene/elimina sus servicios de Windows.
  3. Borra la carpeta de instalación, restos en AppData / ProgramData / Common Files, accesos directos y claves de registro.
  4. Si algo está bloqueado, toma la propiedad (`takeown` / `icacls`) y lo programa para borrarse al reiniciar.

  Antes de borrar muestra la lista completa de elementos para desmarcar lo que se quiera conservar.
- **Explorar disco** — escaneo rápido de una unidad completa (API Win32), navegación por carpetas de mayor a menor, abrir en el Explorador o eliminar.
- **Limpieza rápida** — temporales, papelera, caché de Windows Update y Optimización de distribución, informes de errores, volcados de memoria, caché de Chrome/Edge, Windows.old e hibernación.

## Protecciones

Nunca se borran: la carpeta de Windows, raíces de *Archivos de programa*, *ProgramData*, *Usuarios*, el perfil de usuario y sus carpetas principales (AppData, Documentos, Descargas, Escritorio…), ni la raíz de ninguna unidad. Si una carpeta de instalación contiene otros programas (p. ej. Steam con sus juegos) aparece desmarcada.

> ⚠️ Los borrados son **definitivos** (no pasan por la papelera).

## Uso

1. Descarga el repositorio (o el `.zip` de la última *release*).
2. Doble clic en **`Iniciar DiskPilot.bat`**.
3. Acepta el aviso de Control de cuentas de usuario (UAC) para darle permisos de administrador.

No requiere instalación: usa PowerShell 5.1 y .NET Framework, incluidos en Windows.

### Opciones de línea de comandos

```powershell
powershell -ExecutionPolicy Bypass -File DiskPilot.ps1 -NoElevate   # abrir sin pedir administrador
powershell -ExecutionPolicy Bypass -File DiskPilot.ps1 -SelfTest    # prueba rápida del motor sin interfaz
```

## Estructura

| Archivo | Descripción |
|---|---|
| `DiskPilot.ps1` | Aplicación completa: motor en C# (compilado al vuelo) + interfaz WPF |
| `Iniciar DiskPilot.bat` | Lanzador con doble clic |
| `CHANGELOG.md` | Historial de versiones |
