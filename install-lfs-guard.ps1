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
$hookContent = @'
#!/usr/bin/env bash
if git lfs ls-files | grep -q .; then
  echo "❌ LFS usage is prohibited in this repo."
  exit 1
fi
'@
$hookContent | Set-Content -Path $preCommit -NoNewline
try { icacls $preCommit /grant Everyone:RX > $null } catch {}

