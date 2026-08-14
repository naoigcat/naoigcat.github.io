---
name: upgrade-mermaid
description: >-
  Bumps the Mermaid CDN script version and regenerates the Subresource Integrity hash in
  `_includes/head.html`. Use when upgrading Mermaid, changing the mermaid.jsdelivr URL, or fixing a
  broken SRI mismatch on `mermaid: true` posts.
paths:
  - "_includes/head.html"
---

# upgrade-mermaid

Production loads Mermaid from a CDN **only on posts whose front matter sets `mermaid: true`**.
Dependabot does not bump that script; the version URL and SRI hash in `_includes/head.html` are
**manually maintained**. A mismatched `integrity` breaks all Mermaid posts.

## Workflow

1.  Choose the target Mermaid version (for example from [jsDelivr mermaid](https://www.jsdelivr.com/package/npm/mermaid)).
2.  Update the `src` on the Mermaid `<script>` in `_includes/head.html` to match, e.g.
    `https://cdn.jsdelivr.net/npm/mermaid@VERSION/dist/mermaid.min.js`.
3.  Regenerate the `integrity` attribute for that exact file. Prefer one of:
    -   browser DevTools SRI / “Copy as SRI” for the downloaded script
    -   `openssl dgst -sha512 -binary mermaid.min.js | openssl base64 -A` then prefix with `sha512-`
4.  Keep `crossorigin="anonymous"` and `defer` as in the existing tag.
5.  Spot-check a post with `mermaid: true` (diagrams render; console has no SRI or Mermaid load errors).

Do **not** vendor Mermaid under `assets/` unless the maintainer explicitly asks; CDN opt-in is the
accepted trade-off (see `AGENTS.md`).
