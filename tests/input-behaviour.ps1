# Input behaviour regression test.
#
# Monkey C unit tests cannot reach input handling -- Run No Evil has no way to
# raise a tap or a button press. This test closes that gap by driving REAL input
# into the simulator with tools/input.ps1 and asserting on the [input] trace the
# delegate emits.
#
# It is deliberately separate from `just test`: it needs a simulator window and
# synthesises system-wide mouse events, so it steals the pointer while it runs.
#
#   just input-test

param(
    [string]$Device = "vivoactive5",
    [int]$SettleSec = 9
)

. "$PSScriptRoot\..\tools\env.ps1"

$trace = Join-Path $env:TEMP "pacer-input-behaviour.txt"
$errLog = Join-Path $env:TEMP "pacer-input-behaviour-err.txt"

# --- build + launch -----------------------------------------------------------
& "$PSScriptRoot\..\tools\build.ps1" -Device $Device -Typecheck 3
if ($LASTEXITCODE -ne 0) { throw "input-test: build failed" }

Stop-MonkeyDo
Stop-Simulator
Start-Sleep -Seconds 1
Start-SimulatorIfNeeded | Out-Null

$prg = Join-Path $RepoRoot "bin\pacer-$Device.prg"

# Back now exits the app outright when touch is unlocked, so verifying that
# needs a second, throwaway app instance -- the first one has to survive every
# other check. Each phase gets a fresh launch and a fresh trace.
function Start-App {
    Remove-Item $trace, $errLog -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath $MonkeyDo -ArgumentList @($prg, $Device) -WindowStyle Hidden `
        -RedirectStandardOutput $trace -RedirectStandardError $errLog | Out-Null
    Start-Sleep -Seconds $SettleSec
}

function Test-AppRunning {
    $null -ne (Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'MonkeyDoDeux' })
}

Start-App

# --- harness ------------------------------------------------------------------
$script:failures = 0
$script:checks = 0

function Lines { @(Get-Content $trace -ErrorAction SilentlyContinue | Select-String '\[input\]') }

function Check {
    param(
        [string]$Name,
        [scriptblock]$Do,
        [string]$Expect,
        [switch]$ExpectNothing,
        [switch]$AllowNothing,
        [int]$Attempts = 3
    )

    # SetForegroundWindow is best-effort on Windows, so an injected click can
    # occasionally be lost while focus changes. Retry only when absolutely no
    # event arrived; an unexpected event may have changed app state and must be
    # reported as-is. Checks expecting silence run exactly once.
    $maxAttempts = if ($ExpectNothing) { 1 } else { $Attempts }
    $joined = ""
    $ok = $false

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $before = (Lines).Count
        & $Do | Out-Null
        Start-Sleep -Milliseconds 1500
        $new = (Lines) | Select-Object -Skip $before
        $joined = ($new -join ' | ')
        $ok = if ($ExpectNothing) {
            $new.Count -eq 0
        } else {
            ($AllowNothing -and $new.Count -eq 0) -or ($joined -match $Expect)
        }

        if ($ok -or $new.Count -ne 0) { break }
        if ($attempt -lt $maxAttempts) {
            Write-Host ("  RETRY {0,-22} no input event ({1}/{2})" -f $Name, $attempt, $maxAttempts) -ForegroundColor Yellow
        }
    }

    $script:checks++

    if ($ok) {
        Write-Host ("  PASS  {0,-22} {1}" -f $Name, $(if ($joined) { $joined } else { "(no events)" })) -ForegroundColor Green
    } else {
        Write-Host ("  FAIL  {0,-22} expected {1}" -f $Name, $(if ($ExpectNothing) { "no events" } else { "/$Expect/" })) -ForegroundColor Red
        Write-Host ("        got: {0}" -f $(if ($joined) { $joined } else { "(no events)" })) -ForegroundColor Red
        $script:failures++
    }
}

# Hashtable splatting, not array: an array splat passes its elements
# POSITIONALLY, so @('-Action','tap') binds the literal string "-Action" as the
# value of -Action and fails ValidateSet.
function Inject { param([hashtable]$a) & "$PSScriptRoot\..\tools\input.ps1" @a -Device $Device }

Write-Host ""
Write-Host "input behaviour on $Device" -ForegroundColor Cyan
Write-Host "touch starts enabled; upper button opts into the master lock" -ForegroundColor Cyan

# Teardown must run even when a check throws, or the surviving simulator blocks
# the calling shell and the run looks like a hang.
try {

    # The editor starts unlocked. Every setting is changed directly through its
    # edge controls; tapping the centre text is intentionally inert.
    Check "pace plus"       { Inject @{ Action='tap'; X=335; Y=132 } }              'onSelect from tap -> awaiting coordinates.*tap pace \+'
    Check "strength minus"  { Inject @{ Action='tap'; X=55;  Y=204 } }              'onSelect from tap -> awaiting coordinates.*tap strength -'
    Check "length plus"     { Inject @{ Action='tap'; X=335; Y=276 } }              'onSelect from tap -> awaiting coordinates.*tap length \+'
    Check "tap value"       { Inject @{ Action='tap'; X=195; Y=204 } }              'onSelect from tap -> awaiting coordinates.*tap outside controls -> ignored'

    # A right-swipe must not reach onBack or exit the app.
    Check "swipe right" { Inject @{ Action='swipe'; Target='right' } }              'onBack from swipe -> swallowed' -AllowNothing

    Check "swipe up"   { Inject @{ Action='swipe'; Target='up' } }                  'onNextPage -> swallowed' -AllowNothing
    Check "swipe down" { Inject @{ Action='swipe'; Target='down' } }                'onPreviousPage -> swallowed' -AllowNothing

    # Left swipe is unmapped on this device and should produce nothing at all.
    Check "swipe left" { Inject @{ Action='swipe'; Target='left' } } -ExpectNothing

    # Holding the lower button no longer opens another screen.
    Check "hold menu"      { Inject @{ Action='hold'; Target='menu' } }              'onMenu -> swallowed'

    # The upper physical button opts into the palm-safe master lock. Everything
    # above had to run first: the simulator accepts disabling touch but rejects
    # re-enabling it, so this run is locked from here on.
    Check "lock touch"      { Inject @{ Action='press'; Target='enter' } }           'upper button -> touch locked'

    # Real firmware should suppress the callback. The simulator may still send
    # the behavior phase, in which case the logical lock must swallow it before
    # the coordinate-bearing callback can change data.
    Check "tap while locked" { Inject @{ Action='tap'; X=335; Y=132 } }             'onSelect while locked -> swallowed' -AllowNothing

    # Back while locked unlocks instead of exiting -- Pacer must never leave the
    # watch-global touch setting disabled behind it. The simulator rejects the
    # restore, so what is proved here is the safe failure: still open, still
    # locked. On a watch the restore succeeds and a second Back then exits.
    Check "back while locked" { Inject @{ Action='press'; Target='esc' } }          'onBack from lower button -> (touch unlocked, press again to exit|unlock failed, staying open)'

    # The upper button is always available to unlock too.
    Check "unlock touch"    { Inject @{ Action='press'; Target='enter' } }           'upper button -> (touch unlocked|unlock failed)'

    Write-Host ""
    Write-Host "phase 2: a fresh instance, to watch Back actually exit" -ForegroundColor Cyan

    # The checks above have to keep the app alive, so the exit path needs its own
    # throwaway instance. A fresh instance always starts unlocked, which is
    # exactly the state in which Back is allowed to exit. The old four-second
    # confirmation could never be tested this far: the simulator's rejected
    # restore meant the app never reached the exit at all.
    Stop-MonkeyDo
    Start-Sleep -Seconds 1
    Start-App

    Check "back exits when unlocked" { Inject @{ Action='press'; Target='esc' } }   'onBack from lower button -> touch already on, app exits'

    $script:checks++
    Start-Sleep -Seconds 2
    if (Test-AppRunning) {
        Write-Host ("  FAIL  {0,-22} the app is still running after Back" -f "app really exited") -ForegroundColor Red
        $script:failures++
    } else {
        Write-Host ("  PASS  {0,-22} process is gone" -f "app really exited") -ForegroundColor Green
    }
}
finally {
    Stop-MonkeyDo
    Stop-Simulator
}

Write-Host ""
if ($script:failures -gt 0) {
    Write-Host "INPUT TESTS FAILED  ($script:failures of $script:checks)" -ForegroundColor Red
    exit 1
}
Write-Host "INPUT TESTS PASSED  ($script:checks checks)" -ForegroundColor Green
exit 0
