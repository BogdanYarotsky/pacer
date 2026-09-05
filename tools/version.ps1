# THE VERSION SCHEME, in one place. Dot-sourced by deploy.ps1, release.ps1 and
# package.ps1 -- three scripts that each need to know what a version is, and
# would otherwise each carry their own regex to disagree with. ADR-0039
#
# THE SHAPE OF THE STRING SAYS WHAT THE BUILD IS:
#
#   1.4        TWO segments -- a PUBLIC version. One digit each side of the dot,
#              the minor rolls (1.9 -> 2.0), and this is the only shape the
#              Connect IQ store is ever allowed to see.
#
#   1.4.12     THREE segments -- a DEV build, the 12th sideload since 1.4 was
#              published. It has never been published and never will be.
#
# Nobody has to remember which is which: a bug report quoting "1.4.12" is
# self-evidently not a store install, and package.ps1 refuses to bundle one.
#
# Defines: Get-AppVersion, Set-AppVersion, Next-DevVersion, Next-PublicVersion

$ErrorActionPreference = "Stop"

# The iteration's ceiling. It began as a LAYOUT fact -- "Candle v9.9.999" was
# the widest string the settings screen's title band could take (ADR-0039) --
# and outlived the band: the version is shorter and lower now (ADR-0040), and
# layoutRealLinesFitTheGlass measures every shape the scheme allows, on every
# device. Three digits stays as the scheme's own ceiling; the number is here so
# the failure arrives as a sentence rather than as clipped pixels.
$script:MaxIteration = 999

function Get-AppVersionFile {
    return (Join-Path $RepoRoot "source\candleApp.mc")
}

# Returns a parsed version, or throws with the file named.
function Get-AppVersion {
    $file = Get-AppVersionFile
    $text = Get-Content $file -Raw
    if ($text -notmatch 'APP_VERSION\s*=\s*"(\d)\.(\d)(?:\.(\d{1,3}))?"') {
        throw ("version: could not find a well-formed 'const APP_VERSION = `"X.Y`";' " +
            "or `"X.Y.N`" in $file. One digit each side of the dot, optional " +
            "1-3 digit iteration. ADR-0039")
    }
    $iteration = $null
    if ($Matches[3] -ne "" -and $null -ne $Matches[3]) { $iteration = [int]$Matches[3] }

    return [pscustomobject]@{
        Text      = if ($null -eq $iteration) { "$($Matches[1]).$($Matches[2])" }
                    else { "$($Matches[1]).$($Matches[2]).$iteration" }
        Major     = [int]$Matches[1]
        Minor     = [int]$Matches[2]
        Iteration = $iteration
        IsPublic  = ($null -eq $iteration)
        File      = $file
    }
}

function Set-AppVersion {
    param([Parameter(Mandatory)][string]$From, [Parameter(Mandatory)][string]$To)
    $file = Get-AppVersionFile
    $text = Get-Content $file -Raw
    $text = $text -replace "APP_VERSION\s*=\s*`"$([regex]::Escape($From))`"", "APP_VERSION = `"$To`""
    Set-Content -Path $file -Value $text -NoNewline
}

# One sideload. Bumps the ITERATION and never the public number, which is what
# makes a deploy free: a deploy against an unplugged watch costs an iteration
# nobody will ever see instead of burning a version a wearer might have quoted.
function Next-DevVersion {
    param([Parameter(Mandatory)]$Version)

    $next = if ($Version.IsPublic) { 1 } else { $Version.Iteration + 1 }
    if ($next -gt $script:MaxIteration) {
        throw ("version: $($Version.Text) is at the iteration ceiling of " +
            "$script:MaxIteration -- a fourth digit does not fit the title band. " +
            "Run 'just release' to finalise, or set one with -SetVersion.")
    }
    return "$($Version.Major).$($Version.Minor).$next"
}

# One release. Drops the iteration and rolls the public minor, so 1.3.12 and
# 1.3 both finalise to 1.4 -- what a release publishes is always the NEXT public
# number, never the one already in the store.
function Next-PublicVersion {
    param([Parameter(Mandatory)]$Version)

    $minor = $Version.Minor + 1
    $major = $Version.Major
    if ($minor -gt 9) { $minor = 0; $major += 1 }

    # 9.9 is the end of the odometer. Failing here is deliberate: "10.0" breaks
    # both the one-digit rule and the width budget, and what comes after is a
    # decision for a person, not for a bump.
    if ($major -gt 9) {
        throw ("version: $($Version.Text) is the end of the odometer -- the public " +
            "scheme is one digit each side of the dot (ADR-0039), so there is no " +
            "next version after 9.9. Decide what comes next and set it with " +
            "-SetVersion.")
    }
    return "$major.$minor"
}
