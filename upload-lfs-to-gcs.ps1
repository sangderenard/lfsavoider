param (
    [ValidateNotNullOrEmpty()]
    [string]$QuarantinePath,

    [ValidateNotNullOrEmpty()]
    [string]$GCSBucket,

    [ValidateNotNullOrEmpty()]
    [string]$GCloudKeyPath,

    [string[]]$IncludeExtensions = @('*.whl'),
    [switch]$WhatIf
)

if (-not (Test-Path $GCloudKeyPath)) {
    Write-Error "Missing GCS credentials at $GCloudKeyPath"
    exit 1
}

$env:GOOGLE_APPLICATION_CREDENTIALS = $GCloudKeyPath

if (-not (Test-Path $QuarantinePath)) {
    Write-Warning "Quarantine path not found: $QuarantinePath"
    exit 0
}

# Recursively upload files matching extensions
Get-ChildItem -Recurse -Path $QuarantinePath -Include $IncludeExtensions | ForEach-Object {
    $RelativePath = $_.FullName.Substring($QuarantinePath.Length).TrimStart('\\')
    $GcsPath = "$GCSBucket/$RelativePath".Replace('\\', '/')
    if ($WhatIf) {
        Write-Host "[WhatIf] Would upload $($_.FullName) to $GcsPath"
    } else {
        Write-Host "Uploading $($_.Name) to $GcsPath"
        & gsutil cp $_.FullName $GcsPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Uploaded: $($_.FullName)"
        } else {
            Write-Warning "Failed to upload: $($_.FullName)"
        }
    }
}

$Skipped = Get-ChildItem -Recurse -Path $QuarantinePath | Where-Object { $_.Extension -notin $IncludeExtensions }
Write-Host "Skipped files ($($Skipped.Count)):"
$Skipped | ForEach-Object { Write-Host "Skipped: $($_.FullName)" }
