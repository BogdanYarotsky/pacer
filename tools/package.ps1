# Build the signed store bundle: publish/Candle.iq.
#
# -e packages EVERY product in the manifest as a release build, into one .iq --
# the store reads the device list off the bundle. It goes to the gitignored
# publish/ directory: a submission artifact, not a source file. Regenerate the
# icons first (just icons); the full submission walk-through is
# docs/PUBLISHING.md.
#
#   just package

param(
    [int]$Typecheck = 3
)

. "$PSScriptRoot\env.ps1"
. "$PSScriptRoot\version.ps1"

# --- the devices, before anything is built ------------------------------------
# A product with no launcher icon at its own size, or one the app cannot be used
# on, must not reach the store. ADR-0047
& "$PSScriptRoot\check-devices.ps1"
if ($LASTEXITCODE -ne 0) { throw "package: device check failed, nothing was built" }

# --- THE GUARD ----------------------------------------------------------------
# The store never sees a three-segment version, and this is the one place that
# is enforced rather than remembered. Everything else about the scheme can stay
# loose because a dev build physically cannot become a submission artifact:
# there is exactly one route to publish/Candle.iq and it runs through here.
# ADR-0039
$version = Get-AppVersion
if (-not $version.IsPublic) {
    throw ("package: $($version.Text) is a DEV version -- three segments mean a " +
        "build that has never been published and must not be. Run 'just release' " +
        "to finalise it, walk the wrist pass, then package. (ADR-0039)")
}

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
# ADR-0037, ADR-0039
Write-Host ""
Write-Host "VERSION FOR THE STORE FORM:  $($version.Text)" -ForegroundColor Cyan
Write-Host "The bundle draws 'v$($version.Text)' along the bottom of its settings screen. Type" -ForegroundColor Yellow
Write-Host "the same number into the form's Version box -- nothing else checks they agree." -ForegroundColor Yellow
Write-Host "Devices in this bundle: $($Products -join ', ')" -ForegroundColor Yellow
Write-Host ""
Write-Host "Upload at https://apps.garmin.com/developer/dashboard -- see docs/PUBLISHING.md." -ForegroundColor Yellow
