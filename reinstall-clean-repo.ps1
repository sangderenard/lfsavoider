param (
    [ValidateNotNullOrEmpty()]
    [string]$CleanPath,  # Path for the clean repository

    [ValidateNotNullOrEmpty()]
    [string]$RepoPath,  # Path to the temporary repository

    [ValidateNotNullOrEmpty()]
    [string]$RemoteURL  # Remote URL for the repository
)

# Clean destination if exists
if (Test-Path $CleanPath) { Remove-Item -Recurse -Force $CleanPath }
Copy-Item -Recurse -Force $RepoPath $CleanPath

Set-Location $CleanPath
# Ensure Git operates without LFS filters
git config --local filter.lfs.smudge ""
git config --local filter.lfs.required false

# Emergency manual hold
Write-Host "`nEMERGENCY MODE: Review the repo state before overwriting remote."
Write-Host "Press Enter to continue with FORCE PUSH or Ctrl+C to cancel."
Read-Host

# Force push to clean overwrite the repo (use carefully)
git remote set-url origin $RemoteURL
git push --force --set-upstream origin main
