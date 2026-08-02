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

Remove-Item $trace, $errLog -Force -ErrorAction SilentlyContinue
$prg = Join-Path $RepoRoot "bin\pacer-$Device.prg"
Start-Process -FilePath $MonkeyDo -ArgumentList @($prg, $Device) -WindowStyle Hidden `
    -RedirectStandardOutput $trace -RedirectStandardError $errLog | Out-Null
Start-Sleep -Seconds $SettleSec

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

# The vivoactive 5 simulator is inconsistent: it acknowledges disabling touch
# but may still deliver touch behaviors. Accept either safe result--no event at
# all, or the delegate's consumed fallback--and keep the distinction visible.
$touchConfigured = ((Lines) -join ' | ') -match 'touch enabled=false success=true'

function TouchCheck {
    param([string]$Name, [scriptblock]$Do, [string]$FallbackExpect = "")

    if ($FallbackExpect -eq "") {
        Check $Name $Do -ExpectNothing
    } elseif ($touchConfigured) {
        Check $Name $Do $FallbackExpect -AllowNothing
    } else {
        Check $Name $Do $FallbackExpect
    }
}

Write-Host ""
Write-Host "input behaviour on $Device" -ForegroundColor Cyan
Write-Host ("touch gate: {0}" -f $(if ($touchConfigured) { "master acknowledged; safe fallback also accepted" } else { "simulator rejected; testing delegate fallback" })) -ForegroundColor Cyan

# Teardown must run even when a check throws, or the surviving simulator blocks
# the calling shell and the run looks like a hang.
try {

    # The main View disables touch at the source. No touch behavior or raw touch
    # callback should reach the delegate at all.
    TouchCheck "tap centre"     { Inject @{ Action='tap' } }                        'onSelect from tap -> swallowed'
    TouchCheck "tap off-centre" { Inject @{ Action='tap'; X=120; Y=300 } }          'onSelect from tap -> swallowed'

    # The upper physical button is the way into settings.
    Check "press enter"    { Inject @{ Action='press'; Target='enter' } }           'onSelect from upper button -> settings'

    # Back out of the menu that just opened so later checks run on the main screen.
    Inject @{ Action='press'; Target='esc' } | Out-Null
    Start-Sleep -Milliseconds 1500

    # A right-swipe must not reach onBack or exit the app.
    TouchCheck "swipe right" { Inject @{ Action='swipe'; Target='right' } }         'onBack from swipe -> swallowed'

    # Prove the app survived the swipe using the physical upper button, then
    # return from the menu for the remaining checks.
    Check "button after swipe" { Inject @{ Action='press'; Target='enter' } }        'onSelect from upper button -> settings'
    Inject @{ Action='press'; Target='esc' } | Out-Null
    Start-Sleep -Milliseconds 1500

    TouchCheck "swipe up"   { Inject @{ Action='swipe'; Target='up' } }             'onNextPage -> swallowed'
    TouchCheck "swipe down" { Inject @{ Action='swipe'; Target='down' } }           'onPreviousPage -> swallowed'

    # Left swipe is unmapped on this device and should produce nothing at all.
    TouchCheck "swipe left" { Inject @{ Action='swipe'; Target='left' } }

    # Holding the lower button is the menu behaviour.
    Check "hold menu"      { Inject @{ Action='hold'; Target='menu' } }             'onMenu -> settings'

    # Leave the menu and verify touch was disabled again when the main View was
    # restored.
    Inject @{ Action='press'; Target='esc' } | Out-Null
    Start-Sleep -Milliseconds 1500
    TouchCheck "swipe after menu" { Inject @{ Action='swipe'; Target='right' } }    'onBack from swipe -> swallowed'

    # A short press of the lower button is a real Back that the app declines so
    # the system can exit it.
    Check "press esc"      { Inject @{ Action='press'; Target='esc' } }             'onBack from lower button -> declined'
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
