---
title:     シェアソートで二次元格子を整列する
date:      2026-05-18 05:43:53 +0900
tags:      sort
sort_demo: true
---

## シェアソートを使用する

シェアソート (`shear sort`) は、要素を **正方形の格子（√n × √n）** に並べたうえで、**行** と **列** を交互に整列させていく比較ベースのソートである。

本質的には次の二種類のフェーズを繰り返す。

1.  **行フェーズ**: 各行を、**偶数行は左から昇順・奇数行は右から昇順**（左へ値が大きくなる並び）になるように整える。いわゆる **蛇行方向が交互になる行ソート** である。
2.  **列フェーズ**: 各列を、上から下へ **昇順** になるように整える。

格子の一辺の長さを r とすると、繰り返しはだいたい **O(log r)** 回で十分であり、全体として並列ステップ数は **Θ(r log r)**（要素数 N=r² に対して **Θ(√N log N)**）に収まるとされる。出力の並びは一般に **蛇行順で値が昇順になる配置** になる。

バブルソートやクイックソートが **一次元のインデックス列** を直接いじるのに対し、シェアソートは **二次元インデックスと「同じ行・同じ列だけが比較される」という通信制約** が前提になる点が対照的である。

```pseudocode
procedure shear_sort_rows_then_cols(A, side)
  repeat until snake_order_sorted(A, side)
    for row from 0 to side - 1
      if row is even then
        sort_row_ascending_left_to_right(A, row)
      else
        sort_row_descending_left_to_right(A, row)
    for col from 0 to side - 1
      sort_column_ascending_top_to_bottom(A, col)
```

蛇行順で昇順になった時点では、行優先に左から読むとまだ入れ替わったように見えることがある。実運用や見やすい一次元配列に落とすときは、文献でも触れられるように **仕上げでもう一度だけ行方向に処理を足す**（このデモでは **各行をすべて昇順にそろえる**）と、行優先読みでも昇順になる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('share-sort-demo', function (root) {
  function snakeSorted(a, w, side) {
    const seq = [];
    for (let r = 0; r < side; r++) {
      if (r % 2 === 0) {
        for (let c = 0; c < w; c++) seq.push(a[r * w + c]);
      } else {
        for (let c = w - 1; c >= 0; c--) seq.push(a[r * w + c]);
      }
    }
    for (let i = 1; i < seq.length; i++) {
      if (seq[i - 1] > seq[i]) return false;
    }
    return true;
  }

  function bubbleRowSteps(a, steps, r, w, ascending) {
    const start = r * w;
    const end = start + w;
    for (let pass = 0; pass < w; pass++) {
      let swapped = false;
      for (let j = start; j < end - 1; j++) {
        const cmp = ascending ? a[j] > a[j + 1] : a[j] < a[j + 1];
        steps.push({ kind: 'compare', lo: j, hi: j + 1, arr: a.slice() });
        if (cmp) {
          const t = a[j];
          a[j] = a[j + 1];
          a[j + 1] = t;
          swapped = true;
          steps.push({ kind: 'swap_adj', lo: j, arr: a.slice() });
        }
      }
      if (!swapped) break;
    }
  }

  function bubbleColSteps(a, steps, c, w, side) {
    for (let pass = 0; pass < side; pass++) {
      let swapped = false;
      for (let k = 0; k < side - 1; k++) {
        const i = c + k * w;
        const j = c + (k + 1) * w;
        steps.push({ kind: 'compare', lo: i, hi: j, arr: a.slice() });
        if (a[i] > a[j]) {
          const t = a[i];
          a[i] = a[j];
          a[j] = t;
          swapped = true;
          steps.push({ kind: 'swap_far', lo: i, hi: j, arr: a.slice() });
        }
      }
      if (!swapped) break;
    }
  }

  function generateSteps(initial) {
    const w = 4;
    const side = 4;
    const expect = w * side;
    const a = initial.slice(0, expect);
    while (a.length < expect) {
      a.push(0);
    }
    const steps = [];
    let iter = 0;
    const maxIter = 24;
    steps.push({
      kind: 'phase',
      phase: 'intro',
      arr: a.slice(),
    });
    while (!snakeSorted(a, w, side) && iter < maxIter) {
      iter++;
      steps.push({
        kind: 'phase',
        phase: 'iter',
        num: iter,
        arr: a.slice(),
      });
      steps.push({ kind: 'phase', phase: 'row', arr: a.slice() });
      for (let r = 0; r < side; r++) {
        bubbleRowSteps(a, steps, r, w, r % 2 === 0);
      }
      steps.push({ kind: 'phase', phase: 'col', arr: a.slice() });
      for (let c = 0; c < side; c++) {
        bubbleColSteps(a, steps, c, w, side);
      }
    }
    steps.push({ kind: 'phase', phase: 'finalize', arr: a.slice() });
    for (let r = 0; r < side; r++) {
      bubbleRowSteps(a, steps, r, w, true);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-share',
    initialValues: [
      5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15, 16,
    ],
    initialCaption:
      'シェアソートのデモ（左から4要素ごとに1行。比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase' && s.phase === 'intro') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '4×4 の格子を行優先で並べた16要素です（位置 0〜3 が最上行…）'
        );
        return;
      }
      if (s.kind === 'phase' && s.phase === 'iter') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('繰り返し ' + s.num + ' 周目: 行フェーズ→列フェーズへ');
        return;
      }
      if (s.kind === 'phase' && s.phase === 'row') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '行フェーズ: 偶数行は左から昇順、奇数行は左から降順にそろえる'
        );
        return;
      }
      if (s.kind === 'phase' && s.phase === 'col') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('列フェーズ: 各列を上から昇順にそろえる');
        return;
      }
      if (s.kind === 'phase' && s.phase === 'finalize') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '仕上げ: 各行を昇順にそろえ、左から読んでも昇順になるようにする'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'swap_adj') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + (s.lo + 1) + '）'
        );
        return;
      }
      if (s.kind === 'swap_far') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
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
  id="share-sort-demo"
  preset="bubble"
  data_prefix="share"
  script=sort_demo_js
%}

一次元配列だけを対象にしたバブルソートやクイックソートのデモと見比べると、**列の交換では画面上離れた二本の棒が動く**一方で、**行内の交換は隣同士に見える**という違いがはっきりする。
