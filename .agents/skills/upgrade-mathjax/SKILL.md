---
name: upgrade-mathjax
description: >-
  Bumps the MathJax CDN script version and regenerates the Subresource Integrity hash in
  `_includes/head.html`. Use when upgrading MathJax, changing the mathjax.jsdelivr URL, or fixing a
  broken SRI mismatch on `mathjax: true` posts.
paths:
  - "_includes/head.html"
---

# upgrade-mathjax

Production loads MathJax from a CDN **only on posts whose front matter sets `mathjax: true`**.
Dependabot does not bump that script; the version URL and SRI hash in `_includes/head.html` are
**manually maintained**. A mismatched `integrity` breaks all MathJax posts.

Posts write math with kramdown `$$...$$` (inline in a paragraph, or display when the `$$` block is
its own paragraph). kramdown emits `\(...\)` / `\[...\]` for MathJax to typeset.

## Workflow

1.  Choose the target MathJax version (for example from [jsDelivr mathjax](https://www.jsdelivr.com/package/npm/mathjax)).
2.  Update the `src` on the MathJax `<script>` in `_includes/head.html` to match, e.g.
    `https://cdn.jsdelivr.net/npm/mathjax@VERSION/tex-chtml.js`.
3.  Regenerate the `integrity` attribute for that exact file. Prefer one of:
    -   browser DevTools SRI / “Copy as SRI” for the downloaded script
    -   `openssl dgst -sha512 -binary tex-chtml.js | openssl base64 -A` then prefix with `sha512-`
4.  Keep `id="MathJax-script"`, `async`, and `crossorigin="anonymous"` as in the existing tag.
5.  Spot-check a post with `mathjax: true` (formulas render; console has no SRI or MathJax load
    errors).

Do **not** vendor MathJax under `assets/` unless the maintainer explicitly asks; CDN opt-in is the
accepted trade-off (see `AGENTS.md`).
