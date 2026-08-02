# Drive real input into the Connect IQ simulator: taps, swipes and physical
# button presses. This is what makes input behaviour testable instead of
# inferred -- the simulator only accepts these through its GUI, so they are
# synthesised as actual mouse events.
#
# Geometry is read from the device's own simulator.json, so this works for any
# installed device, not just the vivoactive 5:
#   display.location  where the round screen sits inside the device bitmap
#   keys[].location   where each physical button sits, plus its behavior
#
# Commands:
#   probe                    report window/geometry mapping, click nothing
#   tap <x> <y>              tap at DISPLAY coords (0..389 for vivoactive5)
#   press <enter|esc|menu>   click a physical button
#   hold  <enter|esc|menu>   press and hold (lower button held == onMenu)
#   swipe <right|left|up|down>
#
# Swipe tuning also comes from the device config. On the vivoactive 5:
#   swipeRight -> onBack, but ONLY when the swipe starts within maxDistToEdge
#   (81px) of the edge, travels more than minSwipeDeltaX (78px), and completes
#   inside maxSwipeDuration (250ms). Miss any of those and it is not a Back.

param(
    [Parameter(Mandatory = $true)][ValidateSet('probe','tap','press','hold','swipe')][string]$Action,
    [string]$Target = "",
    [int]$X = -1,
    [int]$Y = -1,
    [string]$Device = "vivoactive5"
)

# Deliberately does NOT dot-source env.ps1: driving the simulator needs neither
# a JDK nor the SDK, only the device config and a running simulator window.
$ErrorActionPreference = "Stop"

if (-not ("Win32Input" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Input {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    public const uint LEFTDOWN = 0x0002, LEFTUP = 0x0004;
}
"@
}

# --- device geometry ----------------------------------------------------------
$cfgPath = Join-Path $env:APPDATA "Garmin\ConnectIQ\Devices\$Device\simulator.json"
if (-not (Test-Path $cfgPath)) { throw "input: no simulator.json for '$Device'. Run: connect-iq-sdk-manager device download --manifest manifest.xml --include-fonts" }
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$disp = $cfg.display.location

# --- locate the simulator window ----------------------------------------------
$sim = Get-Process simulator -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $sim) { throw "input: the simulator is not running. Start it with `just sim` or tools/test.ps1 first." }
$hwnd = $sim.MainWindowHandle

[void][Win32Input]::SetForegroundWindow($hwnd)
Start-Sleep -Milliseconds 400

$rc = New-Object Win32Input+RECT
if (-not [Win32Input]::GetClientRect($hwnd, [ref]$rc)) { throw "input: GetClientRect failed" }
$origin = New-Object Win32Input+POINT
if (-not [Win32Input]::ClientToScreen($hwnd, [ref]$origin)) { throw "input: ClientToScreen failed" }

$clientW = $rc.Right - $rc.Left
$clientH = $rc.Bottom - $rc.Top

# The device bitmap is drawn at the client origin. The client area is taller than
# the bitmap because the menu bar is part of it, so the bitmap is bottom-aligned
# against the status bar; measure the offset rather than assuming zero.
Add-Type -AssemblyName System.Drawing
$png = [System.Drawing.Image]::FromFile((Join-Path $env:APPDATA "Garmin\ConnectIQ\Devices\$Device\$Device.png"))
$imgW = $png.Width; $imgH = $png.Height
$png.Dispose()

$offsetX = [int](($clientW - $imgW) / 2)
$offsetY = [int]($clientH - $imgH)      # bitmap sits below the menu bar
if ($offsetY -lt 0) { $offsetY = 0 }
if ($offsetX -lt 0) { $offsetX = 0 }

function ImageToScreen([int]$ix, [int]$iy) {
    return @{ X = $origin.X + $offsetX + $ix; Y = $origin.Y + $offsetY + $iy }
}
function DisplayToScreen([int]$dx, [int]$dy) {
    return ImageToScreen ($disp.x + $dx) ($disp.y + $dy)
}
function KeyCenter([string]$id) {
    $k = $cfg.keys | Where-Object { $_.id -eq $id } | Select-Object -First 1
    if (-not $k) { throw "input: '$id' is not a key on $Device. Available: $(($cfg.keys | ForEach-Object { $_.id }) -join ', ')" }
    return ImageToScreen ($k.location.x + [int]($k.location.width / 2)) ($k.location.y + [int]($k.location.height / 2))
}

