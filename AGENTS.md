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

## Do not create tests for article body content

Do **not** add regression or assertion scripts that verify the prose, code samples, examples, or
explanatory claims inside `_posts/` — for example grepping a post for a corrected phrase, re-running a
shell / Ruby / SQL fragment published in an article, or asserting benchmark captions and stability
wording. Editorial copy is maintained by hand; it is **not** covered by `tests/`.

That includes creating such scripts while fixing review findings, satisfying a skill that asks for a
regression test, or “for completeness.”

**Sort algorithms** fall under the same rule. Do not add standalone harnesses (for example under
`tests/test-*-sort-*`, `tests/test-*-shivers-*`, or similar Node/shell scripts that extract demo JS from
posts or recompile benchmark Swift). Correctness for the committed Swift path is already exercised by
`verify_correctness` inside the sort-benchmark harness
(`_includes/sort-benchmark/helpers/verify_correctness.swift`). Article demos are illustrative; do not grow
a parallel suite around them.

Site infrastructure checks remain appropriate — tags JSON, demo CSS helpers, Jekyll config, Mermaid
SRI, benchmark memory accounting in `_includes/sort-benchmark/**`, and similar.

Only create tests of article body content if the maintainer **explicitly** asks for them. Do not
recommend adding them in reviews or audits unless asked.

## Keep post paragraphs on one source line

In `_posts/` (and other reader-facing site Markdown), do **not** insert soft line breaks inside a
paragraph. A lone newline is not a visible break in the rendered HTML — CommonMark / kramdown turn it
into a space — so wrapping only makes the source length diverge from the paragraph readers see. Use a
blank line for a new paragraph, or two trailing spaces only when a hard line break is intentional.

Apply this when writing or editing posts, including while resolving review findings. Do not suggest
reflowing post prose to a fixed column width in reviews unless the maintainer asks.

## Do not volunteer these topics in reviews

The following choices are intentional or already accepted trade-offs for this site.
Unless the maintainer asks about them explicitly, **do not** raise them as review findings, nits, or
“consider later” bullets.

-   **Mermaid / MathJax CDN** — Loaded only when front matter sets `mermaid: true` or `mathjax: true`.
    Do not suggest vendoring under `assets` for offline or CDN resilience unless asked. Version URL
    and SRI in `_includes/head.html` are manually maintained (Dependabot does not bump them). Write
    math with kramdown `$$...$$` (inline or display) on `mathjax: true` posts only.
-   **Analytics** — `google_analytics` in `_config.yml`; theme loads it in production only. No
    EU-style consent banner in this site’s markup. Settled unless asked about jurisdictions or CMPs.
-   **Dependabot** — `.github/dependabot.yml` targets **GitHub Actions only**. Gems stay with GitHub
    Pages’ build environment. Do not widen to RubyGems/npm “for completeness” unless those ecosystems
    gain first-class use here.
-   **Sync workflow (`contents: write`)** — `sync.yml` pushes narrow commits when its
    target pins change. Do not flag `contents: write`, automated `git push`,
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
