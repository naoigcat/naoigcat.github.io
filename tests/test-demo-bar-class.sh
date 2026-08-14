#!/usr/bin/env bash
# Regression: DemoSort.attachPlayback option objects must set barClass.
# Without it, default mountBars leaves bars unstyled (invisible).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$root" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
posts_dir = root / "_posts"
marker = "DemoSort.attachPlayback("
errors: list[str] = []
checked = 0

for path in sorted(posts_dir.rglob("*.md")):
    text = path.read_text(encoding="utf-8")
    if marker not in text:
        continue
    rel = path.relative_to(root)
    search_from = 0
    call_no = 0
    while True:
        idx = text.find(marker, search_from)
        if idx < 0:
            break
        call_no += 1
        brace_start = text.find("{", idx + len(marker))
        if brace_start < 0:
            errors.append(f"{rel}: attachPlayback #{call_no}: missing opening '{{'")
            break
        depth = 0
        i = brace_start
        end = -1
        while i < len(text):
            ch = text[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = i
                    break
            i += 1
        if end < 0:
            errors.append(f"{rel}: attachPlayback #{call_no}: unclosed options object")
            break
        block = text[brace_start : end + 1]
        checked += 1
        if not re.search(r"\bbarClass\s*:", block):
            errors.append(
                f"{rel}: attachPlayback #{call_no}: missing barClass "
                "(required so DemoSort.mountBars styles bars)"
            )
        search_from = end + 1

if checked == 0:
    print("No DemoSort.attachPlayback calls found under _posts/", file=sys.stderr)
    sys.exit(1)

if errors:
    print("Missing barClass in sort demo attachPlayback options:", file=sys.stderr)
    for err in errors:
        print(f"  {err}", file=sys.stderr)
    sys.exit(1)

print(f"ok: {checked} attachPlayback call(s) set barClass")
PY
