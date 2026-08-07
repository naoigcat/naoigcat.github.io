#!/usr/bin/env bash
# Regression: Mermaid CDN URL integrity in _includes/head.html must match the file.
# Skips when the CDN cannot be fetched (offline environments).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
head="$root/_includes/head.html"

src="$(
  sed -nE 's/.*src="(https:\/\/cdn\.jsdelivr\.net\/npm\/mermaid@[^"]+\.js)".*/\1/p' "$head" \
    | head -n1
)"
integrity="$(
  sed -nE 's/.*integrity="(sha512-[^"]+)".*/\1/p' "$head" \
    | head -n1
)"

if [[ -z $src ]]; then
  echo "Could not find Mermaid script src in $head" >&2
  exit 1
fi
if [[ -z $integrity ]]; then
  echo "Could not find Mermaid integrity in $head" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
body="$tmpdir/mermaid.min.js"

if ! curl -fsSL --connect-timeout 10 --max-time 60 "$src" -o "$body"; then
  echo "skip: could not fetch Mermaid CDN ($src); integrity not verified"
  exit 0
fi

got="sha512-$(openssl dgst -sha512 -binary "$body" | openssl base64 -A)"
if [[ $got != "$integrity" ]]; then
  echo "Mermaid SRI mismatch for $src" >&2
  echo "head.html: $integrity" >&2
  echo "computed:  $got" >&2
  exit 1
fi

echo "ok: Mermaid SRI matches CDN ($src)"
