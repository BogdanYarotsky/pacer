# Run the app in the simulator and capture the simulator window to shots/<device>.png.
#
# Uses Win32 PrintWindow rather than a screen-region grab so the capture works
# even when the simulator is not the foreground window. PW_RENDERFULLCONTENT (2)
# is required -- the simulator draws through a composited surface that a plain
# PrintWindow(0) call captures as a blank white rectangle.

#
# CLEANUP MATTERS. Both monkeydo and the simulator outlive their work and block
# the calling shell until they are stopped, so this recipe tears both down once
# the frame is captured. Without that, `just shot` appears to hang for minutes
# with the PNG already written to disk. See the notes in env.ps1.
#
# Pass -KeepSim to leave the simulator up (handy when iterating by eye), but be
# aware the command will not return until you close it.

param(
    [string]$Device = "vivoactive5",
    [ValidateRange(0, 3)][int]$Typecheck = 3,
    [int]$SettleSec = 6,
    [switch]$KeepSim,
    # Shoot the RELEASE build (monkeyc -r). Anything behind a (:release)
    # annotation is invisible in every other way we have: unit tests compile
    # with -t, which is a debug build, so this is the only way to see what a
    # Store install actually draws.
    [switch]$Release,
    # Shoot the SETTINGS screen instead of the main one, by pressing the upper
    # button before the capture -- which is the only way to reach it, because
    # nothing on the glass navigates (ADR-0036). Writes <device>-settings.png so
    # it never overwrites the main shot; the listing wants both.
    #
    # The press goes through tools/input.ps1 rather than a second copy of the
    # Win32 click code. That script owns the mapping from a key id to a screen
    # position, reading the device config for it, and a duplicate here would be
    # a second thing to fix when the simulator's chrome changes.
    #
    # It briefly takes the mouse pointer, exactly as `just input-test` does.
    [switch]$Settings,
    # Photograph the simulator that is ALREADY running, exactly as it stands:
    # no build, no launch, no button press, and no teardown afterwards.
    #
    # This is the escape hatch for everything the simulator can only be told
    # through its own GUI. Battery level and the clock live in its Simulation
    # menu (shortcut `m`), are not persisted in simulator.ini, and cannot be set
    # from a script -- and every other mode here kills and relaunches the
    # simulator, which throws away anything set by hand before the shutter
    # opens. So: drive it yourself with `just sim`, set what you want, then take
    # the picture with this.
    #
    # Safe for listing shots because a debug build now draws pixel-identical to
    # a release one: since ADR-0037 the only annotated code left is the
    # delegate's trace, which writes to the console and not the glass.
    [switch]$CaptureOnly,
    # Output basename, without .png. Defaults to the device name.
    [string]$Name = ""
)

. "$PSScriptRoot\env.ps1"

Add-Type -AssemblyName System.Drawing

