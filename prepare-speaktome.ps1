param (
    [ValidateNotNullOrEmpty()]
    [string]$RepoURL,

    [ValidateNotNullOrEmpty()]
    [string]$TargetPath,

    [switch]$WhatIf
)

# Clean slate
if (Test-Path $TargetPath) {
    if ($WhatIf) { Write-Host "[WhatIf] Would remove $TargetPath" } else { Remove-Item -Recurse -Force $TargetPath }
}

Write-Host "Cloning fresh repo to $TargetPath (LFS disabled)"
if (-not $WhatIf) {
    git clone $RepoURL $TargetPath --config filter.lfs.smudge= --config filter.lfs.required=false
    if ($LASTEXITCODE -ne 0) { throw "clone failed" }
} else {
    Write-Host "WhatIf: git clone $RepoURL $TargetPath"
}

if (-not $WhatIf) {
    Set-Location $TargetPath
    git lfs uninstall --local | Out-Null
    Write-Host "Repository prepared at $TargetPath"
    & "$(Join-Path $PSScriptRoot 'install-lfs-guard.ps1')" -TargetPath $TargetPath
} else {
    Write-Host "WhatIf mode: skipping repo configuration"
}

# Wheelhouse copying is now controlled via `lfsavoider.config.ps1`
