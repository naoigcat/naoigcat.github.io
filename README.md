# Today I Learned

Today I learned posts published on GitHub Pages.

## Build environment

The live site is built by **GitHub Pages** using GitHub’s hosted Jekyll stack and the dependency set they maintain.
Jekyll and gem versions follow GitHub’s Pages release line; this repository does not pin that environment with a `Gemfile` or `Gemfile.lock`.

For the versions GitHub uses in production, see [Dependency versions](https://pages.github.com/versions/).

Pushing to the publishing branch runs **Jekyll on GitHub Pages**; that is the canonical hosted build.
Automated tools and contributors should follow [AGENTS.md](./AGENTS.md),
including the policy of **not** suggesting an extra CI job just to duplicate that Jekyll build.

## Local preview

For development, `mise run serve` runs Jekyll in Docker using an image (`naoigcat/github-pages`) that mirrors GitHub’s published Pages dependency set.
The image ref lives in `mise.toml` under `[vars] github_pages_image` so we can bump it when refreshing against GitHub’s stack.
It is not duplicated here: production builds stay tied to GitHub’s hosted environment, which can change without updates to this repo.

Requires Docker and [mise](https://mise.jdx.dev/). The first time you work in this repo, run `mise trust` in the project
root so mise will load `mise.toml` (see [mise trust](https://mise.jdx.dev/cli/trust.html)).

```sh
mise run serve
```

The command starts the server, maps port 4000 to localhost, and opens the site in your default browser (macOS).

## Tags

Tag navigation uses a **single page** at `/tags/`. Each tag links to `/tags/?tag={slug}` (for example `/tags/?tag=sort`).
At build time Jekyll embeds tag→post data in that page; the browser filters by the `tag` query parameter.
No custom `_plugins` generator is required, so **production and local preview behave the same** on GitHub Pages.

## GitHub Pages vs local preview

Production builds run on **GitHub Pages’ hosted Jekyll**, which does **not** execute custom Ruby in `_plugins/`.
This repository does not rely on `_plugins` for site behavior; features that must work in production are implemented with
committed pages, Liquid, and small client-side scripts (such as the tag index above).

Local `mise run serve` uses a Docker image that mirrors GitHub’s Pages dependency set. It may run Jekyll with different
flags than production, but anything committed under `_plugins/` would only affect local output—not the live site.
Do not add custom plugins unless you also change the deployment model.
