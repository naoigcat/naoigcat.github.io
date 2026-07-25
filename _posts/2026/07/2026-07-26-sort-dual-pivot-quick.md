---
title:     デュアルピボットクイックソートで配列を並び替える
date:      2026-07-26 01:37:49 +0900
tags:      sort
sort_demo: true
---

## デュアルピボットクイックソートを使用する

デュアルピボットクイックソート (`dual-pivot quick sort`) は、部分配列の両端から 2 つのピボットを選び、
3 つの区間（第 1 ピボット未満・2 ピボットの間・第 2 ピボット超）に一度で分割してから、各区間を再帰的に整列する。

[クイックソート](/2026/05/02/sort-quick.html)が 1 つのピボットで左右 2 分割するのに対し、
こちらは 1 回の走査で 3 分割する。Java の `Arrays.sort`（プリミティブ型）などで採用されており、
キャッシュ効率や比較回数の面で単一ピボット版より有利になりやすいと報告されている。

1.  **2 ピボットの選択**: 部分配列の先頭と末尾（など）から 2 要素をピボット `p₁`, `p₂` とする。必要なら `p₁ ≤ p₂` になるよう交換する。
2.  **3 分割**: 走査ポインタで要素を `< p₁`・`p₁ ≤ · ≤ p₂`・`> p₂` の 3 領域へ仕分ける。
3.  **ピボットの確定**: `p₁`, `p₂` をそれぞれ中間領域の両端に置く。
4.  **再帰**: 左・中・右の 3 部分配列に同じ処理を繰り返す。十分短い区間は挿入ソートで仕上げる。

```pseudocode
procedure dual_pivot_quick_sort(A, lo, hi)
  if hi - lo <= INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  if A[lo] > A[hi] then
    swap(A[lo], A[hi])
  p1 = A[lo]
  p2 = A[hi]
  less = lo + 1
  great = hi - 1
  k = less
  while k <= great
    if A[k] < p1 then
      swap(A[k], A[less])
      less = less + 1
      k = k + 1
    else if A[k] > p2 then
      while k < great and A[great] > p2
        great = great - 1
      swap(A[k], A[great])
      great = great - 1
      if A[k] < p1 then
        swap(A[k], A[less])
        less = less + 1
      k = k + 1
    else
      k = k + 1
  swap(A[lo], A[less - 1])
  swap(A[hi], A[great + 1])
  dual_pivot_quick_sort(A, lo, less - 2)
  dual_pivot_quick_sort(A, less, great)
  dual_pivot_quick_sort(A, great + 2, hi)
```

