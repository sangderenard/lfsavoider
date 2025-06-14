param (
    [ValidateNotNullOrEmpty()]
    [string]$CleanPath,  # Path for the clean repository

    [ValidateNotNullOrEmpty()]
    [string]$RepoPath,  # Path to the temporary repository

    [ValidateNotNullOrEmpty()]
    [string]$RemoteURL,  # Remote URL for the repository

    [switch]$WhatIf
)

# Clean destination if exists
if (Test-Path $CleanPath) { Remove-Item -Recurse -Force -WhatIf:$WhatIf $CleanPath }
Copy-Item -Recurse -Force -WhatIf:$WhatIf $RepoPath $CleanPath

Set-Location $CleanPath
# Ensure Git operates without LFS filters
git config --local filter.lfs.smudge ""
git config --local filter.lfs.required false

# Place guard file and pre-commit hook
& "$(Join-Path $PSScriptRoot 'install-lfs-guard.ps1')" -TargetPath $CleanPath

# Emergency manual hold
Write-Host "`nEMERGENCY MODE: Review the repo state before overwriting remote."
if (-not $WhatIf) {
    Write-Host "Press Enter to continue with FORCE PUSH or Ctrl+C to cancel."
    Read-Host
} else {
    Write-Host "WhatIf mode enabled: skipping prompt and push"
}

# Force push to clean overwrite the repo (use carefully)
if (-not $WhatIf) {
    git remote set-url origin $RemoteURL
    git push --force --set-upstream origin main
} else {
    Write-Host "WhatIf: git remote set-url origin $RemoteURL"
    Write-Host "WhatIf: git push --force --set-upstream origin main"
}
