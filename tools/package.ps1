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
Write-Host "Upload at https://apps.garmin.com/developer/dashboard -- see docs/PUBLISHING.md." -ForegroundColor Yellow
