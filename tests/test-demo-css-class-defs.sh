#!/usr/bin/env bash
# Regression: demo class names from the review must not be assigned in posts
# unless sort-demo.css defines a rule for them (avoids silent no-op modifiers).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
css="$root/assets/css/sort-demo.css"
posts="$root/_posts"

python3 - "$css" "$posts" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

css_path = Path(sys.argv[1])
posts_dir = Path(sys.argv[2])
css = css_path.read_text(encoding="utf-8")

# Classes that previously had no CSS rule while still being assigned in demos.
watched = [
    "burst-demo__tier--ones",
    "burst-demo__tier--tens",
    "sort-demo-unshuffle__incoming-block",
    "sort-demo-unshuffle__merged-block",
    "sort-demo-unshuffle__piles-block",
    "sort-demo__bar--gap",
    "pigeonhole-demo__input",
    "postman-demo__array",
    "veb-demo__canvas",
]


def css_defines(class_name: str) -> bool:
    # Match .class or #id .class selectors; ignore mere comments mentioning the name.
    return re.search(rf"(?<![\w-])\.{re.escape(class_name)}(?![\w-])", css) is not None


errors: list[str] = []
for class_name in watched:
    post_hits: list[str] = []
    for path in sorted(posts_dir.rglob("*.md")):
        text = path.read_text(encoding="utf-8")
        if class_name in text:
            post_hits.append(str(path.relative_to(posts_dir.parent)))
    if post_hits and not css_defines(class_name):
        errors.append(
            f"{class_name}: assigned in {', '.join(post_hits)} but missing from sort-demo.css"
        )

if errors:
    print("undefined demo CSS class(es):", file=sys.stderr)
    for err in errors:
        print(f"  {err}", file=sys.stderr)
    sys.exit(1)

print(f"ok: {len(watched)} watched demo class name(s) are defined when used")
PY
