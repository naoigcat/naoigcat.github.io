---
title:     交換ソートで配列を並び替える
date:      2026-06-11 07:11:14 +0900
tags:      sort
sort_demo: true
---

## 交換ソートを使用する

交換ソート (`exchange sort`) は、未確定の左端 `i` を基準に、右側の各要素 `A[j]` と比較し、より小さい値が見つかるたびにその場で入れ替える比較ソートである。二重ループの比較パターンは選択ソートと同じだが、最小値の位置を記録してから一度だけ swap するのではなく、
**見つけ次第 swap する**点が異なる。

1.  **外側のインデックス**: 確定済みでない左端を `i` とする（初期は `i = 0`）。
2.  **右側との比較**: `j` を `i+1` から末尾まで進め、`A[j] < A[i]` なら `A[i]` と `A[j]` を入れ替える。
3.  **位置の確定**: 内側ループが終わると、位置 `i` には未整列部分の最小値が残る。
4.  **繰り返し**: `i` を1つ進め、`i = n-2` まで繰り返す。

```pseudocode
procedure exchange_sort(A)
  n = length(A)
  for i from 0 to n - 2
    for j from i + 1 to n - 1
      if A[j] < A[i] then
        swap(A[i], A[j])
```

最悪・平均・最良いずれも比較回数は `O(n²)` で、入力の並びで大きくは変わらない。選択ソートと違い、小さい値を見つけるたびに swap するため交換回数は最悪 `O(n²)` になりうる。追加配列を使わなければ空間計算量は `O(1)` のインプレースソート。等しい値同士の順序を入れ替える実装になりやすく、一般に不安定なソートとして扱われる。

教材によっては隣接要素だけを入れ替えるバブルソート（単純交換法）も「交換ソート」と呼ばれることがある。本記事では上記の **基準位置 `i` と右側全体を比較する即時 swap 型** を指す。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('exchange-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    let t;
    for (let i = 0; i < n - 1; i++) {
      steps.push({ kind: 'round', fixed: i, sortedUpTo: i, arr: a.slice() });
      for (let j = i + 1; j < n; j++) {
        steps.push({
          kind: 'compare',
          lo: i,
          hi: j,
          fixed: i,
          sortedUpTo: i,
          arr: a.slice()
        });
        if (a[j] < a[i]) {
          t = a[i];
          a[i] = a[j];
          a[j] = t;
          steps.push({
            kind: 'swap',
            lo: i,
            hi: j,
            fixed: i,
            sortedUpTo: i,
            arr: a.slice()
          });
        }
      }
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function paintBarStates(container, sortedCount, fixed, compareLo, compareHi, role) {
    const pairs = [];
    for (let k = 0; k < sortedCount; k++) {
      pairs.push([k, 'sorted']);
    }
    if (fixed != null) {
      pairs.push([fixed, 'range']);
    }
    if (compareLo != null && compareHi != null) {
      const r = role === 'swap' ? 'swap' : 'compare';
      pairs.push([compareLo, r], [compareHi, r]);
    }
    DemoSort.assignRoles(container, pairs);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-exchange',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '交換ソートのデモ（確定済みは紫、基準位置は青、比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'round') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, s.fixed, null, null);
        api.setCaption(
          '位置 ' + s.fixed + ' を基準に、右側の各要素と比較して必要なら交換します'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, s.fixed, s.lo, s.hi, 'compare');
        api.setCaption(
          '比較: 基準 位置 ' + s.lo + ' と 位置 ' + s.hi
        );
        return;
      }
      if (s.kind === 'swap') {
        paintBarStates(barsEl, s.sortedUpTo, s.fixed, s.lo, s.hi, 'swap');
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        paintBarStates(barsEl, s.sortedUpTo, s.fixed, null, null);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.arr.length, null, null, null);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="exchange-sort-demo"
  data_prefix="exchange"
  script=sort_demo_js
%}

選択ソートと整列結果は同じだが swap が多くなりやすい。バブルソートのように隣接ペアだけを扱う単純交換法とも、比較するペアの取り方が異なる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="exchange" %}
