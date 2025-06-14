param (
    [Parameter(Mandatory)][string]$RepoPath,
    [Parameter(Mandatory)][string[]]$PathsToPurge,
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

Set-Location $RepoPath

if (-not (Get-Command git-filter-repo -ErrorAction SilentlyContinue)) {
    Write-Host "git-filter-repo not found; installing to local venv" -ForegroundColor Yellow
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { python -m venv .venv }
    $pip = (Join-Path .venv (if ($IsWindows) { 'Scripts\pip.exe' } else { 'bin/pip' }))
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { & $pip install git-filter-repo }
    $filterRepo = (Join-Path .venv (if ($IsWindows) { 'Scripts\git-filter-repo.exe' } else { 'bin/git-filter-repo' }))
} else {
    $filterRepo = 'git-filter-repo'
}

# Write a path-list file for cleaner usage
$PathListFile = "paths-to-purge.txt"

if ($PathsToPurge.Count -eq 0) {
    Write-Host "No specific paths provided, stripping all large blobs from history"
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { & $filterRepo --strip-blobs-bigger-than 100K --force }
    Write-Host "Large blobs purged."
    exit 0
}

$PathsToPurge -join "`n" | Out-File -Encoding utf8 $PathListFile

# Run the filter
Invoke-CheckedCommand -WhatIf:$WhatIf -Command { & $filterRepo --paths-from-file $PathListFile --invert-paths --force }

Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Remove-Item $PathListFile }
Write-Host "LFS-related history purged."
