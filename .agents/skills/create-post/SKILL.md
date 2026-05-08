---
name: create-post
description: >-
    Creates a new post file with the given title, using the prescribed format and front matter.
disable-model-invocation: true
---

# create-post

When the user runs this skill and provides a title (for example: `bash-random-number`), follow the steps below to create
the file.

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

-   **Display title**: Use a separate variable `{display_title}` for front matter and display. Put the original user input
    `{title}` in `{display_title}` as-is, or, when needed, store an explicit translation or natural phrasing (for example Japanese: `bash-random-number` → `Bashでの乱数生成`).
-   **Tags**: Extract the first segment when `{filename_slug}` is split on hyphens (`-`) and use that as the tag. (Example:
    `bash-random-number` → `bash`)

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

Set `title` to `{display_title}` and `tags` to `{tag}` (the first segment of `{filename_slug}`).

## 5. Commit

Before committing the new file, run `git rev-parse --is-inside-work-tree` to verify you are inside a Git repository. If
not, stop and tell the user to run `git init` or work in an existing repository.

When running `git add` and `git commit`, capture standard error. On failure, report the exit code and error output as-is,
then suggest next steps such as retrying, checking with `git status`, or running `git init` if appropriate.

If everything is fine, commit with:

```bash
git add _posts/{year}/{month}/{year}-{month}-{day}-{filename_slug}.md
git commit -m "Add post \`{year}-{month}-{day}-{filename_slug}\`"
```

## 6. Report completion

Report the path and contents of the created file to the user.
