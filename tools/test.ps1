# Build with unit tests, make sure the simulator is up, run the tests, and turn
# the runner's stdout into a real exit code.
#
# Verified against SDK 9.2.0:
#   monkeyc  -t / --unit-test      compiles tests into the PRG
#   monkeydo <prg> <device> /t     runs them  (Windows uses /t, NOT -t --
#                                  monkeydo.bat matches "%~3"=="/t" and falls
#                                  through to its usage banner otherwise)

param(
    [string]$Device = "vivoactive5",
    [ValidateRange(0, 3)][int]$Typecheck = 3,
    [string]$TestName = "",
    [int]$TimeoutSec = 180,
    [switch]$KeepSim
)

. "$PSScriptRoot\env.ps1"

# --- every product, one simulator run each -----------------------------------
# The suite measures the glass and the fonts of the device it runs on, so a
# green run on one watch says nothing about another (ADR-0045). "all" walks the
# manifest, one child run per product, and fails if any of them does.
if ($Device -eq "all") {
    $failed = @()
    foreach ($product in $Products) {
        Write-Host ""
        Write-Host "==================== $product ====================" -ForegroundColor Cyan
        & $PSCommandPath -Device $product -Typecheck $Typecheck -TestName $TestName -TimeoutSec $TimeoutSec
        if ($LASTEXITCODE -ne 0) { $failed += $product }
    }
    Write-Host ""
    if ($failed.Count -gt 0) {
        Write-Host "TESTS FAILED on: $($failed -join ', ')" -ForegroundColor Red
        exit 1
    }
    Write-Host "TESTS PASSED on every product  ($($Products -join ', '))" -ForegroundColor Green
    exit 0
}

# --- prose first --------------------------------------------------------------
# The cheapest possible failure: no build, no simulator. A dangling ADR
# reference or an ADR nothing points at is caught before anything expensive
# starts. See ADR-0033.
& "$PSScriptRoot\check-adrs.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "test: ADR check failed, not building" -ForegroundColor Red
    exit 1
}

# --- then the devices ---------------------------------------------------------
# Equally cheap: every product in the manifest against what the app needs from
# a watch, and its launcher icon at the size it declares. ADR-0047
& "$PSScriptRoot\check-devices.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "test: device check failed, not building" -ForegroundColor Red
    exit 1
}

# --- build --------------------------------------------------------------------
& "$PSScriptRoot\build.ps1" -Device $Device -Typecheck $Typecheck -UnitTest
if ($LASTEXITCODE -ne 0) { Write-Host "test: build failed, not running tests" -ForegroundColor Red; exit 1 }

$prg = Join-Path $RepoRoot "bin\candle-$Device-test.prg"
if (-not (Test-Path $prg)) { throw "test: expected PRG not found at $prg" }

# --- simulator ----------------------------------------------------------------
Start-SimulatorIfNeeded | Out-Null

# --- run ----------------------------------------------------------------------
$monkeydoArgs = @($prg, $Device, "/t")
if ($TestName -ne "") { $monkeydoArgs += $TestName }

Write-Host "==> monkeydo $(Split-Path -Leaf $prg) $Device /t $TestName" -ForegroundColor Cyan

$stdout = Join-Path $env:TEMP "candle-test-out.txt"
$stderr = Join-Path $env:TEMP "candle-test-err.txt"
$proc = Start-Process -FilePath $MonkeyDo -ArgumentList $monkeydoArgs `
    -NoNewWindow -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr

if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
    $proc.Kill()
    throw "test: monkeydo did not finish within ${TimeoutSec}s"
}

$out = (Get-Content $stdout -Raw -ErrorAction SilentlyContinue) + "`n" +
       (Get-Content $stderr -Raw -ErrorAction SilentlyContinue)
Write-Host $out

# The tests are done; nothing may outlive them or the caller never returns.
Stop-MonkeyDo
if (-not $KeepSim) { Stop-Simulator }

# --- parse --------------------------------------------------------------------
# Never treat silence as success: if the RESULTS block is missing, something
# went wrong before the tests ran and that is a failure, not a pass.
if ($out -notmatch 'RESULTS') {
    Write-Host "TEST FAILED: no RESULTS block in the runner output." -ForegroundColor Red
    Write-Host "The app probably crashed before the tests ran, or the simulator was not ready." -ForegroundColor Red
    exit 1
}

$ran = if ($out -match 'Ran\s+(\d+)\s+test') { [int]$Matches[1] } else { 0 }

if ($ran -eq 0) {
    Write-Host "TEST FAILED: the runner reported 0 tests. Are the (:test) annotations present and tests/ on the sourcePath?" -ForegroundColor Red
    exit 1
}

# Run No Evil on SDK 9.2.0 emits:
#     PASSED (passed=13, failed=0, errors=0)
#     FAILED (passed=12, failed=0, errors=1)
# Garmin's own Unit_Testing doc shows the older "failures=0, errors=0" spelling,
# so both are accepted. An ERROR (a thrown assert) counts the same as a failure.
if ($out -notmatch '(?m)^(PASSED|FAILED)\s*\(') {
    Write-Host "TEST FAILED: no PASSED/FAILED summary line in the runner output." -ForegroundColor Red
    exit 1
}
$verdict = $Matches[1]

$failed = if ($out -match '(?:failed|failures)=(\d+)') { [int]$Matches[1] } else { -1 }
$errors = if ($out -match 'errors=(\d+)')              { [int]$Matches[1] } else { -1 }

if ($verdict -eq 'PASSED' -and $failed -eq 0 -and $errors -eq 0) {
    Write-Host "TESTS PASSED  ($ran test$(if($ran -ne 1){'s'}))" -ForegroundColor Green
    exit 0
}

Write-Host "TEST FAILED: $verdict  ran=$ran failed=$failed errors=$errors" -ForegroundColor Red
exit 1
