param (
    [ValidateNotNullOrEmpty()]
    [string]$RepoURL,  # URL of the repository

    [ValidateNotNullOrEmpty()]
    [string]$TargetPath  # Target path for cloning
)

# Clean slate
if (Test-Path $TargetPath) { Remove-Item -Recurse -Force $TargetPath }

Write-Host "Cloning fresh repo to $TargetPath"
git clone $RepoURL $TargetPath

Set-Location $TargetPath
git lfs install

Write-Host "Repository prepared at $TargetPath"
