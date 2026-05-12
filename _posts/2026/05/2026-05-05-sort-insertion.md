---
title:     挿入ソートで配列を並び替える
date:      2026-05-05 06:04:02 +0900
tags:      sort
sort_demo: true
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

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('insertion-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    for (let i = 1; i < n; i++) {
      steps.push({
        kind: 'seg_start',
        keyIdx: i,
        arr: a.slice(),
      });
      let j = i;
      while (j > 0) {
        steps.push({ kind: 'compare', lo: j - 1, hi: j, arr: a.slice(), keyIdx: j });
        if (a[j - 1] > a[j]) {
          const t = a[j];
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

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-insertion',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '挿入ソートのデモ（挿入中の値は紫、比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    onStepError: function (api, err) {
      console.error('Step execution error:', err);
      api.setCaption('エラーが発生しました');
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'seg_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.keyIdx, 'key']]);
        api.setCaption(
          '位置 ' +
            s.keyIdx +
            ' の要素を、左の整列済み区間へ挿入しています（紫が取り込み対象）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '比較: 位置 ' + s.lo + ' と ' + s.hi + '（左側が整列済みの範囲内）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（挿入する値をひとつ左へ進めました）'
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

{% include sort-demo/wrapper.html
  id="insertion-sort-demo"
  preset="insertion"
  data_prefix="insertion"
  script=sort_demo_js
%}

教育用には [バブルソート](/2026/05/01/sort-bubble.html) と同様に実装も追いやすいが、入力が整列済みに近いほどステップが少なくなる点が異なる。広い入力では単体ではなく、より高速なアルゴリズムの補助（小区間処理）としての利用が現実的である。
