#!/usr/bin/env bash
set -euo pipefail

repo_url="$1"
target_path="$2"

if [ -d "$target_path" ]; then
  rm -rf "$target_path"
fi

echo "Cloning fresh repo to $target_path (LFS disabled)"
# Clone without Git LFS filters
git clone "$repo_url" "$target_path" --config filter.lfs.smudge= --config filter.lfs.required=false

cd "$target_path"

echo "Repository prepared at $target_path"

# Install guard to prevent accidental LFS usage
"$(dirname "$0")"/install-lfs-guard.sh "$target_path"
