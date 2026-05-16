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
