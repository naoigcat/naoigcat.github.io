---
title:     シェルソートで配列を並び替える
date:      2026-05-06 07:48:33 +0900
tags:      sort
sort_demo: true
---

## シェルソートを使用する

シェルソート (`shell sort`) は、間隔（ギャップ）を取った部分列に対して挿入ソートを繰り返して全体を整列する。

ギャップが大きいうちは離れた要素同士の交換で粗く並びを整え、ギャップを小さくしていくと最終的に通常の挿入ソートとして収束する。

1.  **ギャップ列の決定**: 例として初期ギャップを `⌊n/2⌋` とし、各フェーズで半分に縮小して最後に 1 にする（古典的な増分列）。実装では Knuth 列など別の増分列を選ぶことも多い。
2.  **ギャップごとの挿入ソート**: 現在のギャップ `g` について、インデックス `g, g+1, …, n-1` を順に見ていき、各位置の要素を左へ「`g` 離れた」要素との比較によって挿入位置へ運ぶ（要素が逆順なら交換し、`j >= g` になるまで繰り返す）。
3.  **繰り返し**: ギャップが 1 になるまで手順 2 を繰り返す。ギャップ 1 のフェーズは通常の挿入ソートと同じになる。

```pseudocode
procedure shell_sort(A)
  n = length(A)
  gap = floor(n / 2)
  while gap > 0
    for i from gap to n - 1
      j = i
      while j >= gap and A[j - gap] > A[j]
        swap(A[j], A[j - gap])
        j = j - gap
    gap = floor(gap / 2)
```

ギャップ列次第だが、単純な `O(n²)` 系より速いことが多く、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('shell-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    let gap = Math.floor(n / 2);
    while (gap > 0) {
      steps.push({ kind: 'gap', gap: gap, arr: a.slice() });
      for (let i = gap; i < n; i++) {
        let j = i;
        while (j >= gap && a[j - gap] > a[j]) {
          steps.push({ kind: 'compare', lo: j - gap, hi: j, arr: a.slice() });
          const t = a[j];
          a[j] = a[j - gap];
          a[j - gap] = t;
          steps.push({ kind: 'swap', lo: j - gap, hi: j, arr: a.slice() });
          j -= gap;
        }
      }
      gap = Math.floor(gap / 2);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-shell',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'シェルソートのデモ（ギャップ変更時はキャプションのみ更新。比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'gap') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ギャップ ' + s.gap + ' で間隔付き挿入ソートを実行します'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '比較: 位置 ' +
            s.lo +
            ' と ' +
            s.hi +
            '（間隔 ' +
            (s.hi - s.lo) +
            '）'
        );
        return;
      }
      if (s.kind === 'swap') {
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
  id="shell-sort-demo"
  data_prefix="shell"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[挿入ソート](/2026/05/05/sort-insertion.html)は隣接だけを見る。シェルはギャップを取った部分列に挿入ソートを繰り返し、ギャップ 1 で挿入ソートに収束する。[コムソート](/2026/05/09/sort-comb.html)もギャップを使うが交換だけで進む。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000008 |        0.000040 |               0 |               0 |
|        512 |        0.000019 |        0.000073 |               0 |               0 |
|       1024 |        0.000044 |        0.000139 |               0 |               0 |
|       2048 |        0.000101 |        0.000213 |               0 |               0 |
|       4096 |        0.000235 |        0.000389 |               0 |               0 |
|       8192 |        0.000551 |        0.000909 |               0 |               0 |
|      16384 |        0.001310 |        0.002700 |               0 |               0 |
|      32768 |        0.003105 |        0.004898 |               0 |               0 |
|      65536 |        0.007336 |        0.010888 |               0 |               0 |
|     131072 |        0.018215 |        0.029881 |               0 |               0 |
|     262144 |        0.046311 |        0.074718 |               0 |               0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="shell" %}
