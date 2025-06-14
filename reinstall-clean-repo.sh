#!/usr/bin/env bash
set -euo pipefail

repo_path="$1"
clean_path="$2"
remote_url="$3"

rm -rf "$clean_path"
cp -R "$repo_path" "$clean_path"

cd "$clean_path"

git config --local filter.lfs.smudge ""
git config --local filter.lfs.required false

echo -e "\nEMERGENCY MODE: Review the repo state before overwriting remote."
read -p "Press Enter to continue with FORCE PUSH or Ctrl+C to cancel" _

git remote set-url origin "$remote_url"
git push --force --set-upstream origin main
