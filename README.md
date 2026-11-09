<p align="center"><img src="assets/logo.png" width="120" alt="DiskPilot"></p>

<h1 align="center">DiskPilot</h1>

Analizador de almacenamiento y desinstalador a fondo para Windows 10/11, con interfaz moderna en modo oscuro.

**Versión actual:** 1.5.0

## ⬇️ Descargar

[![Descargar DiskPilot.exe](https://img.shields.io/badge/Descargar-DiskPilot.exe-7C5CFF?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/Cordobot/DiskPilot/releases/latest/download/DiskPilot.exe)

**[👉 Descargar DiskPilot.exe (Windows 10/11)](https://github.com/Cordobot/DiskPilot/releases/latest/download/DiskPilot.exe)** · [Ver todas las versiones](https://github.com/Cordobot/DiskPilot/releases)

## Funciones

- **Resumen** — gráfica por categorías de cada unidad (Juegos, Programas, Sistema, Datos de apps, Archivos personales, Temporales, Otros, Libre), programas que más ocupan y archivos más grandes (+200 MB). **Haz clic en cualquier categoría** (por ejemplo «Otros») para ver exactamente qué carpetas y archivos la forman y poder abrirlos o borrarlos.
- **Programas** — todos los programas instalados con su icono, ordenados por el tamaño real de su carpeta, con búsqueda y orden por nombre o fecha. Marca varias casillas para desinstalarlos de una vez.
- **Desinstalar a fondo** (con permisos de administrador):
  1. Ejecuta el desinstalador oficial (en modo silencioso cuando el programa lo admite: MSI, Inno Setup, NSIS, Squirrel).
  2. Cierra los procesos del programa y detiene/elimina sus servicios de Windows.
  3. Borra la carpeta de instalación, restos en AppData / ProgramData / Common Files, accesos directos y claves de registro.
  4. Si algo está bloqueado, toma la propiedad (`takeown` / `icacls`) y lo programa para borrarse al reiniciar.

  Antes de borrar muestra la lista completa de elementos para desmarcar lo que se quiera conservar.
- **Explorar disco** — gráfica completa por categorías tras el análisis, escaneo rápido de una unidad completa (API Win32), navegación por carpetas de mayor a menor, abrir en el Explorador o eliminar.
- **Duplicados** — busca archivos idénticos (tamaño → hash parcial → hash MD5 completo) en una unidad o carpeta, agrupa las copias y marca automáticamente las sobrantes conservando la más antigua. Nunca deja borrar todas las copias de un grupo.
- **Limpieza rápida** — temporales, papelera, caché de Windows Update y Optimización de distribución, informes de errores, volcados de memoria, caché de Chrome/Edge, Windows.old e hibernación.

## Protecciones

Nunca se borran: la carpeta de Windows, raíces de *Archivos de programa*, *ProgramData*, *Usuarios*, el perfil de usuario y sus carpetas principales (AppData, Documentos, Descargas, Escritorio…), ni la raíz de ninguna unidad. Si una carpeta de instalación contiene otros programas (p. ej. Steam con sus juegos) aparece desmarcada.

> ⚠️ Los borrados son **definitivos** (no pasan por la papelera).

## Uso

### Opción 1 — Ejecutable (recomendado)

1. Descarga **`DiskPilot.exe`** desde la [última release](https://github.com/Cordobot/DiskPilot/releases/latest).
2. Ábrelo con doble clic y acepta el aviso de administrador (UAC).

Al abrirlo, DiskPilot **se instala o se actualiza solo**:

- Cierra la versión anterior si está abierta (si ya está abierta esta misma versión, la trae al frente).
- Se instala en `%LOCALAPPDATA%\Programs\DiskPilot` sustituyendo la versión anterior, con acceso directo en el menú Inicio (y en el Escritorio la primera vez).
- Borra los archivos de versiones anteriores, incluidos los `DiskPilot*.exe` antiguos en Descargas y Escritorio.
- Aparece en **Configuración → Aplicaciones instaladas**, desde donde se puede desinstalar (o con `DiskPilot.exe --uninstall`).

> Al no estar firmado digitalmente, Windows SmartScreen puede mostrar «Windows protegió tu PC». Pulsa **Más información → Ejecutar de todas formas**.

### Opción 2 — Script

1. Descarga el repositorio (o el `.zip` de la release).
2. Doble clic en **`Iniciar DiskPilot.bat`** y acepta el aviso de UAC.

No requiere instalación: usa PowerShell 5.1 y .NET Framework, incluidos en Windows.

### Opciones de línea de comandos

```powershell
powershell -ExecutionPolicy Bypass -File DiskPilot.ps1 -NoElevate   # abrir sin pedir administrador
powershell -ExecutionPolicy Bypass -File DiskPilot.ps1 -SelfTest    # prueba rápida del motor sin interfaz
```

## Compilar el .exe

No necesita Visual Studio: usa el compilador de C# que trae Windows.

```powershell
powershell -ExecutionPolicy Bypass -File build\build.ps1
```

Genera `dist\DiskPilot.exe` con el script incrustado, icono propio y manifiesto que pide administrador. La versión se toma de `$AppVersion` en `DiskPilot.ps1`.

## Estructura

| Archivo | Descripción |
|---|---|
| `DiskPilot.ps1` | Aplicación completa: motor en C# (compilado al vuelo) + interfaz WPF |
| `Iniciar DiskPilot.bat` | Lanzador con doble clic (sin compilar) |
| `build/` | Lanzador nativo en C#, manifiesto, generador del logo y script de compilación del `.exe` |
| `assets/` | Logo (`logo.png`) e icono (`DiskPilot.ico`) |
| `CHANGELOG.md` | Historial de versiones |
