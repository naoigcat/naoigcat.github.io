---
title:     バケットソートで配列を並び替える
date:      2026-06-23 08:13:00 +0900
tags:      sort
sort_demo: true
---

## バケットソートを使用する

バケットソート (`bucket sort`) は、キーの値域を等幅の区間（バケット）に分割し、各要素を対応するバケットへ仕分け、バケット内を整列して連結する。

入力が値域上でほぼ一様に分布するとき、平均時間計算量は線形に近づく。

1.  **値域の決定**: 配列の最小値 `min` と最大値 `max` から、バケット数 `m`（多くは `n` や `√n`）と区間幅を決める。
2.  **仕分け**: 各要素 `x` について、`(x - min) / (max - min)` などからバケット番号を求め、そのバケットに `x` を追加する。
3.  **バケット内整列**: 各バケットを挿入ソートやマージソートなどで昇順に整える（デモでは挿入ソート）。
4.  **連結**: バケット `0, 1, …` の順に要素を並べ直せば全体が昇順になる。

```pseudocode
procedure bucket_sort(A, m)
  if length(A) = 0 then return
  minVal = minimum(A)
  maxVal = maximum(A)
  buckets = empty list of m arrays
  for each x in A
    b = bucket_index(x, minVal, maxVal, m)
    append x to buckets[b]
  for each bucket B in buckets
    sort(B)
  A = concatenate(buckets)
```

分布が一様なら `O(n)` に近づくが、同一バケットに偏ると内部ソート分だけ遅くなる。

カウンティングソートや基数ソートと同様、キーの分布と値域の見積もりに依存する。浮動小数点や `[0, 1)` に正規化した一様乱数など、区間への写像が自然なデータに向く。サンプルソートのように比較に基づく分割点を標本から求める方式とは異なり、値域を等分する点が特徴的である。

以下のデモでは 15 要素を 5 個のバケットに仕分け、各バケットを挿入ソートで仕上げる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('bucket-sort-demo', function (root) {
  const BUCKET_COUNT = 5;

  function bucketIndex(value, minVal, maxVal, bucketCount) {
    if (maxVal === minVal) {
      return 0;
    }
    const idx = Math.floor(
      ((value - minVal) / (maxVal - minVal + 1)) * bucketCount
    );
    return Math.min(idx, bucketCount - 1);
  }

  function formatBuckets(buckets) {
    const parts = [];
    let b;
    for (b = 0; b < buckets.length; b++) {
      if (buckets[b].length) {
        parts.push('バケット ' + b + ': [' + buckets[b].join(', ') + ']');
      }
    }
    return parts.length ? parts.join(' / ') : '（まだなし）';
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const n = a.length;
    const steps = [];
    if (n === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    const minVal = Math.min.apply(null, a);
    const maxVal = Math.max.apply(null, a);
    const buckets = [];
    let b;
    for (b = 0; b < BUCKET_COUNT; b++) {
      buckets.push([]);
    }

    steps.push({
      kind: 'phase',
      phase: 'distribute',
      arr: a.slice(),
      minVal: minVal,
      maxVal: maxVal,
    });

    let i;
    for (i = 0; i < n; i++) {
      const v = a[i];
      steps.push({
        kind: 'assign_scan',
        idx: i,
        value: v,
        arr: a.slice(),
        minVal: minVal,
        maxVal: maxVal,
      });
      const bucket = bucketIndex(v, minVal, maxVal, BUCKET_COUNT);
      buckets[bucket].push(v);
      steps.push({
        kind: 'assign_done',
        idx: i,
        bucket: bucket,
        value: v,
        arr: a.slice(),
        buckets: buckets.map(function (bk) {
          return bk.slice();
        }),
      });
    }

    const gathered = [];
    for (b = 0; b < BUCKET_COUNT; b++) {
      gathered.push.apply(gathered, buckets[b]);
    }

    steps.push({
      kind: 'gather',
      arr: gathered.slice(),
      buckets: buckets.map(function (bk) {
        return bk.slice();
      }),
    });

    const working = gathered.slice();

    for (b = 0; b < BUCKET_COUNT; b++) {
      const len = buckets[b].length;
      if (len <= 1) {
        continue;
      }
      let lo = 0;
      let pb;
      for (pb = 0; pb < b; pb++) {
        lo += buckets[pb].length;
      }
      const hi = lo + len - 1;

      steps.push({
        kind: 'bucket_start',
        bucket: b,
        lo: lo,
        hi: hi,
        arr: working.slice(),
      });

      let j;
      for (j = lo + 1; j <= hi; j++) {
        let k = j;
        while (k > lo && working[k - 1] > working[k]) {
          steps.push({
            kind: 'compare',
            lo: k - 1,
            hi: k,
            arr: working.slice(),
            bucket: b,
          });
          const t = working[k - 1];
          working[k - 1] = working[k];
          working[k] = t;
          steps.push({
            kind: 'swap',
            lo: k - 1,
            hi: k,
            arr: working.slice(),
            bucket: b,
          });
          k--;
        }
      }

      steps.push({
        kind: 'bucket_done',
        bucket: b,
        lo: lo,
        hi: hi,
        arr: working.slice(),
      });
    }

    steps.push({ kind: 'done', arr: working.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-bucket',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'バケットソートのデモ（仕分けは水色、バケット内整列はオレンジ／緑の枠）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        if (s.phase === 'distribute') {
          api.setCaption(
            'フェーズ1: 値域 [' +
              s.minVal +
              ', ' +
              s.maxVal +
              '] を ' +
              BUCKET_COUNT +
              ' 個のバケットに仕分けます'
          );
        }
        return;
      }
      if (s.kind === 'assign_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          '仕分け: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' のバケット番号を求めます'
        );
        return;
      }
      if (s.kind === 'assign_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' はバケット ' +
            s.bucket +
            ' へ（' +
            formatBuckets(s.buckets) +
            '）'
        );
        return;
      }
      if (s.kind === 'gather') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('バケットを左から順に連結しました');
        return;
      }
      if (s.kind === 'bucket_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'range'], [s.hi, 'range']]);
        api.setCaption(
          'フェーズ2: バケット ' +
            s.bucket +
            ' を挿入ソート（位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '）'
        );
        return;
      }
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
      if (s.kind === 'bucket_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'バケット ' +
            s.bucket +
            ' の整列が完了（位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '）'
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
  id="bucket-sort-demo"
  data_prefix="bucket"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[カウンティングソート](/2026/06/20/sort-counting.html)は値そのものをインデックスにする。バケットは値域を等分し、仕分け後にバケット内を別ソートする。[サンプルソート](/2026/05/20/sort-sample.html)は標本から分割点を求める。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000006 |        0.000069 |            1681 |            1688 |
|        512 |        0.000013 |        0.001068 |            1702 |            1708 |
|       1024 |        0.000025 |        0.000489 |            1746 |            1752 |
|       2048 |        0.000051 |        0.000643 |            1833 |            1840 |
|       4096 |        0.000131 |        0.000602 |            2009 |            2016 |
|       8192 |        0.000211 |        0.000723 |            2175 |            2176 |
|      16384 |        0.000429 |        0.005347 |            2815 |            2816 |
|      32768 |        0.000905 |        0.004018 |            4224 |            4224 |
|      65536 |        0.001882 |        0.015891 |            7040 |            7040 |
|     131072 |        0.003822 |        0.005309 |           12686 |           12736 |
|     262144 |        0.009493 |        0.053594 |           23965 |           24000 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="bucket" %}
