param (
    [ValidateNotNullOrEmpty()]
    [string]$RepoPath,  # Path to the repository

    [ValidateNotNullOrEmpty()]
    [string[]]$PathsToPurge  # List of paths to purge
)

Set-Location $RepoPath

pip install git-filter-repo

# Write a path-list file for cleaner usage
$PathListFile = "paths-to-purge.txt"

if ($PathsToPurge.Count -eq 0) {
    Write-Host "No specific paths provided, stripping all large blobs from history"
    git filter-repo --strip-blobs-bigger-than 100K --force
    Write-Host "Large blobs purged."
    exit 0
}

$PathsToPurge -join "`n" | Out-File -Encoding ascii $PathListFile

# Run the filter
git filter-repo --paths-from-file $PathListFile --invert-paths --force

Remove-Item $PathListFile
Write-Host "LFS-related history purged."
