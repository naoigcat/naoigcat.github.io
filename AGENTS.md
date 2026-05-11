# Instructions for automated assistants

## GitHub Pages already runs Jekyll

This repository is published with **GitHub Pages**. Pushing to the branch that Pages uses triggers **GitHub’s Jekyll build** in their environment.
Whether that build passes or fails is visible in the repository’s Pages deployment state and history.

**Do not recommend** adding GitHub Actions (or other CI) jobs whose *only* purpose is to run `jekyll build` (or equivalent)
“because the site would otherwise not be built,” “to discover build failures before deploy,” or “Pages does not build the site.”
That reasoning is **incorrect for this repository**: integration with the hosted stack is already enforced on push.

Do not volunteer that suggestion in reviews, audits, or advice unless the maintainer **explicitly** asks
for a duplicate build, PR-preview sites, or another goal that requires Actions.
