---
title:     スプレッドソートで配列を並び替える
date:      2026-07-10 08:18:10 +0900
tags:      sort
sort_demo: true
---

## スプレッドソートを使用する

スプレッドソート (`spreadsort`) はハイブリッド型の分布ソートである。キーの最小値・最大値から値域を `n/c` 個程度のビン（区分）に等分して仕分け、各ビン内では要素数に応じて再帰的にスプレッドソートを続けるか、比較ベースの整列（典型例は挿入ソートやクイックソート）へ切り替える。

[フラッシュソート](/2026/07/09/sort-flash.html) や [プロックスマップソート](/2026/06/30/sort-proxmap.html) と同系統だが、ビン数の決め方と再帰／フォールバックの判定が最悪ケース性能を意識して設計されている点が特徴的である。Boost.Sort ライブラリにも実装があり、整数・浮動小数・文字列向けに最適化された派生が含まれる。

1.  **値域の把握**: 部分配列の最小値 `min`・最大値 `max` を求め、値域幅 `log₂(max - min)` を記録する。
2.  **ビン数の決定**: 平均ビンサイズ `c`（典型値は 4 前後）からビン数 `m ≈ n/c` を設定し、値域を `m` 等分する。
3.  **仕分け**: 各要素 `x` について `k = ⌊m · (x - min) / (max - min)⌋` でビン番号を求め、補助配列へ集める。
4.  **ビン内整列**: 各ビンについて要素数が閾値 `get_max_count` 未満なら比較ソート（ここでは挿入ソート）、以上なら再帰的に手順 1〜4 を適用する。

```pseudocode
procedure spreadsort(A)
  n = length(A)
  if n < get_max_count(logRange, n) then
    insertion_sort(A)
    return
  minVal = minimum(A)
  maxVal = maximum(A)
  if minVal = maxVal then return
  m = max(MIN_BINS, floor(n / MEAN_BIN_SIZE))
  if m ≥ (maxVal - minVal + 1) then
    insertion_sort(A)
    return
  scatter A into m bins by value mapping
  for each bin b with count ≥ 2
    if count(b) < get_max_count(logRange, n) then
      insertion_sort(bin b)
    else
      spreadsort(bin b)
```

分布が一様で各ビンのサイズが定数に抑えられるとき、仕分けは `O(n)`、再帰の深さは `O(log n)` 程度となり、全体は線形に近い性能が期待できる。
最悪はすべての要素が同一ビンに入り、比較ソート 1 回分の `O(n log n)`（または偏り次第で `O(n²)`）に近づく。追加メモリはビン数に比例するカウント・一時配列の `O(m)` が典型である。

基数ソートが固定桁数で区分するのに対し、スプレッドソートは**現在の部分配列の値域**に応じてビン幅を動的に決める。フラッシュソートがクラス内を挿入ソートで仕上げるのに対し、スプレッドソートは `get_max_count` により再帰継続と比較ソートの切り替えを行い、偏った分布でも最悪性能を抑える設計となっている。

