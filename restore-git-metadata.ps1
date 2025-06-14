
param(
    [Parameter(Mandatory)][string]$RepoPath,
    [Parameter(Mandatory)][string]$BackupGit,
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

if (Test-Path $BackupGit) {
    Write-Host "Restoring original .git metadata..."
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Remove-Item -Recurse -Force (Join-Path $RepoPath '.git') }
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Copy-Item -Recurse -Force $BackupGit (Join-Path $RepoPath '.git') }
    Write-Host ".git metadata restored."
} else {
    Write-Warning "No .git backup found at $BackupGit"
}
