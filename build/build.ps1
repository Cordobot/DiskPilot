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

# ---------- Icono (degradado violeta-cian con un disco) ----------
Add-Type -AssemblyName System.Drawing
function New-IconPng([int]$s) {
    $bmp = New-Object System.Drawing.Bitmap $s, $s
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
    $r = [Math]::Max(2, [int]($s * 0.22)); $d = $r * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $d, $d, 180, 90); $path.AddArc($s - $d - 1, 0, $d, $d, 270, 90)
    $path.AddArc($s - $d - 1, $s - $d - 1, $d, $d, 0, 90); $path.AddArc(0, $s - $d - 1, $d, $d, 90, 90); $path.CloseFigure()
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Point 0, 0), (New-Object System.Drawing.Point $s, $s),
        [System.Drawing.Color]::FromArgb(124, 92, 255), [System.Drawing.Color]::FromArgb(0, 194, 255))
    $g.FillPath($brush, $path)
    $font = New-Object System.Drawing.Font('Segoe MDL2 Assets', [single]($s * 0.5), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $sf = New-Object System.Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
    $g.DrawString([string][char]0xEDA2, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, ([single]($s * 0.04)), $s, $s), $sf)
    $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    return , $ms.ToArray()
}
$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = foreach ($s in $sizes) { , (New-IconPng $s) }
$ico = Join-Path $obj 'DiskPilot.ico'
$fs = [IO.File]::Create($ico); $bw = New-Object IO.BinaryWriter $fs
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]; $len = $pngs[$i].Length
    $bw.Write([byte]($s % 256)); $bw.Write([byte]($s % 256)); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$len); $bw.Write([uint32]$offset)
    $offset += $len
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Close()

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
