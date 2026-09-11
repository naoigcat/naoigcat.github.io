---
title:     対称マージソートで配列を並び替える
date:      2026-09-11 05:25:31 +0900
tags:      sort
sort_demo: true
---

## 対称マージソートを使用する

対称マージソート (`sym merge sort`) は隣接する整列済み区間を対称比較と回転でマージする、安定なインプレース整列である。

1.  **短いランの整列**: 長さ 20 程度の区間を挿入ソートで整える。
2.  **単一要素の挿入**: 隣接する整列済み区間 `U = A[lo..mid)` と `V = A[mid..hi)` について、片側が 1 要素ならもう一方への挿入位置を二分探索し、隣接スワップで滑り込ませる。
3.  **対称比較**: それ以外では、区間中央まわりで外側から対称に要素対を比較し（実装では二分探索）、回転すべき境界 `start` / `end` を決める。
4.  **回転**: `[start, mid)` と `[mid, end)` をブロックスワップによる回転で入れ替える。
5.  **再帰**: 左右のより小さなマージ問題へ同じ手順を適用する。
6.  **繰り返し**: ラン長を 2 倍にしながら、配列全体が 1 本の昇順列になるまで対称マージ（手順 2〜5）を繰り返す。

```pseudocode
procedure rotate(A, lo, mid, hi)
  // A[lo..mid) と A[mid..hi) をブロックスワップで入れ替える

procedure sym_merge(A, lo, mid, hi)
  if mid - lo = 1 then
    insert A[lo] into A[mid..hi) by binary search and adjacent swaps
    return
  if hi - mid = 1 then
    insert A[mid] into A[lo..mid) by binary search and adjacent swaps
    return
  center = floor((lo + hi) / 2)
  // 対称比較（二分探索）で回転境界 start, end を求める
  (start, end) = symmetric_bounds(A, lo, mid, hi, center)
  if start < mid < end then
    rotate(A, start, mid, end)
  if lo < start < center then
    sym_merge(A, lo, start, center)
  if center < end < hi then
    sym_merge(A, center, end, hi)

procedure sym_merge_sort(A)
  n = length(A)
  block = 20
  for each chunk of size block
    insertion_sort(chunk)
  width = block
  while width < n
    for lo from 0 step 2*width while lo + width < n
      mid = lo + width
      hi = min(lo + 2*width, n)
      sym_merge(A, lo, mid, hi)
    width = width * 2
```

