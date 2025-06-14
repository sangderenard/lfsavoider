# LFS Avoider configuration for PowerShell scripts
# Custom project-specific settings.

<#
# Path to wheelhouse source (optional)
# $WheelhouseSrc = ''

# Array of folder paths (relative to repo root) to quarantine
# $TargetFolders = @()

# Array of paths (relative to repo root) to purge from history
# $PathsToPurge = @()

# Google Cloud Storage settings for uploading artifacts
# $GCSBucket = 'gs://your-lfs-bucket'
# $GCSKeyPath = 'gcs-keys/service-account.json'
#>  # End of examples

# Default configuration values
$WheelhouseSrc = ''
$TargetFolders = @()
$PathsToPurge = @()
$RepoCollectionRoot = 'C:\\Apache24\\htdocs\\AI\\local-lfs-archives'
$GCSBucket = ''
$GCSKeyPath = ''
