---
title:     三分割クイックソートで配列を並び替える
date:      2026-08-12 08:58:58 +0900
tags:      sort
sort_demo: true
---

## 三分割クイックソートを使用する

三分割クイックソート (`3-way quick sort`) は、単一のピボットを基準に部分配列を `< pivot`・`= pivot`・`> pivot` の 3 区間へ一度で分け、等値区間を確定させたうえで両外側だけを再帰する。

Dijkstra のオランダ国旗問題（Dutch National Flag）と同じ 3 色分割が原型で、Bentley と McIlroy の工学的なクイックソート改良でも同値の扱いに使われる。

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)が 2 分割だけだと等値キーが多いときに再帰が深くなるのに対し、こちらは等値帯をその場で確定できるため、重複の多い入力で有利になりやすい。

1.  **ピボットの選択**: 部分配列の先頭（など）から 1 要素をピボットとする。
2.  **3 分割**: 走査ポインタで要素をピボット未満・等値・超過の 3 領域へ仕分ける。
3.  **等値帯の確定**: ピボットと等値連続区間はすでに最終位置にある。
4.  **再帰**: 未満側と超過側だけに同じ処理を繰り返す。十分短い区間は挿入ソートで仕上げる。

```pseudocode
procedure three_way_quick_sort(A, lo, hi)
  if hi - lo <= INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  pivot = A[lo]
  lt = lo
  i = lo + 1
  gt = hi
  while i <= gt
    if A[i] < pivot then
      swap(A[lt], A[i])
      lt = lt + 1
      i = i + 1
    else if A[i] > pivot then
      swap(A[i], A[gt])
      gt = gt - 1
    else
      i = i + 1
  three_way_quick_sort(A, lo, lt - 1)
  three_way_quick_sort(A, gt + 1, hi)
```

平均計算量は `O(n log n)` で、キーの種類が定数個なら線形に近づく。ピボットが偏ると最悪計算量は `O(n²)` になり得る。一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('three-way-quick-sort-demo', function (root) {
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

    function threeWay(lo, hi) {
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

      const pivot = a[lo];
      let lt = lo;
      let i = lo + 1;
      let gt = hi;

      while (i <= gt) {
        steps.push({
          kind: 'scan',
          i: i,
          lt: lt,
          gt: gt,
          lo: lo,
          hi: hi,
          arr: a.slice(),
        });
        if (a[i] < pivot) {
          if (lt !== i) {
            const t1 = a[lt];
            a[lt] = a[i];
            a[i] = t1;
            steps.push({
              kind: 'swap',
              lo: lt,
              hi: i,
              arr: a.slice(),
              phase: 'less',
            });
          }
          lt++;
          i++;
        } else if (a[i] > pivot) {
          if (i !== gt) {
            const t2 = a[i];
            a[i] = a[gt];
            a[gt] = t2;
            steps.push({
              kind: 'swap',
              lo: i,
              hi: gt,
              arr: a.slice(),
              phase: 'great',
            });
          }
          gt--;
        } else {
          i++;
        }
      }

      steps.push({
        kind: 'part_end',
        lo: lo,
        hi: hi,
        lt: lt,
        gt: gt,
        arr: a.slice(),
      });

      if (lt > lo) {
        threeWay(lo, lt - 1);
      }
      if (gt < hi) {
        threeWay(gt + 1, hi);
      }
    }

    if (a.length > 0) {
      threeWay(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-three-way-quick',
    initialValues: [5, 2, 8, 5, 9, 3, 5, 2, 4, 3, 7, 8, 2, 9, 1],
    initialCaption:
      '三分割クイックソートのデモ（同値が多く、等値帯は再帰しない）',
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
        DemoSort.assignRoles(barsEl, [[s.lo, 'pivot']]);
        api.setCaption(
          '3 分割: 部分配列 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（左端をピボットに、< / = / > へ仕分け）'
        );
        return;
      }
      if (s.kind === 'scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'pivot'],
          [s.i, 'compare'],
          [s.lt, 'swap'],
          [s.gt, 'swap'],
        ]);
        api.setCaption(
          '走査: 位置 ' +
            s.i +
            ' をピボットと比較（<' +
            s.lt +
            ' … = … ' +
            s.gt +
            '>）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        const label =
          s.phase === 'insert'
            ? '挿入ソート: 交換しています…'
            : s.phase === 'less'
              ? 'ピボット未満の領域へ移動'
              : s.phase === 'great'
                ? 'ピボット超の領域へ移動'
                : '交換しています…';
        api.setCaption(label);
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        const roles = [];
        for (let p = s.lt; p <= s.gt; p++) {
          roles.push([p, 'pivot']);
        }
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '等値帯確定: 位置 ' +
            s.lt +
            ' … ' +
            s.gt +
            ' はピボットと同値（再帰は外側のみ）'
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
  id="three-way-quick-sort-demo"
  data_prefix="three-way-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)は 1 ピボットで 2 分割するが、等値を左右どちらに寄せるかの規約に依存し、重複が多いと偏りやすい。

[デュアルピボットクイックソート](/2026/07/26/sort-dual-pivot-quick.html)も 1 回の走査で 3 区間に分けるが、ピボットが 2 つで区間の意味が異なる。

三分割版は単一ピボットのまま等値帯を明示的に切り出す点が主題である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000005 |        0.000074 |              62 |              68 |
|        512 |        0.000011 |        0.000060 |              66 |              72 |
|       1024 |        0.000024 |        0.000417 |              61 |              68 |
|       2048 |        0.000053 |        0.000131 |              58 |              64 |
|       4096 |        0.000116 |        0.000214 |              62 |              68 |
|       8192 |        0.000255 |        0.000479 |              58 |              64 |
|      16384 |        0.000558 |        0.000818 |              57 |              64 |
|      32768 |        0.001197 |        0.001971 |              62 |              68 |
|      65536 |        0.002579 |        0.007840 |              62 |              68 |
|     131072 |        0.005431 |        0.009733 |              61 |              68 |
|     262144 |        0.011323 |        0.019386 |              58 |              64 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="three_way_quick" %}
