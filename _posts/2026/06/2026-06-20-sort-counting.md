---
title:     カウンティングソートで配列を並び替える
date:      2026-06-20 12:13:23 +0900
tags:      sort
sort_demo: true
---

## カウンティングソートを使用する

カウンティングソート (`counting sort`) は、各値が何回現れるかを数え、その出現回数からソート後の並びを復元する（要素同士を直接比較しない）。

キーの取りうる値の範囲 `k` が入力長 `n` と同程度かそれより小さいとき、比較ソートの `Ω(n log n)` より有利になりうる。

1.  **出現回数の集計**: 入力配列を走査し、値 `v` ごとの出現回数 `count[v]` を増やす。
2.  **累積和（安定版）**: 安定ソートにする場合は `count` を累積和に変換し、各値の書き込み開始位置を決める。
3.  **出力への配置**: `count` に従い、出力配列（または元配列の上書き）へ値を順に書き込む。安定版では入力を後ろから走査して同値の相対順序を保つ。

```pseudocode
procedure counting_sort(A)
  if length(A) = 0 then return
  minVal = minimum(A)
  maxVal = maximum(A)
  range = maxVal - minVal + 1
  count[0..range-1] = 0
  for each x in A
    count[x - minVal] = count[x - minVal] + 1
  idx = 0
  for v from 0 to range - 1
    repeat count[v] times
      A[idx] = minVal + v
      idx = idx + 1
```

値域幅 k が小さいとき `O(n + k)` となり、比較ソートの `Ω(n log n)` 下界を超えられる。安定ソートである。

整数のように値域が狭いデータや、バケットのインデックスに直結できるキーに向く。一方で `k` が極端に大きいと補助配列だけでメモリを大量に消費するため、汎用の比較ソートに置き換える判断が必要になる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('counting-sort-demo', function (root) {
  function formatCountLine(count, minVal) {
    const parts = [];
    for (let i = 0; i < count.length; i++) {
      if (count[i] > 0) {
        parts.push('値 ' + (minVal + i) + ' → ' + count[i] + ' 個');
      }
    }
    return parts.length ? parts.join('、') : '（まだなし）';
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    const minVal = Math.min.apply(null, a);
    const maxVal = Math.max.apply(null, a);
    const range = maxVal - minVal + 1;
    const count = new Array(range);
    for (let i = 0; i < range; i++) {
      count[i] = 0;
    }

    steps.push({
      kind: 'phase',
      phase: 'count',
      arr: a.slice(),
      count: count.slice(),
      minVal: minVal,
    });

    let i;
    for (i = 0; i < n; i++) {
      steps.push({
        kind: 'count_scan',
        i: i,
        value: a[i],
        arr: a.slice(),
        count: count.slice(),
        minVal: minVal,
      });
      count[a[i] - minVal]++;
      steps.push({
        kind: 'count_bump',
        i: i,
        value: a[i],
        bucket: a[i] - minVal,
        arr: a.slice(),
        count: count.slice(),
        minVal: minVal,
      });
    }

    steps.push({
      kind: 'count_done',
      arr: a.slice(),
      count: count.slice(),
      minVal: minVal,
    });

    const output = [];
    let v;
    let c;

    steps.push({
      kind: 'phase',
      phase: 'place',
      arr: a.slice(),
      count: count.slice(),
      minVal: minVal,
    });

    for (v = 0; v < range; v++) {
      for (c = 0; c < count[v]; c++) {
        output.push(minVal + v);
        steps.push({
          kind: 'place',
          value: minVal + v,
          output: output.slice(),
          minVal: minVal,
        });
      }
    }

    steps.push({ kind: 'done', arr: output.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-counting',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'カウンティングソートのデモ（走査は水色、配置は確定の書き込み）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        if (s.phase === 'count') {
          api.setCaption('フェーズ1: 各値の出現回数を数えます');
        } else {
          api.setCaption('フェーズ2: 出現回数から昇順に並べ直します');
        }
        return;
      }
      if (s.kind === 'count_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'cursor']]);
        api.setCaption(
          '走査: 位置 ' +
            s.i +
            ' の値 ' +
            s.value +
            ' をカウントします'
        );
        return;
      }
      if (s.kind === 'count_bump') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'cursor']]);
        api.setCaption(
          '値 ' +
            s.value +
            ' の出現回数を更新しました（' +
            formatCountLine(s.count, s.minVal) +
            '）'
        );
        return;
      }
      if (s.kind === 'count_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '集計完了: ' + formatCountLine(s.count, s.minVal)
        );
        return;
      }
      if (s.kind === 'place') {
        api.mountBars(barsEl, s.output);
        const last = s.output.length - 1;
        DemoSort.assignRoles(barsEl, [[last, 'write']]);
        api.setCaption(
          '配置: 値 ' + s.value + ' を位置 ' + last + ' に書き込み'
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
  id="counting-sort-demo"
  data_prefix="counting"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[基数ソート](/2026/06/21/sort-radix.html)・[バケットソート](/2026/06/23/sort-bucket.html)と同様に値域に依存する。[自己インデックスソート](/2026/07/07/sort-self-indexed.html)と実装が一致することが多いが、キーをソート空間のアドレスとみなす枠組みが異なる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000001 |        0.000072 |            1665 |            1672 |
|        512 |        0.000002 |        0.000138 |            1669 |            1676 |
|       1024 |        0.000003 |        0.000068 |            1681 |            1688 |
|       2048 |        0.000007 |        0.000386 |            1705 |            1712 |
|       4096 |        0.000015 |        0.000413 |            1754 |            1760 |
|       8192 |        0.000044 |        0.001774 |            1849 |            1856 |
|      16384 |        0.000085 |        0.002388 |            1918 |            1924 |
|      32768 |        0.000173 |        0.000962 |            2180 |            2184 |
|      65536 |        0.000434 |        0.022050 |            2944 |            2944 |
|     131072 |        0.000665 |        0.002231 |            4480 |            4480 |
|     262144 |        0.001343 |        0.003989 |            7555 |            7664 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="counting" %}
