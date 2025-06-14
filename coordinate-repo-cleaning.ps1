param (
    [Parameter(Mandatory)][string]$RepoFolder,
    [string]$RepoName,
    [string[]]$RepoURLs,
    [switch]$New,
    [switch]$UploadLFS,
    [switch]$BackupRemote,
    [string]$BackupDir = (Join-Path $PSScriptRoot 'backups'),
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"
. (Join-Path $PSScriptRoot 'lfsavoider.config.ps1') | Out-Null
$config = @{ TargetFolders = $TargetFolders; PathsToPurge = $PathsToPurge; WheelhouseSrc = $WheelhouseSrc; GCSBucket = $GCSBucket; GCSKeyPath = $GCSKeyPath }
Assert-Config -Config $config

Start-CleanupLog -LogDir $BackupDir
  
foreach ($repoURL in $RepoURLs) {
    if (-not $repoURL) {
        if (-not $RepoName) {
            Write-Error "No repository URL or name provided. Exiting."
            exit 1
        }
        $repoURL = "$RepoName.git"
    } elseif (-not $RepoName) {
        $RepoName = ($repoURL -split '/')[-1] -replace '\.git$', ''
    }

    if (-not $RepoFolder) {
        Write-Error "No repository folder specified. Exiting."
        exit 1
    }

    $BasePath = Join-Path $RepoFolder $RepoName
    $TempPath = "$BasePath-temp"
    $CleanPath = "$BasePath-clean"
    # Define paths for quarantine and additional capture
    $QuarantinePath = "$BasePath-quarantined-lfs"
    $AdditionalCapturePath = "$BasePath-additional-capture"
    $BackupGitPath = "$BasePath-backup-git"

    if (-not (Test-Path $BasePath)) {
        if (-not (Test-Path $RepoFolder)) {
            Write-Error "Repositories folder does not exist: $RepoFolder. Exiting."
            exit 1
        }
        Write-Error "Repository folder does not exist: $BasePath. Exiting."
        exit 1
    }

    # Step 0: Backup repository
    Write-Host "Backing up $RepoName" -ForegroundColor Cyan
    .\backup-repo.ps1 -RepoPath $BasePath -BackupDir $BackupDir -IncludeRemote:$BackupRemote -WhatIf:$WhatIf

    # Step 1: Prepare repository
    Write-Host "Preparing repository: $RepoName"
    .\prepare-speaktome.ps1 -RepoURL $repoURL -TargetPath $TempPath -WhatIf:$WhatIf

    # Step 2: Quarantine LFS data and additional folders
    Write-Host "Quarantining LFS data and additional folders for: $RepoName"
    .\quarantine-lfs-data.ps1 -QuarantinePath $QuarantinePath -AdditionalFolderDestination $AdditionalCapturePath -TargetFolders $TargetFolders -WhatIf:$WhatIf

    # Step 3: Purge LFS history
    Write-Host "Purging LFS history for: $RepoName"
    .\purge-lfs-history.ps1 -RepoPath $TempPath -PathsToPurge $PathsToPurge -WhatIf:$WhatIf

    # Step 4: Reinstall clean repository
    Write-Host "Reinstalling clean repository for: $RepoName"
    .\reinstall-clean-repo.ps1 -RepoPath $TempPath -CleanPath $CleanPath -RemoteURL $repoURL -WhatIf:$WhatIf

    # Step 5: Restore Git metadata (optional)
    Write-Host "Restoring Git metadata for: $RepoName"
    .\restore-git-metadata.ps1 -RepoPath $CleanPath -BackupGit $BackupGitPath -WhatIf:$WhatIf

    # Step 6: Replace old folder if -New is specified
    if ($New) {
        Write-Host "Replacing old folder with new clean repository for: $RepoName"
        if (Test-Path $BasePath) { Remove-Item -Recurse -Force -WhatIf:$WhatIf $basePath }
        Rename-Item -Path $cleanPath -NewName $basePath -WhatIf:$WhatIf
    }

    # Step 7: Upload quarantined LFS files to GCS if -UploadLFS is specified
    if ($UploadLFS -and (Test-Path $QuarantinePath)) {
        Write-Host "Uploading quarantined LFS files to GCS for: $RepoName"
        .\upload-lfs-to-gcs.ps1 -QuarantinePath $QuarantinePath -GCSBucket $GCSBucket -GCloudKeyPath $GCSKeyPath -WhatIf:$WhatIf
    }

    Write-Host "Process completed for: $RepoName"
}

Stop-CleanupLog
