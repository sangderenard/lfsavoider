param (
    [ValidateNotNullOrEmpty()]
    [string]$CleanPath,  # Path for the clean repository

    [ValidateNotNullOrEmpty()]
    [string]$RepoPath,  # Path to the temporary repository

    [ValidateNotNullOrEmpty()]
    [string]$RemoteURL  # Remote URL for the repository

    [switch]$WhatIf
)

# Clean destination if exists
if (Test-Path $CleanPath) {
    if ($WhatIf) {
        Write-Host "[WhatIf] Would remove $CleanPath" -ForegroundColor Yellow
    } else {
        Remove-Item -Recurse -Force $CleanPath
    }
}
if ($WhatIf) {
    Write-Host "[WhatIf] Would copy $RepoPath to $CleanPath" -ForegroundColor Yellow
} else {
    Copy-Item -Recurse -Force $RepoPath $CleanPath
}

Set-Location $CleanPath
# Ensure Git operates without LFS filters
git config --local filter.lfs.smudge ""
git config --local filter.lfs.required false

# Place guard file and pre-commit hook
& "$(Join-Path $PSScriptRoot 'install-lfs-guard.ps1')" -TargetPath $CleanPath

# Emergency manual hold
if (-not $WhatIf) {
    Write-Host "`nEMERGENCY MODE: Review the repo state before overwriting remote."
    Write-Host "Press Enter to continue with FORCE PUSH or Ctrl+C to cancel."
    Read-Host
} else {
    Write-Host "[WhatIf] Skipping interactive confirmation" -ForegroundColor Yellow
}

# Force push to clean overwrite the repo (use carefully)
git remote set-url origin $RemoteURL
if ($WhatIf) {
    Write-Host "[WhatIf] Would force push to $RemoteURL" -ForegroundColor Yellow
} else {
    git push --force --set-upstream origin main
}
