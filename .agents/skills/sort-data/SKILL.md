---
name: sort-data
description: >-
  Keeps YAML under `_data/` alphabetically sorted when adding, editing, or regenerating entries. Use whenever
  changing `_data/sort_algorithms.yml`, `_data/tags_embed.yml`, or any other `_data/*.yml` file.
paths:
  - "_data/**/*.yml"
  - "_data/**/*.yaml"
---

# sort-data

After any edit to files under `_data/`, leave the file **alphabetically sorted**. Do not append new entries at the
end (or in chronological / “related algorithm” order) and leave the rest unsorted.

## Rules by file shape

### Mapping files (e.g. `_data/sort_algorithms.yml`)

-   Sort **top-level keys** A–Z (case-insensitive ASCII / underscore identifiers as in the file today).
-   Preserve each key’s nested fields and comments as-is; do not reorder nested dependency flags solely for
    alphabetical order (`sort_fn` stays first under each algorithm).
-   Keep the existing file header comments unchanged.

### Sequence / list files (e.g. `_data/tags_embed.yml`)

-   Sort **list items** A–Z (case-insensitive).
-   Keep the existing header comments unchanged.

## Workflow

1.  Make the content change (add, rename, remove, or edit an entry).
2.  Re-sort the whole file according to the rules above (not only the new line).
3.  Confirm no keys/items were dropped and nested values for mapping entries still match the pre-edit content.

## Examples

-   Adding `wiki` to `sort_algorithms.yml` → insert under `w…`, between `van_emde_boas` and any later key, with the
    full map still A–Z.
-   Adding `rust` to `tags_embed.yml` → result list like `… ruby`, `rust`, `sort`, …
