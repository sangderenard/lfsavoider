param(
    [Parameter(Mandatory)][string]$RepoPath,
    [Parameter(Mandatory)][string]$BackupDir,
    [switch]$IncludeRemote,
    [string]$RemoteName = 'origin',
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

Start-CleanupLog -LogDir $BackupDir

try {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $repoPath = Resolve-Path $RepoPath
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

    $localArchive = Join-Path $BackupDir "repo-$timestamp.tar.gz"
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { tar -czf $localArchive -C $repoPath . }

    if ($IncludeRemote) {
        $bundleFile = Join-Path $BackupDir "remote-$timestamp.bundle"
        Invoke-CheckedCommand -WhatIf:$WhatIf -Command { git -C $repoPath fetch $RemoteName --prune }
        Invoke-CheckedCommand -WhatIf:$WhatIf -Command { git -C $repoPath bundle create $bundleFile --all }
    }
    Write-Host "Backup complete:" -ForegroundColor Green
    Write-Host " Local archive: $localArchive"
    if ($IncludeRemote) { Write-Host " Remote bundle: $bundleFile" }
} finally {
    Stop-CleanupLog
}
