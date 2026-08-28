---
title:     ホーア分割型クイックソートで配列を並び替える
date:      2026-08-14 11:59:03 +0900
tags:      sort
sort_demo: true
---

## ホーア分割型クイックソートを使用する

ホーア分割型クイックソート (`quick sort with Hoare partition`) は、ピボットを 1 つ選び、両端から内側へ向かう 2 本のポインタで「逆転している組」を見つけて交換し、交差した位置で部分配列を二分する。

分割（partition）にホーアの方式を使う点が特徴である。[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)が片方向走査と境界インデックスでピボットの最終位置を返すのに対し、ホーア分割は左右からの詰め合いで交換回数を抑えやすく、返り値は「左側の末尾」でありピボット要素そのものの最終添字とは限らない。

1.  **ピボットの選択**: 部分配列の中央（など）の要素値をピボットとする。要素を端へ移す必要はない。
2.  **ホーア分割**: `i` を左端の手前、`j` を右端の向こうから始め、`A[i] < pivot` のあいだ `i` を進め、`A[j] > pivot` のあいだ `j` を戻す。`i < j` なら `A[i]` と `A[j]` を交換して続け、`i ≥ j` なら `j` を分割位置として返す。
3.  **再帰**: `lo … j` と `j + 1 … hi` に同じ処理を繰り返す（ピボット添字を除外するロムート型とは区間の切り方が異なる）。

```pseudocode
procedure hoare_quick_sort(A, lo, hi)
  if lo >= hi then
    return
  p = hoare_partition(A, lo, hi)
  hoare_quick_sort(A, lo, p)
  hoare_quick_sort(A, p + 1, hi)

procedure hoare_partition(A, lo, hi)
  pivot = A[lo + floor((hi - lo) / 2)]
  i = lo - 1
  j = hi + 1
  loop
    do
      i = i + 1
    while A[i] < pivot
    do
      j = j - 1
    while A[j] > pivot
    if i >= j then
      return j
    swap(A[i], A[j])
```

等値は `<` / `>` のどちら側にも残りうる。分割後にピボットが `j` に固定される保証はないため、再帰は `p` と `p + 1` で切る（`p - 1` と `p + 1` ではない）。

ロムート分割より平均の交換は少なくなりやすい一方、境界条件と再帰区間の取り扱いに注意が要る。末尾固定ピボットのロムートと同様、ピボット選びが偏ると最悪計算量は `O(n²)` になり得る。

平均計算量は `O(n log n)` で、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('hoare-quick-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function hoarePartition(lo, hi) {
      let pivotIdx = lo + Math.floor((hi - lo) / 2);
      const pivotVal = a[pivotIdx];
      steps.push({
        kind: 'part_start',
        lo,
        hi,
        pivot: pivotIdx,
        arr: a.slice(),
      });
      let i = lo - 1;
      let j = hi + 1;
      for (;;) {
        do {
          i += 1;
          steps.push({
            kind: 'compare',
            lo: i,
            pivot: pivotIdx,
            side: 'i',
            arr: a.slice(),
          });
        } while (a[i] < pivotVal);
        do {
          j -= 1;
          steps.push({
            kind: 'compare',
            lo: j,
            pivot: pivotIdx,
            side: 'j',
            arr: a.slice(),
          });
        } while (a[j] > pivotVal);
        if (i >= j) {
          steps.push({
            kind: 'part_end',
            lo,
            hi,
            split: j,
            pivot: pivotIdx,
            arr: a.slice(),
          });
          return j;
        }
        const t = a[i];
        a[i] = a[j];
        a[j] = t;
        if (pivotIdx === i) pivotIdx = j;
        else if (pivotIdx === j) pivotIdx = i;
        steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice() });
      }
    }

    function hoareQuick(lo, hi) {
      if (lo >= hi) return;
      const p = hoarePartition(lo, hi);
      hoareQuick(lo, p);
      hoareQuick(p + 1, hi);
    }

    if (a.length > 0) {
      hoareQuick(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-hoare-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ホーア分割型クイックソートのデモ（左右ポインタはオレンジ、交換は緑、ピボットは紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          'ホーア分割: 部分配列 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（中央付近をピボット）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.pivot, 'pivot'],
        ]);
        api.setCaption(
          (s.side === 'i' ? '左ポインタ i=' : '右ポインタ j=') +
            s.lo +
            ' をピボットと比較'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('逆転を交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.split, 'pivot']]);
        api.setCaption(
          '分割完了: 左は ' +
            s.lo +
            '…' +
            s.split +
            '、右は ' +
            (s.split + 1) +
            '…' +
            s.hi +
            ' を再帰（返り値は境界 j）'
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
  id="hoare-quick-sort-demo"
  data_prefix="hoare-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)は片方向走査でピボットを最終位置に置き、`p - 1` / `p + 1` で再帰する。
ホーア分割は両端からの交換が中心で、返り値 `j` を境に `j` / `j + 1` で切る。

[三分割クイックソート](/2026/08/12/sort-three-way-quick.html)は等値帯をその場で確定する。[デュアルピボットクイックソート](/2026/07/26/sort-dual-pivot-quick.html)はピボットを 2 つ使い 3 区間に分ける。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000007 |        0.000049 |               0 |               0 |
|        512 |        0.000017 |        0.000066 |               0 |               0 |
|       1024 |        0.000036 |        0.000259 |               0 |               0 |
|       2048 |        0.000075 |        0.000152 |               0 |               0 |
|       4096 |        0.000170 |        0.001208 |               0 |               0 |
|       8192 |        0.000354 |        0.000611 |               0 |               0 |
|      16384 |        0.000747 |        0.001309 |               0 |               0 |
|      32768 |        0.001605 |        0.002451 |               0 |               0 |
|      65536 |        0.003462 |        0.011929 |               0 |               0 |
|     131072 |        0.007363 |        0.015832 |               0 |               0 |
|     262144 |        0.015174 |        0.026003 |               0 |               0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="quick_hoare" %}
