# Today I Learned

Today I learned posts published on GitHub Pages.

## Build environment

The live site is built by **GitHub Pages** using GitHub’s hosted Jekyll stack and the dependency set they maintain.
Jekyll and gem versions follow GitHub’s Pages release line; this repository does not pin that environment with a `Gemfile` or `Gemfile.lock`.

For the versions GitHub uses in production, see [Dependency versions](https://pages.github.com/versions/).

## Local preview

For development, `make serve` runs Jekyll in Docker using an image (`naoigcat/github-pages`) that mirrors GitHub’s published Pages dependency set.
The image tag lives only in the `Makefile` (`serve` target) so we can bump it when refreshing against GitHub’s stack.
It is not duplicated here: production builds stay tied to GitHub’s hosted environment, which can change without updates to this repo.

Requires Docker.

```sh
make serve
```

The command starts the server, maps port 4000 to localhost, and opens the site in your default browser (macOS).
