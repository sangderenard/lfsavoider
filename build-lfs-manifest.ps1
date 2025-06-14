param (
    [string]$RepoCollectionRoot = "../"
    [string]$ConfigFile = "config/manifest.config.json",
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

# === Load repo name from config ===
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Missing config file: $ConfigFile"
    exit 1
}

$Config = Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json

if (-not $Config.repo_name) {
    Write-Error "'repo_name' is missing in config."
    exit 1
}

$RepoName = $Config.repo_name

# === Build derived paths ===

$BasePath        = Join-Path $RepoCollectionRoot $RepoName
$QuarantinePath  = Join-Path $BasePath "$RepoName-quarantined-lfs"
$ManifestPath    = Join-Path $BasePath "$RepoName-manifests"
$TemplatePath    = Join-Path $BasePath "template/feed.html"  # Optional
$ManifestYaml    = Join-Path $ManifestPath "lfs_manifest.yaml"
$ManifestMD      = Join-Path $ManifestPath "lfs_manifest.md"
$ManifestHTML    = Join-Path $ManifestPath "index.html"
$LogFile         = Join-Path $ManifestPath "manifest.log"

if (-not (Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile | Out-Null }
"$(Get-Date -Format s) Starting manifest generation" | Add-Content -Path $LogFile

# === Ensure directories exist ===
@($QuarantinePath, $ManifestPath) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ | Out-Null }
}
"$(Get-Date -Format s) Directories ensured" | Add-Content -Path $LogFile

# === Scan quarantined LFS files ===
$Files = Get-ChildItem -Recurse -Path $QuarantinePath | Where-Object { -not $_.PSIsContainer }

# === Generate YAML ===
$YamlData = [ordered]@{
    schema_version = 1
    repo = $RepoName
    generated = (Get-Date).ToString("s")
    files = @()
}

foreach ($file in $Files) {
    $YamlData.files += [ordered]@{
        name     = $file.Name
        path     = $file.FullName.Substring($QuarantinePath.Length).TrimStart('\\','/')
        size     = $file.Length
        modified = $file.LastWriteTime
    }
}

$YamlData | ConvertTo-Yaml | Set-Content -Path $ManifestYaml
"$(Get-Date -Format s) YAML manifest saved to $ManifestYaml" | Add-Content -Path $LogFile

# === Generate Markdown ===
$Markdown = @(
    "# Manifest for $RepoName",
    "",
    "| File | Size | Modified |",
    "|------|------|----------|"
)
$Markdown += $Files | ForEach-Object {
    "| `$_` | $($_.Length) | $($_.LastWriteTime.ToString('u')) |"
}
$Markdown -join "`n" | Set-Content -Path $ManifestMD
"$(Get-Date -Format s) Markdown manifest saved to $ManifestMD" | Add-Content -Path $LogFile

# === Optional: Generate HTML ===
if (Test-Path $TemplatePath) {
    $HtmlTemplate = Get-Content -Raw -Path $TemplatePath
    $FileRows = $Files | ForEach-Object {
        $rel = $_.FullName.Substring($QuarantinePath.Length).TrimStart('\\','/')
        "<tr><td>$($_.Name)</td><td>$rel</td><td>$($_.Length)</td><td>$($_.LastWriteTime)</td></tr>"
    } | Out-String
    $HtmlFinal = $HtmlTemplate -replace "{{file_rows}}", $FileRows
    $HtmlFinal | Set-Content -Path $ManifestHTML
    "$(Get-Date -Format s) HTML manifest saved to $ManifestHTML" | Add-Content -Path $LogFile
} else {
    Write-Warning "No HTML template found at $TemplatePath"
    "$(Get-Date -Format s) No HTML template found" | Add-Content -Path $LogFile
}

Write-Host "Manifest files generated for $RepoName in $ManifestPath"
"$(Get-Date -Format s) Manifest generation complete" | Add-Content -Path $LogFile
& "$(Join-Path $PSScriptRoot 'install-lfs-guard.ps1')" -TargetPath $ManifestPath -ManifestYaml $ManifestYaml -WhatIf:$WhatIf
