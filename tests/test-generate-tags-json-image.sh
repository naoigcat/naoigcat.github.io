#!/usr/bin/env bash
# Regression: generate-tags-json.sh must read the github_pages_image assignment,
# not an earlier "{{vars.github_pages_image}}" reference in mise.toml.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
script="$root/scripts/generate-tags-json.sh"

awk_prog="$(
  sed -nE "s/.*awk -F'\"' '([^']+)' .*/\\1/p" "$script" | head -n1
)"
if [[ -z $awk_prog ]]; then
  echo "Could not extract awk program from $script" >&2
  exit 1
fi

parse_image() {
  awk -F'"' "$awk_prog" "$1"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Boundary: template reference appears before the assignment.
cat > "$tmpdir/template-first.toml" <<'EOF'
[tasks.serve]
run = '''
  "{{vars.github_pages_image}}" \
'''

[vars]
github_pages_image = "naoigcat/github-pages:999"
EOF

got="$(parse_image "$tmpdir/template-first.toml")"
want="naoigcat/github-pages:999"
if [[ $got != "$want" ]]; then
  echo "template-first: expected $want, got ${got:-<empty>}" >&2
  exit 1
fi

# Normal path: assignment precedes any template reference.
cat > "$tmpdir/assignment-first.toml" <<'EOF'
[vars]
github_pages_image = "naoigcat/github-pages:232"

[tasks.serve]
run = '''
  "{{vars.github_pages_image}}" \
'''
EOF

got="$(parse_image "$tmpdir/assignment-first.toml")"
want="naoigcat/github-pages:232"
if [[ $got != "$want" ]]; then
  echo "assignment-first: expected $want, got ${got:-<empty>}" >&2
  exit 1
fi

echo "ok: github_pages_image assignment parse"
