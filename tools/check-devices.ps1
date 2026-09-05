# Every product in manifest.xml, against what Candle needs from a watch.
#
#   just check-devices          (also runs inside `just test` and `just package`)
#
# The rule is ADR-0047; this is its mechanical half. Every fact comes from the
# device's own SDK config -- nothing here is typed from memory:
#
#   %APPDATA%\Garmin\ConnectIQ\Devices\<id>\compiler.json   resolution,
#       deviceFamily, launcherIcon, the Connect IQ versions it ships with
#   %APPDATA%\Garmin\ConnectIQ\Devices\<id>\simulator.json  display.isTouch
#
# What must hold, per product:
#   1. the config is installed -- otherwise the download command is printed
#   2. ROUND, and SQUARE: the chord maths models a circle (ADR-0011, ADR-0045)
#   3. a TOUCHSCREEN: every value is changed by a tap, and by nothing else
#   4. the device's Connect IQ is at least the manifest's minApiLevel
#   5. resources-<id>/drawables/launcher_icon.png exists AT the launcher size
#      the device declares (ADR-0046) -- otherwise: just icons
#
# No simulator, no build. It costs nothing, so it runs before both.

param([switch]$Quiet)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing

[xml]$manifest = Get-Content (Join-Path $RepoRoot "manifest.xml")
$application = $manifest.manifest.application
$products = @($application.products.product | ForEach-Object { $_.id })
$minApi = [version]$application.minApiLevel
if ($products.Count -eq 0) {
    Write-Host "check-devices: no <iq:product> entries in manifest.xml" -ForegroundColor Red
    exit 1
}

$devicesDir = Join-Path $env:APPDATA "Garmin\ConnectIQ\Devices"
$problems = New-Object System.Collections.Generic.List[string]
$report = New-Object System.Collections.Generic.List[string]

foreach ($id in $products) {
    $dir = Join-Path $devicesDir $id
    $compilerJson = Join-Path $dir "compiler.json"
    $simulatorJson = Join-Path $dir "simulator.json"
    if (-not (Test-Path $compilerJson) -or -not (Test-Path $simulatorJson)) {
        $problems.Add("${id}: no device config under $dir -- run: connect-iq-sdk-manager device download --manifest manifest.xml --include-fonts")
        continue
    }
    $compiler = Get-Content $compilerJson -Raw | ConvertFrom-Json
    $simulator = Get-Content $simulatorJson -Raw | ConvertFrom-Json

    # 2. round and square
    $w = [int]$compiler.resolution.width
    $h = [int]$compiler.resolution.height
    if ($compiler.deviceFamily -notmatch '^round-') {
        $problems.Add("${id}: family '$($compiler.deviceFamily)' is not round -- halfChordAt models a circle (ADR-0045)")
    }
    if ($w -ne $h) {
        $problems.Add("${id}: ${w}x${h} is not square -- the chord maths assumes a square bounding box (ADR-0045)")
    }

    # 3. touch -- the flag sits under the display block, not at the top level
    $touch = [bool]$simulator.display.isTouch
    if (-not $touch) {
        $problems.Add("${id}: no touchscreen -- every value is changed by a tap and nothing else moves one (ADR-0047)")
    }

    # 4. Connect IQ level. A device can ship several part numbers; the lowest
    #    is the one the store will install to.
    $versions = @($compiler.partNumbers | ForEach-Object { [version]$_.connectIQVersion })
    $lowest = ($versions | Sort-Object | Select-Object -First 1)
    if ($lowest -lt $minApi) {
        $problems.Add("${id}: ships Connect IQ $lowest, below the manifest's minApiLevel $minApi")
    }

    # 5. the launcher icon, at the declared size
    $iconW = [int]$compiler.launcherIcon.width
    $iconH = [int]$compiler.launcherIcon.height
    $iconPath = Join-Path $RepoRoot "resources-$id\drawables\launcher_icon.png"
    if (-not (Test-Path $iconPath)) {
        $problems.Add("${id}: no launcher icon at resources-$id\drawables\launcher_icon.png -- run: just icons (ADR-0046)")
    } else {
        $img = [System.Drawing.Image]::FromFile($iconPath)
        try { $haveW = $img.Width; $haveH = $img.Height } finally { $img.Dispose() }
        if ($haveW -ne $iconW -or $haveH -ne $iconH) {
            $problems.Add("${id}: launcher icon is ${haveW}x${haveH} but the device declares ${iconW}x${iconH} -- run: just icons (ADR-0046)")
        }
    }

    $report.Add(("    {0,-12} {1}x{2} {3,-6} {4,-8} icon {5}x{6}  Connect IQ {7}" -f
        $id, $w, $h, $compiler.displayType, $(if ($touch) { "touch" } else { "NO TOUCH" }),
        $iconW, $iconH, $lowest))
}

if ($problems.Count -gt 0) {
    Write-Host "DEVICE CHECK FAILED" -ForegroundColor Red
    foreach ($p in $problems) { Write-Host "  $p" -ForegroundColor Red }
    exit 1
}

if (-not $Quiet) {
    Write-Host "==> devices ok  ($($products.Count) product$(if ($products.Count -ne 1) { 's' }), minApiLevel $minApi)" -ForegroundColor Green
    foreach ($line in $report) { Write-Host $line -ForegroundColor DarkGray }
}
exit 0
