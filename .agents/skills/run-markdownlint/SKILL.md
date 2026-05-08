---
name: run-markdownlint
description: >-
    Enforces Markdown style with markdownlint-cli2 after creating or editing .md
    files. Runs npx markdownlint-cli2, fixes violations, and re-runs until clean.
---

# Markdownlint for edited Markdown

## When this applies

Whenever you **create, replace, or edit** a file whose name ends with `.md` (or `.markdown`), treat lint cleanliness as part of the same task.

## Required workflow

1.  After substantive edits, run from the **workspace root** (or pass absolute paths):

    ```bash
    npx markdownlint-cli2 "<path-to-file.md>"
    ```

1.  If there are findings, apply fixes:

    -   Prefer auto-fix when the rule supports it:

        ```bash
        npx markdownlint-cli2 --fix "<path-to-file.md>"
        ```

    -   For anything `--fix` cannot correct, edit the file manually using the rule ids from markdownlint (headings, list spacing, language tags on fenced code, line length, and similar).

1.  **Re-run** `npx markdownlint-cli2 "<path-to-file.md>"` until it exits **0** with no output (or only benign messages, depending on your config).

1.  If the repo has `.markdownlint.json`, `.markdownlint.yaml`, `.markdownlint-cli2.jsonc`, or `.markdownlintignore`, respect them; they are picked up automatically.

## Do not

-   Mark the task done while markdownlint still reports errors.
-   Silence rules in config unless the user explicitly asks to change project lint policy.
