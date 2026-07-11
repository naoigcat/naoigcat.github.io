---
title:     二分挿入ソートで配列を並び替える
date:      2026-06-10 07:58:29 +0900
tags:      sort
sort_demo: true
---

## 二分挿入ソートを使用する

二分挿入ソート (`binary insertion sort`) は、先頭側の整列済み区間へ要素を取り込むが、挿入位置の探索を二分探索で行う。

挿入ソートと同系統の比較ソートである。

1.  **整列済み領域**: 先頭要素だけを整列済みとみなし、`i = 1, 2, …` の要素を順に処理する。
2.  **キーの取り出し**: 位置 `i` の値をキーと見る。
3.  **二分探索**: 区間 `[0, i-1]` の中で、キーが収まる挿入位置 `pos` を `O(log i)` 回の比較で求める。
4.  **シフト**: `[pos, i-1]` の要素を右へ1つずつずらし、空いた `pos` にキーを置く。
5.  **終了**: すべての `i` について繰り返すと配列全体が昇順になる。

```pseudocode
procedure binary_insertion_sort(A)
  n = length(A)
  for i from 1 to n - 1
    key = A[i]
    lo = 0
    hi = i
    while lo < hi
      mid = floor((lo + hi) / 2)
      if A[mid] > key then
        hi = mid
      else
        lo = mid + 1
    for j from i - 1 down to lo
      A[j + 1] = A[j]
    A[lo] = key
```

比較回数は最悪でも `O(n log n)` に抑えられるが、要素の移動（シフト）は最悪 `O(n²)` のままである。追加配列を使わなければ補助空間は `O(1)` で、シフトの向きを保てば安定ソートにできる。

二分探索で比較回数だけを削っても、ランダムな入力ではシフトコストが支配的になりやすい。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('binary-insertion-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;

    for (let i = 1; i < n; i++) {
      const key = a[i];
      steps.push({
        kind: 'seg_start',
        keyIdx: i,
        arr: a.slice(),
      });

      let lo = 0;
      let hi = i;
      while (lo < hi) {
        const mid = (lo + hi) >> 1;
        steps.push({
          kind: 'search_compare',
          lo: mid,
          hi: i,
          arr: a.slice(),
          keyIdx: i,
          searchLo: lo,
          searchHi: hi,
        });
        if (a[mid] > key) hi = mid;
        else lo = mid + 1;
      }

      steps.push({
        kind: 'search_done',
        pos: lo,
        keyIdx: i,
        arr: a.slice(),
      });

      for (let j = i - 1; j >= lo; j--) {
        a[j + 1] = a[j];
        steps.push({
          kind: 'shift',
          lo: j,
          hi: j + 1,
          arr: a.slice(),
          keyIdx: lo,
        });
      }
      a[lo] = key;
      steps.push({
        kind: 'place',
        pos: lo,
        arr: a.slice(),
      });
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-binary-insertion',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '二分挿入ソートのデモ（挿入中の値は紫、二分探索の比較はオレンジ、シフトは緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    onStepError: function (api, err) {
      console.error('Step execution error:', err);
      api.setCaption('エラーが発生しました');
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'seg_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.keyIdx, 'key']]);
        api.setCaption(
          '位置 ' +
            s.keyIdx +
            ' の要素を、左の整列済み区間へ二分探索で挿入します（紫が取り込み対象）'
        );
        return;
      }
      if (s.kind === 'search_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '二分探索 [' +
            s.searchLo +
            ', ' +
            s.searchHi +
            '): 位置 ' +
            s.lo +
            ' とキー（位置 ' +
            s.hi +
            '）を比較'
        );
        return;
      }
      if (s.kind === 'search_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'key']]);
        api.setCaption('挿入位置 ' + s.pos + ' が決まりました。右へシフトします');
        return;
      }
      if (s.kind === 'shift') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('位置 ' + s.lo + ' の値を右へずらしています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        return;
      }
      if (s.kind === 'place') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'key']]);
        api.setCaption('位置 ' + s.pos + ' にキーを配置しました');
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
  id="binary-insertion-sort-demo"
  data_prefix="binary-insertion"
  script=sort_demo_js
%}

通常の挿入ソートと比べ、整列済み区間が長いほど比較回数の差が出やすい。一方で要素の移動量は同じ順序で増えるため、大きな配列では全体の実行時間は依然として二次的になりがちである。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000013 |        0.000529 |            1661 |            1668 |
|        512 |        0.000040 |        0.000601 |            1665 |            1672 |
|       1024 |        0.000148 |        0.000731 |            1674 |            1680 |
|       2048 |        0.000520 |        0.001505 |            1690 |            1696 |
|       4096 |        0.001956 |        0.004505 |            1722 |            1728 |
|       8192 |        0.007196 |        0.033570 |            1786 |            1792 |
|      16384 |        0.025592 |        0.070849 |            1918 |            1924 |
|      32768 |        0.103003 |        0.334269 |            2178 |            2184 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="binary_insertion" %}
