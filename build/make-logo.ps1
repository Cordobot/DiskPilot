# Genera el logo de DiskPilot: assets\logo.png, assets\DiskPilot.ico
# y lo incrusta (base64) en DiskPilot.ps1 entre los marcadores @@LOGO.
# Uso: powershell -ExecutionPolicy Bypass -File build\make-logo.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$assets = Join-Path $root 'assets'
New-Item -ItemType Directory -Force $assets | Out-Null

function New-Logo([int]$s) {
    $bmp = New-Object System.Drawing.Bitmap $s, $s
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'; $g.CompositingQuality = 'HighQuality'

    # Fondo: cuadrado redondeado con degradado violeta -> cian
    $r = [single]($s * 0.24); $d = $r * 2; $w = [single]($s - 1)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $d, $d, 180, 90); $path.AddArc($w - $d, 0, $d, $d, 270, 90)
    $path.AddArc($w - $d, $w - $d, $d, $d, 0, 90); $path.AddArc(0, $w - $d, $d, $d, 90, 90); $path.CloseFigure()
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.PointF 0, 0), (New-Object System.Drawing.PointF $s, $s),
        [System.Drawing.Color]::FromArgb(124, 92, 255), [System.Drawing.Color]::FromArgb(0, 194, 255))
    $g.FillPath($bg, $path)

    # Gráfico de anillo (uso de disco): segmento principal blanco + segmento translúcido
    $th = [single][Math]::Max(2.2, $s * 0.13)
    $rad = [single]($s * 0.255)
    $c = [single]($s / 2)
    $rect = New-Object System.Drawing.RectangleF ($c - $rad), ($c - $rad), ($rad * 2), ($rad * 2)
    $track = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(85, 255, 255, 255)), $th
    $g.DrawEllipse($track, $rect)
    $main = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), $th
    $main.StartCap = 'Round'; $main.EndCap = 'Round'
    $g.DrawArc($main, $rect, -90, 245)
    # Punto central
    $dot = [single]([Math]::Max(1.5, $s * 0.075))
    $g.FillEllipse([System.Drawing.Brushes]::White, ($c - $dot), ($c - $dot), ($dot * 2), ($dot * 2))

    $g.Dispose()
    return $bmp
}

function Get-PngBytes($bmp) {
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    return , $ms.ToArray()
}

# PNG grande
$big = New-Logo 256
$big.Save((Join-Path $assets 'logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# ICO multi-tamaño (cada tamaño se dibuja por separado para que quede nítido)
$sizes = 16, 20, 24, 32, 40, 48, 64, 128, 256
$pngs = foreach ($s in $sizes) { , (Get-PngBytes (New-Logo $s)) }
$ico = Join-Path $assets 'DiskPilot.ico'
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

# Incrustar el logo (128 px) en DiskPilot.ps1
$b64 = [Convert]::ToBase64String((Get-PngBytes (New-Logo 128)))
$script = Join-Path $root 'DiskPilot.ps1'
$text = [IO.File]::ReadAllText($script)
$new = [regex]::Replace($text, "(?s)# @@LOGO_BEGIN.*?# @@LOGO_END", "# @@LOGO_BEGIN (generado por build\make-logo.ps1)`n`$LogoPng = '$b64'`n# @@LOGO_END")
if ($new -eq $text -and $text -notmatch '@@LOGO_BEGIN') { throw 'Faltan los marcadores @@LOGO en DiskPilot.ps1' }
[IO.File]::WriteAllText($script, $new, (New-Object Text.UTF8Encoding($true)))
Write-Host "Logo generado: $assets (logo.png, DiskPilot.ico) e incrustado en DiskPilot.ps1"