以下のデモでは視認性のためビン数を 5 に固定し、仕分け後の各ビン内整列を挿入ソートで示す（本番実装では要素数に応じて再帰または比較ソートへ切り替える）。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('spread-sort-demo', function (root) {
  const BIN_COUNT = 5;
  const INSERTION_THRESHOLD = 4;

  function binIndex(value, minVal, maxVal, binCount) {
    if (maxVal === minVal) {
      return 0;
    }
    const idx = Math.floor(
      (binCount * (value - minVal)) / (maxVal - minVal)
    );
    return Math.min(idx, binCount - 1);
  }

  function formatBinCounts(counts) {
    const parts = [];
    let k;
    for (k = 0; k < counts.length; k++) {
      if (counts[k] > 0) {
        parts.push('ビン ' + k + ' → ' + counts[k] + ' 個');
      }
    }
    return parts.length ? parts.join('、') : '（まだなし）';
  }

  function formatOffsets(offset) {
    const parts = [];
    let k;
    for (k = 0; k < offset.length - 1; k++) {
      if (offset[k + 1] > offset[k]) {
        parts.push(
          'ビン ' + k + ': [' + offset[k] + ', ' + offset[k + 1] + ')'
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
    const counts = new Array(BIN_COUNT);
    let k;
    for (k = 0; k < BIN_COUNT; k++) {
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
      const bin = binIndex(a[i], minVal, maxVal, BIN_COUNT);
      steps.push({
        kind: 'bin_scan',
        idx: i,
        value: a[i],
        bin: bin,
        arr: a.slice(),
        counts: counts.slice(),
      });
      counts[bin]++;
      steps.push({
        kind: 'bin_bump',
        idx: i,
        value: a[i],
        bin: bin,
        arr: a.slice(),
        counts: counts.slice(),
      });
    }

    const offset = new Array(BIN_COUNT + 1);
    offset[0] = 0;
    for (k = 0; k < BIN_COUNT; k++) {
      offset[k + 1] = offset[k] + counts[k];
    }

    steps.push({
      kind: 'offset_done',
      arr: a.slice(),
      counts: counts.slice(),
      offset: offset.slice(),
    });

    const gathered = new Array(n);
    const pos = offset.slice();
    for (i = 0; i < n; i++) {
      const bin = binIndex(a[i], minVal, maxVal, BIN_COUNT);
      steps.push({
        kind: 'scatter_scan',
        idx: i,
        value: a[i],
        bin: bin,
        arr: a.slice(),
        gathered: gathered.map(function (v) {
          return v;
        }),
        pos: pos.slice(),
      });
      gathered[pos[bin]] = a[i];
      pos[bin]++;
      steps.push({
        kind: 'scatter_done',
        idx: i,
        value: a[i],
        bin: bin,
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
      offset: offset.slice(),
    });

    const working = gathered.slice();

    for (k = 0; k < BIN_COUNT; k++) {
      const lo = offset[k];
      const hi = offset[k + 1] - 1;
      if (hi - lo < 1) {
        continue;
      }

      const binLen = hi - lo + 1;
      const useInsertion = binLen <= INSERTION_THRESHOLD;

      steps.push({
        kind: 'bin_start',
        bin: k,
        lo: lo,
        hi: hi,
        useInsertion: useInsertion,
        arr: working.slice(),
      });

      if (useInsertion) {
        let j;
        for (j = lo + 1; j <= hi; j++) {
          while (j > lo && working[j - 1] > working[j]) {
            steps.push({
              kind: 'compare',
              lo: j - 1,
              hi: j,
              arr: working.slice(),
              bin: k,
            });
            const t = working[j - 1];
            working[j - 1] = working[j];
            working[j] = t;
            steps.push({
              kind: 'swap',
              lo: j - 1,
              hi: j,
              arr: working.slice(),
              bin: k,
            });
            j--;
          }
        }
      } else {
        steps.push({
          kind: 'recurse_note',
          bin: k,
          lo: lo,
          hi: hi,
          arr: working.slice(),
        });
      }

      steps.push({
        kind: 'bin_done',
        bin: k,
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
    dataAttr: 'data-spread',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'スプレッドソートのデモ（仕分けは水色、ビン内整列はオレンジ／緑の枠）',
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
              BIN_COUNT +
              ' 個のビンに仕分けます'
          );
        }
        return;
      }
      if (s.kind === 'bin_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          '仕分け: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' のビン番号を求めます'
        );
        return;
      }
      if (s.kind === 'bin_bump') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' はビン ' +
            s.bin +
            ' へ（' +
            formatBinCounts(s.counts) +
            '）'
        );
        return;
      }
      if (s.kind === 'offset_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ビン境界: ' + formatOffsets(s.offset));
        return;
      }
      if (s.kind === 'scatter_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          '配置: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' をビン ' +
            s.bin +
            ' の区間へ'
        );
        return;
      }
      if (s.kind === 'scatter_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ビン ' +
            s.bin +
            ' へ配置（次の空き位置 ' +
            s.pos[s.bin] +
            '）'
        );
        return;
      }
      if (s.kind === 'gather') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ビン境界どおりに要素を集めました');
        return;
      }
      if (s.kind === 'bin_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'range'], [s.hi, 'range']]);
        if (s.useInsertion) {
          api.setCaption(
            'フェーズ2: ビン ' +
              s.bin +
              ' を挿入ソート（位置 ' +
              s.lo +
              ' … ' +
              s.hi +
              '）'
          );
        } else {
          api.setCaption(
            'フェーズ2: ビン ' +
              s.bin +
              ' は要素数が閾値超過のため再帰的にスプレッドソートします'
          );
        }
        return;
      }
      if (s.kind === 'recurse_note') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'range'], [s.hi, 'range']]);
        api.setCaption(
          'ビン ' +
            s.bin +
            ' へ再帰適用（本デモでは省略し次のビンへ）'
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
      if (s.kind === 'bin_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ビン ' +
            s.bin +
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
  id="spread-sort-demo"
  data_prefix="spread"
  script=sort_demo_js
%}

## フラッシュソートとの違い

[フラッシュソート](/2026/07/09/sort-flash.html) も値域をクラスに分割して仕分けるが、スプレッドソートはビン内のサイズに応じて再帰継続か比較ソートかを動的に選ぶ。

| 観点 | スプレッドソート | フラッシュソート |
| --- | --- | --- |
| 区分数 | `n/c`（平均ビンサイズ `c` 付近） | `⌈√(2n log₂ n)⌉` 程度 |
| ビン内整列 | 閾値で再帰／比較ソートを切替 | 挿入ソートが典型 |
| 最悪性能 | `O(n log n)` 比較へフォールバック可能 | 同一クラス集中で `O(n²)` |
| 実装例 | Boost.Sort `spreadsort` | 各種教科書実装 |

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000003 |        0.000026 |            1682 |            1688 |
|        512 |        0.000006 |        0.000048 |            1690 |            1696 |
|       1024 |        0.000011 |        0.000067 |            1706 |            1712 |
|       2048 |        0.000021 |        0.000064 |            1734 |            1740 |
|       4096 |        0.000043 |        0.000110 |            1793 |            1800 |
|       8192 |        0.000091 |        0.000232 |            1914 |            1920 |
|      16384 |        0.000181 |        0.000405 |            2029 |            2036 |
|      32768 |        0.000345 |        0.000818 |            2499 |            2532 |
|      65536 |        0.000696 |        0.001460 |            3452 |            3556 |
|     131072 |        0.001460 |        0.005788 |            5442 |            5476 |
|     262144 |        0.002981 |        0.007061 |            9282 |            9316 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="spread" %}
