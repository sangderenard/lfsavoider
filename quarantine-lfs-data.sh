#!/usr/bin/env bash
set -euo pipefail

quarantine_path="$1"
additional_dest="$2"
shift 2
targets=("$@")

mkdir -p "$quarantine_path" "$additional_dest"

lfs_patterns=()
if [ -f .gitattributes ]; then
  while read -r line; do
    if [[ $line == *"filter=lfs"* ]]; then
      pattern=$(echo "$line" | awk '{print $1}')
      lfs_patterns+=("$pattern")
    fi
  done < .gitattributes
fi

for folder in "${targets[@]}"; do
  src="$folder"
  dest="$quarantine_path/$(basename "$folder")"
  if [ -d "$src" ]; then
    echo "Quarantining $src -> $dest"
    cp -R "$src" "$dest"
    find "$dest" -type f | while read -r f; do
      keep=false
      for pat in "${lfs_patterns[@]}"; do
        if [[ $(basename "$f") == $pat ]]; then
          keep=true
          break
        fi
      done
      if [ "$keep" = false ]; then
        mv "$f" "$additional_dest/" 2>/dev/null || true
      fi
    done
  else
    echo "Warning: $src does not exist"
  fi
done
