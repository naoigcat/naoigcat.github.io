#!/usr/bin/env bash
# Regression: sort-benchmark harness must measure peak heap growth during the
# sort (explicit buffers), not VmHWM RSS minus a baseline process.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bench="$root/_includes/sort-benchmark.md"

if [[ ! -f $bench ]]; then
  echo "missing $bench" >&2
  exit 1
fi

if grep -q 'VmHWM' "$bench"; then
  echo "$bench still references VmHWM; auxiliary memory must use allocation tracking" >&2
  exit 1
fi

if grep -q -- '--baseline-once' "$bench"; then
  echo "$bench still uses --baseline-once RSS baseline; remove it" >&2
  exit 1
fi

for needle in 'TrackingAllocator' '#[global_allocator]' 'PEAK_BYTES' 'LIVE_BYTES'; do
  if ! grep -qF "$needle" "$bench"; then
    echo "$bench missing allocation-tracking piece: $needle" >&2
    exit 1
  fi
done

if ! grep -qF 'peak_bytes.saturating_sub(base_bytes)' "$bench"; then
  echo "$bench must report peak heap growth over the pre-sort live baseline" >&2
  exit 1
fi

# The child must hand back raw bytes: rounding to KiB per run truncates sub-KiB
# buffers to 0 before the parent averages them, so the average can never show them.
if grep -qE 'saturating_sub\(base_bytes\)[[:space:]]*/[[:space:]]*1024' "$bench"; then
  echo "$bench rounds auxiliary memory to KiB per child run; sum bytes and convert once after averaging" >&2
  exit 1
fi

if ! grep -qE 'total_mem[[:space:]]*/[[:space:]]*RUNS[[:space:]]*/[[:space:]]*1024' "$bench"; then
  echo "$bench must convert the averaged auxiliary memory (total_mem / RUNS) to KiB only for display" >&2
  exit 1
fi

echo "ok: sort-benchmark measures auxiliary memory via allocation peak tracking"
