param (
    [string]$LocalRepoCollectionFolder = "C:\\Apache24\\htdocs\\AI\\local-lfs-archives",
    [string]$ConfigFile = "config\\manifest.config.json"
)

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
$BasePath        = Join-Path $LocalRepoCollectionFolder $RepoName
$QuarantinePath  = Join-Path $BasePath "$RepoName-quarantined-lfs"
$ManifestPath    = Join-Path $BasePath "$RepoName-manifests"
$TemplatePath    = Join-Path $BasePath "template\feed.html"  # Optional
$ManifestYaml    = Join-Path $ManifestPath "lfs_manifest.yaml"
$ManifestMD      = Join-Path $ManifestPath "lfs_manifest.md"
$ManifestHTML    = Join-Path $ManifestPath "index.html"

# === Ensure directories exist ===
@($QuarantinePath, $ManifestPath) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ | Out-Null }
}

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
        path     = $file.FullName
        size     = $file.Length
        modified = $file.LastWriteTime
    }
}

$YamlData | ConvertTo-Yaml | Set-Content -Path $ManifestYaml

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

# === Optional: Generate HTML ===
if (Test-Path $TemplatePath) {
    $HtmlTemplate = Get-Content -Raw -Path $TemplatePath
    $FileRows = $Files | ForEach-Object {
        "<tr><td>$($_.Name)</td><td>$($_.FullName)</td><td>$($_.Length)</td><td>$($_.LastWriteTime)</td></tr>"
    } | Out-String
    $HtmlFinal = $HtmlTemplate -replace "{{file_rows}}", $FileRows
    $HtmlFinal | Set-Content -Path $ManifestHTML
} else {
    Write-Warning "No HTML template found at $TemplatePath"
}

Write-Host "Manifest files generated for $RepoName in $ManifestPath"
