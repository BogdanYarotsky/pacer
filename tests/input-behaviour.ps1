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

# A HELD lower button is the only thing that closes the app, so that check runs
# last and nothing may follow it but the process check. A pressed lower button
# and a right swipe are both swallowed now -- they are indistinguishable on real
# hardware, so the delegate stopped pretending otherwise.
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

function Check-AppRunning {
    param([string]$Name, [string]$Why)
    $script:checks++
    if (Test-AppRunning) {
        Write-Host ("  PASS  {0,-22} {1}" -f $Name, $Why) -ForegroundColor Green
    } else {
        Write-Host ("  FAIL  {0,-22} the app is gone, and {1}" -f $Name, $Why) -ForegroundColor Red
        $script:failures++
    }
}

Write-Host ""
Write-Host "input behaviour on $Device" -ForegroundColor Cyan
Write-Host "two screens; Back never exits; a HELD lower button is the only way out" -ForegroundColor Cyan

# Teardown must run even when a check throws, or the surviving simulator blocks
# the calling shell and the run looks like a hang.
try {

    # --- the main screen ------------------------------------------------------
    #
    # Every setting is changed directly through its edge controls; tapping the
    # centre text is intentionally inert.
    #
    # MAIN carries two rows, POWER over PULSE, centred on the glass: y=144 and
    # y=246, with the edge zones out past x=108 / x=282. The traces name the row
    # through its own caption, so these checks read exactly as the screen does --
    # a re-ordered screen that still passes them is editing the setting a thumb
    # is actually on. Re-ordering Rows.forScreen without swapping the captions
    # here is what these lines exist to catch.
    Check "power plus"      { Inject @{ Action='tap'; X=340; Y=144 } }              'onSelect from tap -> awaiting coordinates.*tap POWER \+'
    Check "power minus"     { Inject @{ Action='tap'; X=50;  Y=144 } }              'onSelect from tap -> awaiting coordinates.*tap POWER -'
    Check "pulse plus"      { Inject @{ Action='tap'; X=340; Y=246 } }              'onSelect from tap -> awaiting coordinates.*tap PULSE \+'
    Check "pulse minus"     { Inject @{ Action='tap'; X=50;  Y=246 } }              'onSelect from tap -> awaiting coordinates.*tap PULSE -'
    Check "tap value"       { Inject @{ Action='tap'; X=195; Y=246 } }              'onSelect from tap -> awaiting coordinates.*tap outside controls -> ignored'

    # Hold-to-repeat: a held control steps immediately, keeps stepping while
    # held (an 1800ms hold at 200ms per step must show at least two), and the
    # release disarms it. A hold on the inert centre arms nothing.
    Check "hold repeats"    { Inject @{ Action='touchhold'; X=340; Y=144 } }        'onHold -> step and repeat.*tap POWER \+.*tap POWER \+.*onRelease -> repeat stopped'
    Check "hold on value"   { Inject @{ Action='touchhold'; X=195; Y=246 } }        'onHold outside controls -> ignored'

    # A right-swipe reaches onBack exactly as the lower button does, and on real
    # hardware the firmware synthesizes a KEY_ESC for it -- so the delegate stopped
    # trying to tell them apart and swallows BOTH. Neither can close the app now.
    Check "swipe right" { Inject @{ Action='swipe'; Target='right' } }              'onBack -> swallowed, hold to exit' -AllowNothing

    Check "swipe up"   { Inject @{ Action='swipe'; Target='up' } }                  'onNextPage -> swallowed' -AllowNothing
    Check "swipe down" { Inject @{ Action='swipe'; Target='down' } }                'onPreviousPage -> swallowed' -AllowNothing

    # A left swipe raises NO behaviour event on this device -- but it does raise
    # onSwipe(SWIPE_LEFT), which nothing here implemented until 2026-08-25, so
    # the old "produces nothing at all" reading of it was really "nothing we had
    # a handler for". Declined, so it still changes nothing; it is recorded only
    # to answer whether the wrist raises onSwipe for a RIGHT swipe, which the
    # simulator does not.
    Check "swipe left" { Inject @{ Action='swipe'; Target='left' } }                'onSwipe 3'

    # --- the settings screen --------------------------------------------------
    #
    # The upper button pushes it, and three separate things close it again. Each
    # close is followed by re-opening, so every one of them is exercised from a
    # screen that really is on the stack rather than from wherever the previous
    # check left things.
    #
    # SETTINGS carries one row, so it sits ON the centre line at y=195. That is
    # the whole reason this section cannot reuse the coordinates above: the same
    # row is at a different height on a screen with fewer rows on it.
    Check "enter opens"     { Inject @{ Action='press'; Target='enter' } }           'upper button -> settings'
    Check "settings plus"   { Inject @{ Action='tap'; X=340; Y=195 } }               'onSelect from tap -> awaiting coordinates.*tap EVERY \+'
    Check "settings inert"  { Inject @{ Action='tap'; X=195; Y=195 } }               'onSelect from tap -> awaiting coordinates.*tap outside controls -> ignored'

    # The button that opened it closes it: a press that opened the screen by
    # accident is undone by the press that follows.
    Check "enter closes"    { Inject @{ Action='press'; Target='enter' } }           'upper button -> settings closed'

    # A right-swipe pops it. On MAIN the same gesture is swallowed because it
    # would end a session; here it costs a wearer nothing, so it is allowed to
    # mean what it means everywhere else on the watch.
    Check "reopen for swipe" { Inject @{ Action='press'; Target='enter' } }          'upper button -> settings'
    Check "swipe closes"    { Inject @{ Action='swipe'; Target='right' } }           'onBack on settings -> settings closed'

    # And the lower button pops it WITHOUT closing the app -- which is the whole
    # reason Back needed a second meaning. The running check is the assertion;
    # the trace line alone would pass just as well on an app that died.
    Check "reopen for back" { Inject @{ Action='press'; Target='enter' } }           'upper button -> settings'
    Check "back closes"     { Inject @{ Action='press'; Target='esc' } }             'onBack on settings -> settings closed'
    Check-AppRunning "settings back kept it" "Back on the settings screen must not exit the app"

    # --- the exit ---------------------------------------------------------------
    #
    # THE PHYSICAL LOWER BUTTON NO LONGER EXITS. Pressed, it is swallowed exactly
    # like the swipe it cannot be told apart from -- and the app must still be
    # running afterwards, which is the assertion the whole fix rests on.
    Check "back swallowed" { Inject @{ Action='press'; Target='esc' } }              'onBack -> swallowed, hold to exit'
    Check-AppRunning "back kept it alive" "the lower button must not close the app any more"

    # HOLDING it does. onMenu is the one gesture in this whole investigation the
    # firmware has never been caught synthesizing, which is why the only exit
    # hangs on it -- so it has to be last, and nothing may follow it but the
    # process check.
    Check "hold exits"     { Inject @{ Action='hold'; Target='menu' } }              'onMenu -> app exits'

    $script:checks++
    Start-Sleep -Seconds 2
    if (Test-AppRunning) {
        Write-Host ("  FAIL  {0,-22} the app is still running after the hold" -f "app really exited") -ForegroundColor Red
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
