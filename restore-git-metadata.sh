#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
backup_git="$2"

if [ -d "$backup_git" ]; then
  echo "Restoring original .git metadata..."
  rm -rf "$repo_path/.git"
  cp -R "$backup_git" "$repo_path/.git"
  echo ".git metadata restored."
else
  echo "No .git backup found at $backup_git"
fi
