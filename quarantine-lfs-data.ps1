param (
    [ValidateNotNullOrEmpty()]
    [string]$QuarantinePath,  # Path for quarantined LFS data

    [ValidateNotNullOrEmpty()]
    [string]$AdditionalFolderDestination,  # Destination for additional folders

    [ValidateNotNullOrEmpty()]
    [string[]]$TargetFolders  # List of target folders to quarantine
)

if (!(Test-Path $QuarantinePath)) {
    New-Item -ItemType Directory -Path $QuarantinePath
}

if (!(Test-Path $AdditionalFolderDestination)) {
    New-Item -ItemType Directory -Path $AdditionalFolderDestination
}

# Detect LFS-tracked files using .gitattributes
$GitattributesPath = Join-Path $PWD ".gitattributes"
$LfsPatterns = if (Test-Path $GitattributesPath) {
    Get-Content $GitattributesPath | Where-Object { $_ -match "filter=lfs" } | ForEach-Object { ($_ -split " `t| ")[0] }
} else {
    @()
}

foreach ($folder in $TargetFolders) {
    $SourcePath = Join-Path $PWD $folder
    $DestPath = Join-Path $QuarantinePath (Split-Path $folder -Leaf)

    if (Test-Path $SourcePath) {
        Write-Host "Quarantining $SourcePath to $DestPath"
        Copy-Item -Recurse -Force $SourcePath $DestPath

        # Move non-LFS files to the additional folder
        Get-ChildItem -Path $DestPath -Recurse | Where-Object {
            $LfsPatterns -notcontains $_.Name
        } | ForEach-Object {
            $AdditionalDest = Join-Path $AdditionalFolderDestination $_.Name
            Move-Item -Path $_.FullName -Destination $AdditionalDest -Force
        }
    } else {
        Write-Warning "$SourcePath does not exist!"
    }
}
