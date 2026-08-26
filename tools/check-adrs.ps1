# Reference integrity for docs/adr. Runs inside `just test` -- no simulator, no
# build, just files, so it costs nothing to enforce on every loop.
#
# Four things must hold:
#   1. Every ADR-NNNN referenced from code or docs resolves to a file.
#   2. Every ADR id is unique and matches its filename.
#   3. Supersession is mutual: if 0017 says superseded-by 0018, then 0018 must
#      say supersedes 0017. A one-sided link is how a chain silently breaks.
#   4. Every ACCEPTED ADR is referenced by something. An accepted ADR nobody
#      points at is write-only prose, which is the failure mode this whole
#      arrangement exists to avoid. Superseded ADRs are exempt -- they are
#      history and need no referent.
#
# This is the first prose in this repo that can fail a build. See ADR-0033.

param([switch]$Quiet)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AdrDir = Join-Path $RepoRoot "docs\adr"
$problems = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $AdrDir)) {
    Write-Host "check-adrs: docs/adr does not exist" -ForegroundColor Red
    exit 1
}

# --- the ADRs on disk ---------------------------------------------------------
$adrs = @{}
foreach ($f in Get-ChildItem $AdrDir -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }) {
    if ($f.Name -notmatch '^(\d{4})-[a-z0-9-]+\.md$') {
        $problems.Add("bad filename: $($f.Name) -- expected NNNN-kebab-slug.md")
        continue
    }
    $id = $Matches[1]
    if ($adrs.ContainsKey($id)) {
        $problems.Add("duplicate id ${id}: $($f.Name) and $($adrs[$id].Name)")
        continue
    }
    $text = Get-Content $f.FullName -Raw
    $status = "MISSING"
    if ($text -match '(?m)^status:\s*(\S+)\s*$') { $status = $Matches[1] }
    if ($status -eq "MISSING") { $problems.Add("ADR ${id}: no 'status:' line") }
    elseif ($status -ne "accepted" -and $status -ne "superseded") {
        $problems.Add("ADR ${id}: status '$status' is neither accepted nor superseded")
    }
    if ($text -notmatch "(?m)^id:\s*$id\s*$") {
        $problems.Add("ADR ${id}: frontmatter id does not match the filename")
    }
    $adrs[$id] = [pscustomobject]@{ Name = $f.Name; Status = $status; Text = $text }
}

# --- references from everywhere that is not an ADR ----------------------------
$scanned = New-Object System.Collections.Generic.List[System.IO.FileInfo]
foreach ($dir in "source", "tests", "tools") {
    $p = Join-Path $RepoRoot $dir
    if (Test-Path $p) { Get-ChildItem $p -File -Recurse | ForEach-Object { $scanned.Add($_) } }
}
Get-ChildItem $RepoRoot -Filter "*.md" -File | ForEach-Object { $scanned.Add($_) }
$docs = Join-Path $RepoRoot "docs"
if (Test-Path $docs) {
    Get-ChildItem $docs -Filter "*.md" -File | ForEach-Object { $scanned.Add($_) }
}

$referenced = @{}
foreach ($f in $scanned) {
    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }
    foreach ($m in [regex]::Matches($content, 'ADR-(\d{4})')) {
        $id = $m.Groups[1].Value
        if (-not $adrs.ContainsKey($id)) {
            $problems.Add("$($f.Name) references ADR-$id, which does not exist")
        } else {
            $referenced[$id] = $true
        }
    }
}

# --- supersession, and the write-only check -----------------------------------
foreach ($id in $adrs.Keys) {
    $a = $adrs[$id]
    if ($a.Text -match '(?m)^superseded-by:\s*(\d{4})\s*$') {
        $by = $Matches[1]
        if (-not $adrs.ContainsKey($by)) {
            $problems.Add("ADR ${id}: superseded-by $by, which does not exist")
        } elseif ($adrs[$by].Text -notmatch "(?m)^supersedes:\s*$id\s*$") {
            $problems.Add("ADR ${id}: says superseded-by $by, but $by does not say supersedes $id")
        }
        if ($a.Status -ne "superseded") {
            $problems.Add("ADR ${id}: has superseded-by but status is '$($a.Status)'")
        }
    }
    if ($a.Status -eq "accepted" -and -not $referenced.ContainsKey($id)) {
        $problems.Add("ADR ${id}: accepted but nothing references it -- write-only prose")
    }
}

# --- report -------------------------------------------------------------------
if ($problems.Count -gt 0) {
    Write-Host "ADR CHECK FAILED" -ForegroundColor Red
    foreach ($p in $problems) { Write-Host "  $p" -ForegroundColor Red }
    exit 1
}

if (-not $Quiet) {
    $accepted = ($adrs.Values | Where-Object { $_.Status -eq "accepted" }).Count
    $superseded = ($adrs.Values | Where-Object { $_.Status -eq "superseded" }).Count
    Write-Host "==> ADRs ok  ($accepted accepted, $superseded superseded)" -ForegroundColor Green
}
exit 0
