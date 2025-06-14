#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
cd "$repo_path"

# Install filter-repo if needed
pip install git-filter-repo

if [ "$#" -eq 1 ]; then
  echo "No specific paths provided, stripping all large blobs from history"
  git filter-repo --strip-blobs-bigger-than 100K --force
  echo "Large blobs purged."
  exit 0
fi

# Purge specified LFS-related paths
shift
paths=("$@")
pathfile=$(mktemp)
printf '%s\n' "${paths[@]}" > "$pathfile"
git filter-repo --paths-from-file "$pathfile" --invert-paths --force
rm "$pathfile"
echo "LFS-related history purged for specified paths."
