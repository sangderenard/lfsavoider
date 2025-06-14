param(
    [string]$TargetPath,
    [string]$ManifestYaml = ""
)

if (-not $TargetPath) {
    Write-Error "TargetPath is required"
    exit 1
}

$hash = "N/A"
if ($ManifestYaml -and (Test-Path $ManifestYaml)) {
    $hash = (Get-FileHash -Algorithm SHA256 $ManifestYaml).Hash
}

$guardFile = Join-Path $TargetPath ".lfs.guard"
"This repository has had Git LFS removed. Reintroducing LFS is prohibited.`nManifest SHA256: $hash" | Set-Content -Path $guardFile

$hookDir = Join-Path $TargetPath ".git/hooks"
if (-not (Test-Path $hookDir)) { New-Item -ItemType Directory -Path $hookDir | Out-Null }
$preCommit = Join-Path $hookDir "pre-commit"
$sourceHook = Join-Path $PSScriptRoot "pre-commit.lfs.guard"
Copy-Item $sourceHook $preCommit -Force

if ($IsWindows) {
    try { icacls $preCommit /grant Everyone:RX > $null } catch {}
    # Lock the pre-commit hook to prevent modification
    Set-ItemProperty -Path $preCommit -Name IsReadOnly -Value $true
}

# Ensure .gitattributes exists
$gitAttr = Join-Path $TargetPath '.gitattributes'
if (-not (Test-Path $gitAttr)) {
    New-Item -ItemType File -Path $gitAttr | Out-Null
}

