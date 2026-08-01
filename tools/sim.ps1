# Build, start the Connect IQ simulator if it is not already up, and load the app.

param(
    [string]$Device = "vivoactive5",
    [ValidateRange(0, 3)][int]$Typecheck = 3
)

. "$PSScriptRoot\env.ps1"

& "$PSScriptRoot\build.ps1" -Device $Device -Typecheck $Typecheck
if ($LASTEXITCODE -ne 0) { throw "sim: build failed" }

$prg = Join-Path $RepoRoot "bin\pacer-$Device.prg"

Start-SimulatorIfNeeded | Out-Null

# Unlike shot/test, this recipe is meant to be interactive: monkeydo runs in the
# foreground and holds the app open until you Ctrl-C. It will not return on its
# own -- that is the point of `just sim`.
Write-Host "==> monkeydo $(Split-Path -Leaf $prg) $Device   (Ctrl-C to stop)" -ForegroundColor Cyan
& $MonkeyDo $prg $Device
