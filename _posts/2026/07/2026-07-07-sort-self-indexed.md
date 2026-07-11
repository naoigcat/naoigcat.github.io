---
title:     自己インデックスソートで配列を並び替える
date:      2026-07-07 08:03:11 +0900
tags:      sort
sort_demo: true
---

## 自己インデックスソートを使用する

自己インデックスソート (`Self-Indexed Sort`, SIS) は、キー値をソート空間内の相対オフセットとして直接使い、整列結果をそこへ散在配置したあと、元の配列へ順序保持圧縮して戻す。

1.  **ソート空間の初期化**: キーの取りうる値域 `[min, max]` に対応する長さ `m = max - min + 1` の補助配列 `ss` を用意し、空（またはゼロ）にする。
2.  **自己インデックス配置**: 入力を走査し、各キー `x` を `ss[x - min]` へ写す。同一キーが複数ある場合は出現回数を数える（または連鎖で衝突を解決する）。
3.  **順序保持圧縮**: `ss` を `min` から昇順に走査し、非空スロットの値を左から元配列へ詰め直す。入力を左から走査して配置した実装では同値の相対順序を保てる。

```pseudocode
procedure self_indexed_sort(A)
  if length(A) = 0 then return
  minVal = minimum(A)
  maxVal = maximum(A)
  m = maxVal - minVal + 1
  ss[0..m-1] = 0
  for each x in A
    ss[x - minVal] = ss[x - minVal] + 1
  idx = 0
  for v from 0 to m - 1
    repeat ss[v] times
      A[idx] = minVal + v
      idx = idx + 1
```

キーをアドレスとして扱う点は **カウンティングソート** と同型である。原論文は時間 `O(n)`・空間 `O(n + m)` を主張するが、フェーズ 1 と 3 で長さ `m` の配列を初期化・走査するため、厳密には **`O(n + m)` の時間** と見なす解釈も一般的である（`m` が `n` よりはるかに大きい値域だと不利になる）。

整数キーで `m` が入力長と同程度に収まるとき（下の計測も `1..n` の並べ替え）に有利になりうる。比較ソートの `Ω(n log n)` 下限には当てはまらない。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('self-indexed-sort-demo', function (root) {
  function formatSpaceLine(ss, minVal) {
    const parts = [];
    let v;
    for (v = 0; v < ss.length; v++) {
      if (ss[v] > 0) {
        parts.push('ss[' + (minVal + v) + '] = ' + ss[v]);
      }
    }
    return parts.length ? parts.join('、') : '（空）';
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
    const span = maxVal - minVal + 1;
    const ss = new Array(span);
    let i;
    for (i = 0; i < span; i++) {
      ss[i] = 0;
    }

    steps.push({
      kind: 'phase',
      phase: 'init',
      arr: a.slice(),
      ss: ss.slice(),
      minVal: minVal,
      span: span,
    });

    steps.push({
      kind: 'phase',
      phase: 'arrange',
      arr: a.slice(),
      ss: ss.slice(),
      minVal: minVal,
    });

    for (i = 0; i < n; i++) {
      steps.push({
        kind: 'arrange_scan',
        i: i,
        value: a[i],
        arr: a.slice(),
        ss: ss.slice(),
        minVal: minVal,
      });
      ss[a[i] - minVal]++;
      steps.push({
        kind: 'arrange_write',
        i: i,
        value: a[i],
        slot: a[i] - minVal,
        arr: a.slice(),
        ss: ss.slice(),
        minVal: minVal,
      });
    }

    steps.push({
      kind: 'arrange_done',
      arr: a.slice(),
      ss: ss.slice(),
      minVal: minVal,
    });

    const output = [];
    let v;
    let c;

    steps.push({
      kind: 'phase',
      phase: 'compress',
      arr: a.slice(),
      ss: ss.slice(),
      minVal: minVal,
    });

    for (v = 0; v < span; v++) {
      for (c = 0; c < ss[v]; c++) {
        output.push(minVal + v);
        steps.push({
          kind: 'compress_write',
          value: minVal + v,
          slot: v,
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
    dataAttr: 'data-self-indexed',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '自己インデックスソートのデモ（入力走査は水色、ソート空間への写し込み、圧縮は確定の書き込み）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        if (s.phase === 'init') {
          api.setCaption(
            'フェーズ1: ソート空間 ss（長さ ' + s.span + '）を初期化します'
          );
        } else if (s.phase === 'arrange') {
          api.setCaption(
            'フェーズ2: 各キーを ss[キー - min] へ自己インデックス配置します'
          );
        } else {
          api.setCaption(
            'フェーズ3: ss を左から走査し、順序保持圧縮で出力配列へ詰めます'
          );
        }
        return;
      }
      if (s.kind === 'arrange_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'cursor']]);
        api.setCaption(
          '走査: 位置 ' +
            s.i +
            ' のキー ' +
            s.value +
            ' → ss[' +
            s.value +
            '] へ写します'
        );
        return;
      }
      if (s.kind === 'arrange_write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'cursor']]);
        api.setCaption(
          'ss[' +
            (s.minVal + s.slot) +
            '] を更新（' +
            formatSpaceLine(s.ss, s.minVal) +
            '）'
        );
        return;
      }
      if (s.kind === 'arrange_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '配置完了: ' + formatSpaceLine(s.ss, s.minVal)
        );
        return;
      }
      if (s.kind === 'compress_write') {
        api.mountBars(barsEl, s.output);
        const last = s.output.length - 1;
        DemoSort.assignRoles(barsEl, [[last, 'write']]);
        api.setCaption(
          '圧縮: ss[' +
            (s.minVal + s.slot) +
            '] の値 ' +
            s.value +
            ' を位置 ' +
            last +
            ' へ書き込み'
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
  id="self-indexed-sort-demo"
  data_prefix="self-indexed"
  script=sort_demo_js
%}

[カウンティングソート](/2026/06/20/sort-counting.html) と実装が一致する場合が多いが、自己インデックスソートはキー＝ソート空間内アドレスという発想と 3 フェーズの枠組みを明示する。値域 `m` が極端に広い整数キーでは補助配列だけでメモリを消費するため、汎用比較ソートへの切り替えを検討する必要がある。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000001 |        0.000077 |            1682 |            1688 |
|        512 |        0.000002 |        0.000044 |            1685 |            1692 |
|       1024 |        0.000004 |        0.000039 |            1698 |            1704 |
|       2048 |        0.000008 |        0.000054 |            1722 |            1728 |
|       4096 |        0.000016 |        0.000071 |            1770 |            1776 |
|       8192 |        0.000046 |        0.000210 |            1866 |            1872 |
|      16384 |        0.000094 |        0.001117 |            1934 |            1940 |
|      32768 |        0.000180 |        0.000569 |            2243 |            2276 |
|      65536 |        0.000363 |        0.000562 |            3012 |            3044 |
|     131072 |        0.000744 |        0.005917 |            4547 |            4580 |
|     262144 |        0.001589 |        0.007850 |            7622 |            7764 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="self_indexed" %}
