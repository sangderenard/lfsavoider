param (
    [Parameter(Mandatory)][string]$QuarantinePath,
    [Parameter(Mandatory)][string]$AdditionalFolderDestination,
    [Parameter(Mandatory)][string[]]$TargetFolders,
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

if (-not (Test-Path $QuarantinePath)) {
    New-Item -ItemType Directory -Path $QuarantinePath | Out-Null
}

if (-not (Test-Path $AdditionalFolderDestination)) {
    New-Item -ItemType Directory -Path $AdditionalFolderDestination | Out-Null
}

# Detect LFS-tracked files using .gitattributes
$GitattributesPath = Join-Path $PWD ".gitattributes"
$LfsPatterns = if (Test-Path $GitattributesPath) {
    Get-Content $GitattributesPath | Where-Object { $_ -match "filter=lfs" } | ForEach-Object { ($_ -split " `t| ")[0] }
} else {
    @()
}

$checksumList = @()
foreach ($folder in $TargetFolders) {
    $SourcePath = Join-Path $PWD $folder
    if (-not (Test-Path $SourcePath)) {
        Write-Warning "$SourcePath does not exist!"
        continue
    }

    Get-ChildItem -Path $SourcePath -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($SourcePath.Length).TrimStart('\\','/')
        $dest = Join-Path $QuarantinePath $folder $relative
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Copy-Item -Path $_.FullName -Destination $dest -Force }

        if ($LfsPatterns -notcontains $_.Name) {
            $addDest = Join-Path $AdditionalFolderDestination $folder $relative
            $addDir = Split-Path $addDest -Parent
            if (-not (Test-Path $addDir)) { New-Item -ItemType Directory -Path $addDir -Force | Out-Null }
            Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Move-Item -Path $dest -Destination $addDest -Force }
        }

        if (-not $WhatIf) {
            $hash = (Get-FileHash -Algorithm SHA256 $_.FullName).Hash
            $checksumList += "$($folder)/$relative $hash"
        }
    }
}

if (-not $WhatIf -and $checksumList.Count -gt 0) {
    $checksumList | Set-Content -Path (Join-Path $QuarantinePath 'checksums.txt')
}
