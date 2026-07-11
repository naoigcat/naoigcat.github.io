---
title:     バイトニックソートで配列を並び替える
date:      2026-05-28 00:35:10 +0900
tags:      sort
sort_demo: true
---

## バイトニックソートを使用する

バイトニックソート (`bitonic sort`) は、部分列を昇順・降順の2つの単調列（バイトニック列）に組み立て、距離 `k` の要素同士を比較・交換するバイトニックマージで整列させる。

1.  **分割**: 長さ `n`（2の冪）の区間を半分に分け、前半を昇順・後半を降順に整えるよう再帰する。
2.  **バイトニック列の形成**: 再帰の底で長さ2の区間は1回の比較で昇順または降順になる。
3.  **バイトニックマージ**: 区間の前半と後半を距離 `n/2` でペアにし、方向に応じて比較交換する。その後、半分の長さで同じ処理を再帰する。
4.  **全体**: 最上位の呼び出しで昇順方向を指定すれば、配列全体が昇順になる。

```pseudocode
procedure compare_exchange(A, i, j, dir_up)
  if dir_up and A[i] > A[j] then
    swap(A[i], A[j])
  if not dir_up and A[i] < A[j] then
    swap(A[i], A[j])

procedure bitonic_merge(A, lo, cnt, dir_up)
  if cnt <= 1 then
    return
  k = cnt / 2
  for i from lo to lo + k - 1
    compare_exchange(A, i, i + k, dir_up)
  bitonic_merge(A, lo, k, dir_up)
  bitonic_merge(A, lo + k, k, dir_up)

procedure bitonic_sort(A, lo, cnt, dir_up)
  if cnt <= 1 then
    return
  k = cnt / 2
  bitonic_sort(A, lo, k, true)
  bitonic_sort(A, lo + k, k, false)
  bitonic_merge(A, lo, cnt, dir_up)
```

並列比較ネットワーク向けで、逐次実行では `O(n log² n)` となり、要素数は 2 の冪を前提とする実装が多い。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('bitonic-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    function compareExchange(i, j, dirUp) {
      steps.push({
        kind: 'compare',
        lo: i,
        hi: j,
        dirUp: dirUp,
        arr: a.slice(),
      });
      const swap = dirUp ? a[i] > a[j] : a[i] < a[j];
      if (swap) {
        const t = a[i];
        a[i] = a[j];
        a[j] = t;
        steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice() });
      }
    }

    function bitonicMerge(lo, cnt, dirUp) {
      if (cnt <= 1) {
        return;
      }
      const k = cnt / 2;
      steps.push({
        kind: 'merge_start',
        lo: lo,
        cnt: cnt,
        dirUp: dirUp,
        arr: a.slice(),
      });
      for (let i = lo; i < lo + k; i++) {
        compareExchange(i, i + k, dirUp);
      }
      bitonicMerge(lo, k, dirUp);
      bitonicMerge(lo + k, k, dirUp);
    }

    function bitonicSort(lo, cnt, dirUp) {
      if (cnt <= 1) {
        return;
      }
      const k = cnt / 2;
      steps.push({
        kind: 'build_start',
        lo: lo,
        cnt: cnt,
        dirUp: dirUp,
        arr: a.slice(),
      });
      bitonicSort(lo, k, true);
      bitonicSort(lo + k, k, false);
      bitonicMerge(lo, cnt, dirUp);
    }

    bitonicSort(0, n, true);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function rangePairs(lo, cnt, role) {
    const pairs = [];
    for (let k = lo; k < lo + cnt; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-bitonic',
    initialValues: [8, 3, 12, 1, 6, 14, 2, 15, 5, 11, 9, 4, 13, 7, 10, 0],
    initialCaption:
      'バイトニックソートのデモ（対象区間は青、比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'build_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.cnt, 'range'));
        api.setCaption(
          'バイトニック列の構築: 区間 ' +
            s.lo +
            ' … ' +
            (s.lo + s.cnt - 1) +
            '（前半を昇順・後半を降順に再帰）'
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.cnt, 'range'));
        api.setCaption(
          'バイトニックマージ: 区間 ' +
            s.lo +
            ' … ' +
            (s.lo + s.cnt - 1) +
            ' を ' +
            (s.dirUp ? '昇順' : '降順') +
            ' へ整える'
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

{% include sort-demo.html
  id="bitonic-sort-demo"
  data_prefix="bitonic"
  script=sort_demo_js
%}

マージソートのように「分割してから整列する」構造を持つが、マージではなく固定距離の比較交換で順序を決める点が異なる。

奇偶転置ソートと同様、ラウンド内の比較パターンが決定的であるため、可視化するとネットワーク状の動きが見えやすい。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000017 |        0.000422 |            1662 |            1668 |
|        512 |        0.000034 |        0.000406 |            1666 |            1672 |
|       1024 |        0.000078 |        0.000540 |            1674 |            1680 |
|       2048 |        0.000171 |        0.000507 |            1690 |            1696 |
|       4096 |        0.000382 |        0.000765 |            1721 |            1728 |
|       8192 |        0.000906 |        0.001474 |            1786 |            1792 |
|      16384 |        0.001891 |        0.003437 |            1918 |            1924 |
|      32768 |        0.004394 |        0.035621 |            2178 |            2184 |
|      65536 |        0.009015 |        0.024121 |            2690 |            2696 |
|     131072 |        0.019486 |        0.062187 |            3714 |            3720 |
|     262144 |        0.040656 |        0.177968 |            5762 |            5768 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="bitonic" %}
