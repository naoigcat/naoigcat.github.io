#!/usr/bin/env bash
# Regression: GitHub Pages builds with `future: true` (github-pages gem default),
# so every local Jekyll invocation must pass --future. Without it, a post whose
# `date:` is ahead of the build clock is dropped from site.tags, its tag JSON is
# deleted by the cleanup step, and `mise run serve` hides the post entirely.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

# Each entry: file, subcommand that must carry --future.
checks=(
  "$root/scripts/generate-tags-json.sh|jekyll build"
  "$root/mise.toml|jekyll serve"
)

for check in "${checks[@]}"; do
  file="${check%%|*}"
  subcommand="${check##*|}"
  name="${file#"$root/"}"

  # Collect every invocation line of the subcommand; there must be at least one.
  invocations="$(grep -E "(^|[[:space:]])${subcommand}([[:space:]]|$)" "$file" || true)"
  if [[ -z $invocations ]]; then
    echo "$name: no '$subcommand' invocation found" >&2
    exit 1
  fi

  while IFS= read -r line; do
    if ! grep -qE -- "(^|[[:space:]])--future([[:space:]]|$)" <<<"$line"; then
      echo "$name: '$subcommand' runs without --future: $line" >&2
      exit 1
    fi
  done <<<"$invocations"
done

echo "ok: local Jekyll invocations pass --future"
