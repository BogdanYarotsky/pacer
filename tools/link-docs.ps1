# Point ./sdk-docs and ./sdk-samples at the currently active SDK.
#
# Junctions, not symlinks: Windows symlinks need elevation or Developer Mode,
# neither of which is required here. Both are gitignored -- they are a view into
# the installed SDK, not repo content.
#
# Re-run after `connect-iq-sdk-manager sdk set <version>` so the docs on disk
# always match the compiler that is actually building the app.

. "$PSScriptRoot\env.ps1"

foreach ($pair in @(
    @{ Name = "sdk-docs";    Target = (Join-Path $SdkRoot "doc") },
    @{ Name = "sdk-samples"; Target = (Join-Path $SdkRoot "samples") }
)) {
    $link = Join-Path $RepoRoot $pair.Name

    if (-not (Test-Path $pair.Target)) {
        Write-Host "SKIP $($pair.Name): the active SDK has no $($pair.Target)" -ForegroundColor Yellow
        continue
    }

    if (Test-Path $link) {
        # Only ever remove a reparse point, never a real directory of content.
        $item = Get-Item $link -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Remove-Item $link -Force -Recurse
        } else {
            throw "link-docs: $link exists and is a real directory, not a junction. Refusing to delete it."
        }
    }

    New-Item -ItemType Junction -Path $link -Target $pair.Target | Out-Null
    $count = (Get-ChildItem $link -Recurse -File -ErrorAction SilentlyContinue).Count
    Write-Host "$($pair.Name) -> $($pair.Target)  ($count files)" -ForegroundColor Green
}
