---
title:     ブリックソートで配列を並び替える
date:      2026-05-17 06:55:41 +0900
tags:      sort
sort_demo: true
---

## ブリックソートを使用する

ブリックソート (`brick sort`) は、隣接2要素を比較し逆順なら入れ替える操作を、奇数インデックス側と偶数インデックス側の2種類の組に分けて交互に繰り返す。

奇偶転置ソート (`odd-even sort`) やパリティソート (`parity sort`) とも呼ばれ、レンガを積むように交互の組で整列が進むイメージから名付けられた。

1.  **偶数組**: インデックス `(0,1), (2,3), (4,5), …` のペアを左サイドから順に見て、右の要素の方が小さければ入れ替える。
2.  **奇数組**: インデックス `(1,2), (3,4), (5,6), …` のペアについて同様に比較・交換する。
3.  **収束**: 偶数組と奇数組をまとめて 1 ラウンドとみなし、あるラウンドで一度も交換が起きなければ全体は昇順に整っているので終了する。

ラウンド内のペアは互いに独立して並列化でき、逐次実行では最悪計算量 `O(n²)` となる。安定ソートである。

```pseudocode
procedure brick_sort(A)
  n = length(A)
  sorted = false
  while not sorted
    sorted = true
    for i from 0 to n - 2 by 2
      if A[i] > A[i + 1] then
        swap(A[i], A[i + 1])
        sorted = false
    for i from 1 to n - 2 by 2
      if A[i] > A[i + 1] then
        swap(A[i], A[i + 1])
        sorted = false
```

バブルソートと同様に局所的な交換だけで進むが、奇数組・偶数組を交互に適用する点が異なる。並列プロセッサ向けに設計されたアルゴリズムとして知られ、各組の比較・交換は互いに独立して実行できる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('brick-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }
    while (true) {
      let swapped = false;
      steps.push({ kind: 'phase', phase: 'even', arr: a.slice() });
      for (let i = 0; i < n - 1; i += 2) {
        steps.push({ kind: 'compare', lo: i, hi: i + 1, arr: a.slice() });
        if (a[i] > a[i + 1]) {
          const t = a[i];
          a[i] = a[i + 1];
          a[i + 1] = t;
          swapped = true;
          steps.push({ kind: 'swap', lo: i, hi: i + 1, arr: a.slice() });
        }
      }
      steps.push({ kind: 'phase', phase: 'odd', arr: a.slice() });
      for (let i = 1; i < n - 1; i += 2) {
        steps.push({ kind: 'compare', lo: i, hi: i + 1, arr: a.slice() });
        if (a[i] > a[i + 1]) {
          const t2 = a[i];
          a[i] = a[i + 1];
          a[i + 1] = t2;
          swapped = true;
          steps.push({ kind: 'swap', lo: i, hi: i + 1, arr: a.slice() });
        }
      }
      if (!swapped) {
        break;
      }
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-brick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ブリックソートのデモ（奇数組・偶数組を交互に適用。比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          s.phase === 'even'
            ? '偶数組: 位置 0-1, 2-3, … のペアを順に比較'
            : '奇数組: 位置 1-2, 3-4, … のペアを順に比較'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + (s.lo + 1) + '）'
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
  id="brick-sort-demo"
  data_prefix="brick"
  script=sort_demo_js
%}

奇数組と偶数組を交互に進めるため、バブルソートの単方向走査とは異なり、小さい値も大きい値も両端へ同時に寄せやすい。偶・奇の組に分けて常に隣同士だけを見る点は、先頭から順に走査するバブルソートとの違いとしてもはっきりする。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000039 |        0.000651 |            1662 |            1668 |
|        512 |        0.000131 |        0.000471 |            1665 |            1672 |
|       1024 |        0.000443 |        0.000872 |            1673 |            1680 |
|       2048 |        0.001551 |        0.003336 |            1690 |            1696 |
|       4096 |        0.005781 |        0.011730 |            1722 |            1728 |
|       8192 |        0.020974 |        0.030058 |            1786 |            1792 |
|      16384 |        0.082163 |        0.191235 |            1918 |            1924 |
|      32768 |        0.332577 |        0.644139 |            2178 |            2184 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="brick" %}
