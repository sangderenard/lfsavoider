$repoPath = "C:\Apache24\htdocs\AI\speaktome-clean"
$backupGit = "C:\Apache24\htdocs\AI\speaktome-backup-git\.git"

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$WhatIf
)

if (Test-Path $backupGit) {
    Write-Host "Restoring original .git metadata..."
    if ($PSCmdlet.ShouldProcess($repoPath, 'Replace .git with backup')) {
        Remove-Item -Recurse -Force -WhatIf:$WhatIf (Join-Path $repoPath ".git")
        Copy-Item -Recurse -Force -WhatIf:$WhatIf $backupGit (Join-Path $repoPath ".git")
    }
    Write-Host ".git metadata restored."
} else {
    Write-Warning "No .git backup found at $backupGit"
}
