param(
    [Parameter(Mandatory)][string]$TargetPath,
    [string]$ManifestYaml = "",
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

if (-not $TargetPath) {
    Write-Error "TargetPath is required"
    exit 1
}

$hash = "N/A"
if ($ManifestYaml -and (Test-Path $ManifestYaml)) {
    $hash = (Get-FileHash -Algorithm SHA256 $ManifestYaml).Hash
}

$guardFile = Join-Path $TargetPath '.lfs.guard'
"This repository has had Git LFS removed. Reintroducing LFS is prohibited.`nManifest SHA256: $hash" | Set-Content -Path $guardFile

$hookDir = Join-Path $TargetPath ".git/hooks"
if (-not (Test-Path $hookDir)) { New-Item -ItemType Directory -Path $hookDir | Out-Null }
$preCommit = Join-Path $hookDir 'pre-commit'
$sourceHook = Join-Path $PSScriptRoot 'pre-commit.lfs.guard'
Invoke-CheckedCommand -WhatIf:$WhatIf -Command { Copy-Item $sourceHook $preCommit -Force }

if ($IsWindows) {
    try { icacls $preCommit /grant Everyone:RX > $null } catch {}
}

# Ensure .gitattributes exists
$gitAttr = Join-Path $TargetPath '.gitattributes'
if (-not (Test-Path $gitAttr)) {
    New-Item -ItemType File -Path $gitAttr | Out-Null
}