function Click([hashtable]$p, [int]$holdMs = 40) {
    [void][Win32Input]::SetCursorPos($p.X, $p.Y)
    Start-Sleep -Milliseconds 60
    [Win32Input]::mouse_event([Win32Input]::LEFTDOWN, 0, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds $holdMs
    [Win32Input]::mouse_event([Win32Input]::LEFTUP, 0, 0, 0, [IntPtr]::Zero)
}

switch ($Action) {

    'probe' {
        Write-Host "simulator hwnd   : $hwnd"
        Write-Host "client origin    : $($origin.X),$($origin.Y)   size ${clientW}x${clientH}"
        Write-Host "device bitmap    : ${imgW}x${imgH}   offset in client: $offsetX,$offsetY"
        Write-Host "display in image : $($disp.x),$($disp.y)  $($disp.width)x$($disp.height)"
        $c = DisplayToScreen ([int]($disp.width / 2)) ([int]($disp.height / 2))
        Write-Host "display centre   -> screen $($c.X),$($c.Y)"
        foreach ($k in $cfg.keys) {
            $p = KeyCenter $k.id
            Write-Host ("key {0,-6} ({1,-12}) -> screen {2},{3}" -f $k.id, $k.behavior, $p.X, $p.Y)
        }
    }

    'tap' {
        if ($X -lt 0 -or $Y -lt 0) { $X = [int]($disp.width / 2); $Y = [int]($disp.height / 2) }
        $p = DisplayToScreen $X $Y
        Write-Host "tap display($X,$Y) -> screen $($p.X),$($p.Y)"
        Click $p
    }

    'press' {
        if ($Target -eq "") { throw "input: press needs a key id (enter|esc|menu)" }
        $p = KeyCenter $Target
        Write-Host "press '$Target' -> screen $($p.X),$($p.Y)"
        Click $p
    }

    'hold' {
        if ($Target -eq "") { throw "input: hold needs a key id (enter|esc|menu)" }
        $p = KeyCenter $Target
        Write-Host "hold '$Target' 1200ms -> screen $($p.X),$($p.Y)"
        Click $p 1200
    }

    'swipe' {
        if ($Target -eq "") { $Target = "right" }

        # Pull the real thresholds for this gesture out of the device config so
        # the synthesised swipe is one the firmware will actually recognise.
        $gestureName = "swipe" + $Target.Substring(0,1).ToUpper() + $Target.Substring(1)
        $g = $cfg.display.behaviors | Where-Object { $_.gesture -eq $gestureName } | Select-Object -First 1
        $minDx = if ($g -and $g.minSwipeDeltaX) { [int]$g.minSwipeDeltaX } else { 78 }
        $edge  = if ($g -and $g.maxDistToEdge)  { [int]$g.maxDistToEdge }  else { 81 }
        $maxMs = if ($g -and $g.maxSwipeDuration) { [int]$g.maxSwipeDuration } else { 250 }
        $travel = $minDx + 60
        $mid = [int]($disp.width / 2)

        switch ($Target) {
            'right' { $sx = [int]($edge / 2);            $sy = $mid; $ex = $sx + $travel; $ey = $mid }
            'left'  { $sx = $disp.width - [int]($edge/2); $sy = $mid; $ex = $sx - $travel; $ey = $mid }
            'up'    { $sx = $mid; $sy = $disp.height - [int]($edge/2); $ex = $mid; $ey = $sy - $travel }
            'down'  { $sx = $mid; $sy = [int]($edge / 2);              $ex = $mid; $ey = $sy + $travel }
        }

        $a = DisplayToScreen $sx $sy
        $b = DisplayToScreen $ex $ey
        Write-Host "swipe $Target : display($sx,$sy)->($ex,$ey)  screen($($a.X),$($a.Y))->($($b.X),$($b.Y))  under ${maxMs}ms"

        [void][Win32Input]::SetCursorPos($a.X, $a.Y)
        Start-Sleep -Milliseconds 80
        [Win32Input]::mouse_event([Win32Input]::LEFTDOWN, 0, 0, 0, [IntPtr]::Zero)

        $steps = 8
        $perStep = [Math]::Max(1, [int](($maxMs - 80) / $steps))
        for ($i = 1; $i -le $steps; $i++) {
            $ix = $a.X + [int]((($b.X - $a.X) * $i) / $steps)
            $iy = $a.Y + [int]((($b.Y - $a.Y) * $i) / $steps)
            [void][Win32Input]::SetCursorPos($ix, $iy)
            Start-Sleep -Milliseconds $perStep
        }
        [Win32Input]::mouse_event([Win32Input]::LEFTUP, 0, 0, 0, [IntPtr]::Zero)
    }
}
