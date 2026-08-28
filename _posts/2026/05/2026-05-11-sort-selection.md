---
title:     選択ソートで配列を並び替える
date:      2026-05-11 20:49:36 +0900
tags:      sort
sort_demo: true
---

## 選択ソートを使用する

選択ソート (`selection sort`) は、未整列の範囲から最小（または最大）の要素を1つ選び、先頭側の未確定位置と交換することを繰り返す。

1.  **外側のインデックス**: 確定済みでない左端を `i` とする（初期は `i = 0`）。
2.  **最小の探索**: `j` を `i+1` から末尾まで動かし、`A[i..]` の中で最小の要素の位置を `minIdx` として記録する（`A[j]` と現時点の最小 `A[minIdx]` を比較する）。
3.  **交換**: `minIdx ≠ i` なら `A[i]` と `A[minIdx]` を入れ替える。これで位置 `i` の値は全体の中で `i` 番目に小さいものに確定する。
4.  **繰り返し**: `i` を1つ進め、`i = n-2` まで繰り返す（残り1要素は自動的に最大側に位置する）。

```pseudocode
procedure selection_sort(A)
  n = length(A)
  for i from 0 to n - 2
    minIdx = i
    for j from i + 1 to n - 1
      if A[j] < A[minIdx] then
        minIdx = j
    if minIdx != i then
      swap(A[i], A[minIdx])
```

比較回数は常に `O(n²)` だが、交換回数は高々 `O(n)` で、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('selection-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    let minIdx;
    let t;
    for (let iss = 0; iss < n - 1; iss++) {
      steps.push({ kind: 'round', sortedUpTo: iss, arr: a.slice() });
      minIdx = iss;
      for (let j = iss + 1; j < n; j++) {
        steps.push({
          kind: 'compare',
          lo: minIdx,
          hi: j,
          sortedUpTo: iss,
          arr: a.slice()
        });
        if (a[j] < a[minIdx]) {
          minIdx = j;
        }
      }
      if (minIdx !== iss) {
        t = a[iss];
        a[iss] = a[minIdx];
        a[minIdx] = t;
        steps.push({
          kind: 'swap',
          lo: iss,
          hi: minIdx,
          sortedUpTo: iss,
          arr: a.slice()
        });
      }
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function paintBarStates(container, sortedCount, compareLo, compareHi, role) {
    const pairs = [];
    for (let k = 0; k < sortedCount; k++) {
      pairs.push([k, 'sorted']);
    }
    if (compareLo != null && compareHi != null) {
      const r = role === 'swap' ? 'swap' : 'compare';
      pairs.push([compareLo, r], [compareHi, r]);
    }
    DemoSort.assignRoles(container, pairs);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-selection',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '選択ソートのデモ（確定済みは紫、比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'round') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, null, null);
        api.setCaption(
          '位置 ' + s.sortedUpTo + ' に入れる最小値を、右側から探します'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, s.lo, s.hi, 'compare');
        api.setCaption(
          '比較: 現在最小候補 位置 ' + s.lo + ' と 位置 ' + s.hi
        );
        return;
      }
      if (s.kind === 'swap') {
        paintBarStates(barsEl, s.sortedUpTo, s.lo, s.hi, 'swap');
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        paintBarStates(barsEl, s.sortedUpTo, null, null);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.arr.length, null, null);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="selection-sort-demo"
  data_prefix="selection"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[交換ソート](/2026/06/11/sort-exchange.html)と比較パターンは同じだが、最小位置を記録してから 1 回交換する。[トーナメントソート](/2026/05/26/sort-tournament.html)も最小を繰り返し取り出すが、木で比較を共有する。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000019 |        0.000083 |               0 |               0 |
|        512 |        0.000065 |        0.000159 |               0 |               0 |
|       1024 |        0.000228 |        0.000407 |               0 |               0 |
|       2048 |        0.000825 |        0.001372 |               0 |               0 |
|       4096 |        0.003073 |        0.008557 |               0 |               0 |
|       8192 |        0.011688 |        0.018198 |               0 |               0 |
|      16384 |        0.045350 |        0.086183 |               0 |               0 |
|      32768 |        0.178182 |        0.211426 |               0 |               0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="selection" %}
