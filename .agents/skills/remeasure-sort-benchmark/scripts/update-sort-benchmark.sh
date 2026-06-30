#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: update-sort-benchmark.sh <algorithm> [--dry-run]

  <algorithm>  Key from _data/sort_algorithms.yml (e.g. bubble, polyphase_merge).
               Also accepts a post slug such as sort-bubble or 2026-05-01-sort-bubble.

  --dry-run    Render the benchmark script and print the post path without running Docker.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

algorithm="$1"
dry_run=0
if [[ ${2:-} == "--dry-run" ]]; then
  dry_run=1
elif [[ -n ${2:-} ]]; then
  usage >&2
  exit 2
fi

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
script_dir="$(cd "$(dirname "$0")" && pwd)"

resolve_algorithm() {
  local input="$1"
  if rg -q "^${input}:" "$root/_data/sort_algorithms.yml"; then
    printf '%s\n' "$input"
    return
  fi

  local slug="${input#sort-}"
  slug="${slug//-/_}"
  if rg -q "^${slug}:" "$root/_data/sort_algorithms.yml"; then
    printf '%s\n' "$slug"
    return
  fi

  local from_post
  from_post="$(
    rg -l "sort-benchmark\\.md algorithm=\"[^\"]+\"" "$root/_posts" 2>/dev/null \
      | rg "$input" \
      | head -1 \
      || true
  )"
  if [[ -n $from_post ]]; then
    rg -o 'algorithm="[^"]+"' "$from_post" | head -1 | tr -d '"' | cut -d= -f2
    return
  fi

  return 1
}

if ! algorithm="$(resolve_algorithm "$algorithm")"; then
  echo "Unknown algorithm or post slug: $1" >&2
  exit 1
fi

post_matches="$(rg -l "sort-benchmark\\.md algorithm=\"${algorithm}\"" "$root/_posts" 2>/dev/null || true)"
if [[ -z $post_matches ]]; then
  echo "No post includes sort-benchmark.md algorithm=\"${algorithm}\"" >&2
  exit 1
fi

post_count="$(printf '%s\n' "$post_matches" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ $post_count -gt 1 ]]; then
  echo "Multiple posts reference algorithm=\"${algorithm}\":" >&2
  printf '%s\n' "$post_matches" | sed 's/^/  /' >&2
  exit 1
fi

post="$(printf '%s\n' "$post_matches" | head -1)"
echo "algorithm: ${algorithm}" >&2
echo "post:      ${post#"$root/"}" >&2

if [[ $dry_run -eq 1 ]]; then
  "$script_dir/render-benchmark-script.sh" "$algorithm" >/dev/null
  echo "Dry run OK (benchmark script renders)." >&2
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not available. Start Docker and retry." >&2
  exit 1
fi

bench_script="$(mktemp)"
bench_output="$(mktemp)"
trap 'rm -f "$bench_script" "$bench_output"' EXIT

"$script_dir/render-benchmark-script.sh" "$algorithm" >"$bench_script"
chmod +x "$bench_script"

echo "Running benchmark (this may take 10–30+ minutes)…" >&2
if ! "$bench_script" | tee "$bench_output"; then
  echo "Benchmark failed." >&2
  exit 1
fi

python3 - "$post" "$bench_output" <<'PY'
import re
import sys
from pathlib import Path

post_path = Path(sys.argv[1])
bench_path = Path(sys.argv[2])
text = post_path.read_text(encoding="utf-8")
bench_lines = bench_path.read_text(encoding="utf-8").splitlines()

data_rows = [line for line in bench_lines if re.match(r"^\|\s+\d", line)]
if not data_rows:
    raise SystemExit("Benchmark output contained no data rows")

start = "<!-- sort-benchmark-result:start -->"
end = "<!-- sort-benchmark-result:end -->"
start_idx = text.find(start)
end_idx = text.find(end)
if start_idx == -1 or end_idx == -1 or end_idx <= start_idx:
    raise SystemExit(f"Missing {start} / {end} markers in {post_path}")

header = """|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|"""

block = "\n".join(
    [
        start,
        "",
        header,
        *data_rows,
        "",
        end,
    ]
)

updated = text[:start_idx] + block + text[end_idx + len(end) :]
post_path.write_text(updated, encoding="utf-8")
print(f"Updated {post_path} ({len(data_rows)} rows)", file=sys.stderr)
PY

echo "Running markdownlint…" >&2
( cd "$root" && mise run lint -- "${post#"$root/"}" )
