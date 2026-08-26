#!/usr/bin/env bash
# Regression: post layout must escape page.author like page.title so HTML in
# front matter cannot inject into the byline.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
layout="$root/_layouts/post.html"

if [[ ! -f $layout ]]; then
  echo "missing layout: $layout" >&2
  exit 1
fi

if ! grep -qE '\{\{\s*page\.author\s*\|\s*escape\s*\}\}' "$layout"; then
  echo "_layouts/post.html: page.author must use | escape (same as page.title)" >&2
  grep -n 'page.author' "$layout" >&2 || true
  exit 1
fi

# Bare {{ page.author }} (no escape) must not remain in the byline span.
if grep -nE '\{\{\s*page\.author\s*\}\}' "$layout"; then
  echo "_layouts/post.html: found unescaped page.author output" >&2
  exit 1
fi

echo "ok: post layout escapes page.author"
