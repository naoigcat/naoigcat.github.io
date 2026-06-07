---
title:     奇偶マージソートで配列を並び替える
date:      2026-05-29 05:41:09 +0900
tags:      sort
sort_demo: true
---

## 奇偶マージソートを使用する

奇偶マージソート (`odd-even merge sort`) は、奇偶マージネットワークを再帰的に適用して配列を整列する比較ソートである。

前半・後半をそれぞれソートしたあと、偶数番地の部分列と奇数番地の部分列を独立にマージし、隣接する奇偶ペアを比較交換することで2列を1本の昇順列へまとめる。

1.  **分割**: 長さ `n`（2の冪）の区間を半分に分け、左右それぞれを再帰的に奇偶マージソートする。
2.  **奇偶マージ（再帰）**: 距離 `r` の要素同士を比較する前に、偶数側・奇数側の部分列へ同じマージを再帰適用する（`r` は 1, 2, 4, … と倍化）。
3.  **比較交換**: 奇数側先頭から距離 `r` のペア `(i, i+r)` を順に比較し、大きい方を右へ送る。
4.  **底**: `2r ≥ n` になったら `(lo, lo+r)` の1ペアだけを比較交換して終了する。

```pseudocode
procedure compare_exchange(A, i, j)
  if A[i] > A[j] then
    swap(A[i], A[j])

procedure odd_even_merge(A, lo, n, r)
  m = r * 2
  if m < n then
    odd_even_merge(A, lo, n, m)
    odd_even_merge(A, lo + r, n, m)
    for i from lo + r to lo + n - r - 1 step m
      compare_exchange(A, i, i + r)
  else
    compare_exchange(A, lo, lo + r)

procedure odd_even_merge_sort(A, lo, n)
  if n <= 1 then
    return
  m = n / 2
  odd_even_merge_sort(A, lo, m)
  odd_even_merge_sort(A, lo + m, m)
  odd_even_merge(A, lo, n, 1)
```

奇偶転置ソートが隣接ペアだけをラウンドごとに更新するのに対し、奇偶マージソートはすでに整列した部分列同士を奇数・偶数インデックスに分けてマージする点が異なる。要素数は2の冪を前提とする実装が一般的である。

逐次実行では時間計算量 `O(n log² n)`、インプレース版では追加配列を使わず `O(1)` の補助記憶で済む（再帰スタックは別）が、等しいキーの相対順序を保たない不安定なソートである。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('oddeven-merge-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    function compareExchange(i, j) {
      steps.push({ kind: 'compare', lo: i, hi: j, arr: a.slice() });
      if (a[i] > a[j]) {
        const t = a[i];
        a[i] = a[j];
        a[j] = t;
        steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice() });
      }
    }

    function oddEvenMerge(lo, len, r) {
      const m = r * 2;
      steps.push({
        kind: 'merge_start',
        lo: lo,
        len: len,
        r: r,
        arr: a.slice(),
      });
      if (m < len) {
        oddEvenMerge(lo, len, m);
        oddEvenMerge(lo + r, len, m);
        for (let i = lo + r; i + r < lo + len; i += m) {
          compareExchange(i, i + r);
        }
      } else {
        compareExchange(lo, lo + r);
      }
    }

    function oddEvenMergeSort(lo, len) {
      if (len <= 1) {
        return;
      }
      const half = len / 2;
      steps.push({
        kind: 'sort_start',
        lo: lo,
        len: len,
        arr: a.slice(),
      });
      oddEvenMergeSort(lo, half);
      oddEvenMergeSort(lo + half, half);
      oddEvenMerge(lo, len, 1);
    }

    oddEvenMergeSort(0, n);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function rangePairs(lo, len, role) {
    const pairs = [];
    for (let k = lo; k < lo + len; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-oddeven-merge',
    initialValues: [8, 3, 12, 1, 6, 14, 2, 15, 5, 11, 9, 4, 13, 7, 10, 0],
    initialCaption:
      '奇偶マージソートのデモ（対象区間は青、比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'sort_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.len, 'range'));
        api.setCaption(
          '再帰ソート: 区間 ' +
            s.lo +
            ' … ' +
            (s.lo + s.len - 1) +
            ' を左右に分割して整列'
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.len, 'range'));
        api.setCaption(
          '奇偶マージ: 区間 ' +
            s.lo +
            ' … ' +
            (s.lo + s.len - 1) +
            '（比較距離 r = ' +
            s.r +
            '）'
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
            '（距離 ' +
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

{% include sort-demo/wrapper.html
  id="oddeven-merge-sort-demo"
  data_prefix="oddeven-merge"
  script=sort_demo_js
%}

奇偶転置ソートと名前が近いが、転置版は「全要素が昇順になるまで偶数相・奇数相を繰り返す」単純なネットワークであるのに対し、奇偶マージソートは分割ソート＋奇偶マージの2段構造を持つ。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000010 |        0.000360 |            1661 |            1668 |
|        512 |        0.000023 |        0.000352 |            1665 |            1672 |
|       1024 |        0.000055 |        0.000627 |            1674 |            1680 |
|       2048 |        0.000127 |        0.000643 |            1689 |            1696 |
|       4096 |        0.000286 |        0.000562 |            1722 |            1728 |
|       8192 |        0.000642 |        0.000823 |            1785 |            1792 |
|      16384 |        0.001454 |        0.001806 |            1917 |            1924 |
|      32768 |        0.004030 |        0.011511 |            2178 |            2184 |
|      65536 |        0.011155 |        0.151606 |            2690 |            2696 |
|     131072 |        0.032456 |        0.067621 |            3714 |            3720 |
|     262144 |        0.081530 |        0.602119 |            5762 |            5768 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="oddeven_merge" %}
