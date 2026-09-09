#!/usr/bin/env bash
# Regression: sort-demo.css must not invert colors under prefers-color-scheme:
# dark while the site chrome stays light-only (Minima / _sass/style.scss).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
css="$root/assets/css/sort-demo.css"

if grep -n 'prefers-color-scheme:[[:space:]]*dark' "$css"; then
  echo "sort-demo.css must not define dark-scheme overrides without a site dark theme" >&2
  exit 1
fi

echo "ok: sort-demo.css has no orphan prefers-color-scheme: dark rules"
