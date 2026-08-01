# Compile pacer for one or all target devices.
#
#   -Device      device id, or "all" to build every product in manifest.xml
#   -Typecheck   0=off 1=gradual 2=informative 3=strict   (monkeyc -l)
#   -UnitTest    include unit tests in the build           (monkeyc -t)
#   -Release     strip debug info                          (monkeyc -r)
#
# Flags verified against `monkeyc --help` on SDK 9.2.0.

param(
    [string]$Device = "all",
    [ValidateRange(0, 3)][int]$Typecheck = 3,
    [switch]$UnitTest,
    [switch]$Release
)

. "$PSScriptRoot\env.ps1"

$targets = if ($Device -eq "all") { $Products } else { @($Device) }

foreach ($t in $targets) {
    if ($Products -notcontains $t) {
        throw "'$t' is not in manifest.xml. Declared products: $($Products -join ', ')"
    }
}

$outDir = Join-Path $RepoRoot "bin"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$failed = @()
foreach ($t in $targets) {
    $suffix = if ($UnitTest) { "-test" } else { "" }
    $out = Join-Path $outDir "pacer-$t$suffix.prg"

    $monkeycArgs = @(
        "-d", $t
        "-f", (Join-Path $RepoRoot "monkey.jungle")
        "-o", $out
        "-y", $DevKey
        "-w"                      # show compiler warnings
        "-l", $Typecheck          # 3 = strict
    )
    if ($UnitTest) { $monkeycArgs += "-t" }   # -t,--unit-test on monkeyc
    if ($Release)  { $monkeycArgs += "-r" }

    Write-Host "==> $t  (typecheck=$Typecheck$(if($UnitTest){', unit-test'})$(if($Release){', release'}))" -ForegroundColor Cyan

    Push-Location $RepoRoot
    try { & $MonkeyC @monkeycArgs; $code = $LASTEXITCODE } finally { Pop-Location }

    if ($code -ne 0) {
        Write-Host "FAILED: $t (monkeyc exit $code)" -ForegroundColor Red
        $failed += $t
    } else {
        $kb = [math]::Round((Get-Item $out).Length / 1KB, 1)
        Write-Host "    ok  $out  ($kb KB)" -ForegroundColor Green
    }
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "BUILD FAILED for: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "BUILD OK  ($($targets.Count) device$(if($targets.Count -ne 1){'s'}))" -ForegroundColor Green
