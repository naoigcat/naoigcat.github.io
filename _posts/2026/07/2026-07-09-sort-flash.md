---
title:     フラッシュソートで配列を並び替える
date:      2026-07-09 07:59:33 +0900
tags:      sort
sort_demo: true
---

## フラッシュソートを使用する

フラッシュソート (`flash sort`) は、キーの最小値・最大値から値域を `m` 個のクラス（区分）に等分し、各要素を対応クラスへ仕分け、クラス内を挿入ソートで仕上げる。

バケットソートと同様に分布が一様なとき平均時間計算量は線形に近づくが、補助配列として大きなバケット列を持たず、インプレースの循環交換でクラス境界へ要素を集める点が特徴的である。

1.  **値域とクラス数**: 配列の最小値 `min`・最大値 `max` を求め、クラス数 `m` を `⌈√(2 n log₂ n)⌉` 程度（実装によっては `0.45 n` 付近）に設定する。
2.  **出現数の集計**: 各要素 `x` について `k = ⌊(m - 1)(x - min) / (max - min)⌋` でクラス番号を求め、クラスごとの要素数を数える。
3.  **境界の確定**: 累積和から各クラスが最終配列のどの区間 `[start_k, end_k)` を占めるかを決める。
4.  **インプレース配置**: 右端から走査し、属するクラスがまだ確定していない要素を、対応クラスの未確定先頭位置と交換して前進させる（循環交換）。
5.  **クラス内整列**: 各区間について挿入ソートを行えば全体が昇順になる。

```pseudocode
procedure flash_sort(A)
  n = length(A)
  if n ≤ 1 then return
  minVal = minimum(A)
  maxVal = maximum(A)
  if minVal = maxVal then return
  m = max(2, ceil(sqrt(2 * n * log2(n))))
  count[0..m-1] = 0
  for each x in A
    k = floor((m - 1) * (x - minVal) / (maxVal - minVal))
    count[k] = count[k] + 1
  boundary[0] = 0
  for k from 0 to m - 1
    boundary[k + 1] = boundary[k] + count[k]
  permute A in-place using boundary as class tails
  for k from 0 to m - 1
    insertion_sort(A[boundary[k] .. boundary[k + 1] - 1])
```

分布が一様なら `O(n)` に近づくが、同一クラスに偏ると `O(n²)` になる。

カウンティングソートが値域幅 `k` 分の配列を要するのに対し、フラッシュソートはクラス数を `m ≪ k` に抑えて分布の粗い写像を行う。バケットソートが各バケットを独立配列として持つのに対し、最終配列上の区間へ直接集めるインプレース志向の実装が多い。

