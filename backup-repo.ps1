param(
    [ValidateNotNullOrEmpty()]
    [string]$RepoPath,

    [string]$RemoteURL = '',

    [string]$BackupDir = (Join-Path $PSScriptRoot 'backups'),

    [switch]$SkipLocal,
    [switch]$SkipRemote,
    [switch]$WhatIf
)

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMddHHmmss'

if (-not $SkipLocal) {
    $localTar = Join-Path $BackupDir "local-$timestamp.tar.gz"
    Write-Host "Backing up local repo to $localTar"
    if (-not $WhatIf) {
        & tar -czf $localTar -C $RepoPath .
        if ($LASTEXITCODE -ne 0) { throw "Failed to create local backup" }
    }
}

if ($RemoteURL -and -not $SkipRemote) {
    $remoteClone = Join-Path $env:TEMP "remote-backup-$timestamp"
    $remoteTar = Join-Path $BackupDir "remote-$timestamp.tar.gz"
    Write-Host "Backing up remote repo $RemoteURL"
    if (-not $WhatIf) {
        git clone --mirror $RemoteURL $remoteClone
        if ($LASTEXITCODE -ne 0) { throw "Failed to clone remote" }
        & tar -czf $remoteTar -C $remoteClone .
        Remove-Item -Recurse -Force $remoteClone
    }
}

Write-Host "Backup complete"
