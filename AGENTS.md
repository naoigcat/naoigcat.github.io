# Instructions for automated assistants

## GitHub Pages already runs Jekyll

This repository is published with **GitHub Pages**. Pushing to the branch that Pages uses triggers **GitHub’s Jekyll build** in their environment.
Whether that build passes or fails is visible in the repository’s Pages deployment state and history.

**Do not recommend** adding GitHub Actions (or other CI) jobs whose *only* purpose is to run `jekyll build` (or equivalent)
“because the site would otherwise not be built,” “to discover build failures before deploy,” or “Pages does not build the site.”
That reasoning is **incorrect for this repository**: integration with the hosted stack is already enforced on push.

Do not volunteer that suggestion in reviews, audits, or advice unless the maintainer **explicitly** asks
for a duplicate build, PR-preview sites, or another goal that requires Actions.

## Custom `_plugins` and local vs production

GitHub Pages’ default Jekyll build **does not run** custom Ruby plugins from `_plugins/`. Only the [whitelisted plugins](https://pages.github.com/versions/) apply in production.

This repository **must not depend** on `_plugins/` for behavior that needs to work on the live site. Tag pages are implemented on the committed `/tags/` page: build-time Liquid embeds tag metadata, and `/tags/?tag={slug}` filters posts in the browser (`assets/js/tags.js`). Post footers link to that query form, not to per-tag paths like `/tags/sort/`.

Local `mise run serve` may still load `_plugins/` if files are present, which can create **dev/prod drift**. Do not reintroduce tag generators or other custom plugins without an explicit deployment change. If a feature needs a generator, prefer committed Liquid/JS or ask the maintainer about changing how Pages is built.

## In-article JavaScript targets modern browsers

The JavaScript embedded in posts (for example, the sort-algorithm demos under `_posts/` that mount via `{% include sort-demo.html ... %}`)
**does not need to support Internet Explorer or any other engine that lacks ES2015+ syntax**.
Treat the runtime baseline as evergreen browsers.

When writing or editing article scripts, prefer contemporary, readable language features:
`const`/`let` rather than `var`, arrow functions, template literals, default and rest parameters, destructuring,
`class`, `Promise`/`async`/`await`, `Map`/`Set`, optional chaining and nullish coalescing, `BigInt` literals, and similar constructs
are all acceptable whenever they make the demo clearer.

The goal is to **keep article code from accreting legacy patterns for the sake of obsolete browsers**, not to mandate any
specific keyword. Do not rewrite working article scripts toward older idioms (for example forcing `var`, hand-rolled polyfills,
transpiled-style output, or browser-version sniffing) in the name of broader compatibility,
and do not flag the existing modern syntax as a review finding unless the maintainer explicitly asks to widen the supported browser set.

## Do not volunteer these topics in reviews

The following choices are intentional or already accepted trade-offs for this site.
Unless the maintainer asks about them explicitly, **do not** raise them as review findings, nits, or “consider later” bullets.

### Third-party JavaScript (Mermaid)

Production loads the Mermaid script from a CDN **only on posts whose front matter sets `mermaid: true`**. That opt-in loading is deliberate.
Do not suggest vendoring the same version under `assets` for offline verification or CDN resilience unless the maintainer asks;
it is an optional future trade-off against maintenance cost, not an outstanding gap.

Because Dependabot does not bump that script, the version URL and Subresource Integrity hash
in `_includes/head.html` are **manually maintained**.
When upgrading Mermaid, update the `src` version and regenerate `integrity`
(for example with a browser devtools SRI tool or `openssl`) so the hash matches the new file;
mismatches break all `mermaid: true` posts.

### Analytics

`_config.yml` defines `google_analytics`, and the theme is expected to load it in production only.
There is no EU-style consent banner in this site’s own markup.
Treat analytics and consent posture as settled unless the maintainer asks about jurisdictions or CMPs.

### Dependabot scope

`.github/dependabot.yml` targets **GitHub Actions only**. Gems are intentionally left to GitHub Pages’ build environment; that split is deliberate.
Do not suggest widening Dependabot to RubyGems/npm “for completeness” unless those ecosystems gain first-class use in this repo.

### Sync workflows and `contents: write`

Two workflows declare `permissions: contents: write` and push commits when their target files change. That narrow automation is intentional.
Do not flag `contents: write`, automated `git push`, or these “commit only the touched lines” designs as review findings
unless the maintainer asks to change them.

**Markdownlint pin (`sync-markdownlint.yml`).** On push to `main` or `dependabot/**` when
`.github/workflows/lint.yml` changes, the workflow resolves the pinned
`DavidAnson/markdownlint-cli2-action` ref, updates only the `markdownlint_cli2_image = "…"` line in
`mise.toml`, and pushes when that line changes. Local lint runs via `mise run lint` (Docker image from
that var).
It is gated with `if: github.ref == 'refs/heads/main' || github.actor == 'dependabot[bot]'`.

**GitHub Pages Docker image (`sync-githubpages.yml`).** On `workflow_dispatch` or a weekly schedule,
it compares `github_pages_image` in `mise.toml` to numeric tags on Docker Hub for the configured
repo, bumps the tag to the latest numeric value when higher, commits `mise.toml`, and pushes.

Human security reviewers may still want to track that workflows with repository write access increase blast radius **if**
malicious workflow YAML could reach branches where Actions runs.
Routine mitigation is branch protection and required review so untrusted contributors cannot land arbitrary workflows.
Do not recycle that generic posture into AI review nits (for example urging removal of write permissions or extra gates)
unless the maintainer explicitly asks.

### Site metadata consistency

The site uses `lang: ja` with Japanese article bodies while retaining an Irish-language–style display name in `title` (and similar branding).
That mix is intentional. Do not flag it as inconsistent for SEO or browser language heuristics unless the maintainer asks to revisit naming or localization.

### Error pages (`404.html`)

The not-found page is intentionally English (`lang: en` and English body copy; no `title` in front matter
so it stays out of Minima’s header nav), while the rest of the site defaults to Japanese metadata from `_config.yml`.
The HTML `<title>` (tab label) is set in `_includes/head.html` when `page.path` is `404.html`, without adding front matter `title`.
Do not suggest aligning it with `site.lang` unless the maintainer asks.
