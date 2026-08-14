# Instructions for automated assistants

Always-on project constraints. Task-specific workflows live under `.agents/skills/`
(see [Cursor Skills](https://cursor.com/docs/skills.md)); load those when the work matches.

## GitHub Pages already runs Jekyll

This repository is published with **GitHub Pages**. Pushing to the branch that Pages uses triggers
**GitHub’s Jekyll build** in their environment. Build success or failure is visible in the repository’s
Pages deployment state and history.

**Do not recommend** adding GitHub Actions (or other CI) jobs whose *only* purpose is to run
`jekyll build` (or equivalent) “because the site would otherwise not be built,” “to discover build
failures before deploy,” or “Pages does not build the site.” That reasoning is **incorrect for this
repository**: integration with the hosted stack is already enforced on push.

Do not volunteer that suggestion in reviews, audits, or advice unless the maintainer **explicitly**
asks for a duplicate build, PR-preview sites, or another goal that requires Actions.

## Custom `_plugins` and local vs production

GitHub Pages’ default Jekyll build **does not run** custom Ruby plugins from `_plugins/`.
Only the [whitelisted plugins](https://pages.github.com/versions/) apply in production.

This repository **must not depend** on `_plugins/` for behavior that needs to work on the live site.
Tag pages use committed Liquid on `/tags/` plus on-demand `/assets/tags/{slug}.json`
(`assets/js/tags.js`); regenerate JSON with `mise run tags` after changing posts or tag metadata.
Post footers link to that query form, not to per-tag paths like `/tags/sort/`.

Local `mise run serve` may still load `_plugins/` if files are present (**dev/prod drift**).
Do not reintroduce tag generators or other custom plugins without an explicit deployment change.
If a feature needs a generator, prefer committed Liquid/JS or ask the maintainer about changing how
Pages is built.

## Do not create sort-algorithm test scripts

Do **not** add standalone test or regression scripts for sort algorithms (for example under
`tests/test-*-sort-*`, `tests/test-*-shivers-*`, or similar Node/shell harnesses that extract demo JS
from posts or recompile benchmark Rust). That includes creating them while fixing review findings,
“for completeness,” or because another skill asks for a regression test.

Correctness for the committed Rust path is already exercised by `verify_correctness` inside the
sort-benchmark harness (`_includes/sort-benchmark/helpers/verify_correctness.rs`). Article demos are
illustrative; do not grow a parallel test suite around them.

Only create such scripts if the maintainer **explicitly** asks for them. Do not recommend adding them
in reviews or audits unless asked.

## Do not volunteer these topics in reviews

The following choices are intentional or already accepted trade-offs for this site.
Unless the maintainer asks about them explicitly, **do not** raise them as review findings, nits, or
“consider later” bullets.

-   **Mermaid CDN** — Loaded only when front matter sets `mermaid: true`. Do not suggest vendoring
    under `assets` for offline or CDN resilience unless asked. Version URL and SRI in
    `_includes/head.html` are manually maintained (Dependabot does not bump them).
-   **Analytics** — `google_analytics` in `_config.yml`; theme loads it in production only. No
    EU-style consent banner in this site’s markup. Settled unless asked about jurisdictions or CMPs.
-   **Dependabot** — `.github/dependabot.yml` targets **GitHub Actions only**. Gems stay with GitHub
    Pages’ build environment. Do not widen to RubyGems/npm “for completeness” unless those ecosystems
    gain first-class use here.
-   **Sync workflows (`contents: write`)** — `sync-markdownlint.yml` and `sync-githubpages.yml` push
    narrow commits when their target pins change. Do not flag `contents: write`, automated `git push`,
    or “commit only the touched lines” as review findings unless asked to change them. Do not recycle
    generic “write access increases blast radius” nits unless the maintainer explicitly asks.
-   **Site metadata** — `lang: ja` with Japanese bodies and an Irish-language–style `title` (and
    similar branding) is intentional. Do not flag for SEO or language heuristics unless asked.
-   **Site description** — `site.description` is on-page footer content (Minima). Do not suggest
    `<meta name="description">`, `{%- seo -%}`, `jekyll-seo-tag`, or “unused because not in `<head>`”
    findings unless asked.
-   **`404.html`** — Intentionally English (`lang: en`; no front matter `title` so it stays out of
    Minima’s header nav). Tab title is set in `_includes/head.html` when `page.path` is `404.html`.
    Do not suggest aligning it with `site.lang` unless asked.
