# LFS Avoider configuration
# Custom project-specific settings.

# Example: wheelhouse source directory (optional)
# WHEELHOUSE_SRC="/path/to/wheelhouse"
# Default: no wheelhouse
WHEELHOUSE_SRC=""

# Additional target folders to quarantine (relative to repo root)
# TARGET_FOLDERS=("path/to/folder1" "path/to/folder2")
# Default: none
TARGET_FOLDERS=()

# Paths to purge from history (relative to repo root)
# PATHS_TO_PURGE=("path/to/file1" "path/to/folder2")
# Default: none
PATHS_TO_PURGE=()

# GCS configuration (optional)
# GCS_BUCKET="gs://your-lfs-bucket"
# GCS_KEY_PATH="gcs-keys/service-account.json"
# Default: none
GCS_BUCKET=""
GCS_KEY_PATH=""
