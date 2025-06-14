# LFS Avoider

A cross-platform toolkit for permanently removing Git LFS usage from a repository. Each script focuses on a single step: quarantine large binaries, purge history, rebuild without LFS hooks, and optionally archive artifacts to Google Cloud Storage (GCS). **Never re-enable Git LFS in repositories processed with these tools.**

For detailed usage, see [docs/operator_manual.md](docs/operator_manual.md).

## Overview

The repository contains both PowerShell and Bash implementations. Use whichever environment fits your needs. Scripts assume they are run in disposable clones, never directly on your primary repo.

## Configuration

All bash orchestrations load `lfsavoider.config.sh` for project-specific settings. Customize the following variables in that file:

- `WHEELHOUSE_SRC` (optional): path to a local wheelhouse directory.
- `TARGET_FOLDERS` (optional): array of folder paths (relative to repo root) to quarantine.
- `PATHS_TO_PURGE` (optional): array of paths (relative to repo root) to remove from commit history.
- `GCS_BUCKET` and `GCS_KEY_PATH` (optional): Google Cloud Storage settings for uploading artifacts.

### Security and Configuration

- Provide GCS credentials and any secrets through your CI runner or environment, not in this repository.
- Upload quarantined archives to GCS and keep them out of version control.

### Safety

Operations remove and replace directories. Work on fresh clones or throwaway copies only.

## Quick Start (Bash)

```bash
# 1. Clone the repo you want to clean with LFS disabled
./prepare-speaktome.sh https://example.com/repo.git /tmp/repo-temp

# 2. Quarantine LFS data and capture additional folders
./quarantine-lfs-data.sh /tmp/repo-quarantine /tmp/repo-additional AGENTS/proposals/wheelhouse_repo

# 3. Purge those folders from history
./purge-lfs-history.sh /tmp/repo-temp AGENTS/proposals/wheelhouse_repo

# 4. Reinstall the cleaned repo and force push
./reinstall-clean-repo.sh /tmp/repo-temp /tmp/repo-clean https://example.com/repo.git

# 5. Optionally upload quarantined binaries to GCS
./upload-lfs-to-gcs.sh /tmp/repo-quarantine gs://your-lfs-bucket gcs-keys/service-account.json
```

PowerShell scripts provide the same functionality with similar parameters.

## Script Reference

| Script | Purpose | Usage Example |
| ------ | ------- | ------------- |
| `prepare-speaktome.(ps1|sh)` | Clone a repo with LFS disabled | `./prepare-speaktome.sh <repo_url> <target_path>` |
| `quarantine-lfs-data.(ps1|sh)` | Copy target folders, separating files tracked by LFS | `./quarantine-lfs-data.sh <quarantine_path> <additional_dest> <folder> [...]` |
| `purge-lfs-history.(ps1|sh)` | Remove paths from git history using `git filter-repo` | `./purge-lfs-history.sh <repo_path> <path> [...]` |
| `reinstall-clean-repo.(ps1|sh)` | Push the cleaned repo to a fresh remote | `./reinstall-clean-repo.sh <repo_path> <clean_path> <remote_url>` |
| `restore-git-metadata.(ps1|sh)` | Restore `.git` metadata from backup if needed | `./restore-git-metadata.sh <repo_path> <backup_git>` |
| `upload-lfs-to-gcs.(ps1|sh)` | Upload quarantined binaries to GCS | `./upload-lfs-to-gcs.sh <quarantine_path> <bucket> <keyfile>` |
| `build-lfs-manifest.(ps1|sh)` | Generate YAML/Markdown manifests of quarantined files | `./build-lfs-manifest.ps1` |
| `coordinate-repo-cleaning.(ps1|sh)` | Orchestrate all steps above | `./coordinate-repo-cleaning.sh -r /repos -u https://example.com/repo.git` |
| `check-lfs-integrity.ps1` | Verify that all LFS objects exist on the server | `pwsh ./check-lfs-integrity.ps1` |

## LFS Guard

Every script installs a `.lfs.guard` file and a `pre-commit` hook to prevent reintroducing Git LFS. The guard stores the SHA-256 hash of the latest manifest so clones can verify integrity.

