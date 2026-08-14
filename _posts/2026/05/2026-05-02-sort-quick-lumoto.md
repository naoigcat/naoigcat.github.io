---
title:     ロムート分割型クイックソートで配列を並び替える
date:      2026-05-02 01:56:15 +0900
tags:      sort
sort_demo: true
---

## ロムート分割型クイックソートを使用する

ロムート分割型クイックソート (`quick sort with Lomuto partition`) は、ピボットを 1 つ選び、部分配列を「ピボット未満」と「ピボット以上」に分け、その両側へ同じ処理を再帰する。

分割（partition）にロムートの方式を使う点が特徴である。右端をピボットに据え、走査ポインタ `j` と境界ポインタ `i` の 2 本だけで左右を切り分ける。境界の意味が読みやすく、学習用の実装や可視化に向いている。

1.  **ピボットの選択**: 部分配列の右端要素をピボットとする（中央値などを使う場合は、選んだ要素をあらかじめ右端へ移してから同じ分割に入る）。
2.  **ロムート分割**: `i` を「ピボット未満領域の次の空き位置」とし、`j` で `lo … hi - 1` を走査する。`A[j] < pivot` なら `A[i]` と交換して `i` を進める。走査後にピボットを `A[i]` へ移すと、`i` がピボットの最終位置になる。
3.  **再帰**: ピボット左側（`lo … i - 1`）と右側（`i + 1 … hi`）に、要素が 1 つ以下になるまで手順 1〜2 を繰り返す。

```pseudocode
procedure lomuto_quick_sort(A, lo, hi)
  if lo >= hi then
    return
  p = lomuto_partition(A, lo, hi)
  lomuto_quick_sort(A, lo, p - 1)
  lomuto_quick_sort(A, p + 1, hi)

procedure lomuto_partition(A, lo, hi)
  pivot = A[hi]
  i = lo
  for j from lo to hi - 1
    if A[j] < pivot then
      swap(A[i], A[j])
      i = i + 1
  swap(A[i], A[hi])
  return i
```

分割後は `lo … i - 1` がピボット未満、`i` がピボット、`i + 1 … hi` がピボット以上になる。等値は右側へ寄せるため、キーの重複が多い入力では右側が厚くなりやすい。

[ホーア分割型クイックソート](/2026/08/14/sort-quick-hoare.html)と比べると、境界が一目で分かる反面、交換回数が増えやすく、末尾をそのままピボットにすると昇順・降順に近い入力で分割が偏りやすい。実用ではランダムピボットや三点中央値などのピボット選択と組み合わせ、偏りを起こしにくくすることが多い。

平均計算量は `O(n log n)` だが、ピボットが偏ると最悪計算量 `O(n²)` になり、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('lumoto-quick-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    function lomutoPartition(lo, hi) {
      const pivotVal = a[hi];
      let i = lo;
      for (let j = lo; j <= hi - 1; j++) {
        steps.push({ kind: 'compare', lo: j, hi: hi, arr: a.slice() });
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
        steps.push({ kind: 'swap', lo: i, hi: hi, arr: a.slice() });
      }
      return i;
    }
    function lomutoQuick(lo, hi) {
      if (lo >= hi) return;
      steps.push({ kind: 'part_start', lo: lo, hi: hi, arr: a.slice() });
      const p = lomutoPartition(lo, hi);
      steps.push({ kind: 'part_end', pivot: p, arr: a.slice() });
      lomutoQuick(lo, p - 1);
      lomutoQuick(p + 1, hi);
    }
    if (a.length > 0) {
      lomutoQuick(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-lumoto-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ロムート分割型クイックソートのデモ（比較はオレンジ、交換は緑、確定したピボットは紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.hi, 'pivot']]);
        api.setCaption(
          'ロムート分割: 部分配列 位置 ' + s.lo + ' … ' + s.hi + '（右端をピボット）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'pivot']]);
        api.setCaption(
          '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）'
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
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          'ピボット確定: 位置 ' +
            s.pivot +
            ' に小さい値群と大きい値群が分かれました'
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
  id="lumoto-quick-sort-demo"
  data_prefix="lumoto-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[マージソート](/2026/05/03/sort-merge.html)は補助配列で最悪計算量 `O(n log n)` を保証するが追加メモリが要る。
[ヒープソート](/2026/05/04/sort-heap.html)はインプレースで最悪計算量 `O(n log n)` だが、ロムート分割型クイックほど平均が速いとは限らない。

[三分割クイックソート](/2026/08/12/sort-three-way-quick.html)は `< / = / >` の 3 区間に分け等値帯をその場で確定する。
[デュアルピボットクイックソート](/2026/07/26/sort-dual-pivot-quick.html)はピボットを 2 つ使い、1 回の走査で 3 分割する。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000005 |        0.000044 |              62 |              68 |
|        512 |        0.000011 |        0.000069 |              65 |              72 |
|       1024 |        0.000024 |        0.000097 |              70 |              76 |
|       2048 |        0.000050 |        0.000404 |              62 |              68 |
|       4096 |        0.000108 |        0.000177 |              69 |              76 |
|       8192 |        0.000235 |        0.000336 |              62 |              68 |
|      16384 |        0.000507 |        0.001878 |              58 |              64 |
|      32768 |        0.001088 |        0.001596 |              57 |              64 |
|      65536 |        0.002323 |        0.008512 |              78 |              84 |
|     131072 |        0.004945 |        0.007501 |              62 |              68 |
|     262144 |        0.010508 |        0.054033 |              62 |              68 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="quick_lumoto" %}
