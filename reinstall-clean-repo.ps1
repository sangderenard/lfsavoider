param (
    [Parameter(Mandatory)][string]$CleanPath,
    [Parameter(Mandatory)][string]$RepoPath,
    [Parameter(Mandatory)][string]$RemoteURL,
    [switch]$AutoConfirm,
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

# Clean destination if exists

if (Test-Path $CleanPath) {
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Remove-Item -Recurse -Force $CleanPath }
}
Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Copy-Item -Recurse -Force $RepoPath $CleanPath }

if (-not $WhatIf) { Set-Location $CleanPath }
Invoke-CheckedCommand -WhatIf:$WhatIf -Command { git -C $CleanPath config --local filter.lfs.smudge "" }
Invoke-CheckedCommand -WhatIf:$WhatIf -Command { git -C $CleanPath config --local filter.lfs.required false }

# Place guard file and pre-commit hook
& "$(Join-Path $PSScriptRoot 'install-lfs-guard.ps1')" -TargetPath $CleanPath -WhatIf:$WhatIf

if (-not $AutoConfirm -and -not $WhatIf) {
    Write-Host "`nReview repo state before overwriting remote." -ForegroundColor Yellow
    Read-Host "Press Enter to continue or Ctrl+C to cancel"
} else {
    Write-Host "AutoConfirm or WhatIf enabled: skipping prompt"
}

# Force push to clean overwrite the repo (use carefully)
if (-not $WhatIf) {
    Invoke-CheckedCommand -Command { git remote set-url origin $RemoteURL }
    Invoke-CheckedCommand -Command { git push --force --set-upstream origin main }
} else {
    Write-Host "WhatIf: git remote set-url origin $RemoteURL"
    Write-Host "WhatIf: git push --force --set-upstream origin main"
}
