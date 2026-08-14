---
title:     サークルソートで配列を並び替える
date:      2026-08-09 02:30:18 +0900
tags:      sort
sort_demo: true
---

## サークルソートを使用する

サークルソート (`circle sort`) は、区間の両端から内側へ向かう「直径」上の要素同士を比較・交換し、そのあと区間を半分に分けて同じ処理を再帰する整列である。配列上に同心円を描き、同じ円上で向かい合う位置を見る、という比喩で説明されることが多い。

1 回の再帰パスだけでは必ずしも昇順にならないため、パス中に一度でも交換が起きた場合は配列全体に対して同じ処理を繰り返す。

1.  **直径比較（halver）**: 部分配列 `A[lo .. hi]` について、`A[lo]` と `A[hi]`、`A[lo+1]` と `A[hi-1]`、… のように向かい合う要素を比較し、逆順なら交換する。
2.  **奇数長の中央**: 要素数が奇数のとき、ポインタが中央で出会ったあと、中央要素とその右隣を比較して必要なら入れ替える。
3.  **再帰分割**: 区間を前後半に分け、それぞれに同じパスを再帰する。区間長が 1 以下なら何もしない。
4.  **反復**: パス全体で交換が起きなくなるまで、手順 1〜3 を配列全体に繰り返す。

```pseudocode
procedure circle_pass(A, lo, hi) -> swapped
  if lo >= hi then
    return false
  swapped = false
  left = lo
  right = hi
  while left < right
    if A[left] > A[right] then
      swap(A[left], A[right])
      swapped = true
    left = left + 1
    right = right - 1
  if left == right and right + 1 <= hi and A[left] > A[right + 1] then
    swap(A[left], A[right + 1])
    swapped = true
  mid = lo + floor((hi - lo) / 2)
  left_swapped = circle_pass(A, lo, mid)
  right_swapped = circle_pass(A, mid + 1, hi)
  return swapped or left_swapped or right_swapped

procedure circle_sort(A)
  n = length(A)
  if n < 2 then
    return
  while circle_pass(A, 0, n - 1)
    // 交換がなくなるまで繰り返す
```

1 パスあたりの比較回数はおおよそ `O(n log n)` で、パス回数は典型的に `O(log n)` 程度とされるため、全体は `O(n log² n)` 前後になる。補助配列は使わず、再帰の深さは `O(log n)` である。一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('circle-sort-demo', function (root) {
  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k <= hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function circlePass(a, lo, hi, steps) {
    if (lo >= hi) {
      return false;
    }
    steps.push({ kind: 'pass_range', lo: lo, hi: hi, arr: a.slice() });
    let swapped = false;
    let left = lo;
    let right = hi;
    while (left < right) {
      steps.push({
        kind: 'compare',
        lo: left,
        hi: right,
        arr: a.slice(),
      });
      if (a[left] > a[right]) {
        const t = a[left];
        a[left] = a[right];
        a[right] = t;
        steps.push({ kind: 'swap', lo: left, hi: right, arr: a.slice() });
        swapped = true;
      }
      left += 1;
      right -= 1;
    }
    if (left === right && right + 1 <= hi) {
      steps.push({
        kind: 'compare',
        lo: left,
        hi: right + 1,
        middle: true,
        arr: a.slice(),
      });
      if (a[left] > a[right + 1]) {
        const t = a[left];
        a[left] = a[right + 1];
        a[right + 1] = t;
        steps.push({
          kind: 'swap',
          lo: left,
          hi: right + 1,
          arr: a.slice(),
        });
        swapped = true;
      }
    }
    const mid = lo + Math.floor((hi - lo) / 2);
    const leftSwapped = circlePass(a, lo, mid, steps);
    const rightSwapped = circlePass(a, mid + 1, hi, steps);
    return swapped || leftSwapped || rightSwapped;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length < 2) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }
    let round = 1;
    let again = true;
    while (again) {
      steps.push({ kind: 'round_start', round: round, arr: a.slice() });
      again = circlePass(a, 0, a.length - 1, steps);
      steps.push({
        kind: 'round_end',
        round: round,
        again: again,
        arr: a.slice(),
      });
      round += 1;
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-circle',
    initialValues: [8, 3, 12, 1, 6, 14, 2, 15, 5, 11, 9, 4, 13, 7, 10, 0],
    initialCaption:
      'サークルソートのデモ（対象区間は青、直径比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'round_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('第 ' + s.round + ' パス開始（配列全体）');
        return;
      }
      if (s.kind === 'pass_range') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '直径比較の対象区間: 位置 ' + s.lo + ' … ' + s.hi
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          (s.middle ? '中央とその右隣を比較: 位置 ' : '直径上を比較: 位置 ') +
            s.lo +
            ' と ' +
            s.hi
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'round_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          s.again
            ? '第 ' + s.round + ' パスで交換あり → もう一周する'
            : '第 ' + s.round + ' パスで交換なし → 完了'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="circle-sort-demo"
  data_prefix="circle"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)はピボットで区間を分割するが、サークルソートの直径比較はピボット値を選ばず、両端から内側へ向かう固定パターンで入れ替えるだけである。

[バイトニックソート](/2026/05/28/sort-bitonic.html)も距離を意識した比較ネットワークだが、昇順・降順のバイトニック列を組み立ててからマージするのに対し、本アルゴリズムはパスを繰り返して収束させる。

[コムソート](/2026/05/09/sort-comb.html)はギャップを縮小しながら遠方の要素を入れ替える点が近いが、再帰的な同心円状の分割は行わない。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000017 |        0.000114 |              74 |              80 |
|        512 |        0.000038 |        0.000129 |              61 |              68 |
|       1024 |        0.000086 |        0.000274 |              61 |              68 |
|       2048 |        0.000219 |        0.001918 |              58 |              64 |
|       4096 |        0.000469 |        0.004720 |              62 |              68 |
|       8192 |        0.001043 |        0.008992 |              70 |              76 |
|      16384 |        0.002217 |        0.015200 |              62 |              68 |
|      32768 |        0.004864 |        0.030524 |              62 |              68 |
|      65536 |        0.010428 |        0.028383 |              62 |              68 |
|     131072 |        0.025252 |        0.069694 |              58 |              64 |
|     262144 |        0.054851 |        0.121746 |              81 |              88 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="circle" %}
