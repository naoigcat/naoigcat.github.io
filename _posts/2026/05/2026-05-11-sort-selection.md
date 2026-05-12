---
layout:    post
title:     選択ソートで配列を並び替える
date:      2026-05-11 20:49:36 +0900
tags:      sort
sort_demo: true
---

## 選択ソートを使用する

選択ソート (`selection sort`) は、未整列の範囲から **最小（または最大）の要素を1つ選び**、先頭側の未確定位置と交換することを繰り返す比較ソートである。各パスで「確定する要素」がはっきりするため、[バブルソート](/2026/05/01/sort-bubble.html) と同様に挙動を追いやすく、初学者向けの題材としてよく登場する。

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

最悪・平均・最良いずれも **比較回数は O(n²)** で、入力の並びで大きくは変わらない。交換回数は高々 **O(n)** と少ないのが特徴である。追加配列を使わなければ **空間計算量は O(1)** のインプレースソート。等しい値同士の順序を入れ替える実装になりやすく、一般に **不安定** なソートとして扱われる。

[クイックソート](/2026/05/02/sort-quick.html) やマージソートと比べると漸近的な効率は劣るが、実装が短く、動きの説明に向く。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('selection-sort-demo', function (root) {
  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var n = a.length;
    var iss;
    var j;
    var minIdx;
    var t;
    for (iss = 0; iss < n - 1; iss++) {
      steps.push({ kind: 'round', sortedUpTo: iss, arr: a.slice() });
      minIdx = iss;
      for (j = iss + 1; j < n; j++) {
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
    var pairs = [];
    var k;
    for (k = 0; k < sortedCount; k++) {
      pairs.push([k, 'sorted']);
    }
    if (compareLo != null && compareHi != null) {
      var r = role === 'swap' ? 'swap' : 'compare';
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
      var barsEl = api.barsEl;
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

{% include sort-demo/wrapper.html
  id="selection-sort-demo"
  preset="selection"
  data_prefix="selection"
  script=sort_demo_js
%}

実装が単純な分、入力サイズが大きい場面では標準ライブラリのソートやより漸近的に有利なアルゴリズムに任せるのが現実的である。
