[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$RepoPath = $PWD,
    [string]$BackupGit = '',
    [switch]$WhatIf
)

if (-not $BackupGit) { $BackupGit = Join-Path $RepoPath '..\backup-git\.git' }

if (Test-Path $BackupGit) {
    Write-Host "Restoring original .git metadata..."
    if ($PSCmdlet.ShouldProcess($RepoPath, 'Replace .git with backup')) {
        Remove-Item -Recurse -Force -WhatIf:$WhatIf (Join-Path $RepoPath ".git")
        Copy-Item -Recurse -Force -WhatIf:$WhatIf $BackupGit (Join-Path $RepoPath ".git")
    }
    Write-Host ".git metadata restored."
} else {
    Write-Warning "No .git backup found at $BackupGit"
}