平均計算量は `O(n log n)` だが、ピボットの偏り次第で最悪計算量 `O(n²)` になり得る。一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('dual-pivot-quick-sort-demo', function (root) {
  const INSERTION_THRESHOLD = 4;

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function insertionSort(lo, hi) {
      for (let i = lo + 1; i <= hi; i++) {
        let j = i;
        while (j > lo) {
          steps.push({
            kind: 'compare',
            lo: j - 1,
            hi: j,
            arr: a.slice(),
            phase: 'insert',
          });
          if (a[j - 1] > a[j]) {
            const t = a[j - 1];
            a[j - 1] = a[j];
            a[j] = t;
            steps.push({
              kind: 'swap',
              lo: j - 1,
              hi: j,
              arr: a.slice(),
              phase: 'insert',
            });
            j--;
          } else {
            break;
          }
        }
      }
    }

    function dualPivot(lo, hi) {
      if (lo >= hi) return;
      if (hi - lo <= INSERTION_THRESHOLD) {
        steps.push({
          kind: 'phase',
          text:
            '要素が ' +
            (hi - lo + 1) +
            ' 個以下のため、この範囲は挿入ソート（閾値 ' +
            INSERTION_THRESHOLD +
            ' 以下）',
          arr: a.slice(),
        });
        insertionSort(lo, hi);
        return;
      }

      steps.push({ kind: 'part_start', lo: lo, hi: hi, arr: a.slice() });

      if (a[lo] > a[hi]) {
        const t = a[lo];
        a[lo] = a[hi];
        a[hi] = t;
        steps.push({ kind: 'pivot_swap', lo: lo, hi: hi, arr: a.slice() });
      }

      const pivot1 = a[lo];
      const pivot2 = a[hi];
      let less = lo + 1;
      let great = hi - 1;
      let k = less;

      while (k <= great) {
        steps.push({
          kind: 'scan',
          k: k,
          less: less,
          great: great,
          lo: lo,
          hi: hi,
          arr: a.slice(),
        });
        if (a[k] < pivot1) {
          if (k !== less) {
            const t1 = a[k];
            a[k] = a[less];
            a[less] = t1;
            steps.push({
              kind: 'swap',
              lo: k,
              hi: less,
              arr: a.slice(),
              phase: 'less',
            });
          }
          less++;
          k++;
        } else if (a[k] > pivot2) {
          while (k < great && a[great] > pivot2) {
            steps.push({
              kind: 'great_scan',
              k: k,
              great: great,
              lo: lo,
              hi: hi,
              arr: a.slice(),
            });
            great--;
          }
          if (k <= great) {
            const t2 = a[k];
            a[k] = a[great];
            a[great] = t2;
            steps.push({
              kind: 'swap',
              lo: k,
              hi: great,
              arr: a.slice(),
              phase: 'great',
            });
            great--;
            if (a[k] < pivot1) {
              const t3 = a[k];
              a[k] = a[less];
              a[less] = t3;
              steps.push({
                kind: 'swap',
                lo: k,
                hi: less,
                arr: a.slice(),
                phase: 'less',
              });
              less++;
            }
          }
          k++;
        } else {
          k++;
        }
      }

      if (lo !== less - 1) {
        const t4 = a[lo];
        a[lo] = a[less - 1];
        a[less - 1] = t4;
        steps.push({
          kind: 'swap',
          lo: lo,
          hi: less - 1,
          arr: a.slice(),
          phase: 'pivot1',
        });
      }
      if (hi !== great + 1) {
        const t5 = a[hi];
        a[hi] = a[great + 1];
        a[great + 1] = t5;
        steps.push({
          kind: 'swap',
          lo: hi,
          hi: great + 1,
          arr: a.slice(),
          phase: 'pivot2',
        });
      }

      steps.push({
        kind: 'part_end',
        lo: lo,
        hi: hi,
        pivot1: less - 1,
        pivot2: great + 1,
        arr: a.slice(),
      });

      if (lo + 1 < less) {
        dualPivot(lo, less - 2);
      }
      if (less < great) {
        dualPivot(less, great);
      }
      if (great + 1 < hi) {
        dualPivot(great + 2, hi);
      }
    }

    if (a.length > 0) {
      dualPivot(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-dual-pivot-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'デュアルピボットクイックソートのデモ（左端・右端が 2 ピボット、3 分割は走査中のハイライト）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'pivot'], [s.hi, 'pivot']]);
        api.setCaption(
          '3 分割: 部分配列 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（左端・右端を 2 ピボットに）'
        );
        return;
      }
      if (s.kind === 'pivot_swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('第 1 ピボット > 第 2 ピボットのため、両端を交換');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        return;
      }
      if (s.kind === 'scan' || s.kind === 'great_scan') {
        api.mountBars(barsEl, s.arr);
        const roles = [[s.lo, 'pivot'], [s.hi, 'pivot']];
        if (s.kind === 'scan') {
          roles.push([s.k, 'compare']);
        } else {
          roles.push([s.great, 'compare']);
        }
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          s.kind === 'scan'
            ? '走査: 位置 ' +
                s.k +
                ' を 2 ピボットと比較（<' +
                s.less +
                ' … ' +
                s.great +
                '> の 3 領域へ仕分け）'
            : '右側領域: 位置 ' + s.great + ' が第 2 ピボット以下になるまで縮める'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        const label =
          s.phase === 'insert'
            ? '挿入ソート: 交換しています…'
            : s.phase === 'less'
              ? '第 1 ピボット未満の領域へ移動'
              : s.phase === 'great'
                ? '第 2 ピボット超の領域へ移動'
                : s.phase === 'pivot1'
                  ? '第 1 ピボットを確定位置へ'
                  : s.phase === 'pivot2'
                    ? '第 2 ピボットを確定位置へ'
                    : '交換しています…';
        api.setCaption(label);
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot1, 'pivot'], [s.pivot2, 'pivot']]);
        api.setCaption(
          '2 ピボット確定: 位置 ' +
            s.pivot1 +
            ' と ' +
            s.pivot2 +
            ' の間に中間領域、外側に小さい・大きい領域'
        );
        return;
      }
      if (s.kind === 'compare' && s.phase === 'insert') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '挿入ソート: 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="dual-pivot-quick-sort-demo"
  data_prefix="dual-pivot-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[クイックソート](/2026/05/02/sort-quick.html)は 1 ピボットで 2 分割するが、デュアルピボット版は 1 回の分割で 3 区間に分ける。
[サンプルソート](/2026/05/20/sort-sample.html)も複数の分割点を使うが、標本からスプリッターを選び並列化を想定した設計であるのに対し、
デュアルピボット版は両端 2 要素をピボットに据えるインプレースな再帰である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000010 |        0.000254 |              58 |              64 |
|        512 |        0.000019 |        0.000103 |              62 |              68 |
|       1024 |        0.000041 |        0.000273 |              82 |              88 |
|       2048 |        0.000080 |        0.000195 |              61 |              68 |
|       4096 |        0.000187 |        0.000397 |              62 |              68 |
|       8192 |        0.000447 |        0.001076 |              62 |              68 |
|      16384 |        0.000887 |        0.002198 |              82 |              88 |
|      32768 |        0.002008 |        0.009033 |              58 |              64 |
|      65536 |        0.004223 |        0.015791 |              58 |              64 |
|     131072 |        0.010088 |        0.040626 |              58 |              64 |
|     262144 |        0.016550 |        0.024620 |              62 |              68 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="dual_pivot_quick" %}
