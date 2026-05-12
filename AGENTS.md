# Instructions for automated assistants

## GitHub Pages already runs Jekyll

This repository is published with **GitHub Pages**. Pushing to the branch that Pages uses triggers **GitHub’s Jekyll build** in their environment.
Whether that build passes or fails is visible in the repository’s Pages deployment state and history.

**Do not recommend** adding GitHub Actions (or other CI) jobs whose *only* purpose is to run `jekyll build` (or equivalent)
“because the site would otherwise not be built,” “to discover build failures before deploy,” or “Pages does not build the site.”
That reasoning is **incorrect for this repository**: integration with the hosted stack is already enforced on push.

Do not volunteer that suggestion in reviews, audits, or advice unless the maintainer **explicitly** asks
for a duplicate build, PR-preview sites, or another goal that requires Actions.

## Do not volunteer these topics in reviews

The following choices are intentional or already accepted trade-offs for this site.
Unless the maintainer asks about them explicitly, **do not** raise them as review findings, nits, or “consider later” bullets.

### Third-party JavaScript (Mermaid)

Production loads the Mermaid script from a CDN **only on posts whose front matter sets `mermaid: true`**. That opt-in loading is deliberate.
Do not suggest vendoring the same version under `assets` for offline verification or CDN resilience unless the maintainer asks;
it is an optional future trade-off against maintenance cost, not an outstanding gap.

### Analytics

`_config.yml` defines `google_analytics`, and the theme is expected to load it in production only.
There is no EU-style consent banner in this site’s own markup.
Treat analytics and consent posture as settled unless the maintainer asks about jurisdictions or CMPs.

### Dependabot scope

`.github/dependabot.yml` targets **GitHub Actions only**. Gems are intentionally left to GitHub Pages’ build environment; that split is deliberate.
Do not suggest widening Dependabot to RubyGems/npm “for completeness” unless those ecosystems gain first-class use in this repo.

### Site metadata consistency

The site uses `lang: ja` with Japanese article bodies while retaining an Irish-language–style display name in `title` (and similar branding).
That mix is intentional. Do not flag it as inconsistent for SEO or browser language heuristics unless the maintainer asks to revisit naming or localization.

### Error pages (`404.html`)

The not-found page is intentionally English (`lang: en` and English body copy; no `title` in front matter so it stays out of Minima’s header nav)
while the rest of the site defaults to Japanese metadata from `_config.yml`.
Do not suggest aligning it with `site.lang` unless the maintainer asks.
