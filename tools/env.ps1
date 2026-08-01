# Dot-sourced by every other script in tools/. Resolves the toolchain and fails
# loudly with an actionable message rather than letting a later step die obscurely.
#
# Defines: $SdkRoot $SdkBin $MonkeyC $MonkeyDo $ConnectIQ $DevKey $RepoRoot $Products

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

# --- java ---------------------------------------------------------------------
# monkeyc.bat shells out to bare `java`, so it must be on PATH, not just JAVA_HOME.
if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
    if ($env:Path -notlike "*$env:JAVA_HOME\bin*") { $env:Path = "$env:JAVA_HOME\bin;$env:Path" }
}
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "java not found. Set JAVA_HOME or put java on PATH. Expected JDK 21 (Temurin) at %USERPROFILE%\.jdks."
}

# --- SDK ----------------------------------------------------------------------
# connect-iq-sdk-manager is the source of truth for which SDK is pinned.
$mgr = Get-Command connect-iq-sdk-manager -ErrorAction SilentlyContinue
if (-not $mgr) {
    $candidate = "$env:USERPROFILE\bin\connect-iq-sdk-manager.exe"
    if (Test-Path $candidate) { $mgr = $candidate } else {
        throw "connect-iq-sdk-manager not found. Run ~/bin/garmin-bootstrap.ps1 first."
    }
}
$SdkBin = (& $mgr sdk current-path --bin 2>$null | Out-String).Trim()
if (-not $SdkBin -or -not (Test-Path $SdkBin)) {
    throw "No active Connect IQ SDK. Run: connect-iq-sdk-manager sdk set 9.2.0"
}
$SdkRoot = Split-Path -Parent $SdkBin

$MonkeyC   = Join-Path $SdkBin "monkeyc.bat"
$MonkeyDo  = Join-Path $SdkBin "monkeydo.bat"
$ConnectIQ = Join-Path $SdkBin "connectiq.bat"
foreach ($t in @($MonkeyC, $MonkeyDo, $ConnectIQ)) {
    if (-not (Test-Path $t)) { throw "Missing SDK tool: $t" }
}

# --- signing key --------------------------------------------------------------
# Machine-level and shared across every Connect IQ app. Never project-local.
$DevKey = $env:GARMIN_DEVELOPER_KEY
if (-not $DevKey) {
    throw "GARMIN_DEVELOPER_KEY is not set. It should point at %USERPROFILE%\.garmin-keys\developer_key.der"
}
if (-not (Test-Path $DevKey)) {
    throw "Developer key not found at GARMIN_DEVELOPER_KEY=$DevKey"
}

# --- simulator ----------------------------------------------------------------
# Start the simulator ONLY via this helper.
#
# A SURVIVING SIMULATOR BLOCKS THE CALLER.
#
# The simulator never exits on its own, and while it is alive the shell that
# started it does not return -- so an automated recipe looks like it has hung
# long after its real work finished (the PNG is on disk, the tests have already
# reported PASSED). Measured: `just shot` sat for 218s with the script complete,
# and returned the instant the simulator was killed.
#
# Launch flags do not fix this. Redirecting the standard handles makes it worse
# (a redirect forces UseShellExecute off, so the child inherits this shell's
# handles); -WindowStyle Minimized alone does not help either. The only reliable
# rule is: whoever starts the simulator must stop it. Non-interactive recipes
# therefore tear it down; `just sim` is the interactive exception.
function Start-SimulatorIfNeeded {
    param([int]$TimeoutSec = 60)

    if (Get-Process simulator -ErrorAction SilentlyContinue) { return $false }

    Write-Host "==> starting simulator" -ForegroundColor Cyan
    Start-Process -FilePath $ConnectIQ -WindowStyle Minimized | Out-Null

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        Start-Sleep -Milliseconds 500
        $sim = Get-Process simulator -ErrorAction SilentlyContinue |
               Where-Object { $_.MainWindowHandle -ne 0 }
    } while (-not $sim -and (Get-Date) -lt $deadline)

    if (-not $sim) { throw "the Connect IQ simulator did not come up within ${TimeoutSec}s" }
    Start-Sleep -Seconds 2   # the shell port lags the window by a moment
    return $true
}

# monkeydo.bat returns immediately but leaves a java grandchild
# (com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux) alive for as long as the
# app is loaded, which blocks the caller the same way. Match it on its command
# line so unrelated java processes are never touched.
function Stop-Simulator {
    Get-Process simulator -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host "    stopped simulator (pid $($_.Id))" -ForegroundColor DarkGray
    }
}

function Stop-MonkeyDo {
    Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'MonkeyDoDeux' } |
        ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Host "    stopped monkeydo (pid $($_.ProcessId))" -ForegroundColor DarkGray
        }
}

# --- target devices -----------------------------------------------------------
# Parsed from manifest.xml so the device list has exactly one home. Adding a
# product to the manifest is all it takes for all-devices to pick it up.
[xml]$manifest = Get-Content (Join-Path $RepoRoot "manifest.xml")
$Products = @($manifest.manifest.application.products.product | ForEach-Object { $_.id })
if ($Products.Count -eq 0) { throw "No <iq:product> entries found in manifest.xml" }
