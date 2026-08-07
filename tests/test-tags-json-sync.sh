#!/usr/bin/env bash
# Regression: committed assets/tags/*.json must match post front matter,
# and tags_embed slugs must resolve to existing tag JSON files.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$root" <<'PY'
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

root = Path(sys.argv[1])
posts_dir = root / "_posts"
tags_dir = root / "assets" / "tags"
embed_path = root / "_data" / "tags_embed.yml"

errors: list[str] = []

tag_to_posts: dict[str, list[tuple[str, str, str]]] = defaultdict(list)

for path in sorted(posts_dir.rglob("*.md")):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        errors.append(f"{path.relative_to(root)}: missing front matter")
        continue
    end = text.find("\n---", 3)
    if end < 0:
        errors.append(f"{path.relative_to(root)}: unclosed front matter")
        continue
    fm = text[3:end]

    title_m = re.search(r"^title:\s*(.*)$", fm, re.M)
    tags_m = re.search(r"^tags:\s*(.*)$", fm, re.M)
    date_m = re.search(r"^date:\s*(\d{4}-\d{2}-\d{2})", fm, re.M)
    name_m = re.match(r"(\d{4})-(\d{2})-(\d{2})-(.+)\.md$", path.name)

    if not title_m:
        errors.append(f"{path.relative_to(root)}: missing title")
        continue
    if not tags_m or not tags_m.group(1).strip():
        errors.append(f"{path.relative_to(root)}: missing inline tags")
        continue
    if not date_m:
        errors.append(f"{path.relative_to(root)}: missing date")
        continue
    if not name_m:
        errors.append(f"{path.relative_to(root)}: unexpected filename")
        continue

    title = title_m.group(1).strip()
    tags = tags_m.group(1).split()
    date = date_m.group(1)
    url = f"/{name_m.group(1)}/{name_m.group(2)}/{name_m.group(3)}/{name_m.group(4)}.html"
    for tag in tags:
        tag_to_posts[tag].append((title, url, date))

json_names: set[str] = set()
for path in sorted(tags_dir.glob("*.json")):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"{path.relative_to(root)}: invalid JSON ({exc})")
        continue

    for key in ("name", "slug", "posts"):
        if key not in data:
            errors.append(f"{path.relative_to(root)}: missing {key!r}")

    name = data.get("name")
    slug = data.get("slug")
    posts = data.get("posts")

    if not isinstance(name, str) or not name:
        errors.append(f"{path.relative_to(root)}: name must be a non-empty string")
        continue
    if slug != path.stem:
        errors.append(
            f"{path.relative_to(root)}: slug {slug!r} must equal filename stem {path.stem!r}"
        )
    if name != path.stem:
        # Current site tags are ASCII slugs equal to the tag name.
        errors.append(
            f"{path.relative_to(root)}: name {name!r} must equal filename stem {path.stem!r}"
        )

    json_names.add(name)

    if not isinstance(posts, list):
        errors.append(f"{path.relative_to(root)}: posts must be a list")
        continue

    expected = [
        {"title": title, "url": url}
        for title, url, _date in sorted(
            tag_to_posts.get(name, []), key=lambda row: row[2], reverse=True
        )
    ]
    got = []
    for i, post in enumerate(posts):
        if not isinstance(post, dict):
            errors.append(f"{path.relative_to(root)}: posts[{i}] must be an object")
            continue
        for key in ("title", "url", "date"):
            if key not in post:
                errors.append(f"{path.relative_to(root)}: posts[{i}] missing {key!r}")
        got.append({"title": post.get("title"), "url": post.get("url")})

    if got != expected:
        errors.append(
            f"{path.relative_to(root)}: post list does not match front matter "
            f"(json={len(got)}, posts={len(expected)})"
        )
        for i, (a, b) in enumerate(zip(got, expected)):
            if a != b:
                errors.append(f"  first diff at index {i}: json={a!r} posts={b!r}")
                break
        if len(got) != len(expected):
            json_urls = {row["url"] for row in got}
            post_urls = {row["url"] for row in expected}
            only_json = sorted(json_urls - post_urls)
            only_posts = sorted(post_urls - json_urls)
            if only_json:
                errors.append(f"  only in JSON: {only_json[:5]}")
            if only_posts:
                errors.append(f"  only in posts: {only_posts[:5]}")

missing_json = sorted(set(tag_to_posts) - json_names)
extra_json = sorted(json_names - set(tag_to_posts))
if missing_json:
    errors.append(f"tag JSON missing for: {missing_json}")
if extra_json:
    errors.append(f"tag JSON without posts: {extra_json}")

if not embed_path.is_file():
    errors.append(f"missing {embed_path.relative_to(root)}")
else:
    embed_slugs: list[str] = []
    for line in embed_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            embed_slugs.append(stripped[2:].strip())
    if not embed_slugs:
        errors.append("tags_embed.yml has no slugs")
    for slug in embed_slugs:
        if not (tags_dir / f"{slug}.json").is_file():
            errors.append(f"tags_embed slug {slug!r} has no assets/tags/{slug}.json")

if errors:
    print("tag JSON sync failed:", file=sys.stderr)
    for err in errors:
        print(err, file=sys.stderr)
    raise SystemExit(1)

print(
    f"ok: {len(json_names)} tag JSON file(s) match {sum(len(v) for v in tag_to_posts.values())} post-tag link(s)"
)
PY
