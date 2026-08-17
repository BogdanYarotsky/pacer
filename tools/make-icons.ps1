# Render the Candle mark and emit every size the app and the store need.
#
# The mark is drawn once, procedurally, at 1000x1000 -- a white candle body,
# a short wick, and an amber teardrop flame with a lighter core -- then
# downscaled with high-quality bicubic to:
#
#   publish/store-icon-500.png            500x500, content in a 480px box
#                                         (the store wants ~10px of padding)
#   resources/drawables/launcher_icon.png 56x56, the vivoactive 5 launcher size
#                                         (from the device compiler.json)
#   resources/drawables/logo_small.png    30x30, the release build's bottom-slot
#                                         mark on the main screen
#
# The script IS the versioned artwork: publish/ is gitignored, so regenerate
# the store icon before a submission. Tweak the shape here, re-run, rebuild.
#
#   pwsh -NoProfile -File tools/make-icons.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Split-Path $PSScriptRoot -Parent

# --- draw the master ------------------------------------------------------
$size = 1000
$master = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($master)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$wick  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 138, 110, 75))
$flame = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 179, 92))
$core  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 224, 160))

function New-Teardrop([float]$cx, [float]$tipY, [float]$bulge, [float]$bottomY) {
    # A flame: a point at the top easing into a round bottom. Two mirrored
    # Beziers meeting at the tip and at the bottom centre.
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $bulgeY = $tipY + (($bottomY - $tipY) * 0.62)
    $p.AddBezier($cx, $tipY, ($cx + ($bulge * 0.55)), ($tipY + (($bottomY - $tipY) * 0.30)), ($cx + $bulge), ($bulgeY - 40), ($cx + $bulge), $bulgeY)
    $p.AddBezier(($cx + $bulge), $bulgeY, ($cx + $bulge), ($bottomY - 10), ($cx + ($bulge * 0.55)), $bottomY, $cx, $bottomY)
    $p.AddBezier($cx, $bottomY, ($cx - ($bulge * 0.55)), $bottomY, ($cx - $bulge), ($bottomY - 10), ($cx - $bulge), $bulgeY)
    $p.AddBezier(($cx - $bulge), $bulgeY, ($cx - $bulge), ($bulgeY - 40), ($cx - ($bulge * 0.55)), ($tipY + (($bottomY - $tipY) * 0.30)), $cx, $tipY)
    $p.CloseFigure()
    return $p
}

# Body: rounded rectangle, x 360..640, y 480..900.
$body = New-Object System.Drawing.Drawing2D.GraphicsPath
$bx = 360; $by = 480; $bw = 280; $bh = 420; $r = 60
$body.AddArc($bx, $by, $r, $r, 180, 90)
$body.AddArc(($bx + $bw - $r), $by, $r, $r, 270, 90)
$body.AddArc(($bx + $bw - $r), ($by + $bh - $r), $r, $r, 0, 90)
$body.AddArc($bx, ($by + $bh - $r), $r, $r, 90, 90)
$body.CloseFigure()
$g.FillPath($white, $body)

# Wick: a short stub between body and flame.
$g.FillRectangle($wick, 490, 430, 20, 60)

# Flame: outer teardrop and lighter core, floating just above the wick.
$g.FillPath($flame, (New-Teardrop 500 130 105 425))
$g.FillPath($core,  (New-Teardrop 500 240 55 405))

$g.Dispose()

# --- emit the sizes ---------------------------------------------------------
function Save-Scaled([System.Drawing.Bitmap]$src, [int]$canvas, [int]$pad, [string]$path) {
    $bmp = New-Object System.Drawing.Bitmap($canvas, $canvas, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gg = [System.Drawing.Graphics]::FromImage($bmp)
    $gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $gg.Clear([System.Drawing.Color]::Transparent)
    $box = $canvas - (2 * $pad)
    $gg.DrawImage($src, (New-Object System.Drawing.Rectangle($pad, $pad, $box, $box)))
    $gg.Dispose()
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host ("wrote {0}  ({1}x{1}, {2:N0} bytes)" -f $path, $canvas, (Get-Item $path).Length)
}

Save-Scaled $master 500 10 (Join-Path $RepoRoot "publish\store-icon-500.png")
Save-Scaled $master 56 0 (Join-Path $RepoRoot "resources\drawables\launcher_icon.png")
Save-Scaled $master 30 0 (Join-Path $RepoRoot "resources\drawables\logo_small.png")

$master.Dispose()
Write-Host "done. Rebuild to compile the drawables; regenerate before a store submission." -ForegroundColor Green
