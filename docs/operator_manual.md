# LFS Avoider Operator Manual

This document describes each script in the **LFS Avoider** toolchain and how to use them to clean repositories of Git LFS content.

## Table of Contents

- [Workflow](#workflow)
- [Script Reference](#script-reference)
  - [prepare-speaktome.sh](#prepare-speaktomesh)
  - [quarantine-lfs-data.sh](#quarantine-lfs-datash)
  - [purge-lfs-history.sh](#purge-lfs-historysh)
  - [reinstall-clean-repo.sh](#reinstall-clean-reposh)
  - [restore-git-metadata.sh](#restore-git-metadatosh)
  - [upload-lfs-to-gcs.sh](#upload-lfs-to-gcssh)
  - [build-lfs-manifest.sh](#build-lfs-manifestsh)
  - [coordinate-repo-cleaning.sh](#coordinate-repo-cleaningsh)
  - [check-lfs-integrity.ps1](#check-lfs-integrityps1)
  - [install-lfs-guard.sh](#install-lfs-guardsh)

## Workflow

The typical cleaning process follows these steps:

1. **Prepare a clean clone** using `prepare-speaktome.sh`.
2. **Quarantine large files** with `quarantine-lfs-data.sh`.
3. **Purge LFS references from history** via `purge-lfs-history.sh`.
4. **Reinstall the cleaned repository** with `reinstall-clean-repo.sh`.
5. **Restore `.git` metadata** if you have a backup using `restore-git-metadata.sh`.
6. **Optionally upload quarantined binaries** to Google Cloud Storage with `upload-lfs-to-gcs.sh`.
7. **Generate manifests** for auditing via `build-lfs-manifest.sh`.
8. Use `coordinate-repo-cleaning.sh` to orchestrate everything if desired.

All scripts add a `.lfs.guard` file and a `pre-commit` hook to prevent reintroduction of Git LFS.

## Script Reference

### prepare-speaktome.sh

Clone a repository with Git LFS disabled and install an LFS guard.

```
./prepare-speaktome.sh <repo_url> <target_path>
```

- `repo_url` – URL of the repository to clone.
- `target_path` – destination folder for the clean clone.

### quarantine-lfs-data.sh

Copy target folders to a quarantine location and separate out files that are not tracked by LFS patterns found in `.gitattributes`.

```
./quarantine-lfs-data.sh <quarantine_path> <additional_dest> <folder1> [folder2 ...]
```

- `quarantine_path` – location to store quarantined content.
- `additional_dest` – path where non-LFS files will be moved.
- `folder1...` – folders to inspect for LFS content.

### purge-lfs-history.sh

Remove specified paths from the Git history using `git filter-repo`.

```
./purge-lfs-history.sh <repo_path> <path1> [path2 ...]
```

- `repo_path` – repository where history rewriting will occur.
- `path1...` – paths to purge from history.

### reinstall-clean-repo.sh

Copy a cleaned repository to a new location and force push to a remote after manual confirmation.

```
./reinstall-clean-repo.sh <repo_path> <clean_path> <remote_url>
```

- `repo_path` – temporary repository after cleaning steps.
- `clean_path` – folder to hold the final cleaned copy.
- `remote_url` – URL of the remote repository to push to.

### restore-git-metadata.sh

Restore a backed up `.git` directory into a repository.

```
./restore-git-metadata.sh <repo_path> <backup_git>
```

- `repo_path` – repository where metadata should be restored.
- `backup_git` – path to the backed up `.git` directory.

### upload-lfs-to-gcs.sh

Upload quarantined binary files to a Google Cloud Storage bucket.

```
./upload-lfs-to-gcs.sh <quarantine_path> <gcs_bucket> <gcloud_key_path>
```

- `quarantine_path` – folder containing quarantined binaries.
- `gcs_bucket` – destination GCS bucket (e.g., `gs://bucket-name`).
- `gcloud_key_path` – JSON service account key for authentication.

### build-lfs-manifest.sh

Create YAML, Markdown, and optional HTML manifests describing quarantined files.

```
./build-lfs-manifest.sh <archive_root> [config_file]
```

- `archive_root` – base folder containing the quarantine and manifest directories.
- `config_file` – JSON config with `repo_name` (defaults to `config/manifest.config.json`).

### coordinate-repo-cleaning.sh

High level wrapper that executes the full cleaning workflow. Options mirror the individual scripts.

```
./coordinate-repo-cleaning.sh \
  -r <repo_folder> \
  -n <repo_name> \
  -u <repo_url> \
  -a <additional_folder> \
  --additional-dest <dest> \
  --quarantine <quarantine_path> \
  --new \
  --upload-lfs
```

### check-lfs-integrity.ps1

PowerShell utility to verify that all LFS objects referenced in a repository exist on the server.

```
pwsh ./check-lfs-integrity.ps1
```

### install-lfs-guard.sh

Manually install the LFS guard and pre-commit hook into a path.

```
./install-lfs-guard.sh <target_path> [manifest_yaml]
```

- `target_path` – repository or directory where the guard should be placed.
- `manifest_yaml` – optional path to a manifest used to compute a SHA-256 hash stored in `.lfs.guard`.

