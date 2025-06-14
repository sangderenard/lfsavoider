param (
    [Parameter(Mandatory)][string]$RepoURL,
    [Parameter(Mandatory)][string]$TargetPath,
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

# Clean slate
if (Test-Path $TargetPath) {
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Remove-Item -Recurse -Force $TargetPath }
}

Write-Host "Cloning fresh repo to $TargetPath (LFS disabled)"
Invoke-CheckedCommand -WhatIf:$WhatIf -Command { git clone $RepoURL $TargetPath --config filter.lfs.smudge= --config filter.lfs.required=false }

if (-not $WhatIf) { Set-Location $TargetPath }
Invoke-CheckedCommand -WhatIf:$WhatIf -Command { git -C $TargetPath lfs uninstall --local }

Write-Host "Repository prepared at $TargetPath"
& "$(Join-Path $PSScriptRoot 'install-lfs-guard.ps1')" -TargetPath $TargetPath -WhatIf:$WhatIf

# Wheelhouse copying is now controlled via `lfsavoider.config.ps1`
