#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
shift
paths=("$@")

cd "$repo_path"

pip install git-filter-repo

pathfile=$(mktemp)
printf '%s\n' "${paths[@]}" > "$pathfile"

git filter-repo --paths-from-file "$pathfile" --invert-paths --force

rm "$pathfile"

echo "LFS-related history purged."
