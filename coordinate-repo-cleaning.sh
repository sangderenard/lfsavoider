#!/usr/bin/env bash
set -euo pipefail

# Load project-specific configuration
source "$(dirname "$0")/lfsavoider.config.sh"

repo_folder=""
repo_name=""
repo_urls=()
quarantine_path=""
new_flag=false
upload_lfs=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo-folder) repo_folder="$2"; shift 2;;
    -n|--repo-name) repo_name="$2"; shift 2;;
    -u|--repo-url) repo_urls+=("$2"); shift 2;;
    --quarantine) quarantine_path="$2"; shift 2;;
    --new) new_flag=true; shift;;
    --upload-lfs) upload_lfs=true; shift;;
    *) echo "Unknown option $1"; exit 1;;
  esac
done

for repo_url in "${repo_urls[@]}"; do
  if [ -z "$repo_url" ]; then
    if [ -z "$repo_name" ]; then
      echo "No repository URL or name provided. Exiting." >&2
      exit 1
    fi
    repo_url="${repo_name}.git"
  elif [ -z "$repo_name" ]; then
    repo_name=$(basename "$repo_url" .git)
  fi

  if [ -z "$repo_folder" ]; then
    echo "No repository folder specified. Exiting." >&2
    exit 1
  fi

  base_path="$repo_folder/$repo_name"
  temp_path="$base_path-temp"
  clean_path="$base_path-clean"
  quarantine="${quarantine_path:-$base_path-quarantined-lfs}"
  backup_git="$base_path-backup-git"
  # Directory for non-LFS files or additional capture
  additional_capture="$base_path-additional-capture"

  if [ ! -d "$base_path" ]; then
    if [ ! -d "$repo_folder" ]; then
      echo "Repositories folder does not exist: $repo_folder. Exiting." >&2
      exit 1
    fi
    echo "Repository folder does not exist: $base_path. Exiting." >&2
    exit 1
  fi

  echo "Preparing repository: $repo_name"
  ./prepare-speaktome.sh "$repo_url" "$temp_path"

  # Check for broken LFS pointers
  if ! ./check-lfs-integrity.sh; then
    echo "Broken LFS pointers detected, removing pointer files"
    find "$temp_path" -type f -exec grep -Il "version https://git-lfs.github.com/spec/v1" {} \; | while read -r f; do
      echo "Deleting pointer file $f"
      rm -f "$f"
    done
  fi

  echo "Quarantining LFS data and additional folders for: $repo_name"
  ./quarantine-lfs-data.sh "$quarantine" "$additional_capture" "${TARGET_FOLDERS[@]:-}"

  echo "Purging LFS history for: $repo_name"
  ./purge-lfs-history.sh "$temp_path" "${PATHS_TO_PURGE[@]:-}"

  echo "Reinstalling clean repository for: $repo_name"
  ./reinstall-clean-repo.sh "$temp_path" "$clean_path" "$repo_url"

  echo "Restoring Git metadata for: $repo_name"
  ./restore-git-metadata.sh "$clean_path" "$backup_git"

  if [ "$new_flag" = true ]; then
    echo "Replacing old folder with new clean repository for: $repo_name"
    rm -rf "$base_path"
    mv "$clean_path" "$base_path"
  fi

  if [ "$upload_lfs" = true ] && [ -d "$quarantine" ]; then
    echo "Uploading quarantined LFS files to GCS for: $repo_name"
    # Use configured GCS settings
    ./upload-lfs-to-gcs.sh "$quarantine" "$GCS_BUCKET" "$GCS_KEY_PATH"
  fi

  echo "Process completed for: $repo_name"
done
