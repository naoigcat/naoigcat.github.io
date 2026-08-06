#!/usr/bin/env bash
# Regression: only paths that should ship may remain outside Jekyll exclude.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
config="$root/_config.yml"

# Whitelist: top-level paths that must remain publishable (not excluded).
whitelist="$(cat <<'EOF'
404.html
apple-touch-icon-precomposed.png
assets
favicon.ico
index.md
tags
EOF
)"

excluded="$(
  awk '
    /^exclude:/ { in_exclude = 1; next }
    in_exclude && /^[^[:space:]#-]/ { in_exclude = 0 }
    in_exclude && /^[[:space:]]*-[[:space:]]*/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "")
      sub(/[[:space:]]*$/, "")
      if ($0 != "") print
    }
  ' "$config"
)"

if [[ -z $excluded ]]; then
  echo "exclude: list is missing or empty in $config" >&2
  exit 1
fi

# Top-level entries Jekyll would consider (not hidden / underscore-special).
candidates="$(
  find "$root" -maxdepth 1 -mindepth 1 \( -type f -o -type d \) -print \
    | sed "s|^$root/||" \
    | awk '
        /^\./ { next }
        /^_/ { next }
        /^#/ { next }
        /^~/ { next }
        { print }
      ' \
    | LC_ALL=C sort
)"

included="$(
  comm -23 \
    <(printf '%s\n' "$candidates") \
    <(printf '%s\n' "$excluded" | LC_ALL=C sort)
)"

if [[ $included != "$whitelist" ]]; then
  echo "publishable top-level paths must equal the whitelist" >&2
  echo "whitelist:" >&2
  printf '%s\n' "$whitelist" >&2
  echo "actual (candidates minus exclude):" >&2
  printf '%s\n' "$included" >&2
  echo "exclude:" >&2
  printf '%s\n' "$excluded" >&2
  exit 1
fi

echo "ok: only whitelisted top-level paths remain outside exclude"
