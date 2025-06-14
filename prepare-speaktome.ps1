param (
    [ValidateNotNullOrEmpty()]
    [string]$RepoURL,  # URL of the repository

    [ValidateNotNullOrEmpty()]
    [string]$TargetPath  # Target path for cloning
)

# Clean slate
if (Test-Path $TargetPath) { Remove-Item -Recurse -Force $TargetPath }

Write-Host "Cloning fresh repo to $TargetPath (LFS disabled)"
# Clone without engaging Git LFS filters
git clone $RepoURL $TargetPath --config filter.lfs.smudge= --config filter.lfs.required=false

Set-Location $TargetPath


Write-Host "Repository prepared at $TargetPath"
