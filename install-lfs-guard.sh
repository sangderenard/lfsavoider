#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <target_path> [manifest_yaml]" >&2
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

target="$1"
manifest="${2:-}"

hash="N/A"
if [[ -n "$manifest" && -f "$manifest" ]]; then
  hash=$(sha256sum "$manifest" | awk '{print $1}')
fi

mkdir -p "$target"
cat > "$target/.lfs.guard" <<EOF2
This repository has had Git LFS removed. Reintroducing LFS is prohibited.
Manifest SHA256: $hash
EOF2

hook_dir="$target/.git/hooks"
mkdir -p "$hook_dir"
cat > "$hook_dir/pre-commit" <<'HOOK'
#!/usr/bin/env bash
if git lfs ls-files | grep -q .; then
  echo "❌ LFS usage is prohibited in this repo."
  exit 1
fi
HOOK
chmod +x "$hook_dir/pre-commit"

