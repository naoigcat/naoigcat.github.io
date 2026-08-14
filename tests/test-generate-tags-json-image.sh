#!/usr/bin/env bash
# Regression: every script that resolves the pages image must read the
# github_pages_image assignment, not an earlier "{{vars.github_pages_image}}"
# reference in mise.toml.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
scripts=(
  "$root/scripts/generate-tags-json.sh"
  "$root/.agents/skills/benchmark-sort/scripts/render-benchmark-script.sh"
)

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

# Normal path: assignment precedes any template reference.
cat > "$tmpdir/assignment-first.toml" <<'EOF'
[vars]
github_pages_image = "naoigcat/github-pages:232"

[tasks.serve]
run = '''
  "{{vars.github_pages_image}}" \
'''
EOF

for script in "${scripts[@]}"; do
  awk_prog="$(
    sed -nE "s/.*awk -F'\"' '([^']+)' .*/\\1/p" "$script" | head -n1
  )"
  if [[ -z $awk_prog ]]; then
    echo "Could not extract awk program from $script" >&2
    exit 1
  fi

  name="$(basename "$script")"

  got="$(awk -F'"' "$awk_prog" "$tmpdir/template-first.toml")"
  want="naoigcat/github-pages:999"
  if [[ $got != "$want" ]]; then
    echo "$name template-first: expected $want, got ${got:-<empty>}" >&2
    exit 1
  fi

  got="$(awk -F'"' "$awk_prog" "$tmpdir/assignment-first.toml")"
  want="naoigcat/github-pages:232"
  if [[ $got != "$want" ]]; then
    echo "$name assignment-first: expected $want, got ${got:-<empty>}" >&2
    exit 1
  fi
done

echo "ok: github_pages_image assignment parse"
