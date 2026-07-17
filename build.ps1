param(
    [Parameter(Mandatory = $true)]
    [string]$DeveloperKey,

    [string]$Output = (Join-Path $PSScriptRoot "bin\pacer-vivoactive5.prg")
)

$ErrorActionPreference = "Stop"

if ($null -eq (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "Java was not found on PATH. Install a 64-bit Java runtime or JDK 11 or newer first."
}

$sdkConfig = Join-Path $env:APPDATA "Garmin\ConnectIQ\current-sdk.cfg"
if (-not (Test-Path -LiteralPath $sdkConfig)) {
    throw "No active Connect IQ SDK was found. Install one with Garmin SDK Manager first: $sdkConfig"
}

$sdkRoot = (Get-Content -LiteralPath $sdkConfig -Raw).Trim()
if (-not (Test-Path -LiteralPath $sdkRoot)) {
    throw "The active SDK path in current-sdk.cfg does not exist: $sdkRoot"
}

$compilerCandidates = @(
    (Join-Path $sdkRoot "bin\monkeyc.bat"),
    (Join-Path $sdkRoot "bin\monkeyc.exe"),
    (Join-Path $sdkRoot "bin\monkeyc")
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($null -eq $compiler) {
    throw "monkeyc was not found below the active SDK: $sdkRoot"
}

$resolvedKey = (Resolve-Path -LiteralPath $DeveloperKey).Path
if (-not [System.IO.Path]::IsPathRooted($Output)) {
    $Output = Join-Path $PSScriptRoot $Output
}
$outputDirectory = Split-Path -Parent $Output
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

Push-Location $PSScriptRoot
try {
    & $compiler `
        -d vivoactive5 `
        -f (Join-Path $PSScriptRoot "monkey.jungle") `
        -o $Output `
        -y $resolvedKey

    if ($LASTEXITCODE -ne 0) {
        throw "monkeyc failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "Built $Output"
