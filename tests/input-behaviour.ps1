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
#   just input-test              # the default device
#   just input-test fr955        # any product in manifest.xml
#
# NO COORDINATES ARE WRITTEN IN THIS FILE. The delegate prints the geometry it
# decodes taps against, once per screen, as a debug trace:
#
#   [input] map screen 0 width 390 height 390 rows 144,246 edge 104 below 297
#
# and every tap below is aimed by that line -- inside a zone by half its reach,
# on a row's centre line, in the band below the rows. That is what lets one
# script test every glass the app runs on: the numbers used to be typed in here
# for one watch, and a second watch would have needed a second copy of every
# check. ADR-0045

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

# A HELD menu button is the only thing that closes the app, so that check runs
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

# The geometry of one screen, read back from the delegate's own trace. The
# points derived here are the only coordinates any check uses:
#
#   Left / Right  inside the "-" / "+" zone by half the zone's reach
#   Mid           the centre line, where every row is inert
#   Column        inside the "+" column, just past the zone's inner edge -- the
#                 x for a tap that is out of the rows only because of its y
#   Band          a quarter of the way from the bottom of the row block to the
#                 bottom edge: below the rows, and inside the round glass at
#                 the Column x on every glass the design fits
function Get-InputMap([int]$Screen) {
    $line = (Lines) | Where-Object { "$_" -match "\[input\] map screen $Screen " } | Select-Object -Last 1
    if (-not $line) {
        throw "input-test: the app printed no '[input] map screen $Screen' line -- is this a debug build?"
    }
    if ("$line" -notmatch 'width (\d+) height (\d+) rows ([\d,]+) edge (\d+) below (\d+)') {
        throw "input-test: could not parse the map line: $line"
    }
    $w = [int]$Matches[1]
    $h = [int]$Matches[2]
    $edge = [int]$Matches[4]
    $below = [int]$Matches[5]
    return @{
        Width  = $w
        Height = $h
        Rows   = @($Matches[3] -split ',' | ForEach-Object { [int]$_ })
        Left   = [int]($edge / 2)
        Right  = $w - [int]($edge / 2)
        Mid    = [int]($w / 2)
        Column = $w - $edge + 2
        Band   = $below + [int](($h - $below) / 4)
    }
}

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
Write-Host "two screens; Back never exits; a HELD menu button is the only way out" -ForegroundColor Cyan

