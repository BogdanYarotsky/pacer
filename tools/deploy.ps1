# Bump the on-screen version, build, and push the PRG to the watch.
#
# THE WATCH IS MTP, NOT USB MASS STORAGE.
#
# Verified on this machine: the vivoactive 5 enumerates as a Windows Portable
# Device (Get-PnpDevice -Class WPD, InstanceId USB\VID_091E&PID_514A) and never
# receives a drive letter. Copy-Item to a path like E:\GARMIN\APPS cannot work.
# The Shell.Application COM namespace is the supported scriptable route.
#
# VERIFICATION CAVEAT: current firmware hides .prg files after install, so the
# file cannot be read back to prove the copy landed. The ONLY proof is launching
# Candle on the watch and reading the version off the main screen. That is why
# this script bumps the version before every build.

param(
    [string]$Device = "vivoactive5",
    [switch]$NoBump,
    [string]$SetVersion = ""
)

. "$PSScriptRoot\env.ps1"

$appFile = Join-Path $RepoRoot "source\candleApp.mc"

# --- resolve the version ------------------------------------------------------
$content = Get-Content $appFile -Raw
if ($content -notmatch 'APP_VERSION\s*=\s*"(\d+)\.(\d+)"') {
    throw "deploy: could not find 'const APP_VERSION = `"X.Y`";' in $appFile"
}
$currentVersion = "$($Matches[1]).$($Matches[2])"
$major = $Matches[1]
$minor = $Matches[2]

if ($SetVersion -ne "") {
    $nextVersion = $SetVersion
} elseif ($NoBump) {
    $nextVersion = $currentVersion
} else {
    # Keep the zero padding: 0.08 -> 0.09, not 0.9.
    $width = $minor.Length
    $nextVersion = "$major." + ([int]$minor + 1).ToString().PadLeft($width, '0')
}

if ($nextVersion -ne $currentVersion) {
    $content = $content -replace "APP_VERSION\s*=\s*`"$([regex]::Escape($currentVersion))`"", "APP_VERSION = `"$nextVersion`""
    Set-Content -Path $appFile -Value $content -NoNewline
    Write-Host "version  $currentVersion -> $nextVersion" -ForegroundColor Cyan
} else {
    Write-Host "version  $currentVersion (unchanged)" -ForegroundColor Cyan
}

# --- build --------------------------------------------------------------------
& "$PSScriptRoot\build.ps1" -Device $Device -Typecheck 3
if ($LASTEXITCODE -ne 0) { throw "deploy: build failed, nothing was sent to the watch" }

$prg = Join-Path $RepoRoot "bin\candle-$Device.prg"

# --- find the watch over MTP --------------------------------------------------
$shell = New-Object -ComObject Shell.Application
$thisPC = $shell.NameSpace(17)   # ssfDRIVES
if ($null -eq $thisPC) { throw "deploy: could not open the This PC shell namespace" }

$watch = $null
foreach ($item in $thisPC.Items()) {
    if ($item.Name -match 'v.?voactive' -or $item.Name -match 'Garmin') { $watch = $item; break }
}

if ($null -eq $watch) {
    Write-Host ""
    Write-Host "DEPLOY FAILED: the watch is not connected." -ForegroundColor Red
    Write-Host "  Plug the vivoactive 5 in with a DATA-capable USB cable and unlock it." -ForegroundColor Red
    Write-Host "  It appears under 'This PC' as a portable device named 'vivoactive 5'," -ForegroundColor Red
    Write-Host "  NOT as a drive letter -- it speaks MTP." -ForegroundColor Red
    Write-Host "  Built PRG is ready at: $prg" -ForegroundColor Yellow
    exit 1
}

Write-Host "==> found portable device: $($watch.Name)" -ForegroundColor Cyan

# Walk down to GARMIN\APPS. Storage volume names vary ("Internal Storage", the
# device name again), so descend by looking for GARMIN at each level.
function Find-ChildFolder($folder, $name) {
    if ($null -eq $folder) { return $null }
    foreach ($i in $folder.Items()) {
        if ($i.IsFolder -and $i.Name -eq $name) { return $i.GetFolder }
    }
    return $null
}

$root = $watch.GetFolder
$garmin = Find-ChildFolder $root "GARMIN"
if ($null -eq $garmin) {
    # One level down, through the storage volume.
    foreach ($vol in $root.Items()) {
        if ($vol.IsFolder) {
            $candidate = Find-ChildFolder $vol.GetFolder "GARMIN"
            if ($null -ne $candidate) { $garmin = $candidate; break }
        }
    }
}
if ($null -eq $garmin) { throw "deploy: could not find a GARMIN folder on $($watch.Name)" }

$apps = Find-ChildFolder $garmin "APPS"
if ($null -eq $apps) { throw "deploy: could not find GARMIN\APPS on $($watch.Name)" }

# --- copy ---------------------------------------------------------------------
# MTP needs the file to already have its destination name, so stage a correctly
# named copy in TEMP first.
$staged = Join-Path $env:TEMP "candle.prg"
Copy-Item $prg $staged -Force

Write-Host "==> copying candle.prg to GARMIN\APPS over MTP" -ForegroundColor Cyan
# 16 = respond "Yes to All" to any overwrite prompt.
$apps.CopyHere($staged, 16)

# CopyHere is asynchronous and gives no completion signal, so wait for the name
# to appear rather than assuming. Absence is NOT proof of failure -- see below.
$deadline = (Get-Date).AddSeconds(30)
$seen = $false
do {
    Start-Sleep -Milliseconds 700
    foreach ($i in $apps.Items()) { if ($i.Name -match '^candle(\.prg)?$') { $seen = $true; break } }
} while (-not $seen -and (Get-Date) -lt $deadline)

Write-Host ""
if ($seen) {
    # Observed: the name shows up in APPS straight after CopyHere. That only
    # means an entry exists -- the shell reports Size=0 for every item over MTP
    # (OUT.BIN reads 0 too), so it says nothing about whether the bytes landed
    # intact. Once the watch installs the app the entry goes away again.
    Write-Host "copied   candle.prg -> $($watch.Name) GARMIN\APPS" -ForegroundColor Green
} else {
    Write-Host "candle.prg is not visible in GARMIN\APPS after the copy." -ForegroundColor Yellow
    Write-Host "That happens once the firmware has installed it, and is not evidence either way." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "THE COPY CANNOT BE VERIFIED FROM HERE." -ForegroundColor Yellow
Write-Host "Disconnect the watch, open Candle, and confirm the main screen reads v$nextVersion." -ForegroundColor Yellow
Write-Host "If it shows an older version, the watch is still running the previous build." -ForegroundColor Yellow
