# Compila DiskPilot.exe usando el compilador de C# incluido en Windows (.NET Framework 4).
# Uso:  powershell -ExecutionPolicy Bypass -File build\build.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dist = Join-Path $root 'dist'
$obj  = Join-Path $here 'obj'
New-Item -ItemType Directory -Force $dist, $obj | Out-Null

$script = Join-Path $root 'DiskPilot.ps1'
$version = ([regex]::Match((Get-Content $script -Raw -Encoding UTF8), "\`$AppVersion = '([\d\.]+)'")).Groups[1].Value
if (-not $version) { throw 'No se encontró $AppVersion en DiskPilot.ps1' }
Write-Host "Versión: $version"

# ---------- Logo e icono (también lo incrusta en DiskPilot.ps1) ----------
& (Join-Path $here 'make-logo.ps1')
$ico = Join-Path $root 'assets\DiskPilot.ico'

# ---------- Compilación ----------
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
$src = Join-Path $obj 'Launcher.cs'
(Get-Content (Join-Path $here 'Launcher.cs') -Raw -Encoding UTF8).Replace('__VERSION__', $version) | Set-Content $src -Encoding UTF8
$out = Join-Path $dist 'DiskPilot.exe'
& $csc /nologo /target:winexe /optimize+ /platform:anycpu "/out:$out" "/win32icon:$ico" "/win32manifest:$(Join-Path $here 'app.manifest')" `
    /reference:System.Windows.Forms.dll /reference:System.Management.dll "/resource:$script,DiskPilot.ps1" $src
if ($LASTEXITCODE -ne 0) { throw "Falló la compilación ($LASTEXITCODE)" }
Copy-Item $ico (Join-Path $dist 'DiskPilot.ico') -Force
Write-Host "Generado: $out ($([Math]::Round((Get-Item $out).Length / 1KB)) KB)"
