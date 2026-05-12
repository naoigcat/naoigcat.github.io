---
layout: post
title:  挿入ソートで配列を並び替える
date:   2026-05-05 06:04:02 +0900
tags:   sort
---

## 挿入ソートを使用する

挿入ソート (`insertion sort`) は、先頭側の **すでに整列済みの部分配列** を拡張しながら、未処理の要素を **先頭側の並びへの挿入位置** が見つかるまでひとつずつ先頭へ寄せていく比較ソートである。

1.  **整列済み領域**: 最初は先頭要素だけを整列済みとみなす（長さ `1` の配列は自明に整列済み）。
2.  **対象**: 続くインデックス `i = 1, 2, …` の要素を、この時点で整列済みの区間 `[0, i-1]` に取り込む。
3.  **挿入位置の探索**: `a[i]` を **キー** と見て、キーより大きい隣接要素がある限り、その要素を先頭側へ繰り上げ（または隣接交換で等価な操作として）キーが収まる位置まで動かす。
4.  **終了**: キーを空いた位置へ置いたら、`[0, i]` が整列済みとなる。すべての `i` について繰り返す。

実装によっては繰り上げを代入で書くほうが読みやすく、視覚化では **隣接スワップ** で同じ並びになる例が多い。以下は隣接比較と交換で表現したアルゴリズムである。

```pseudocode
procedure insertion_sort(A)
  n = length(A)
  for i from 1 to n - 1
    j = i
    while j > 0 and A[j - 1] > A[j] then
      swap(A[j - 1], A[j])
      j = j - 1
```

最悪・平均は比較回数ともに **O(n²)**。すでに昇順に近い入力では内部のループが早く終わり **最良は約 O(n)**。追加配列なしなら **O(1)** の補助空間。**安定ソート**（等しい値の順序が保てる）。

小さな長さにおいては単純でオーバーヘッドも少ないメリットがある。

<!-- markdownlint-disable MD046 -->
<div id="insertion-sort-demo" class="insertion-sort-demo">
<style>
.insertion-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.insertion-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.insertion-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.insertion-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.insertion-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.insertion-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.insertion-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.insertion-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.insertion-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.insertion-sort-demo__bar[data-role="key"] {
  outline: 3px solid #9b59b6;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(155,89,182,.35), 0 2px 6px rgba(0,0,0,.18);
}
.insertion-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .insertion-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .insertion-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .insertion-sort-demo__caption { color: #bbb; }
}
</style>
<div class="insertion-sort-demo__toolbar">
  <button type="button" data-is="shuffle">シャッフル</button>
  <button type="button" data-is="play">自動再生</button>
  <button type="button" data-is="pause" disabled>一時停止</button>
  <button type="button" data-is="step">1ステップ</button>
</div>
<div class="insertion-sort-demo__bars" data-is="bars" aria-live="polite"></div>
<p class="insertion-sort-demo__caption" data-is="caption"></p>
<script src="{{ '/assets/js/demo-sort.js' | relative_url }}"></script>
<script>
(function () {
  var root = document.getElementById('insertion-sort-demo');
  if (!root) return;
  var DemoSort = window.DemoSort;
  if (!DemoSort || !DemoSort.attachPlayback) return;

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var n = a.length;
    var i, j;
    for (i = 1; i < n; i++) {
      steps.push({
        kind: 'seg_start',
        keyIdx: i,
        arr: a.slice(),
      });
      j = i;
      while (j > 0) {
        steps.push({ kind: 'compare', lo: j - 1, hi: j, arr: a.slice(), keyIdx: j });
        if (a[j - 1] > a[j]) {
          var t = a[j];
          a[j] = a[j - 1];
          a[j - 1] = t;
          steps.push({
            kind: 'swap',
            lo: j - 1,
            hi: j,
            arr: a.slice(),
            keyIdx: j - 1,
          });
          j--;
        } else break;
      }
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function setRoles(container, lo, hi, kind, keyIdx) {
    var nodes = container.children;
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].removeAttribute('data-role');
    }
    if (keyIdx != null && nodes[keyIdx]) nodes[keyIdx].setAttribute('data-role', 'key');
    if (lo == null || hi == null) return;
    if (nodes[lo])
      nodes[lo].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
    if (nodes[hi])
      nodes[hi].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-is',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '挿入ソートのデモ（挿入中の値は紫、比較はオレンジ、交換は緑）',
    barClass: 'insertion-sort-demo__bar',
    generateSteps: generateSteps,
    onStepError: function (api, err) {
      console.error('Step execution error:', err);
      api.setCaption('エラーが発生しました');
    },
    applyStep: async function (api, s) {
      var barsEl = api.barsEl;
      if (s.kind === 'seg_start') {
        api.mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null, null, s.keyIdx);
        api.setCaption(
          '位置 ' +
            s.keyIdx +
            ' の要素を、左の整列済み区間へ挿入しています（紫が取り込み対象）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        setRoles(barsEl, s.lo, s.hi, 'compare', null);
        api.setCaption(
          '比較: 位置 ' + s.lo + ' と ' + s.hi + '（左側が整列済みの範囲内）'
        );
        return;
      }
      if (s.kind === 'swap') {
        var prev = api.steps[api.idx - 2];
        var lo = prev && prev.kind === 'compare' ? prev.lo : s.lo;
        setRoles(barsEl, lo, lo + 1, 'swap', null);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, lo);
        api.mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null, null, null);
        api.setCaption(
          '交換しました（挿入する値をひとつ左へ進めました）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null, null, null);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
})();
</script>
</div>
<!-- markdownlint-enable MD046 -->

教育用には [バブルソート](/2026/05/01/sort-bubble.html) と同様に実装も追いやすいが、入力が整列済みに近いほどステップが少なくなる点が異なる。広い入力では単体ではなく、より高速なアルゴリズムの補助（小区間処理）としての利用が現実的である。
