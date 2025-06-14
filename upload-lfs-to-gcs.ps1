param (
    [Parameter(Mandatory)][string]$QuarantinePath,
    [Parameter(Mandatory)][string]$GCSBucket,
    [Parameter(Mandatory)][string]$GCloudKeyPath,
    [string[]]$IncludeExtensions = @('*.whl'),
    [switch]$WhatIf
)

. "$PSScriptRoot/helpers.ps1"

if (-not (Test-Path $GCloudKeyPath)) {
    Write-Error "Missing GCS credentials at $GCloudKeyPath"
    exit 1
}

$env:GOOGLE_APPLICATION_CREDENTIALS = $GCloudKeyPath

if (-not (Test-Path $QuarantinePath)) {
    Write-Warning "Quarantine path not found: $QuarantinePath"
    exit 0
}

if (-not (Test-Path $QuarantinePath)) {
    Write-Warning "Quarantine path not found: $QuarantinePath"
    exit 0
}

Get-ChildItem -Recurse -Path $QuarantinePath -Include $IncludeExtensions | ForEach-Object {
    $RelativePath = $_.FullName.Substring($QuarantinePath.Length).TrimStart('\')
    $GcsPath = "$GCSBucket/$RelativePath".Replace('\\', '/')
    Write-Host "Uploading $($_.Name) to $GcsPath"
    Invoke-CheckedCommand -WhatIf:$WhatIf -Command { gsutil cp $_.FullName $GcsPath }
}

$skipped = Get-ChildItem -Recurse -Path $QuarantinePath | Where-Object { $_.Extension -notin $IncludeExtensions }
if ($skipped.Count -gt 0) {
    Write-Host "Skipped files:" -ForegroundColor Yellow
    $skipped | ForEach-Object { Write-Host $_.FullName }
}