# Teardown must run even when a check throws, or the surviving simulator blocks
# the calling shell and the run looks like a hang.
try {

    # --- the main screen ------------------------------------------------------
    #
    # Every setting is changed directly through its edge controls; tapping the
    # centre text is intentionally inert.
    #
    # MAIN carries two rows, POWER over BUZZ, centred on the glass. The traces
    # name the row through its own caption, so these checks read exactly as the
    # screen does -- a re-ordered screen that still passes them is editing the
    # setting a thumb is actually on. Re-ordering Rows.forScreen without
    # swapping the captions here is what these lines exist to catch.
    $main = Get-InputMap 0
    Write-Host ("map: {0}x{1}, rows at y={2}, zones reach x<={3} / x>={4}" -f
        $main.Width, $main.Height, ($main.Rows -join ','), ($main.Left * 2), ($main.Width - ($main.Left * 2))) -ForegroundColor DarkGray

    Check "power plus"      { Inject @{ Action='tap'; X=$main.Right; Y=$main.Rows[0] } }   'onSelect from tap -> awaiting coordinates.*tap POWER \+'
    Check "power minus"     { Inject @{ Action='tap'; X=$main.Left;  Y=$main.Rows[0] } }   'onSelect from tap -> awaiting coordinates.*tap POWER -'
    Check "buzz plus"       { Inject @{ Action='tap'; X=$main.Right; Y=$main.Rows[1] } }   'onSelect from tap -> awaiting coordinates.*tap BUZZ \+'
    Check "buzz minus"      { Inject @{ Action='tap'; X=$main.Left;  Y=$main.Rows[1] } }   'onSelect from tap -> awaiting coordinates.*tap BUZZ -'
    Check "tap value"       { Inject @{ Action='tap'; X=$main.Mid;   Y=$main.Rows[1] } }   'onSelect from tap -> awaiting coordinates.*tap outside controls -> ignored'

    # Hold-to-repeat: a held control steps immediately, keeps stepping while
    # held (an 1800ms hold at 200ms per step must show at least two), and the
    # release disarms it. A hold on the inert centre arms nothing.
    Check "hold repeats"    { Inject @{ Action='touchhold'; X=$main.Right; Y=$main.Rows[0] } }   'onHold -> step and repeat.*tap POWER \+.*tap POWER \+.*onRelease -> repeat stopped'
    Check "hold on value"   { Inject @{ Action='touchhold'; X=$main.Mid;   Y=$main.Rows[1] } }   'onHold outside controls -> ignored'

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
    # The upper button pushes it, and the SAME PRESS is the only thing that
    # closes it. ADR-0036 retired the BACK button that used to sit in the bottom
    # band, so nothing on the glass and no gesture pops this screen any more.
    #
    # SETTINGS carries two rows, EVERY over PACE. Its map is read separately
    # rather than reused from the main screen's: both hold two rows today, so
    # the two maps agree, but a screen that grows a third row moves its own
    # rows and nothing else's.
    Check "enter opens"     { Inject @{ Action='press'; Target='enter' } }           'upper button -> settings'
    $settings = Get-InputMap 1

    Check "every plus"      { Inject @{ Action='tap'; X=$settings.Right; Y=$settings.Rows[0] } }   'onSelect from tap -> awaiting coordinates.*tap EVERY \+'
    Check "every minus"     { Inject @{ Action='tap'; X=$settings.Left;  Y=$settings.Rows[0] } }   'onSelect from tap -> awaiting coordinates.*tap EVERY -'
    Check "pace plus"       { Inject @{ Action='tap'; X=$settings.Right; Y=$settings.Rows[1] } }   'onSelect from tap -> awaiting coordinates.*tap PACE \+'
    Check "pace minus"      { Inject @{ Action='tap'; X=$settings.Left;  Y=$settings.Rows[1] } }   'onSelect from tap -> awaiting coordinates.*tap PACE -'
    Check "settings inert"  { Inject @{ Action='tap'; X=$settings.Mid;   Y=[int]($settings.Height / 2) } }   'onSelect from tap -> awaiting coordinates.*tap outside controls -> ignored'

    # The band below the rows was the BACK button until ADR-0036. It is inert
    # now, and a tap there must be ignored rather than pop the screen -- this is
    # the check that would catch the control coming back by accident.
    #
    # The x is inside the "+" column and not on the centre line: only the y
    # puts this tap outside a row, so the check fails if the row block ever
    # grows downward into the band.
    Check "bottom band inert" { Inject @{ Action='tap'; X=$settings.Column; Y=$settings.Band } }   'onSelect from tap -> awaiting coordinates.*tap outside controls -> ignored'

    # A swipe and a pressed lower button both arrive as Back, and this screen
    # swallows both exactly as the main screen does -- same trace, same hint.
    # Each is followed by a running check, because the trace line alone would
    # pass just as well on an app that had died.
    Check "swipe swallowed" { Inject @{ Action='swipe'; Target='right' } }           'onBack -> swallowed, hold to exit' -AllowNothing
    Check-AppRunning "settings swipe kept it" "a swipe on the settings screen must not exit the app"
    Check "back swallowed here" { Inject @{ Action='press'; Target='esc' } }         'onBack -> swallowed, hold to exit'
    Check-AppRunning "settings back kept it" "Back on the settings screen must not exit the app"

    # The button that opened it closes it: a press that opened the screen by
    # accident is undone by the press that follows, and this is now the ONLY
    # way back to the main screen.
    Check "enter closes"    { Inject @{ Action='press'; Target='enter' } }           'upper button -> settings closed'

    # --- the exit ---------------------------------------------------------------
    #
    # THE PHYSICAL BACK BUTTON NO LONGER EXITS. Pressed, it is swallowed exactly
    # like the swipe it cannot be told apart from -- and the app must still be
    # running afterwards, which is the assertion the whole fix rests on.
    Check "back swallowed" { Inject @{ Action='press'; Target='esc' } }              'onBack -> swallowed, hold to exit'
    Check-AppRunning "back kept it alive" "the lower button must not close the app any more"

    # HOLDING the menu button does. onMenu is the one gesture in this whole
    # investigation the firmware has never been caught synthesizing, which is
    # why the only exit hangs on it -- so it has to be last, and nothing may
    # follow it but the process check. Which physical button carries the hold
    # is the device's business (the vívoactive 5's lower button, the Forerunner
    # 955's UP); input.ps1 reads it off the device config as the key named
    # "menu". ADR-0047
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
