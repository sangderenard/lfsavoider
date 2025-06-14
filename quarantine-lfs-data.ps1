param (
    [ValidateNotNullOrEmpty()]
    [string]$QuarantinePath,  # Path for quarantined LFS data

    [ValidateNotNullOrEmpty()]
    [string]$AdditionalFolderDestination,  # Destination for additional folders

    [ValidateNotNullOrEmpty()]
    [string[]]$TargetFolders,  # List of target folders to quarantine

    [switch]$WhatIf
)

if (!(Test-Path $QuarantinePath)) {
    if ($WhatIf) { Write-Host "[WhatIf] Would create $QuarantinePath" } else { New-Item -ItemType Directory -Path $QuarantinePath | Out-Null }
}

if (!(Test-Path $AdditionalFolderDestination)) {
    if ($WhatIf) { Write-Host "[WhatIf] Would create $AdditionalFolderDestination" } else { New-Item -ItemType Directory -Path $AdditionalFolderDestination | Out-Null }
}

# Detect LFS-tracked files using .gitattributes
$GitattributesPath = Join-Path $PWD ".gitattributes"
$LfsPatterns = if (Test-Path $GitattributesPath) {
    Get-Content $GitattributesPath | Where-Object { $_ -match "filter=lfs" } | ForEach-Object { ($_ -split " `t| ")[0] }
} else {
    @()
}

$ChecksumFile = Join-Path $QuarantinePath 'checksums.txt'
if (-not $WhatIf) { Clear-Content -Path $ChecksumFile -ErrorAction SilentlyContinue }

foreach ($folder in $TargetFolders) {
    $SourcePath = Join-Path $PWD $folder
    $DestPath = Join-Path $QuarantinePath $folder

    if (Test-Path $SourcePath) {
        Write-Host "Quarantining $SourcePath to $DestPath"
        if ($WhatIf) {
            Write-Host "[WhatIf] Would copy $SourcePath to $DestPath"
        } else {
            Copy-Item -Recurse -Force $SourcePath $DestPath
        }

        # Move non-LFS files to the additional folder
        Get-ChildItem -Path $DestPath -Recurse | Where-Object {
            $LfsPatterns -notcontains $_.Name
        } | ForEach-Object {
            $Relative = $_.FullName.Substring($DestPath.Length).TrimStart('\\','/')
            $AdditionalDest = Join-Path $AdditionalFolderDestination $Relative
            if ($WhatIf) {
                Write-Host "[WhatIf] Would move $_ to $AdditionalDest"
            } else {
                New-Item -ItemType Directory -Path (Split-Path $AdditionalDest) -Force | Out-Null
                Move-Item -Path $_.FullName -Destination $AdditionalDest -Force
            }
        }
    } else {
        Write-Warning "$SourcePath does not exist!"
    }
}

if (-not $WhatIf) {
    Get-ChildItem -Recurse -File -Path $QuarantinePath | ForEach-Object {
        $rel = $_.FullName.Substring($QuarantinePath.Length).TrimStart('\\','/')
        $hash = Get-FileHash -Algorithm SHA256 $_.FullName
        "$($hash.Hash) *$rel" | Add-Content -Path $ChecksumFile
    }
    Write-Host "Checksums written to $ChecksumFile"
}
