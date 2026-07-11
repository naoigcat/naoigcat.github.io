---
title:     シアソートで二次元格子を整列する
date:      2026-05-18 05:43:53 +0900
tags:      sort
sort_demo: true
---

## シアソートを使用する

シアソート (`shear sort`) は、要素を正方形の格子（`√n × √n`）に並べ、行と列を交互に整列させていく。

本質的には次の二種類のフェーズを繰り返す。

1.  **行フェーズ**: 各行を、偶数行は左から昇順・奇数行は右から昇順（左へ値が大きくなる並び）になるように整える。いわゆる蛇行方向が交互になる行ソートである。
2.  **列フェーズ**: 各列を、上から下へ昇順になるように整える。

二次元格子上の行・列整列を繰り返す並列向けソートで、要素数 N に対し `Θ(√N log N)` ステップで収まる。

バブルソートやクイックソートが一次元のインデックス列を直接いじるのに対し、シアソートは二次元インデックスと「同じ行・同じ列だけが比較される」という通信制約が前提になる点が対照的である。

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

蛇行順で昇順になった時点では、行優先に左から読むとまだ入れ替わったように見えることがある。実運用や見やすい一次元配列に落とすときは、文献でも触れられるように仕上げでもう一度だけ行方向に処理を足す（このデモでは各行をすべて昇順にそろえる）と、行優先読みでも昇順になる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('shear-sort-demo', function (root) {
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
    dataAttr: 'data-shear',
    initialValues: [
      5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15, 16,
    ],
    initialCaption:
      'シアソートのデモ（左から4要素ごとに1行。比較はオレンジ、交換は緑）',
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

{% include sort-demo.html
  id="shear-sort-demo"
  data_prefix="shear"
  script=sort_demo_js
%}

一次元配列だけを対象にしたソートに比べて、列の交換では画面上離れた二本の棒が動く一方で、行内の交換は隣同士に見える。

## 類似アルゴリズムとの相違点

[バブルソート](/2026/05/01/sort-bubble.html)や[クイックソート](/2026/05/02/sort-quick.html)は一次元配列を直接変更する。シアソートは二次元格子の行・列整列だけが許され、並列通信モデルが前提である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000018 |        0.001078 |            1854 |            1860 |
|        512 |        0.000043 |        0.000630 |            1866 |            1872 |
|       1024 |        0.000088 |        0.000508 |            1878 |            1884 |
|       2048 |        0.000243 |        0.000611 |            1914 |            1920 |
|       4096 |        0.000598 |        0.004951 |            1978 |            1984 |
|       8192 |        0.001687 |        0.005320 |            2106 |            2112 |
|      16384 |        0.004316 |        0.006946 |            2212 |            2304 |
|      32768 |        0.012391 |        0.017377 |            2792 |            2816 |
|      65536 |        0.039612 |        0.052896 |            3816 |            3840 |
|     131072 |        0.097635 |        0.298610 |            5864 |            5888 |
|     262144 |        0.312589 |        0.737209 |            9960 |            9984 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="shear" %}
