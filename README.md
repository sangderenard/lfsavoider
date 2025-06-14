# LFS Avoider

This project provides tools to permanently remove Git LFS usage from a repository. The goal is to quarantine any large binary content, purge all Git LFS metadata, rebuild a clean repository without the LFS hooks, and upload the large binaries to Google Cloud Storage (GCS) for archival. **Never enable Git LFS** in any workflow when using these scripts.

## Overview

PowerShell scripts originally orchestrate the process. This repository now includes a Bash suite that mirrors those scripts. Use whichever toolchain fits your environment but ensure Git LFS is disabled at all times.

### Security and Configuration

- GCS credentials and other sensitive configuration **must** come from secret storage. Do not store them in this repository.
- Processed archives should be uploaded to GCS and not committed back here.
- If cross-repo access is required, store any authentication tokens in your runner's secrets.

### Safety

These scripts expect to work on fresh clones or disposable copies of a repository. They are **not** intended for in-place cleaning of the repository that the agent is executing from. If a step would require deleting the runner's repository, abort the operation.

## Bash scripts

The following Bash scripts mirror the PowerShell ones:

- `prepare-speaktome.sh` – clone a repo with LFS disabled
- `quarantine-lfs-data.sh` – copy target folders and separate any LFS tracked files
- `purge-lfs-history.sh` – remove paths from history using `git filter-repo`
- `reinstall-clean-repo.sh` – push the cleaned repo to a fresh remote
- `restore-git-metadata.sh` – restore `.git` metadata from backup if needed
- `upload-lfs-to-gcs.sh` – upload quarantined binaries to GCS
- `build-lfs-manifest.sh` – generate YAML and Markdown manifests for quarantined files
- `coordinate-repo-cleaning.sh` – orchestrate all steps

Check each script for usage details. The repository intentionally omits persistent archives; after running, push the sanitized repo to a new remote and store binary artifacts in GCS.

## PowerShell utilities

- `check-lfs-integrity.ps1` – verify that all LFS objects referenced in the repository exist on the server

## LFS Guard

All scripts now place a `.lfs.guard` file and a pre-commit hook into generated repositories and manifest folders. The hook script used is provided as `pre-commit.lfs.guard` in this repository. The guard includes a SHA-256 hash of the current manifest so clones can verify integrity and will block any attempt to commit any form of Git LFS usage.
