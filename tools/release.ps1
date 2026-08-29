# Finalise the version for a store release, and stop.
#
#   just release
#
# This does NOT build the bundle and it does NOT touch the watch. It does the
# one thing that has to happen before either: make sure the version in the
# source is a PUBLIC one, with the unit suite green behind it.
#
# WHAT IT DOES DEPENDS ON THE SHAPE IT FINDS, and that is the whole trick:
#
#   1.3.12  a dev build -> finalises to 1.4. Unambiguous: work has happened
#           since 1.3, so the next thing published is the next public number.
#
#   1.4     already public -> LEAVES IT ALONE. This is not a no-op worth
#           skipping; it is the case that makes a first release possible
#           (1.0 is published as 1.0, not as 1.1) and it is also how you
#           re-run the gate after a wrist pass sent you back.
#
# So the public number advances on the first `just deploy` AFTER a release --
# which iterates to X.Y.1 -- and never twice for the same body of work.
#
# WHY IT STOPS BEFORE PACKAGING. The step in between is the wrist pass, and it
# cannot be automated: a sideload to this watch cannot be verified from the host
# at all (ADR-0034), so a person has to read the number off the glass. A recipe
# running straight through to `just package` would produce the submission
# artifact before the only test that matters had been taken. It prints the next
# command instead of running it. ADR-0039
#
# The tests run BEFORE the version is touched, so a red suite leaves the source
# exactly as it found it.

param(
    [string]$SetVersion = "",
    [switch]$SkipTests
)

. "$PSScriptRoot\env.ps1"
. "$PSScriptRoot\version.ps1"

$version = Get-AppVersion
Write-Host ""
Write-Host "==> release: found $($version.Text)" -ForegroundColor Cyan

if ($SetVersion -ne "") {
    $next = $SetVersion
    Write-Host "    hand-set to $next" -ForegroundColor Cyan
} elseif ($version.IsPublic) {
    $next = $version.Text
    Write-Host "    already a public version -- leaving it as it is." -ForegroundColor Cyan
    Write-Host "    (if $($version.Text) is ALREADY in the store, you want a dev build first:" -ForegroundColor DarkGray
    Write-Host "     run 'just deploy' to iterate, then release again.)" -ForegroundColor DarkGray
} else {
    $next = Next-PublicVersion $version
    Write-Host "    finalising $($version.Text) -> $next" -ForegroundColor Cyan
}

# A hand-set version still has to be public: the whole scheme rests on the store
# never seeing three segments, and -SetVersion is exactly where that would slip.
if ($next -notmatch '^\d\.\d$') {
    throw ("release: '$next' is not a public version. The store only ever sees " +
        "X.Y, one digit each side of the dot -- three segments mean a dev build " +
        "(ADR-0039).")
}

# --- the gate -----------------------------------------------------------------
if ($SkipTests) {
    Write-Host "    SKIPPING the unit suite (-SkipTests)" -ForegroundColor Yellow
} else {
    Write-Host ""
    & "$PSScriptRoot\test.ps1" -Device "vivoactive5" -Typecheck 3
    if ($LASTEXITCODE -ne 0) {
        throw "release: tests failed. The version is untouched -- fix them and run again."
    }
}

# --- finalise -----------------------------------------------------------------
if ($next -ne $version.Text) {
    Set-AppVersion -From $version.Text -To $next
    Write-Host ""
    Write-Host "version  $($version.Text) -> $next" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "version  $next (unchanged, already public)" -ForegroundColor Green
}

Write-Host ""
Write-Host "NOT DONE. Nothing has been built and nothing has been sent to the watch." -ForegroundColor Yellow
Write-Host "The wrist pass comes next and cannot be automated." -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Sideload THIS EXACT BUILD. No bump -- 'just deploy' would iterate" -ForegroundColor Yellow
Write-Host "     to $next.1 and you would be verifying a number nobody will ship:" -ForegroundColor Yellow
Write-Host "         just deploy-nobump" -ForegroundColor White
Write-Host ""
Write-Host "  2. Walk docs/PUBLISHING.md section 1 on the watch. The settings" -ForegroundColor Yellow
Write-Host "     screen's title must read:" -ForegroundColor Yellow
Write-Host "         Candle v$next" -ForegroundColor White
Write-Host ""
Write-Host "  3. The real-input checks, on a machine you are not also using:" -ForegroundColor Yellow
Write-Host "         just input-test" -ForegroundColor White
Write-Host ""
Write-Host "  4. Only then, the submission artifacts:" -ForegroundColor Yellow
Write-Host "         just icons; just shot-release; just package" -ForegroundColor White
Write-Host ""
Write-Host "If the wrist pass fails: fix it, sideload with 'just deploy' (which" -ForegroundColor Yellow
Write-Host "iterates to $next.1), and run 'just release -SetVersion $next' when it is" -ForegroundColor Yellow
Write-Host "clean -- that keeps $next for the build that actually ships." -ForegroundColor Yellow