if (-not ("Win32ShotApi" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32ShotApi {
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
}

# --- build + launch -----------------------------------------------------------
if ($CaptureOnly) {
    if (-not (Get-Process simulator -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })) {
        throw ("shot: -CaptureOnly photographs a simulator that is already running, " +
            "and there is none. Start one with 'just sim', set up the screen you " +
            "want, then run this.")
    }
    Write-Host "==> capturing the running simulator as it stands (no build, no launch)" -ForegroundColor Cyan
} else {

& "$PSScriptRoot\build.ps1" -Device $Device -Typecheck $Typecheck -Release:$Release
if ($LASTEXITCODE -ne 0) { throw "shot: build failed" }

$prg = Join-Path $RepoRoot "bin\candle-$Device.prg"

Start-SimulatorIfNeeded | Out-Null

Write-Host "==> monkeydo $(Split-Path -Leaf $prg) $Device" -ForegroundColor Cyan
# monkeydo holds the connection open for as long as the app runs, so it must be
# launched detached with its output redirected and killed once the frame is
# captured. Left attached with -NoNewWindow it keeps the console handle open and
# the caller (just) hangs forever even though the capture already succeeded.
$doProc = Start-Process -FilePath $MonkeyDo -ArgumentList @($prg, $Device) `
    -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $env:TEMP "candle-shot-out.txt") `
    -RedirectStandardError  (Join-Path $env:TEMP "candle-shot-err.txt")
Start-Sleep -Seconds $SettleSec

}   # end of the build-and-launch branch

function Capture-Simulator {
    $sim = Get-Process simulator -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if (-not $sim) { throw "shot: no simulator window to capture" }
    $hwnd = $sim.MainWindowHandle

    [void][Win32ShotApi]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 800

    $rect = New-Object Win32ShotApi+RECT
    if (-not [Win32ShotApi]::GetWindowRect($hwnd, [ref]$rect)) { throw "shot: GetWindowRect failed" }
    $cw = $rect.Right - $rect.Left
    $ch = $rect.Bottom - $rect.Top
    if ($cw -le 0 -or $ch -le 0) { throw "shot: simulator window has no size ($cw x $ch)" }

    $b = New-Object System.Drawing.Bitmap $cw, $ch
    $gfx = [System.Drawing.Graphics]::FromImage($b)
    $hdc = $gfx.GetHdc()
    $ok = [Win32ShotApi]::PrintWindow($hwnd, $hdc, 2)   # 2 = PW_RENDERFULLCONTENT
    $gfx.ReleaseHdc($hdc)
    $gfx.Dispose()
    if (-not $ok) { $b.Dispose(); throw "shot: PrintWindow failed for hwnd $hwnd" }
    return $b
}

# Did the screen actually CHANGE? -- i.e. did the press land, or is this the
# main screen about to be saved under a -settings filename?
#
# THIS CHECK EXISTS BECAUSE THE SILENT FAILURE HAPPENED, twice. A press that
# does not register produces a perfectly good capture of the wrong screen, under
# the right name, and one reached a store-listing folder before anyone looked.
#
# It compares the frame against the one taken before the press, and asks nothing
# about what is drawn. The first attempt at this DID ask -- it looked for the
# flame's amber, on the reasoning that every string is white on black -- and it
# passed a main-screen capture on the first run, because the simulator's own
# status bar has an amber sun in it, outside the watch face entirely. A test
# that needs to know which pixels are "the watch" needs the device geometry, and
# a test that needs a colour needs that colour to stay unique. Difference needs
# neither.
#
# The threshold is what separates a screen change from the clock advancing a
# digit: main -> settings repaints nearly the whole face, a minute rolling over
# moves a few hundred pixels. Sampled on a stride, because precision here buys
# nothing.
function Measure-FrameDifference([System.Drawing.Bitmap]$a, [System.Drawing.Bitmap]$b) {
    if ($a.Width -ne $b.Width -or $a.Height -ne $b.Height) { return 1.0 }
    $differing = 0
    $sampled = 0
    for ($y = 0; $y -lt $a.Height; $y += 3) {
        for ($x = 0; $x -lt $a.Width; $x += 3) {
            $sampled += 1
            $pa = $a.GetPixel($x, $y)
            $pb = $b.GetPixel($x, $y)
            if ([Math]::Abs($pa.R - $pb.R) + [Math]::Abs($pa.G - $pb.G) +
                [Math]::Abs($pa.B - $pb.B) -gt 60) {
                $differing += 1
            }
        }
    }
    if ($sampled -eq 0) { return 0.0 }
    return $differing / [double]$sampled
}

# 2% of sampled pixels. A screen change moves far more than that; a clock digit
# and the battery arc move far less.
$script:ChangedFraction = 0.02

# --- capture ------------------------------------------------------------------
if ($Settings) {
    # The push animates (SLIDE_LEFT); capturing mid-slide gives a smeared frame
    # with both screens on it, which is not a thing any wearer ever sees.
    #
    # Retrying is only sound because the frame is CHECKED first: a blind second
    # press would close the screen the first one opened. Every press here
    # follows a capture that proved we are still on the main screen.
    $before = Capture-Simulator
    $bmp = $null
    $changed = 0.0

    for ($attempt = 1; $attempt -le 3; $attempt += 1) {
        Write-Host "==> pressing the upper button (attempt $attempt)" -ForegroundColor Cyan
        & "$PSScriptRoot\input.ps1" -Action press -Target enter -Device $Device
        if ($LASTEXITCODE -ne 0) { throw "shot: could not press the upper button" }
        Start-Sleep -Milliseconds 1500

        if ($null -ne $bmp) { $bmp.Dispose() }
        $bmp = Capture-Simulator
        $changed = Measure-FrameDifference $before $bmp
        if ($changed -ge $script:ChangedFraction) {
            Write-Host ("    screen changed ({0:P1} of sampled pixels) -- settings screen reached" -f $changed) -ForegroundColor DarkGray
            break
        }
        Write-Host ("    screen unchanged ({0:P1}) -- the press did not register" -f $changed) -ForegroundColor Yellow
    }

    $before.Dispose()
    if ($changed -lt $script:ChangedFraction) {
        $bmp.Dispose()
        Stop-MonkeyDo
        if (-not $KeepSim) { Stop-Simulator }
        throw ("shot: the screen never changed after 3 presses. NOTHING was written -- " +
            "a capture of the main screen under a -settings name is worse than no " +
            "capture, and has happened. Re-run when the machine is idle; this steals " +
            "the pointer and loses to anything else using it.")
    }
} else {
    $bmp = Capture-Simulator
}

$w = $bmp.Width
$h = $bmp.Height

$shotDir = Join-Path $RepoRoot "shots"
New-Item -ItemType Directory -Path $shotDir -Force | Out-Null
$name = if ($Name -ne "") { "$Name.png" } elseif ($Settings) { "$Device-settings.png" } else { "$Device.png" }
$path = Join-Path $shotDir $name
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# --- clean up every process this script started -------------------------------
Stop-MonkeyDo

if (-not $KeepSim) { Stop-Simulator }

$len = (Get-Item $path).Length
Write-Host "wrote $path  ($w x $h, $([math]::Round($len/1KB,1)) KB)" -ForegroundColor Green
if ($len -lt 5KB) {
    Write-Host "WARNING: the capture is suspiciously small and may be blank." -ForegroundColor Yellow
}
