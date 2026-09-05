# Render the Candle mark and emit every size the app and the store need.
#
# The mark is drawn once, procedurally, at 1000x1000 -- a white candle body,
# a short wick, and an amber teardrop flame with a lighter core -- then
# downscaled with high-quality bicubic to:
#
#   publish/store-icon-500.png                    500x500, content in a 480px
#                                                 box (the store wants ~10px of
#                                                 padding)
#   resources-<device>/drawables/launcher_icon.png  ONE PER PRODUCT in
#                                                 manifest.xml, at the launcher
#                                                 size that device's own
#                                                 compiler.json declares
#
# ONE ICON PER DEVICE, AND THE SIZE IS READ, NOT TYPED. The compiler accepts an
# icon of the wrong size and scales it with a warning; the settings screen
# draws this same bitmap as its logo (ADR-0040), so a scaled icon would be a
# scaled logo on the one band a test measures a bitmap against. ADR-0046 is why
# each device gets its own at exact size, and why the folders are keyed by
# device id rather than by screen family: the launcher size is a per-device
# fact that does not follow the resolution. There is no icon in the base
# resources/ folder on purpose -- a product without a generated folder fails to
# build, which beats building with a resampled mark.
#
# THERE IS NO THIRD SIZE per device, and that is deliberate. The settings
# screen's top band draws the launcher icon itself rather than a logo of its
# own: it is the same mark at the same size, so a second file would be a second
# thing to keep in step for no gain. It also reads correctly -- the mark on the
# screen is the mark you tapped to get here.
#
# A 40x40 logo_small.png did exist once, in the MAIN screen's bottom slot on
# release builds, and it was deleted because that slot must hold a fact about
# the session in progress (ADR-0005): the screen you breathe on is not a place
# to advertise. That still holds. The settings screen is not that screen.
#
# The script IS the versioned artwork: publish/ is gitignored, so regenerate
# the store icon before a submission. Tweak the shape here, re-run, rebuild.
#
#   pwsh -NoProfile -File tools/make-icons.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$RepoRoot = Split-Path $PSScriptRoot -Parent

# --- the products, and the launcher size each declares ------------------------
[xml]$manifest = Get-Content (Join-Path $RepoRoot "manifest.xml")
$products = @($manifest.manifest.application.products.product | ForEach-Object { $_.id })
if ($products.Count -eq 0) { throw "make-icons: no <iq:product> entries in manifest.xml" }

$devicesDir = Join-Path $env:APPDATA "Garmin\ConnectIQ\Devices"
$targets = @()
foreach ($id in $products) {
    $compilerJson = Join-Path $devicesDir "$id\compiler.json"
    if (-not (Test-Path $compilerJson)) {
        throw ("make-icons: no device config for '$id' at $compilerJson -- run: " +
            "connect-iq-sdk-manager device download --manifest manifest.xml --include-fonts")
    }
    $compiler = Get-Content $compilerJson -Raw | ConvertFrom-Json
    $w = [int]$compiler.launcherIcon.width
    $h = [int]$compiler.launcherIcon.height
    if ($w -ne $h) { throw "make-icons: $id declares a ${w}x${h} launcher icon, and the mark is square" }
    $targets += [pscustomobject]@{ Id = $id; Size = $w }
}

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
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host ("wrote {0}  ({1}x{1}, {2:N0} bytes)" -f $path, $canvas, (Get-Item $path).Length)
}

# The resource XML beside each icon. Identical for every device and generated
# with it, so the folder is self-describing and nobody edits one by hand.
$drawablesXml = @'
<drawables>
    <!-- GENERATED by tools/make-icons.ps1; do not edit. The launcher icon at
         the size THIS device's compiler.json declares, one folder per product
         (ADR-0046). Drawn in two places: the launcher, and the settings screen's
         top band (ADR-0040). Re-run `just icons` after changing the manifest. -->
    <bitmap id="LauncherIcon" filename="launcher_icon.png" />
</drawables>
'@

Save-Scaled $master 500 10 (Join-Path $RepoRoot "publish\store-icon-500.png")
foreach ($t in $targets) {
    $dir = Join-Path $RepoRoot "resources-$($t.Id)\drawables"
    Save-Scaled $master $t.Size 0 (Join-Path $dir "launcher_icon.png")
    Set-Content -Path (Join-Path $dir "drawables.xml") -Value $drawablesXml -NoNewline
}

$master.Dispose()
Write-Host "done. Rebuild to compile the drawables; regenerate before a store submission." -ForegroundColor Green
