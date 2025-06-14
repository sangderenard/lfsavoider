#!/usr/bin/env bash
set -euo pipefail

quarantine_path="$1"
gcs_bucket="$2"
gcloud_key_path="$3"

if [ ! -f "$gcloud_key_path" ]; then
  echo "Missing GCS credentials at $gcloud_key_path" >&2
  exit 1
fi

export GOOGLE_APPLICATION_CREDENTIALS="$gcloud_key_path"

if [ ! -d "$quarantine_path" ]; then
  echo "Quarantine path not found: $quarantine_path"
  exit 0
fi

find "$quarantine_path" -type f -name '*.whl' | while read -r file; do
  rel="${file#$quarantine_path/}"
  gcs_path="$gcs_bucket/$rel"
  echo "Uploading $file to $gcs_path"
  gsutil cp "$file" "$gcs_path"
done

echo "Skipped files (if any):"
find "$quarantine_path" -type f ! -name '*.whl' -print
