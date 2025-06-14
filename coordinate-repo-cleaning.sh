#!/usr/bin/env bash
set -euo pipefail

repo_folder=""
repo_name=""
repo_urls=()
additional_folders=()
additional_dest=""
quarantine_path=""
new_flag=false
upload_lfs=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo-folder) repo_folder="$2"; shift 2;;
    -n|--repo-name) repo_name="$2"; shift 2;;
    -u|--repo-url) repo_urls+=("$2"); shift 2;;
    -a|--additional-folder) additional_folders+=("$2"); shift 2;;
    --additional-dest) additional_dest="$2"; shift 2;;
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
  additional_capture="${additional_dest:-$base_path-additional-capture}"
  backup_git="$base_path-backup-git"

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

  echo "Quarantining LFS data and additional folders for: $repo_name"
  ./quarantine-lfs-data.sh "$quarantine" "$additional_capture" AGENTS/proposals/wheelhouse_repo "${additional_folders[@]}"

  echo "Purging LFS history for: $repo_name"
  ./purge-lfs-history.sh "$temp_path" AGENTS/proposals/wheelhouse_repo

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
    ./upload-lfs-to-gcs.sh "$quarantine" "gs://your-lfs-bucket" "gcs-keys/service-account.json"
  fi

  echo "Process completed for: $repo_name"
done
