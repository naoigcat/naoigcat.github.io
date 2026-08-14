---
name: write-article-javascript
description: >-
  Conventions for JavaScript embedded in posts and sort demos (evergreen browsers, modern ES2015+).
  Use when writing or editing article scripts, `{% include sort-demo.html %}` demos under `_posts/`,
  or shared demo helpers such as `assets/js/sort-demo.js`.
paths:
  - "_posts/**/*.md"
  - "assets/js/sort-demo.js"
  - "_includes/sort-demo.html"
  - "assets/css/sort-demo.css"
---

# write-article-javascript

In-article JavaScript (for example sort-algorithm demos under `_posts/` that mount via
`{% include sort-demo.html ... %}`) **does not need to support Internet Explorer or any other engine
that lacks ES2015+ syntax**. Treat the runtime baseline as evergreen browsers.

## Prefer modern, readable features

When writing or editing article scripts, prefer contemporary language features whenever they make the
demo clearer:

-   `const` / `let` rather than `var`
-   arrow functions, template literals, default and rest parameters, destructuring
-   `class`, `Promise` / `async` / `await`, `Map` / `Set`
-   optional chaining and nullish coalescing, `BigInt` literals, and similar constructs

## Do not regress toward legacy idioms

The goal is to **keep article code from accreting legacy patterns for the sake of obsolete browsers**,
not to mandate any specific keyword.

Do **not**:

-   rewrite working article scripts toward older idioms (forcing `var`, hand-rolled polyfills,
    transpiled-style output, or browser-version sniffing) in the name of broader compatibility
-   flag existing modern syntax as a review finding unless the maintainer explicitly asks to widen
    the supported browser set
