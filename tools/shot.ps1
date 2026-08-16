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
    [switch]$Release
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
& "$PSScriptRoot\build.ps1" -Device $Device -Typecheck $Typecheck -Release:$Release
if ($LASTEXITCODE -ne 0) { throw "shot: build failed" }

$prg = Join-Path $RepoRoot "bin\pacer-$Device.prg"

Start-SimulatorIfNeeded | Out-Null

Write-Host "==> monkeydo $(Split-Path -Leaf $prg) $Device" -ForegroundColor Cyan
# monkeydo holds the connection open for as long as the app runs, so it must be
# launched detached with its output redirected and killed once the frame is
# captured. Left attached with -NoNewWindow it keeps the console handle open and
# the caller (just) hangs forever even though the capture already succeeded.
$doProc = Start-Process -FilePath $MonkeyDo -ArgumentList @($prg, $Device) `
    -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $env:TEMP "pacer-shot-out.txt") `
    -RedirectStandardError  (Join-Path $env:TEMP "pacer-shot-err.txt")
Start-Sleep -Seconds $SettleSec

# --- capture ------------------------------------------------------------------
$sim = Get-Process simulator -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $sim) { throw "shot: no simulator window to capture" }
$hwnd = $sim.MainWindowHandle

[void][Win32ShotApi]::SetForegroundWindow($hwnd)
Start-Sleep -Milliseconds 800

$rect = New-Object Win32ShotApi+RECT
if (-not [Win32ShotApi]::GetWindowRect($hwnd, [ref]$rect)) { throw "shot: GetWindowRect failed" }
$w = $rect.Right - $rect.Left
$h = $rect.Bottom - $rect.Top
if ($w -le 0 -or $h -le 0) { throw "shot: simulator window has no size ($w x $h)" }

$bmp = New-Object System.Drawing.Bitmap $w, $h
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $gfx.GetHdc()
$ok = [Win32ShotApi]::PrintWindow($hwnd, $hdc, 2)   # 2 = PW_RENDERFULLCONTENT
$gfx.ReleaseHdc($hdc)
$gfx.Dispose()

if (-not $ok) { $bmp.Dispose(); throw "shot: PrintWindow failed for hwnd $hwnd" }

$shotDir = Join-Path $RepoRoot "shots"
New-Item -ItemType Directory -Path $shotDir -Force | Out-Null
$path = Join-Path $shotDir "$Device.png"
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
