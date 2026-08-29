# Turn the raw simulator captures in shots/ into store-ready listing images.
#
#   just store-shots
#
# WHY THIS IS A SCRIPT. It was done by hand once, and every step of it is a
# judgement that has to come out identical next release or the listing's two
# images will not match each other. Cropping "about square, roughly centred" by
# eye is exactly the kind of thing that looks fine alone and wrong side by side.
#
# WHAT THE STORE WANTS. Garmin's own submission page does not publish image
# specs; these come from the developer forums and from what the upload form
# accepts, so treat them as observed rather than documented:
#
#   * SQUARE. The store site stretches a non-square image into a square slot,
#     which is why so many listings show ovals where a round watch should be.
#     This is the one that actually bites.
#   * 500x500 px, and no larger.
#   * PNG, under ~150 KB each.
#
# If a future upload rejects one of these, the form's own message is better
# evidence than this comment -- update it here rather than working around it.

param(
    [int]$Size = 500,
    [int]$WarnKB = 150
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing

$shots = Join-Path $RepoRoot "shots"
$outDir = Join-Path $RepoRoot "publish"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# Find the watch in the capture, without assuming where the window put it.
#
# The landmark is the WHITE client background, not the black display: the
# simulator window has a black border, so "the darkest region" spans the whole
# frame and isolates nothing. Everything that is not background is watch.
#
# The widest row of non-background pixels is the case's equator -- straps are
# narrower than the case, so this finds the body rather than the band, and the
# side buttons are included because they stick out furthest of all.
function Get-WatchBounds([System.Drawing.Bitmap]$b) {
    $top = 55                      # below the title and menu bars
    $bottom = $b.Height - 40       # above the status bar
    $bestWidth = 0; $bestY = 0; $bestLeft = 0; $bestRight = 0

    # The LONGEST CONTIGUOUS run, not the leftmost-to-rightmost span. The window
    # has a 1-2px black border down each edge, and a span measurement reads that
    # as a watch nearly as wide as the window -- which is how the first version
    # of this asked for a 633px crop out of a 604px capture. A run measurement
    # ignores the border, because white separates it from the watch.
    for ($y = $top; $y -lt $bottom; $y += 2) {
        $runStart = -1
        for ($x = 0; $x -lt $b.Width; $x += 2) {
            $c = $b.GetPixel($x, $y)
            $isWatch = ($c.R -lt 240 -or $c.G -lt 240 -or $c.B -lt 240)
            if ($isWatch) {
                if ($runStart -lt 0) { $runStart = $x }
            }
            if ((-not $isWatch) -or ($x + 2) -ge $b.Width) {
                if ($runStart -ge 0) {
                    $runEnd = if ($isWatch) { $x } else { $x - 2 }
                    if (($runEnd - $runStart) -gt $bestWidth) {
                        $bestWidth = $runEnd - $runStart; $bestY = $y
                        $bestLeft = $runStart; $bestRight = $runEnd
                    }
                    $runStart = -1
                }
            }
        }
    }
    if ($bestWidth -le 0) { throw "store-shots: found no watch against the background" }
    return @{
        CenterX = [int](($bestLeft + $bestRight) / 2)
        CenterY = $bestY
        Width   = $bestWidth + 1
    }
}

function Convert-One([string]$inPath, [string]$outPath, [string]$label) {
    if (-not (Test-Path $inPath)) { throw "store-shots: $inPath does not exist -- run the shot recipes first" }
    $src = [System.Drawing.Bitmap]::FromFile($inPath)
    try {
        $w = Get-WatchBounds $src

        # A square framing the case with a little air, clamped to the capture.
        # 1.06 keeps the side buttons off the edge without pulling in so much
        # strap that the watch shrinks in the listing thumbnail.
        $side = [int]($w.Width * 1.06)
        $half = [int]($side / 2)
        $left = [Math]::Max(0, $w.CenterX - $half)
        $top = [Math]::Max(0, $w.CenterY - $half)
        if (($left + $side) -gt $src.Width)  { $left = $src.Width - $side }
        if (($top + $side) -gt $src.Height)  { $top = $src.Height - $side }
        if ($left -lt 0 -or $top -lt 0) { throw "store-shots: the capture is too small to crop $side px square" }

        $out = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $g = [System.Drawing.Graphics]::FromImage($out)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        # White first: Format24bppRgb has no alpha, so any transparency in the
        # capture would otherwise composite against black. Today's captures are
        # fully opaque, but the capture method is not this script's business.
        $g.Clear([System.Drawing.Color]::White)
        $g.DrawImage($src,
            (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)),
            (New-Object System.Drawing.Rectangle($left, $top, $side, $side)),
            [System.Drawing.GraphicsUnit]::Pixel)
        $g.Dispose()
        $out.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $out.Dispose()

        $kb = [math]::Round((Get-Item $outPath).Length / 1KB, 1)
        $flag = if ($kb -gt $WarnKB) { " -- OVER the ~$WarnKB KB the store is reported to accept" } else { "" }
        Write-Host ("    {0,-9} watch {1}px at ({2},{3}) -> {4}px square -> {5}x{5}, {6} KB{7}" -f
            $label, $w.Width, $w.CenterX, $w.CenterY, $side, $Size, $kb, $flag) -ForegroundColor $(if ($flag) { "Yellow" } else { "Green" })
    } finally {
        $src.Dispose()
    }
}

Write-Host "==> store listing images ($Size x $Size, square)" -ForegroundColor Cyan
Convert-One (Join-Path $shots "vivoactive5.png") (Join-Path $outDir "store-shot-1-main.png") "main"
Convert-One (Join-Path $shots "vivoactive5-settings.png") (Join-Path $outDir "store-shot-2-settings.png") "settings"

Write-Host ""
Write-Host "Upload in filename order. The main screen goes first -- it is the one" -ForegroundColor Yellow
Write-Host "shown in the store's app list, where the settings screen would just" -ForegroundColor Yellow
Write-Host "read as an unexplained pair of numbers." -ForegroundColor Yellow
