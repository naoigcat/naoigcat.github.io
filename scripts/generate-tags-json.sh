#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
pages_image="$(awk -F'"' '/github_pages_image/ { print $2; exit }' "$root/mise.toml")"
out_dir="$root/assets/tags"

if [[ -z $pages_image ]]; then
  echo "Could not read github_pages_image from mise.toml" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not available. Start Docker and retry." >&2
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

rsync -a \
  --exclude .git \
  --exclude _site \
  --exclude assets/tags \
  "$root/" "$workdir/"

mkdir -p "$workdir/_layouts"
printf '%s\n' '{{ content }}' > "$workdir/_layouts/null.html"

{
  echo "---"
  echo "layout: null"
  echo "markdown: false"
  echo "---"
  cat "$root/scripts/export-all-tags.md.liquid"
} > "$workdir/export-all-tags.html"

site_out="$workdir/_site"
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$workdir:/work" \
  "$pages_image" \
  jekyll build -s /work -d /work/_site >/dev/null

python3 - "$site_out/export-all-tags.html" "$out_dir" <<'PY'
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
dest = Path(sys.argv[2])

if not source.is_file():
    raise SystemExit(f"Export file not found: {source}")

tags = json.loads(source.read_text(encoding="utf-8"))
dest.mkdir(parents=True, exist_ok=True)

seen: set[str] = set()
for tag in tags:
    slug = tag["slug"]
    seen.add(slug)
    path = dest / f"{slug}.json"
    path.write_text(json.dumps(tag, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

for path in dest.glob("*.json"):
    if path.stem not in seen:
        path.unlink()

print(f"Wrote {len(seen)} tag JSON files to {dest}", file=sys.stderr)
PY
