---
layout: post
title:  選択ソートで配列を並び替える
date:   2026-05-11 20:49:36 +0900
tags:   sort
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

<!-- markdownlint-disable MD046 -->
<div id="selection-sort-demo" class="selection-sort-demo">
<style>
.selection-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.selection-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.selection-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.selection-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.selection-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.selection-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.selection-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.selection-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.selection-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.selection-sort-demo__bar[data-role="sorted"] {
  outline: 3px solid #9b59b6;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(155,89,182,.35), 0 2px 6px rgba(0,0,0,.18);
}
.selection-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .selection-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .selection-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .selection-sort-demo__caption { color: #bbb; }
}
</style>
<div class="selection-sort-demo__toolbar">
  <button type="button" data-ssel="shuffle">シャッフル</button>
  <button type="button" data-ssel="play">自動再生</button>
  <button type="button" data-ssel="pause" disabled>一時停止</button>
  <button type="button" data-ssel="step">1ステップ</button>
</div>
<div class="selection-sort-demo__bars" data-ssel="bars" aria-live="polite"></div>
<p class="selection-sort-demo__caption" data-ssel="caption"></p>
<script src="{{ '/assets/js/demo-sort.js' | relative_url }}"></script>
<script>
(function () {
  var root = document.getElementById('selection-sort-demo');
  if (!root) return;
  var DemoSort = window.DemoSort;
  if (!DemoSort || !DemoSort.attachPlayback) return;

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
    var nodes = container.children;
    var k;
    for (k = 0; k < nodes.length; k++) {
      nodes[k].removeAttribute('data-role');
    }
    for (k = 0; k < sortedCount && k < nodes.length; k++) {
      nodes[k].setAttribute('data-role', 'sorted');
    }
    if (compareLo == null || compareHi == null) return;
    var r = role === 'swap' ? 'swap' : 'compare';
    if (nodes[compareLo]) nodes[compareLo].setAttribute('data-role', r);
    if (nodes[compareHi]) nodes[compareHi].setAttribute('data-role', r);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-ssel',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '選択ソートのデモ（確定済みは紫、比較はオレンジ、交換は緑）',
    barClass: 'selection-sort-demo__bar',
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
})();
</script>
</div>
<!-- markdownlint-enable MD046 -->

実装が単純な分、入力サイズが大きい場面では標準ライブラリのソートやより漸近的に有利なアルゴリズムに任せるのが現実的である。
