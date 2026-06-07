---
title:     奇偶転置ソートで配列を並び替える
date:      2026-05-17 06:55:41 +0900
tags:      sort
sort_demo: true
---

## 奇偶転置ソートを使用する

奇偶転置ソート (`odd-even sort`) は、2種類の組に分けて隣接要素同士だけを比較し、逆順なら交換する操作を繰り返す比較ソートである。

1.  **偶数組**: インデックス `(0,1), (2,3), (4,5), …` のペアを左サイドから順に見て、右の要素の方が小さければ入れ替える。
2.  **奇数組**: インデックス `(1,2), (3,4), (5,6), …` のペアについて同様に比較・交換する。
3.  **収束**: 偶数組と奇数組をまとめて 1 ラウンドとみなし、あるラウンドで一度も交換が起きなければ全体は昇順に整っているので終了する。

隣接ペアだけを同時に処理できるため、同じ組内の比較・交換は互いに干渉せず、ラウンド内では「飛び飛びのペア」をまとめて進めることができる。

逐次実行では最悪時間計算量は `O(n²)`（ラウンド数は `O(n)`、各ラウンドで `O(n)` 本の隣接ペア）、追加の配列を使わず `O(1)` の補助記憶でよいインプレースな実装が可能である。隣接交換のみで安定なソートになる。クイックソートのような分割再帰型と比べれば遅いが、構造が単純でデバッグや可視化向きである。

```pseudocode
procedure odd_even_sort(A)
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

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('oddeven-sort-demo', function (root) {
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
    dataAttr: 'data-oddeven',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '奇偶転置ソートのデモ（偶数相・奇数相を交互に適用。比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          s.phase === 'even'
            ? '偶数相: 位置 0-1, 2-3, … のペアを順に比較'
            : '奇数相: 位置 1-2, 3-4, … のペアを順に比較'
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

{% include sort-demo/wrapper.html
  id="oddeven-sort-demo"
  data_prefix="oddeven"
  script=sort_demo_js
%}

偶・奇の相に分けて常に隣同士だけを見るため、バブルソートと並べると「先頭から順に走査するか、飛び飛びのペアで進めるか」の違いがはっきりする。

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

{% include sort-benchmark.md algorithm="oddeven" %}
