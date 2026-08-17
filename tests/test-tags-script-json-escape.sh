#!/usr/bin/env bash
# Regression: JSON embedded in /tags/ <script> must escape "<" so a title
# containing "</script>" cannot break out of the script element.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pages_image="$(awk -F'"' '/^github_pages_image[[:space:]]*=/ { print $2; exit }' "$root/mise.toml")"

if [[ -z $pages_image ]]; then
  echo "Could not read github_pages_image from mise.toml" >&2
  exit 1
fi

for path in tags/index.html _includes/tags-tag-json-full.html; do
  if ! grep -qE "jsonify \| replace: '<', '\\\\u003c'" "$root/$path"; then
    echo "$path: missing jsonify | replace escape for script-safe JSON" >&2
    exit 1
  fi
  # Every jsonify in these templates must be followed by the replace (no bare jsonify).
  if grep -nE '\|\s*jsonify\s*}}' "$root/$path" | grep -vq "replace:"; then
    echo "$path: found jsonify without | replace: '<', '\\u003c'" >&2
    grep -nE '\|\s*jsonify' "$root/$path" >&2 || true
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "skip: Docker is not available; source escape checked only"
  exit 0
fi

workdir="$(mktemp -d "${TMPDIR:-/tmp}/tags-script-escape.XXXXXX")"
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

# Prefer workspace-adjacent temp if /tmp cannot be bind-mounted.
if ! docker run --rm -v "$workdir:/work" "$pages_image" true >/dev/null 2>&1; then
  workdir="$root/.tmp-tags-script-escape-test"
  rm -rf "$workdir"
  mkdir -p "$workdir"
  cleanup() { rm -rf "$workdir"; }
fi

rsync -a \
  --exclude .git \
  --exclude _site \
  --exclude .tmp-tags-script-escape-test \
  "$root/" "$workdir/"

python3 - "$workdir" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
config = root / "_config.yml"
text = config.read_text(encoding="utf-8")
# Inject a site title that would close the tags-data script without escaping.
if re.search(r"^title:\s*", text, re.M):
    text = re.sub(
        r"^title:\s*.*$",
        'title: "Leak </script><script>alert(1)</script>"',
        text,
        count=1,
        flags=re.M,
    )
else:
    text = 'title: "Leak </script><script>alert(1)</script>"\n' + text
config.write_text(text, encoding="utf-8")
PY

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$workdir:/work" \
  "$pages_image" \
  jekyll build -s /work -d /work/_site >/dev/null

built="$workdir/_site/tags/index.html"
if [[ ! -f $built ]]; then
  echo "Built tags page missing: $built" >&2
  exit 1
fi

python3 - "$built" <<'PY'
from pathlib import Path
import json
import re
import sys

html = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(
    r'<script type="application/json" id="tags-data">(.*?)</script>',
    html,
    re.S,
)
if not match:
    raise SystemExit("tags-data script block not found in built /tags/")

payload = match.group(1)
if "</script>" in payload:
    raise SystemExit("raw </script> remains inside tags-data JSON payload")

data = json.loads(payload)
title = data.get("siteTitle", "")
if "<" not in title or "script" not in title:
    raise SystemExit(f"expected decoded siteTitle to contain <script…>, got {title!r}")
if "\\u003c" not in match.group(0) and "\\u003c" not in payload:
    # json.loads already decoded; confirm the HTML source used escapes.
    if "\\u003c" not in html[match.start() : match.end()]:
        raise SystemExit("expected \\u003c escapes in tags-data HTML source")

print("ok: tags-data escapes </script> in JSON-in-script embedding")
PY
