#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: render-benchmark-script.sh <algorithm>" >&2
  exit 2
fi

algorithm="$1"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
pages_image="$(awk -F'"' '/github_pages_image/ { print $2; exit }' "$root/mise.toml")"

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

mkdir -p "$workdir/_layouts" "$workdir/_includes" "$workdir/_data"
cp -R "$root/_includes/sort-benchmark" "$workdir/_includes/"
cp "$root/_includes/sort-benchmark.md" "$workdir/_includes/"
cp "$root/_data/sort_algorithms.yml" "$workdir/_data/"

cat >"$workdir/_config.yml" <<'YAML'
title: benchmark-render
theme: null
plugins: []
YAML

cat >"$workdir/_layouts/null.html" <<'HTML'
{{ content }}
HTML

cat >"$workdir/render.md" <<MD
---
layout: null
---
{% include sort-benchmark.md algorithm="${algorithm}" %}
MD

docker run --rm \
  -v "$workdir:/work" \
  "$pages_image" \
  jekyll build -s /work -d /work/_site >/dev/null

python3 - "$workdir/_site/render.html" <<'PY'
import html
import sys
from html.parser import HTMLParser
from pathlib import Path


class CodeExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_target = False
        self.in_code = False
        self.chunks: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_map = dict(attrs)
        if tag == "div" and attr_map.get("class") == "sort-benchmark-code":
            self.in_target = True
        if self.in_target and tag == "code":
            self.in_code = True

    def handle_endtag(self, tag: str) -> None:
        if self.in_target and tag == "code":
            self.in_code = False
        if tag == "div" and self.in_target:
            self.in_target = False

    def handle_data(self, data: str) -> None:
        if self.in_code:
            self.chunks.append(data)


path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"Rendered HTML not found: {path}")

parser = CodeExtractor()
parser.feed(path.read_text(encoding="utf-8"))
script = html.unescape("".join(parser.chunks)).strip()
if not script.startswith("set -euo pipefail"):
    raise SystemExit("Failed to extract benchmark shell script from rendered HTML")
print(script)
PY
