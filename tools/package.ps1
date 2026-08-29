# Build the signed store bundle: publish/Candle.iq.
#
# -e packages every product in the manifest (one today: vivoactive5) as a
# release build. The .iq goes to the gitignored publish/ directory -- it is a
# submission artifact, not a source file. Regenerate the store icon first
# (tools/make-icons.ps1); the full submission walk-through is docs/PUBLISHING.md.
#
#   just package

param(
    [int]$Typecheck = 3
)

. "$PSScriptRoot\env.ps1"

$outDir = Join-Path $RepoRoot "publish"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$out = Join-Path $outDir "Candle.iq"

Write-Host "==> packaging Candle.iq (release, typecheck=$Typecheck)" -ForegroundColor Cyan
& $MonkeyC `
    -e `
    -f (Join-Path $RepoRoot "monkey.jungle") `
    -o $out `
    -y $DevKey `
    -r -w -l $Typecheck

if ($LASTEXITCODE -ne 0) { throw "package: monkeyc -e failed ($LASTEXITCODE)" }
if (-not (Test-Path $out)) { throw "package: monkeyc reported success but $out does not exist" }

$size = (Get-Item $out).Length
Write-Host ("    ok  {0}  ({1:N1} KB)" -f $out, ($size / 1KB)) -ForegroundColor Green

# --- the version to type into the store form ----------------------------------
# The manifest has NO app-version field: the Connect IQ store takes the version
# as free text on the upload form. So the listing agrees with the glass only if
# someone types the right thing, and the only defence against typing the wrong
# thing is printing it here, read from the same constant the app draws.
# ADR-0037
$appFile = Join-Path $RepoRoot "source\candleApp.mc"
if ((Get-Content $appFile -Raw) -notmatch 'APP_VERSION\s*=\s*"([^"]+)"') {
    throw "package: could not find APP_VERSION in $appFile"
}
$version = $Matches[1]

Write-Host ""
Write-Host "VERSION FOR THE STORE FORM:  $version" -ForegroundColor Cyan
Write-Host "The bundle draws 'Candle v$version' on its settings screen. Type the same" -ForegroundColor Yellow
Write-Host "string into the form's Version box -- nothing else checks that they agree." -ForegroundColor Yellow
Write-Host ""
Write-Host "Upload at https://apps.garmin.com/developer/dashboard -- see docs/PUBLISHING.md." -ForegroundColor Yellow
