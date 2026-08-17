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

$trace = Join-Path $env:TEMP "candle-input-behaviour.txt"
$errLog = Join-Path $env:TEMP "candle-input-behaviour-err.txt"

# --- build + launch -----------------------------------------------------------
& "$PSScriptRoot\..\tools\build.ps1" -Device $Device -Typecheck 3
if ($LASTEXITCODE -ne 0) { throw "input-test: build failed" }

Stop-MonkeyDo
Stop-Simulator
Start-Sleep -Seconds 1
Start-SimulatorIfNeeded | Out-Null

$prg = Join-Path $RepoRoot "bin\candle-$Device.prg"

# Back closes the app, so the exit check runs last and nothing may follow it.
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
Write-Host "the app owns no touch state; Back is the only thing that closes it" -ForegroundColor Cyan

# Teardown must run even when a check throws, or the surviving simulator blocks
# the calling shell and the run looks like a hang.
try {

    # Every setting is changed directly through its edge controls; tapping the
    # centre text is intentionally inert.
    #
    # The rows are EVERY, PULSE, POWER top to bottom, so y=132 is the interval
    # and y=204 the pulse length. The traces name the row, so these checks read
    # exactly as the screen does: a re-ordered screen that still passes them is
    # editing the setting a thumb is actually on.
    Check "every plus"      { Inject @{ Action='tap'; X=335; Y=132 } }              'onSelect from tap -> awaiting coordinates.*tap every \+'
    Check "pulse minus"     { Inject @{ Action='tap'; X=55;  Y=204 } }              'onSelect from tap -> awaiting coordinates.*tap pulse -'
    Check "power plus"      { Inject @{ Action='tap'; X=335; Y=276 } }              'onSelect from tap -> awaiting coordinates.*tap power \+'
    Check "tap value"       { Inject @{ Action='tap'; X=195; Y=204 } }              'onSelect from tap -> awaiting coordinates.*tap outside controls -> ignored'

    # Hold-to-repeat: a held control steps immediately, keeps stepping while
    # held (an 1800ms hold at 200ms per step must show at least two), and the
    # release disarms it. A hold on the inert centre arms nothing.
    Check "hold repeats"    { Inject @{ Action='touchhold'; X=335; Y=132 } }         'onHold -> step and repeat.*tap every \+.*tap every \+.*onRelease -> repeat stopped'
    Check "hold on value"   { Inject @{ Action='touchhold'; X=195; Y=204 } }         'onHold outside controls -> ignored'

    # A right-swipe reaches onBack exactly as the lower button does. This is the
    # one distinction the delegate still has to make, and getting it wrong closes
    # the app on a stray swipe mid-session.
    Check "swipe right" { Inject @{ Action='swipe'; Target='right' } }              'onBack from swipe -> swallowed' -AllowNothing

    Check "swipe up"   { Inject @{ Action='swipe'; Target='up' } }                  'onNextPage -> swallowed' -AllowNothing
    Check "swipe down" { Inject @{ Action='swipe'; Target='down' } }                'onPreviousPage -> swallowed' -AllowNothing

    # Left swipe is unmapped on this device and should produce nothing at all.
    Check "swipe left" { Inject @{ Action='swipe'; Target='left' } } -ExpectNothing

    # Holding the lower button no longer opens another screen.
    Check "hold menu"      { Inject @{ Action='hold'; Target='menu' } }              'onMenu -> swallowed'

    # The upper button lost its only job when the app-level touch lock went; palm
    # safety is the watch's own Lock Screen now. It must still be swallowed rather
    # than fall through to anything else.
    Check "upper button"   { Inject @{ Action='press'; Target='enter' } }            'upper button -> no action'

    # Back closes the app, unconditionally -- so it has to be last, and what
    # follows it is the proof that it really did. There is no state left for it
    # to consult: the whole point of handing the lock to the OS is that Candle has
    # nothing to restore before leaving.
    Check "back exits"     { Inject @{ Action='press'; Target='esc' } }              'onBack from lower button -> app exits'

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
