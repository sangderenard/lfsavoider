#!/usr/bin/env bash
set -euo pipefail

local_repo_collection_folder="${1:-/path/to/local-archives}"
config_file="${2:-config/manifest.config.json}"

if [ ! -f "$config_file" ]; then
  echo "Missing config file: $config_file" >&2
  exit 1
fi

repo_name=$(jq -r '.repo_name' "$config_file")
if [ -z "$repo_name" ] || [ "$repo_name" = "null" ]; then
  echo "'repo_name' is missing in config." >&2
  exit 1
fi

base_path="$local_repo_collection_folder/$repo_name"
quarantine_path="$base_path/${repo_name}-quarantined-lfs"
manifest_path="$base_path/${repo_name}-manifests"
template_path="$base_path/template/feed.html"
manifest_yaml="$manifest_path/lfs_manifest.yaml"
manifest_md="$manifest_path/lfs_manifest.md"
manifest_html="$manifest_path/index.html"

mkdir -p "$quarantine_path" "$manifest_path"

files=$(find "$quarantine_path" -type f)

{
  echo "schema_version: 1"
  echo "repo: $repo_name"
  echo "generated: $(date -Iseconds)"
  echo "files:"
  for f in $files; do
    echo "  - name: $(basename "$f")"
    echo "    path: $f"
    echo "    size: $(stat -c%s "$f")"
    echo "    modified: $(date -r "$f" -Iseconds)"
  done
} > "$manifest_yaml"

{
  echo "# Manifest for $repo_name"
  echo ""
  echo "| File | Size | Modified |"
  echo "|------|------|----------|"
  for f in $files; do
    echo "| $(basename "$f") | $(stat -c%s "$f") | $(date -r "$f" -u '+%Y-%m-%d %H:%M:%S') |"
  done
} > "$manifest_md"

if [ -f "$template_path" ]; then
  file_rows=""
  for f in $files; do
    file_rows+="<tr><td>$(basename "$f")</td><td>$f</td><td>$(stat -c%s "$f")</td><td>$(date -r "$f")</td></tr>"
  done
  sed "s/{{file_rows}}/$file_rows/" "$template_path" > "$manifest_html"
else
  echo "No HTML template found at $template_path"
fi

# Place LFS guard and hook in manifest directory
"$(dirname "$0")"/install-lfs-guard.sh "$manifest_path" "$manifest_yaml"
