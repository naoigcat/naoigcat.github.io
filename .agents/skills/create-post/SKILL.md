---
name: create-post
description: >-
    Creates a new post file with the given title, using the prescribed format and front matter.
---

# create-post

When the user runs this skill and provides a title (for example: `bash-random-number`), follow the steps below to create
the file.

## Language

-   **Display title and body**: Write the front matter `title` value (`{display_title}`) and all article body content (the
    Markdown after the closing front matter `---`) **in Japanese**. The user may still supply an ASCII/kebab-style slug for
    `{filename_slug}`; only the human-facing title and prose must be Japanese.

## 1. Obtain date and time

Get the current time and always derive the following values from the instant converted to **Asia/Tokyo** (Japan Standard
Time, JST). Use a timezone-aware API or library so results are consistent across environments (for example:
`Intl.DateTimeFormat` with `timeZone: 'Asia/Tokyo'`, `date-fns-tz`, or `moment-timezone`).

-   `{year}`: Four-digit Gregorian year from the JST instant (`YYYY`; example: 2026)
-   `{month}`: Two-digit month from the JST instant (`MM`; example: 04)
-   `{day}`: Two-digit day from the JST instant (`DD`; example: 10)
-   `{date}`: The same JST instant formatted as `yyyy-mm-dd HH:MM:SS +0900` (example: `2026-04-10 12:00:00 +0900`)

## 2. Determine the file path

Keep the user-provided title as `{title}` and introduce a separate variable `{filename_slug}` for the file name. Store a
value in `{filename_slug}` by converting the user input to ASCII kebab-case suitable for file names. Apply these rules
when generating it:

-   First normalize `{title}` with Unicode normalization NFKC.
-   Convert Japanese and other non-ASCII characters to ASCII as far as possible, using romanization or a transliteration
    library appropriate to the source language.
-   Replace whitespace and runs of delimiter characters with a hyphen (`-`).
-   Convert uppercase Latin letters to lowercase.
-   Remove any character that is not a lowercase Latin letter, digit, or hyphen.
-   Collapse consecutive hyphens into one, and trim leading and trailing hyphens.
-   The final `{filename_slug}` must match the regular expression `^[a-z0-9-]+$`.
-   If the conversion yields an empty string, treat it as an error and ask the user to re-enter the title. If you adopt a
    fallback, state explicitly that you are appending a short random ID to produce `{filename_slug}`.

Create the new Markdown file at:

`_posts/{year}/{month}/{year}-{month}-{day}-{filename_slug}.md`

-   Create parent directories if they do not exist.
-   If a file already exists at that path, do not overwrite it without confirmation, or prompt the user to choose a different
    file name.

## 3. Prepare fields

-   **Display title**: Use a separate variable `{display_title}` for front matter and display. It must be **Japanese**
    phrasing appropriate for the post (if the user gives an ASCII slug like `bash-random-number`, expand it to a natural
    Japanese title such as `Bashでの乱数生成`).
-   **Tags**: Split `{filename_slug}` on hyphens (`-`) and resolve `{tag}` from those segments.
    -   The **first segment is always the leading tag** (this is the primary category, e.g. `git`, `sort`, `yaml`). It
        comes first in the final list.
    -   For the remaining segments, **add a segment as an additional tag only when that segment is itself a meaningful
        tag** — typically a tool, platform, language, framework, or other well-known proper noun that already appears as
        a tag elsewhere in `_posts/`. Skip segments that are merely descriptive words.
    -   Adjacent segments may be **joined with a hyphen** to form a single tag when together they spell one proper noun
        (e.g. `github-copilot`).
    -   Render `{tag}` as a **space-separated list** in the order the segments appear.
    -   Examples:
        -   `bash-random-number` → `bash` (`random` and `number` are descriptive, not separate tags)
        -   `sh-which-of-debian-utils` → `bash debian` (`debian` is a platform tag; the `sh` slug prefix maps to the
            existing `bash` primary tag, see the note below)
        -   `vscode-github-copilot-commit-message-generation` → `vscode github-copilot`
        -   `sort-bubble` → `sort` (`bubble` is descriptive, not a tag)
    -   When in doubt, **prefer fewer tags** and do not invent new tags that are not already used elsewhere in `_posts/`.
    -   Note: a few first-segment slugs are normalized to a canonical tag name (e.g. `sh-*` → `bash`, `objc-*` →
        `objective-c`). Reuse the same normalization that recent posts use; check sibling posts under `_posts/` to confirm.

## 4. Write the file

Write the following front matter in the created file:

```markdown
---
layout: post
title:  {display_title}
date:   {date}
tags:   {tag}
---
```

Optional front matter keys (add only when the post needs them):

-   **`mermaid: true`** — `head.html` loads the Mermaid CDN script so Mermaid fenced code blocks render.
-   **`sort_demo: true`** — `head.html` loads sort-demo CSS and `demo-sort.js` when using `{% include sort-demo/wrapper.html %}`.

Set `title` to `{display_title}` and `tags` to `{tag}` (the space-separated list resolved in step 3, always starting with
the first segment of `{filename_slug}`). Write the **article body in Japanese**.

## 5. Run markdownlint

When creation or editing of the `.md` file is complete, **read and follow**
`.agents/skills/run-markdownlint/SKILL.md` (the **run-markdownlint** skill): run `markdownlint-cli2` on the file, fix issues,
and re-run until lint passes. Do not treat the post as finished while markdownlint still reports errors.

## 6. Commit

Before committing the new file, run `git rev-parse --is-inside-work-tree` to verify you are inside a Git repository. If
not, stop and tell the user to run `git init` or work in an existing repository.

When running `git add` and `git commit`, capture standard error. On failure, report the exit code and error output as-is,
then suggest next steps such as retrying, checking with `git status`, or running `git init` if appropriate.

If everything is fine, commit with:

```bash
git add _posts/{year}/{month}/{year}-{month}-{day}-{filename_slug}.md
git commit -m "Add post \`{year}-{month}-{day}-{filename_slug}\`"
```

## 7. Report completion

Report the path and contents of the created file to the user.
