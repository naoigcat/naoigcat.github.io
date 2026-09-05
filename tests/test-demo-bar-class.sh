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


def find_options_block(text: str, call_end: int) -> tuple[str | None, int, str | None]:
    """Return (block, resume_index, error) for the options literal following a call.

    The literal must start right after "attachPlayback(" (whitespace only), so a
    variable such as attachPlayback(opts) is reported instead of silently matching
    whatever object literal appears later in the file. Braces inside strings,
    template literals, and comments are skipped so caption text like '}' does not
    unbalance the depth count.
    """
    m = re.compile(r"\s*\{").match(text, call_end)
    if m is None:
        return None, call_end, "options must be an inline object literal starting with '{'"
    brace_start = m.end() - 1
    depth = 0
    i = brace_start
    n = len(text)
    while i < n:
        ch = text[i]
        if ch in "'\"`":
            quote = ch
            i += 1
            while i < n and text[i] != quote:
                if text[i] == "\\":
                    i += 1
                elif quote != "`" and text[i] == "\n":
                    break  # unterminated single-line string; stop skipping
                i += 1
        elif text.startswith("//", i):
            i = text.find("\n", i)
            if i < 0:
                break
        elif text.startswith("/*", i):
            i = text.find("*/", i + 2)
            if i < 0:
                break
            i += 1
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[brace_start : i + 1], i + 1, None
        i += 1
    return None, n, "unclosed options object"


def check_text(text: str, rel: str) -> int:
    count = 0
    search_from = 0
    call_no = 0
    while True:
        idx = text.find(marker, search_from)
        if idx < 0:
            break
        call_no += 1
        block, search_from, err = find_options_block(text, idx + len(marker))
        if block is None:
            errors.append(f"{rel}: attachPlayback #{call_no}: {err}")
            break
        count += 1
        if not re.search(r"\bbarClass\s*:", block):
            errors.append(
                f"{rel}: attachPlayback #{call_no}: missing barClass "
                "(required so DemoSort.mountBars styles bars)"
            )
    return count


# Self-check the parser on the shapes that used to be misjudged before scanning posts.
self_checks = [
    # Variable-passed options must not borrow a later object literal that has barClass.
    (
        "DemoSort.attachPlayback(opts);\nconst other = { barClass: 'x' };\n",
        "options must be an inline object literal",
    ),
    # A closing brace inside a string must not terminate the literal early.
    (
        "DemoSort.attachPlayback({\n  initialCaption: '}',\n  barClass: 'bar',\n});\n",
        None,
    ),
    # Braces in comments and template literals are likewise ignored.
    (
        "DemoSort.attachPlayback({ // {\n  caption: `${x}}`, /* } */ barClass: 'bar' });\n",
        None,
    ),
    # Missing barClass is still reported.
    (
        "DemoSort.attachPlayback({\n  initialCaption: '}',\n});\n",
        "missing barClass",
    ),
]
for text, expected in self_checks:
    errors.clear()
    check_text(text, "<self-check>")
    got = errors[0] if errors else None
    if (expected is None) != (got is None) or (expected and expected not in got):
        print(f"self-check failed for {text!r}: expected {expected!r}, got {got!r}", file=sys.stderr)
        sys.exit(1)
errors.clear()

for path in sorted(posts_dir.rglob("*.md")):
    text = path.read_text(encoding="utf-8")
    if marker not in text:
        continue
    checked += check_text(text, str(path.relative_to(root)))

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