1 回の対称マージは要素移動がおおむね `O((m+n) log m)`（`m ≤ n` を短い側とする）なので、ボトムアップ全体の最悪計算量は `O(n log² n)` である。追加ヒープは使わず、再帰深さは `O(log n)` に収まる。安定性は、同値での分岐を「左を優先」する比較と回転の組み立てで保つ。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('sym-merge-sort-demo', function (root) {
  const BLOCK = 4;

  function rangePairs(lo, hiExclusive, role) {
    const pairs = [];
    for (let k = lo; k < hiExclusive; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function pushSwap(a, lo, hi, steps) {
    const t = a[lo];
    a[lo] = a[hi];
    a[hi] = t;
    steps.push({ kind: 'swap', lo: lo, hi: hi, arr: a.slice() });
  }

  function insertionSortRange(a, lo, hi, steps) {
    for (let i = lo + 1; i < hi; i++) {
      steps.push({ kind: 'compare', i: i - 1, j: i, arr: a.slice() });
      let j = i;
      while (j > lo && a[j - 1] > a[j]) {
        pushSwap(a, j - 1, j, steps);
        j -= 1;
        if (j > lo) {
          steps.push({ kind: 'compare', i: j - 1, j: j, arr: a.slice() });
        }
      }
    }
  }

  function swapRangeAnimated(a, left, right, n, steps) {
    for (let i = 0; i < n; i++) {
      pushSwap(a, left + i, right + i, steps);
    }
  }

  function rotate(a, lo, mid, hi, steps) {
    steps.push({ kind: 'rotate', lo: lo, mid: mid, hi: hi, arr: a.slice() });
    let i = mid - lo;
    let j = hi - mid;
    while (i !== j) {
      if (i > j) {
        swapRangeAnimated(a, mid - i, mid, j, steps);
        i -= j;
      } else {
        swapRangeAnimated(a, mid - i, mid + j - i, i, steps);
        j -= i;
      }
    }
    swapRangeAnimated(a, mid - i, mid, i, steps);
    steps.push({ kind: 'rotate_done', lo: lo, hi: hi, arr: a.slice() });
  }

  function symMerge(a, lo, mid, hi, steps) {
    steps.push({ kind: 'merge_start', lo: lo, mid: mid, hi: hi, arr: a.slice() });

    if (mid - lo === 1) {
      let i = mid;
      let j = hi;
      while (i < j) {
        const h = Math.floor((i + j) / 2);
        steps.push({ kind: 'compare', i: h, j: lo, arr: a.slice() });
        if (a[h] < a[lo]) {
          i = h + 1;
        } else {
          j = h;
        }
      }
      for (let k = lo; k < i - 1; k++) {
        pushSwap(a, k, k + 1, steps);
      }
      steps.push({ kind: 'merge_done', lo: lo, hi: hi, arr: a.slice() });
      return;
    }

    if (hi - mid === 1) {
      let i = lo;
      let j = mid;
      while (i < j) {
        const h = Math.floor((i + j) / 2);
        steps.push({ kind: 'compare', i: mid, j: h, arr: a.slice() });
        if (a[mid] >= a[h]) {
          i = h + 1;
        } else {
          j = h;
        }
      }
      let k = mid;
      while (k > i) {
        pushSwap(a, k - 1, k, steps);
        k -= 1;
      }
      steps.push({ kind: 'merge_done', lo: lo, hi: hi, arr: a.slice() });
      return;
    }

    const center = Math.floor((lo + hi) / 2);
    const n = center + mid;
    let start;
    let r;
    if (mid > center) {
      start = n - hi;
      r = center;
    } else {
      start = lo;
      r = mid;
    }
    const p = n - 1;

    while (start < r) {
      const c = Math.floor((start + r) / 2);
      steps.push({
        kind: 'sym_compare',
        i: p - c,
        j: c,
        lo: lo,
        mid: mid,
        hi: hi,
        arr: a.slice(),
      });
      if (a[p - c] >= a[c]) {
        start = c + 1;
      } else {
        r = c;
      }
    }

    const end = n - start;
    steps.push({
      kind: 'bounds',
      lo: lo,
      mid: mid,
      hi: hi,
      start: start,
      end: end,
      center: center,
      arr: a.slice(),
    });

    if (start < mid && mid < end) {
      rotate(a, start, mid, end, steps);
    }
    if (lo < start && start < center) {
      symMerge(a, lo, start, center, steps);
    }
    if (center < end && end < hi) {
      symMerge(a, center, end, hi, steps);
    }
    steps.push({ kind: 'merge_done', lo: lo, hi: hi, arr: a.slice() });
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n === 0) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    let start = 0;
    while (start < n) {
      const end = Math.min(start + BLOCK, n);
      steps.push({ kind: 'run_start', lo: start, hi: end, arr: a.slice() });
      insertionSortRange(a, start, end, steps);
      steps.push({ kind: 'run_done', lo: start, hi: end, arr: a.slice() });
      start = end;
    }

    let width = BLOCK;
    while (width < n) {
      steps.push({ kind: 'level_start', width: width, arr: a.slice() });
      let lo = 0;
      while (lo + width < n) {
        const mid = lo + width;
        const hi = Math.min(lo + 2 * width, n);
        symMerge(a, lo, mid, hi, steps);
        lo = hi;
      }
      width *= 2;
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-sym-merge',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '対称マージソートのデモ（区間は青、対称比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'run_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption('短いランを挿入ソート: [' + s.lo + ', ' + s.hi + ')');
        return;
      }
      if (s.kind === 'run_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption('ラン整列完了: [' + s.lo + ', ' + s.hi + ')');
        return;
      }
      if (s.kind === 'level_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ラン長 ' + s.width + ' のペアを対称マージ');
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '対称マージ: [' + s.lo + ', ' + s.mid + ') ∪ [' + s.mid + ', ' + s.hi + ')'
        );
        return;
      }
      if (s.kind === 'sym_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.i, 'compare'],
          [s.j, 'compare'],
        ]);
        api.setCaption('対称比較: 位置 ' + s.i + ' と ' + s.j);
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.i, 'compare'],
          [s.j, 'compare'],
        ]);
        api.setCaption('比較: 位置 ' + s.i + ' と ' + s.j);
        return;
      }
      if (s.kind === 'bounds') {
        api.mountBars(barsEl, s.arr);
        const roles = rangePairs(s.lo, s.hi, 'range');
        if (s.start < s.end) {
          for (let k = s.start; k < s.end; k++) {
            roles.push([k, 'swap']);
          }
        }
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '回転区間: [' + s.start + ', ' + s.end + ')（mid = ' + s.mid + '）'
        );
        return;
      }
      if (s.kind === 'rotate') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'swap'));
        api.setCaption(
          '回転: [' + s.lo + ', ' + s.mid + ') ↔ [' + s.mid + ', ' + s.hi + ')'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('交換: 位置 ' + s.lo + ' と ' + s.hi);
        if (Math.abs(s.lo - s.hi) === 1) {
          await DemoSort.flipAdjacentSwap(barsEl, Math.min(s.lo, s.hi));
        } else {
          await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        }
        DemoSort.syncBarsAccessibility(barsEl);
        return;
      }
      if (s.kind === 'rotate_done' || s.kind === 'merge_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption('区間 [' + s.lo + ', ' + s.hi + ') を更新');
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 200,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="sym-merge-sort-demo"
  data_prefix="sym-merge"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[マージソート](/2026/05/03/sort-merge.html)は線形補助配列で 1 回のマージを `O(n)` にし、全体を `O(n log n)` にする。

[ウィキソート](/2026/05/31/sort-wiki.html)や[グレイルソート](/2026/06/01/sort-grail.html)もインプレース安定整列を目指すが、平方根サイズのブロックと内部バッファ（またはキー）でマージコストを `O(n)` 級に押し下げ、全体を `O(n log n)` にする。

対称マージソートは対称マージ単体をボトムアップに積む古典構成で、実装は単純になる一方、最悪は `O(n log² n)` に留まる。ウィキ／グレイルの部品としての「回転ベースマージ」とは同系統だが、ブロックタグ付けまでは踏み込まない。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000012 |        0.000058 |               0 |               0 |
|        512 |        0.000027 |        0.000084 |               0 |               0 |
|       1024 |        0.000061 |        0.003818 |               0 |               0 |
|       2048 |        0.000146 |        0.001603 |               0 |               0 |
|       4096 |        0.000288 |        0.000504 |               0 |               0 |
|       8192 |        0.000639 |        0.001095 |               0 |               0 |
|      16384 |        0.001408 |        0.010186 |               0 |               0 |
|      32768 |        0.003047 |        0.006908 |               0 |               0 |
|      65536 |        0.006780 |        0.015404 |               0 |               0 |
|     131072 |        0.014363 |        0.033329 |               0 |               0 |
|     262144 |        0.031181 |        0.090916 |               0 |               0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="sym_merge" %}
