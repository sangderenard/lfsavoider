param (
    [ValidateNotNullOrEmpty()]
    [string]$RepoPath,

    [ValidateNotNullOrEmpty()]
    [string[]]$PathsToPurge,

    [switch]$WhatIf
)

Set-Location $RepoPath

if (-not (Get-Command git-filter-repo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing git-filter-repo" -ForegroundColor Yellow
    if (-not $WhatIf) { pip install git-filter-repo | Out-Null }
} else {
    Write-Host "git-filter-repo already installed"
}

# Write a path-list file for cleaner usage
$PathListFile = "paths-to-purge.txt"

if ($PathsToPurge.Count -eq 0) {
    Write-Host "No specific paths provided, stripping all large blobs from history"
    git filter-repo --strip-blobs-bigger-than 100K --force
    Write-Host "Large blobs purged."
    exit 0
}

$PathsToPurge -join "`n" | Out-File -Encoding utf8 $PathListFile

# Run the filter
if ($WhatIf) {
    Write-Host "[WhatIf] Would run git filter-repo with $PathListFile"
} else {
    git filter-repo --paths-from-file $PathListFile --invert-paths --force
}

if ($WhatIf) { Write-Host "[WhatIf] Would remove $PathListFile" } else { Remove-Item $PathListFile }
Write-Host "LFS-related history purged."
