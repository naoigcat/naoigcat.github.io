---
title:     バブルソートで配列を並び替える
date:      2026-05-01 00:56:20 +0900
tags:      sort
sort_demo: true
---

## バブルソートを使用する

バブルソート (`bubble sort`) は、隣り合う要素を比較し、順序が逆なら入れ替える操作を繰り返して配列を昇順（または降順）に整列する。

小さい（または大きい）値が「泡のように」一端へ浮き上がっていく様子からこの名前が付いている。

1.  **走査開始**: 配列の先頭から、隣り合う2要素 `(a[i], a[i+1])` を順に見ていく。
2.  **交換**: `a[i] > a[i+1]` のときだけ2つを入れ替える。そうでなければ何もしない。
3.  **走査終了**: 1回の始端から終端への走査が終わると、常に大きい方が終端へ押し出されるため最大の要素は必ず終端に移動する。
4.  **繰り返し**: 配列がソートされるまで上記の走査を繰り返す。最適化として、すでに終端に固定された最大要素は次の走査から比較対象から外してよい。

```pseudocode
procedure bubble_sort(A)
  n = length(A)
  for i from 0 to n - 1
    swapped = false
    for j from 0 to n - 2 - i
      if A[j] > A[j + 1] then
        swap(A[j], A[j + 1])
        swapped = true
    if not swapped then
      break
```

最悪計算量は `O(n²)` だが、すでに整列済みなら `O(n)` で済み、安定ソートである。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('bubble-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    let swapped;
    for (let i = 0; i < n - 1; i++) {
      swapped = false;
      for (let j = 0; j < n - 1 - i; j++) {
        steps.push({ kind: 'compare', lo: j, hi: j + 1, arr: a.slice() });
        if (a[j] > a[j + 1]) {
          const t = a[j];
          a[j] = a[j + 1];
          a[j + 1] = t;
          swapped = true;
          steps.push({ kind: 'swap', lo: j, hi: j + 1, arr: a.slice() });
        }
      }
      if (!swapped) break;
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-bubble',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'バブルソートのデモ（比較はオレンジ、交換は緑の枠）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
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
  id="bubble-sort-demo"
  data_prefix="bubble"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[シェーカーソート](/2026/05/08/sort-shaker.html)は双方向の走査、[コムソート](/2026/05/09/sort-comb.html)は離れたペアから始めて間隔を狭める。いずれも隣接交換だが、バブルソートより実効速度が出やすいことがある。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000030 |        0.000096 |              58 |              64 |
|        512 |        0.000091 |        0.000282 |              62 |              68 |
|       1024 |        0.000305 |        0.001079 |              82 |              88 |
|       2048 |        0.001118 |        0.005678 |              58 |              64 |
|       4096 |        0.004255 |        0.014444 |              61 |              68 |
|       8192 |        0.016817 |        0.034865 |              62 |              68 |
|      16384 |        0.066442 |        0.144063 |              58 |              64 |
|      32768 |        0.270144 |        0.421798 |              69 |              76 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="bubble" %}
