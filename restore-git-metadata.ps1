$repoPath = "C:\Apache24\htdocs\AI\speaktome-clean"
$backupGit = "C:\Apache24\htdocs\AI\speaktome-backup-git\.git"

if (Test-Path $backupGit) {
    Write-Host "Restoring original .git metadata..."
    Remove-Item -Recurse -Force (Join-Path $repoPath ".git")
    Copy-Item -Recurse -Force $backupGit (Join-Path $repoPath ".git")
    Write-Host ".git metadata restored."
} else {
    Write-Warning "No .git backup found at $backupGit"
}
