#!/usr/bin/env bash
# Entry point for repository regression tests. Invoked via `mise run test`.
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
failed=0
count=0

while IFS= read -r -d '' test_file; do
  count=$((count + 1))
  name="$(basename "$test_file")"
  echo "==> $name"
  case "$test_file" in
    *.sh)
      if ! bash "$test_file"; then
        failed=1
      fi
      ;;
    *.mjs)
      if ! node "$test_file"; then
        failed=1
      fi
      ;;
  esac
done < <(find "$dir" -maxdepth 1 \( -name 'test-*.sh' -o -name 'test-*.mjs' \) -print0 | sort -z)

if (( count == 0 )); then
  echo "No test scripts found under $dir" >&2
  exit 1
fi

if (( failed != 0 )); then
  echo "FAILED: one or more tests did not pass" >&2
  exit 1
fi

echo "All $count test(s) passed."
