param (
    [ValidateNotNullOrEmpty()]
    [string]$QuarantinePath = "C:\Apache24\htdocs\AI\quarantined-lfs",

    [ValidateNotNullOrEmpty()]
    [string]$GCSBucket = "gs://your-lfs-bucket",

    [ValidateNotNullOrEmpty()]
    [string]$GCloudKeyPath = "C:\Apache24\htdocs\AI\gcs-keys\service-account.json"
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

# Recursively upload only binary LFS-type files (e.g., *.whl)
Get-ChildItem -Recurse -Path $QuarantinePath -Include *.whl | ForEach-Object {
    $RelativePath = $_.FullName.Substring($QuarantinePath.Length).TrimStart('\')
    $GcsPath = "$GCSBucket/$RelativePath".Replace('\\', '/')
    Write-Host "Uploading $($_.Name) to $GcsPath"
    & gsutil cp $_.FullName $GcsPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Uploaded: $($_.FullName)"
    } else {
        Write-Warning "Failed to upload: $($_.FullName)"
    }
}

# Log skipped files
Write-Host "Skipped files (if any):"
Get-ChildItem -Recurse -Path $QuarantinePath | Where-Object { $_.Extension -notin '.whl', '.bin', '.zip', '.tar.gz', '.dll' } | ForEach-Object {
    Write-Host "Skipped: $($_.FullName)"
}
