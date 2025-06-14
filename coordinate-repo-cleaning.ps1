param (
    [ValidateNotNullOrEmpty()]
    [string]$RepoFolder,  # Path to the repository folder

    [ValidateNotNullOrEmpty()]
    [string]$RepoName,  # Name of the repository

    [ValidateNotNullOrEmpty()]
    [string[]]$RepoURLs,  # List of repository URLs

    [string[]]$AdditionalFolders = @(),  # Additional folders to copy or excise

    [string]$AdditionalFolderDestination = "",  # Destination for additional folders

    [string]$QuarantinePath = "",  # Path for quarantined LFS data

    [switch]$New,  # Replace old folders if the process completes successfully

    [switch]$UploadLFS,  # Upload quarantined LFS files to GCS

    [switch]$WhatIf     # If specified, show actions without executing
)

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
    $QuarantinePath = if ($QuarantinePath) { $QuarantinePath } else { "$BasePath-quarantined-lfs" }
    $AdditionalCapturePath = if ($AdditionalFolderDestination) { $AdditionalFolderDestination } else { "$BasePath-additional-capture" }
    $BackupGitPath = "$BasePath-backup-git"

    if (-not (Test-Path $BasePath)) {
        if (-not (Test-Path $RepoFolder)) {
            Write-Error "Repositories folder does not exist: $RepoFolder. Exiting."
            exit 1
        }
        Write-Error "Repository folder does not exist: $BasePath. Exiting."
        exit 1
    }

    # Step 1: Prepare repository
    Write-Host "Preparing repository: $RepoName"
    .\prepare-speaktome.ps1 -repoURL $repoURL -targetPath $TempPath

    # Step 2: Quarantine LFS data and additional folders
    Write-Host "Quarantining LFS data and additional folders for: $RepoName"
    .\quarantine-lfs-data.ps1 -TargetFolders @("AGENTS\proposals\wheelhouse_repo") + $AdditionalFolders -AdditionalFolderDestination $AdditionalCapturePath -QuarantinePath $QuarantinePath

    # Step 3: Purge LFS history
    Write-Host "Purging LFS history for: $RepoName"
    .\purge-lfs-history.ps1 -RepoPath $TempPath -PathsToPurge @("AGENTS/proposals/wheelhouse_repo")

    # Step 4: Reinstall clean repository
    Write-Host "Reinstalling clean repository for: $RepoName"
    .\reinstall-clean-repo.ps1 -repoPath $TempPath -cleanPath $CleanPath -RemoteURL $repoURL -WhatIf:$WhatIf

    # Step 5: Restore Git metadata (optional)
    Write-Host "Restoring Git metadata for: $RepoName"
    .\restore-git-metadata.ps1 -repoPath $CleanPath -WhatIf:$WhatIf

    # Step 6: Replace old folder if -New is specified
    if ($New) {
        Write-Host "Replacing old folder with new clean repository for: $RepoName"
        if (Test-Path $BasePath) { Remove-Item -Recurse -Force -WhatIf:$WhatIf $basePath }
        Rename-Item -Path $cleanPath -NewName $basePath -WhatIf:$WhatIf
    }

    # Step 7: Upload quarantined LFS files to GCS if -UploadLFS is specified
    if ($UploadLFS -and (Test-Path $QuarantinePath)) {
        Write-Host "Uploading quarantined LFS files to GCS for: $RepoName"
        .\upload-lfs-to-gcs.ps1 -QuarantinePath $QuarantinePath -GCSBucket "gs://your-lfs-bucket" -GCloudKeyPath "gcs-keys/service-account.json"
    }

    Write-Host "Process completed for: $RepoName"
}
