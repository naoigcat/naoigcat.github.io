---
title:     トーナメントソートで配列を並び替える
date:      2026-05-26 12:54:02 +0900
tags:      sort
sort_demo: true
---

## トーナメントソートを使用する

トーナメントソート (`tournament sort`) は、各要素を葉とする完全二分木を用意し、隣接する葉同士の比較で勝者（昇順なら小さい方のインデックス）を親へ伝播させるトーナメント木を構築する。

根には常に未処理領域の最小要素の位置が残るため、最小を1つ取り出すたびに根から葉へ向かって木だけを更新すればよく、毎回配列全体を走査する選択ソートより比較回数を抑えられる。

1.  **木の準備**: 要素数 `n` 以上の2の冪 `k` の葉を持つ配列 `tree` を用意する。葉 `tree[k+i]` にはインデックス `i`（`i ≥ n` の余りは無効）を入れる。
2.  **構築**: 葉から根へ向かい、各内部ノードに左右の子の勝者インデックスを記録する。
3.  **抽出**: 根 `tree[1]` が示すインデックスの値を出力位置へ書き出し、その葉を比較から外す。
4.  **更新**: 無効化した葉から親へ遡り、各内部ノードの勝者を再計算する。
5.  **繰り返し**: `n` 回手順3〜4を行えば昇順に整列する。

```pseudocode
procedure tournament_sort(A)
  n = length(A)
  k = smallest power of 2 with k >= n
  build tree leaves with indices 0 .. k-1 (padding invalid)
  for i from k-1 down to 1
    tree[i] = winner(A, tree[2i], tree[2i+1])
  for pos from 0 to n - 1
    idx = tree[1]
    output[pos] = A[idx]
    mark A[idx] as removed (sentinel)
    update tree along path from leaf k + idx to root
  copy output back into A
```

選択ソートより比較回数を抑えられ、全体で `O(n log n)` 程度だが、トーナメント木に `O(n)` の追加領域が要り、一般に不安定である。

外部ソートの置換選択（replacement selection）で「次に小さいレコード」を繰り返し取り出す構造と同型であり、ディスク上の連続ブロックから順位を決める場面で名前がよく登場する。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('tournament-sort-demo', function (root) {
  function generateSteps(initial) {
    const work = initial.slice();
    const display = initial.slice();
    const steps = [];
    const n = work.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: display.slice() });
      return steps;
    }

    let cap = 1;
    while (cap < n) {
      cap *= 2;
    }
    const tree = new Array(2 * cap).fill(-1);

    function winner(left, right) {
      if (left < 0) {
        return right;
      }
      if (right < 0) {
        return left;
      }
      const lv = work[left];
      const rv = work[right];
      if (lv === Infinity) {
        return right;
      }
      if (rv === Infinity) {
        return left;
      }
      return lv <= rv ? left : right;
    }

    for (let i = 0; i < cap; i++) {
      tree[cap + i] = i < n ? i : -1;
    }

    steps.push({
      kind: 'caption',
      text: 'トーナメント木を構築: 葉のペアを比較して勝者インデックスを親へ伝える',
      arr: display.slice(),
      sortedUpTo: 0,
    });

    for (let i = cap - 1; i >= 1; i--) {
      const lo = tree[2 * i];
      const hi = tree[2 * i + 1];
      if (lo >= 0 && hi >= 0) {
        steps.push({
          kind: 'compare',
          lo: lo,
          hi: hi,
          arr: display.slice(),
          phase: 'build',
          sortedUpTo: 0,
        });
      }
      tree[i] = winner(lo, hi);
    }

    for (let pos = 0; pos < n; pos++) {
      const win = tree[1];
      steps.push({
        kind: 'champion',
        win: win,
        pos: pos,
        arr: display.slice(),
        sortedUpTo: pos,
      });
      display[pos] = work[win];
      work[win] = Infinity;
      steps.push({
        kind: 'write',
        pos: pos,
        win: win,
        arr: display.slice(),
        sortedUpTo: pos,
      });
      let node = cap + win;
      tree[node] = -1;
      while (node > 1) {
        node = Math.floor(node / 2);
        const lo = tree[2 * node];
        const hi = tree[2 * node + 1];
        if (lo >= 0 && hi >= 0) {
          steps.push({
            kind: 'compare',
            lo: lo,
            hi: hi,
            arr: display.slice(),
            phase: 'rebuild',
            sortedUpTo: pos,
          });
        }
        tree[node] = winner(lo, hi);
      }
    }

    steps.push({ kind: 'done', arr: display.slice() });
    return steps;
  }

  function paintBarStates(container, sortedUpTo, pairs) {
    const all = [];
    for (let k = 0; k < sortedUpTo; k++) {
      all.push([k, 'sorted']);
    }
    for (const pair of pairs) {
      all.push(pair);
    }
    DemoSort.assignRoles(container, all);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-tournament',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'トーナメントソートのデモ（確定済みは紫、比較はオレンジ、勝者はカーソル、書き込みは書き込み色）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'caption') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, []);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption(
          (s.phase === 'build' ? '構築: ' : '更新: ') +
            '位置 ' +
            s.lo +
            ' と ' +
            s.hi +
            ' を比較'
        );
        return;
      }
      if (s.kind === 'champion') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [[s.win, 'cursor']]);
        api.setCaption(
          '木の根: 位置 ' + s.win + ' が次の最小（出力位置 ' + s.pos + '）'
        );
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [[s.pos, 'write']]);
        api.setCaption(
          '位置 ' + s.pos + ' に最小値を確定（元は位置 ' + s.win + '）'
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
  id="tournament-sort-demo"
  data_prefix="tournament"
  script=sort_demo_js
%}

選択ソートのように「毎回最小を1つ確定する」流れは同じだが、最小の探索を木で共有するため漸近的には有利になりやすい。一方で補助配列と更新処理の分、小さな `n` では定数倍で負けることもある。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000014 |        0.000448 |            1670 |            1676 |
|        512 |        0.000028 |        0.000865 |            1678 |            1684 |
|       1024 |        0.000052 |        0.000292 |            1698 |            1704 |
|       2048 |        0.000109 |        0.001297 |            1738 |            1744 |
|       4096 |        0.000237 |        0.000934 |            1818 |            1824 |
|       8192 |        0.000535 |        0.004348 |            1849 |            1856 |
|      16384 |        0.001211 |        0.004490 |            2048 |            2048 |
|      32768 |        0.002568 |        0.006344 |            2688 |            2688 |
|      65536 |        0.005691 |        0.039156 |            3967 |            3968 |
|     131072 |        0.013399 |        0.067338 |            6528 |            6528 |
|     262144 |        0.031101 |        0.575988 |           11765 |           11768 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="tournament" %}
