---
title:     反復型クイックソートで配列を並び替える
date:      2026-09-22 06:57:23 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## 反復型クイックソートを使用する

反復型クイックソート (`iterative quicksort`) は、[ロムート分割型クイックソート](/2026/05/02/sort-quick-lomuto.html)と同じ分割を使いながら、再帰呼び出しの代わりに区間 `(lo, hi)` を明示スタックへ積んで処理する実装である。アルゴリズムの比較回数や分割の形は再帰版と同じで、制御の置き方が異なる。

1.  **初期化**: 整列対象の全体区間 `(0, n - 1)` をスタックに積む。
2.  **取り出し**: スタックから区間を 1 つ取り出す。要素が 1 つ以下なら捨て、十分小さい区間は[挿入ソート](/2026/05/05/sort-insertion.html)へ回す。
3.  **分割**: 中央付近をピボットにしたロムート分割でピボット最終位置 `p` を求める。
4.  **積む**: `lo … p - 1` と `p + 1 … hi` のうち、長い方を先に積み、短い方を後から積む。次に処理されるのは短い方なので、平均のスタック深さは $$O(\log n)$$ に抑えやすい。

```pseudocode
procedure iterative_quick_sort(A)
  stack = empty stack of (lo, hi)
  push (0, length(A) - 1) onto stack
  while stack is not empty
    (lo, hi) = pop stack
    if lo >= hi then
      continue
    if hi - lo is small then
      insertion_sort(A[lo .. hi])
      continue
    p = lomuto_partition(A, lo, hi)
    left = (lo, p - 1) if p > lo else none
    right = (p + 1, hi) if p < hi else none
    // push larger first so the smaller side is processed next
    if length(left) > length(right) then
      push left, then right (when present)
    else
      push right, then left (when present)
```

再帰版でコールスタックが深くなりすぎる環境や、末尾再帰最適化に頼れない実装言語でも、ヒープ上の明示スタックなら深さ上限を自分で決められる。

時間計算量の期待値は再帰版と同じ $$O(n \log n)$$、最悪は $$O(n^2)$$ で、不安定である。追加領域はスタックと小区間の作業分で、平均 $$O(\log n)$$、最悪 $$O(n)$$ になりうる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('iterative-quick-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function lomutoPartition(lo, hi) {
      const mid = lo + Math.floor((hi - lo) / 2);
      const t0 = a[mid];
      a[mid] = a[hi];
      a[hi] = t0;
      steps.push({ kind: 'pivot_move', lo: mid, hi, arr: a.slice() });
      const pivotVal = a[hi];
      let i = lo;
      for (let j = lo; j < hi; j++) {
        steps.push({ kind: 'compare', lo: j, hi, arr: a.slice() });
        if (a[j] < pivotVal) {
          if (i !== j) {
            const t = a[i];
            a[i] = a[j];
            a[j] = t;
            steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice() });
          }
          i++;
        }
      }
      if (i !== hi) {
        const t2 = a[i];
        a[i] = a[hi];
        a[hi] = t2;
        steps.push({ kind: 'swap', lo: i, hi, arr: a.slice() });
      }
      return i;
    }

    const stack = [[0, a.length - 1]];
    steps.push({ kind: 'push', lo: 0, hi: a.length - 1, depth: 1, arr: a.slice() });
    while (stack.length > 0) {
      const [lo, hi] = stack.pop();
      steps.push({
        kind: 'pop',
        lo,
        hi,
        depth: stack.length,
        arr: a.slice(),
      });
      if (lo >= hi) continue;
      steps.push({ kind: 'part_start', lo, hi, arr: a.slice() });
      const p = lomutoPartition(lo, hi);
      steps.push({ kind: 'part_end', pivot: p, lo, hi, arr: a.slice() });
      const leftOk = p > lo;
      const rightOk = p < hi;
      const leftLen = leftOk ? p - lo : 0;
      const rightLen = rightOk ? hi - p : 0;
      const pushSide = (sideLo, sideHi) => {
        stack.push([sideLo, sideHi]);
        steps.push({
          kind: 'push',
          lo: sideLo,
          hi: sideHi,
          depth: stack.length,
          arr: a.slice(),
        });
      };
      if (leftLen > rightLen) {
        if (leftOk) pushSide(lo, p - 1);
        if (rightOk) pushSide(p + 1, hi);
      } else {
        if (rightOk) pushSide(p + 1, hi);
        if (leftOk) pushSide(lo, p - 1);
      }
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-iterative-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '反復型クイックソートのデモ（比較はオレンジ、交換は緑、ピボットは紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'push') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'スタックへ積む: ' +
            s.lo +
            ' … ' +
            s.hi +
            '（深さ ' +
            s.depth +
            '）'
        );
        return;
      }
      if (s.kind === 'pop') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'スタックから取り出す: ' +
            s.lo +
            ' … ' +
            s.hi +
            '（残り深さ ' +
            s.depth +
            '）'
        );
        return;
      }
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        const mid = s.lo + Math.floor((s.hi - s.lo) / 2);
        DemoSort.assignRoles(barsEl, [[mid, 'pivot']]);
        api.setCaption(
          'ロムート分割: 部分配列 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（中央付近をピボット）'
        );
        return;
      }
      if (s.kind === 'pivot_move') {
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('ピボットを右端へ移しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.hi, 'pivot']]);
        api.setCaption('ピボットを右端（位置 ' + s.hi + '）へ移しました');
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.hi, 'pivot'],
        ]);
        api.setCaption(
          '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          'ピボット確定: 位置 ' +
            s.pivot +
            '。左右区間をスタックへ戻します'
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
  id="iterative-quick-sort-demo"
  data_prefix="iterative-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lomuto.html)は同じ分割を再帰で進める。反復型はコールスタックの代わりに明示スタックを使うだけで、分割の意味は変わらない。

[ホーア分割型クイックソート](/2026/08/14/sort-quick-hoare.html)は両端ポインタの分割で区間の切り方が異なる。こちらもスタックで非再帰化できるが、本記事はロムート分割との組み合わせを示す。

[イントロソート](/2026/05/07/sort-intro.html)は再帰深さの監視でヒープソートへ切り替える。反復型クイックは深さをスタック長として見えるようにし、アルゴリズム切替までは行わない。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size | Average time (s) | Maximum time (s) | Average memory (KiB) | Maximum memory (KiB) |
|-----------:|-----------------:|-----------------:|---------------------:|---------------------:|
|        256 |         0.000023 |         0.001825 |                    0 |                    0 |
|        512 |         0.000031 |         0.000309 |                    0 |                    0 |
|       1024 |         0.000054 |         0.000720 |                    0 |                    0 |
|       2048 |         0.000095 |         0.000932 |                    0 |                    0 |
|       4096 |         0.000186 |         0.001603 |                    0 |                    0 |
|       8192 |         0.000393 |         0.004895 |                    0 |                    0 |
|      16384 |         0.000825 |         0.010287 |                    0 |                    0 |
|      32768 |         0.001728 |         0.013224 |                    0 |                    0 |
|      65536 |         0.003532 |         0.008432 |                    0 |                    0 |
|     131072 |         0.006881 |         0.017141 |                    0 |                    0 |
|     262144 |         0.013408 |         0.019852 |                    0 |                    0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="iterative_quick" %}
