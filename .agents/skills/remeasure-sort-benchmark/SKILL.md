---
name: remeasure-sort-benchmark
description: >-
    Re-runs the Rust/Docker sort benchmark for one or all sort posts and replaces the committed table between
    `<!-- sort-benchmark-result:start -->` and `<!-- sort-benchmark-result:end -->`. Use when the user asks to
    remeasure, refresh, or update sort benchmark tables, after changing `_includes/sort-benchmark/**`,
    `_data/sort_algorithms.yml`, or the Rust version in `_includes/sort-benchmark.md`.
---

# remeasure-sort-benchmark

Re-measure the static benchmark table at the end of sort-algorithm posts and write fresh numbers back into the
Markdown source.

## Scope

-   **In scope:** posts under `_posts/` that contain `{% include sort-benchmark.md algorithm="…" %}` and a
    `<!-- sort-benchmark-result:start -->` … `<!-- sort-benchmark-result:end -->` block.
-   **Out of scope:** changing benchmark methodology (`RUNS`, size range, Docker/Rust versions) unless the user
    explicitly asks — those live in `_includes/sort-benchmark.md` and `_data/sort_algorithms.yml`.

## Prerequisites

-   **Docker** running locally (`docker info` succeeds). The benchmark script pulls `rust:1.95.0` and builds inside
    a container.
-   **Time:** one algorithm typically needs **10–30+ minutes** (`quadratic_average: true` → 8 sizes × 8192 runs;
    otherwise 11 sizes × 8192 runs). Do not interrupt a running benchmark.
-   **Memory:** if `docker build` fails during LTO, raise Docker Desktop memory to **4 GB+** and retry.
-   Run commands from the **repository root**.

## Resolve the target

Accept any of these as `{algorithm}`:

| User input | Resolves to |
| --- | --- |
| YAML key (`bubble`, `polyphase_merge`, …) | used as-is |
| Post slug suffix (`sort-bubble`, `sort-polyphase-merge`) | hyphens after `sort-` → underscores |
| Post filename fragment (`2026-05-01-sort-bubble`) | read `algorithm="…"` from that post |

List all sort posts:

```bash
rg -l 'sort-benchmark\.md algorithm="' _posts
```

List YAML keys:

```bash
rg '^[a-z_]+:' _data/sort_algorithms.yml
```

## Workflow (single algorithm)

### 1. Optional dry run

Verify Jekyll can render the benchmark shell script for the algorithm:

```bash
.agents/skills/remeasure-sort-benchmark/scripts/update-sort-benchmark.sh {algorithm} --dry-run
```

### 2. Run benchmark and update the post

```bash
.agents/skills/remeasure-sort-benchmark/scripts/update-sort-benchmark.sh {algorithm}
```

The script:

1.  Renders the same bash script shown on the live post (`render-benchmark-script.sh` → Jekyll include → extract
    `<pre><code>` from `.sort-benchmark-code`).
2.  Executes that script (Docker build + `docker run --rm --init rust-benchmark`).
3.  Replaces only the **data rows** inside the `sort-benchmark-result` markers, keeping the fixed header row and
    marker comments.
4.  Runs `mise run lint -- "<post-path>"`.

On failure, read stderr from the benchmark container (`sort failed`, `benchmark child process failed`, compile
errors). Fix `_includes/sort-benchmark/algorithms/{algorithm}.rs` or `_data/sort_algorithms.yml` helper flags
before retrying.

### 3. Report

Tell the user:

-   algorithm id and post path updated
-   row count (8 for `quadratic_average: true`, 11 otherwise)
-   that numbers reflect the current committed benchmark sources and `rust:1.95.0`

Do **not** commit unless the user asks.

## Workflow (all sort posts)

When the user wants every sort table refreshed (for example after bumping Rust in `_includes/sort-benchmark.md`):

```bash
while IFS= read -r algo; do
  .agents/skills/remeasure-sort-benchmark/scripts/update-sort-benchmark.sh "$algo"
done < <(rg -o 'algorithm="[^"]+"' _posts -h | sed 's/algorithm="//;s/"//' | sort -u)
```

Run sequentially — parallel runs contend for Docker and CPU. Expect **many hours** for all 42 algorithms.

## Manual fallback

If the helper scripts fail, follow the same steps by hand:

1.  `mise run serve` (or build once with the GitHub Pages Docker image), open the post, expand **計測に使用したコードを表示する**,
    copy the bash script, run it locally.
2.  From stdout, take lines matching `^\| *[0-9]` (data rows only).
3.  Replace the block between the HTML comment markers, preserving:

    ```markdown
    <!-- sort-benchmark-result:start -->

    |       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
    |-----------:|----------------:|----------------:|----------------:|----------------:|
    |        … data rows … |

    <!-- sort-benchmark-result:end -->
    ```

4.  `mise run lint -- "<post-path>"`

## Table format rules

-   Keep the **exact** header and separator rows already used in sibling posts (column widths differ from the
    benchmark program’s stdout header — only data rows come from Docker output).
-   Leave one blank line after `<!-- sort-benchmark-result:start -->` and before `<!-- sort-benchmark-result:end -->`
    (matches existing posts).
-   Do not edit the `{% include sort-benchmark.md algorithm="…" %}` line unless the YAML key changed.

## Related files

| File | Role |
| --- | --- |
| `_includes/sort-benchmark.md` | Generates the Docker/Rust benchmark script (`rust:1.95.0`, `RUNS = 8192`) |
| `_data/sort_algorithms.yml` | `sort_fn`, helper flags, `quadratic_average` (caps max size at `2^15`) |
| `_includes/sort-benchmark/algorithms/<id>.rs` | Per-algorithm Rust implementation |
| `_includes/sort-benchmark/helpers/*.rs` | Shared helpers included when YAML flags are set |

When adding a **new** algorithm, finish YAML + Rust first (see comments in `sort_algorithms.yml`), create the post
with an empty data table, then run this skill to fill numbers.
