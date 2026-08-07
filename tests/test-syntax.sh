#!/usr/bin/env bash
# Regression: committed shell and site JS must parse.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

check_bash() {
  local path="$1"
  if ! bash -n "$path"; then
    echo "bash -n failed: $path" >&2
    failed=1
  fi
}

check_node() {
  local path="$1"
  if ! node --check "$path"; then
    echo "node --check failed: $path" >&2
    failed=1
  fi
}

while IFS= read -r -d '' path; do
  check_bash "$path"
done < <(find "$root/scripts" "$root/tests" -type f -name '*.sh' -print0 | sort -z)

while IFS= read -r -d '' path; do
  check_node "$path"
done < <(find "$root/assets/js" -type f -name '*.js' -print0 | sort -z)

if (( failed != 0 )); then
  exit 1
fi

echo "ok: shell and JS syntax"