以下のデモでは視認性のためクラス数を 5 に固定し、配置フェーズはクラス境界へ集めた結果を示す（本番実装では上記の循環交換を用いる）。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('flash-sort-demo', function (root) {
  const CLASS_COUNT = 5;

  function classIndex(value, minVal, maxVal, classCount) {
    if (maxVal === minVal) {
      return 0;
    }
    const idx = Math.floor(
      ((classCount - 1) * (value - minVal)) / (maxVal - minVal)
    );
    return Math.min(idx, classCount - 1);
  }

  function formatClassCounts(counts) {
    const parts = [];
    let k;
    for (k = 0; k < counts.length; k++) {
      if (counts[k] > 0) {
        parts.push('クラス ' + k + ' → ' + counts[k] + ' 個');
      }
    }
    return parts.length ? parts.join('、') : '（まだなし）';
  }

  function formatBoundaries(boundary) {
    const parts = [];
    let k;
    for (k = 0; k < boundary.length - 1; k++) {
      if (boundary[k + 1] > boundary[k]) {
        parts.push(
          'クラス ' + k + ': [' + boundary[k] + ', ' + boundary[k + 1] + ')'
        );
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
    const counts = new Array(CLASS_COUNT);
    let k;
    for (k = 0; k < CLASS_COUNT; k++) {
      counts[k] = 0;
    }

    steps.push({
      kind: 'phase',
      phase: 'classify',
      arr: a.slice(),
      minVal: minVal,
      maxVal: maxVal,
    });

    let i;
    for (i = 0; i < n; i++) {
      const cls = classIndex(a[i], minVal, maxVal, CLASS_COUNT);
      steps.push({
        kind: 'class_scan',
        idx: i,
        value: a[i],
        cls: cls,
        arr: a.slice(),
        counts: counts.slice(),
      });
      counts[cls]++;
      steps.push({
        kind: 'class_bump',
        idx: i,
        value: a[i],
        cls: cls,
        arr: a.slice(),
        counts: counts.slice(),
      });
    }

    const boundary = new Array(CLASS_COUNT + 1);
    boundary[0] = 0;
    for (k = 0; k < CLASS_COUNT; k++) {
      boundary[k + 1] = boundary[k] + counts[k];
    }

    steps.push({
      kind: 'boundary_done',
      arr: a.slice(),
      counts: counts.slice(),
      boundary: boundary.slice(),
    });

    const gathered = new Array(n);
    const pos = boundary.slice();
    for (i = 0; i < n; i++) {
      const cls = classIndex(a[i], minVal, maxVal, CLASS_COUNT);
      steps.push({
        kind: 'place_scan',
        idx: i,
        value: a[i],
        cls: cls,
        arr: a.slice(),
        gathered: gathered.map(function (v) {
          return v;
        }),
        pos: pos.slice(),
      });
      gathered[pos[cls]] = a[i];
      pos[cls]++;
      steps.push({
        kind: 'place_done',
        idx: i,
        value: a[i],
        cls: cls,
        arr: a.slice(),
        gathered: gathered.map(function (v) {
          return v;
        }),
        pos: pos.slice(),
      });
    }

    steps.push({
      kind: 'gather',
      arr: gathered.slice(),
      boundary: boundary.slice(),
    });

    const working = gathered.slice();

    for (k = 0; k < CLASS_COUNT; k++) {
      const lo = boundary[k];
      const hi = boundary[k + 1] - 1;
      if (hi - lo < 1) {
        continue;
      }

      steps.push({
        kind: 'class_start',
        cls: k,
        lo: lo,
        hi: hi,
        arr: working.slice(),
      });

      let j;
      for (j = lo + 1; j <= hi; j++) {
        while (j > lo && working[j - 1] > working[j]) {
          steps.push({
            kind: 'compare',
            lo: j - 1,
            hi: j,
            arr: working.slice(),
            cls: k,
          });
          const t = working[j - 1];
          working[j - 1] = working[j];
          working[j] = t;
          steps.push({
            kind: 'swap',
            lo: j - 1,
            hi: j,
            arr: working.slice(),
            cls: k,
          });
          j--;
        }
      }

      steps.push({
        kind: 'class_done',
        cls: k,
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
    dataAttr: 'data-flash',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'フラッシュソートのデモ（仕分けは水色、クラス内整列はオレンジ／緑の枠）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        if (s.phase === 'classify') {
          api.setCaption(
            'フェーズ1: 値域 [' +
              s.minVal +
              ', ' +
              s.maxVal +
              '] を ' +
              CLASS_COUNT +
              ' 個のクラスに仕分けます'
          );
        }
        return;
      }
      if (s.kind === 'class_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          '仕分け: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' のクラス番号を求めます'
        );
        return;
      }
      if (s.kind === 'class_bump') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' はクラス ' +
            s.cls +
            ' へ（' +
            formatClassCounts(s.counts) +
            '）'
        );
        return;
      }
      if (s.kind === 'boundary_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'クラス境界: ' + formatBoundaries(s.boundary)
        );
        return;
      }
      if (s.kind === 'place_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          '配置: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' をクラス ' +
            s.cls +
            ' の区間へ'
        );
        return;
      }
      if (s.kind === 'place_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'クラス ' +
            s.cls +
            ' へ配置（次の空き位置 ' +
            s.pos[s.cls] +
            '）'
        );
        return;
      }
      if (s.kind === 'gather') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('クラス境界どおりに要素を集めました');
        return;
      }
      if (s.kind === 'class_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'range'], [s.hi, 'range']]);
        api.setCaption(
          'フェーズ2: クラス ' +
            s.cls +
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
      if (s.kind === 'class_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'クラス ' +
            s.cls +
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
  id="flash-sort-demo"
  data_prefix="flash"
  script=sort_demo_js
%}

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000003 |        0.000043 |            1874 |            1880 |
|        512 |        0.000006 |        0.000066 |            1882 |            1888 |
|       1024 |        0.000011 |        0.000203 |            1894 |            1900 |
|       2048 |        0.000020 |        0.000064 |            1918 |            1924 |
|       4096 |        0.000040 |        0.000086 |            1970 |            1976 |
|       8192 |        0.000089 |        0.000167 |            2066 |            2072 |
|      16384 |        0.000186 |        0.000450 |            2141 |            2148 |
|      32768 |        0.000397 |        0.000685 |            2496 |            2532 |
|      65536 |        0.000882 |        0.002015 |            3263 |            3300 |
|     131072 |        0.002012 |        0.003658 |            4800 |            4836 |
|     262144 |        0.004773 |        0.013502 |            7872 |            7908 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="flash" %}
