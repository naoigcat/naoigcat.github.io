---
title:     パワーソートで配列を並び替える
date:      2026-05-24 20:08:19 +0900
tags:      sort
sort_demo: true
---

## パワーソートを使用する

パワーソート (`Powersort`) は、James Ian Munro と Sebastian Wild が 2018 年に提案した **安定** な比較ソートである。

ティムソートと同じく **すでに整列している連続区間（ラン）** を見つけ、マージソートの枠組みで併合する **適応型（adaptive）** アルゴリズムだが、**どのラン同士をいつマージするか** の方針だけを差し替えた改良版と捉えられる。

Python 3.11 以降の `list.sort()` では、ラン検出や短いランの拡張などティムソート由来の仕組みを保ったまま、マージ方針がパワーソートに置き換わっている。

1.  **ランの検出**: 左から昇順または厳密な降順の連続区間を見つける。降順ランは反転して昇順にそろえる。
2.  **ランの拡張**: 長さが **最小ラン長 `min_run`** 未満なら挿入ソートで伸ばす（デモでは見やすさのため 4 に固定）。
3.  **パワーの計算**: 隣接する 2 ランの「中点位置」から、理想のマージ木上での **ノードの深さ** に相当する整数 **パワー** を求める。
4.  **スタックに従ったマージ**: 未マージのランをスタックに積み、新しいパワーがスタック先端より小さくなるまで **左側のラン** と **現在のラン** を併合する。
5.  **仕上げ**: 入力末尾まで進んだあと、スタックに残ったランをすべてマージして全体を整列する。

ティムソートはスタック上端 **3 本** の長さ関係を見る **経験則** でマージ順を決めていた。

パワーソートは **2 ランの中点** だけからパワーを 1 つ計算し、**ほぼ最適な二分マージ木** に沿う順序で併合する。ラン検出や短いランの拡張はティムソートと同じ思想だが、マージ順の決め方だけが **パワー** という 1 つの整数に集約される点が特徴である。

理論上、既存ラン長 `(L₁, …, Lᵣ)` に対する適応性は、加法項 O(n) を除き **最適** に近い。

```pseudocode
procedure node_power(n, b1, e1, b2, e2)
  n1 := e1 - b1
  n2 := e2 - b2
  a := (b1 + n1/2) / n
  b := (b2 + n2/2) / n
  p := 0
  while floor(a · 2^p) = floor(b · 2^p) do
    p := p + 1
  return p

procedure powersort(A)
  S := empty stack of (run, power)
  b1 := 0; e1 := first_run_end(A, 0)
  while e1 < length(A)
    b2 := e1; e2 := first_run_end(A, b2)
    P := node_power(length(A), b1, e1, b2, e2)
    while S is not empty and S.top().power > P
      (b1, e1) := merge(S.pop().run, A[b1..e1))
    S.push((A[b1..e1), P))
    b1 := b2; e1 := e2
  while S is not empty
    (b1, e1) := merge(S.pop().run, A[b1..e1])
```

**最悪時間計算量** は O(n log n)。**安定ソート** であり、等しいキーの相対順序を保つ。

補助領域はマージ用に O(n) が必要になることが多い。

ティムソートと比べ、特定のラン長パターンで起きうる **非効率なマージ**（理論上最大で約 50% のオーバーヘッド）を避けやすく、スタック高さも **O(log n)** で抑えられる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('power-sort-demo', function (root) {
  const MIN_RUN = 4;

  function nodePower(n, b1, e1, b2, e2) {
    const n1 = e1 - b1;
    const n2 = e2 - b2;
    const a = (b1 + n1 / 2) / n;
    const b = (b2 + n2 / 2) / n;
    let p = 0;
    while (Math.floor(a * Math.pow(2, p)) === Math.floor(b * Math.pow(2, p))) {
      p++;
    }
    return p;
  }

  function buildDisplay(a, lo, tmp) {
    const d = a.slice();
    for (let t = 0; t < tmp.length; t++) {
      d[lo + t] = tmp[t];
    }
    return d;
  }

  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k <= hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    const stack = [];

    function countRun(i) {
      if (i >= n - 1) return 1;
      if (a[i] <= a[i + 1]) {
        let j = i + 1;
        while (j < n - 1 && a[j] <= a[j + 1]) j++;
        return j - i + 1;
      }
      let j = i + 1;
      while (j < n - 1 && a[j] > a[j + 1]) j++;
      return j - i + 1;
    }

    function reverseRun(lo, hi) {
      steps.push({ kind: 'run_desc', lo: lo, hi: hi, arr: a.slice() });
      while (lo < hi) {
        steps.push({ kind: 'reverse_compare', lo: lo, hi: hi, arr: a.slice() });
        const t = a[lo];
        a[lo] = a[hi];
        a[hi] = t;
        steps.push({ kind: 'reverse_swap', lo: lo, hi: hi, arr: a.slice() });
        lo++;
        hi--;
      }
    }

    function insertionExtend(lo, hi) {
      for (let i = lo + 1; i <= hi; i++) {
        steps.push({
          kind: 'extend_start',
          lo: lo,
          hi: hi,
          keyIdx: i,
          arr: a.slice(),
        });
        let j = i;
        while (j > lo) {
          steps.push({
            kind: 'extend_compare',
            lo: j - 1,
            hi: j,
            keyIdx: j,
            arr: a.slice(),
          });
          if (a[j - 1] > a[j]) {
            const t = a[j];
            a[j] = a[j - 1];
            a[j - 1] = t;
            steps.push({
              kind: 'extend_swap',
              lo: j - 1,
              hi: j,
              keyIdx: j - 1,
              arr: a.slice(),
            });
            j--;
          } else {
            break;
          }
        }
      }
    }

    function merge(lo1, hi1, lo2, hi2) {
      const lo = lo1;
      const hi = hi2;
      const mid = hi1;
      steps.push({ kind: 'merge_start', lo: lo, mid: mid, hi: hi, arr: a.slice() });
      const tmp = [];
      let i = lo1;
      let j = lo2;
      while (i <= mid && j <= hi) {
        steps.push({
          kind: 'merge_compare',
          lo: lo,
          mid: mid,
          hi: hi,
          i: i,
          j: j,
          arr: buildDisplay(a, lo, tmp),
        });
        if (a[i] <= a[j]) {
          tmp.push(a[i]);
          i++;
        } else {
          tmp.push(a[j]);
          j++;
        }
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      while (i <= mid) {
        tmp.push(a[i]);
        i++;
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      while (j <= hi) {
        tmp.push(a[j]);
        j++;
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      for (let t = 0; t < tmp.length; t++) {
        a[lo + t] = tmp[t];
      }
      steps.push({ kind: 'merge_done', lo: lo, hi: hi, arr: a.slice() });
      return { lo: lo, hi: hi };
    }

    function prepareRun(start) {
      let runLen = countRun(start);
      const runEnd = start + runLen - 1;
      const descending = runLen > 1 && a[start] > a[start + 1];

      if (descending) {
        reverseRun(start, runEnd);
      } else if (runLen > 1) {
        steps.push({ kind: 'run_asc', lo: start, hi: runEnd, arr: a.slice() });
      } else {
        steps.push({ kind: 'run_single', lo: start, hi: runEnd, arr: a.slice() });
      }

      const targetEnd = Math.min(start + MIN_RUN - 1, n - 1);
      if (runEnd < targetEnd) {
        steps.push({
          kind: 'extend_range',
          lo: start,
          hi: targetEnd,
          runEnd: runEnd,
          arr: a.slice(),
        });
        insertionExtend(start, targetEnd);
      }

      return Math.min(start + MIN_RUN, n);
    }

    let b1 = 0;
    let e1 = prepareRun(0);

    while (e1 < n) {
      const b2 = e1;
      const e2 = prepareRun(b2);
      const p = nodePower(n, b1, e1, b2, e2);
      steps.push({
        kind: 'power_calc',
        b1: b1,
        e1: e1,
        b2: b2,
        e2: e2,
        power: p,
        arr: a.slice(),
      });

      while (stack.length > 0 && stack[stack.length - 1].power > p) {
        const top = stack.pop();
        steps.push({
          kind: 'power_merge',
          topPower: top.power,
          newPower: p,
          arr: a.slice(),
        });
        const merged = merge(top.lo, top.hi, b1, e1 - 1);
        b1 = merged.lo;
        e1 = merged.hi + 1;
      }

      stack.push({ lo: b1, hi: e1 - 1, power: p });
      steps.push({
        kind: 'run_ready',
        lo: b1,
        hi: e1 - 1,
        power: p,
        arr: a.slice(),
      });
      b1 = b2;
      e1 = e2;
    }

    while (stack.length > 0) {
      const top = stack.pop();
      steps.push({ kind: 'power_flush', topPower: top.power, arr: a.slice() });
      const merged = merge(top.lo, top.hi, b1, e1 - 1);
      b1 = merged.lo;
      e1 = merged.hi + 1;
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-power',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'パワーソートのデモ（ラン・マージ対象は青、比較はオレンジ、交換・確定は緑、挿入キーは紫、パワー判定は黄）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'run_asc') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '昇順ラン: 位置 ' + s.lo + ' … ' + s.hi + ' はすでに整列しています'
        );
        return;
      }
      if (s.kind === 'run_single') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'range']]);
        api.setCaption('長さ 1 のラン: 位置 ' + s.lo);
        return;
      }
      if (s.kind === 'run_desc') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '降順ラン: 位置 ' + s.lo + ' … ' + s.hi + ' を反転して昇順にします'
        );
        return;
      }
      if (s.kind === 'reverse_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('反転のため比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'reverse_swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('反転のため交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '反転のため交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'extend_range') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          'ランを minRun=' +
            MIN_RUN +
            ' まで拡張: 位置 ' +
            s.lo +
            ' … ' +
            s.hi
        );
        return;
      }
      if (s.kind === 'extend_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.keyIdx, 'key']]);
        api.setCaption(
          '挿入でラン拡張: 位置 ' + s.keyIdx + ' の値を左の整列済み部分へ'
        );
        return;
      }
      if (s.kind === 'extend_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'extend_swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption('交換しました（挿入位置を探しています）');
        return;
      }
      if (s.kind === 'power_calc') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          ...rangePairs(s.b1, s.e1 - 1, 'range'),
          ...rangePairs(s.b2, s.e2 - 1, 'pivot'),
        ]);
        api.setCaption(
          'パワー計算: 左 [' +
            s.b1 +
            '…' +
            (s.e1 - 1) +
            '] と 右 [' +
            s.b2 +
            '…' +
            (s.e2 - 1) +
            '] → power=' +
            s.power
        );
        return;
      }
      if (s.kind === 'power_merge') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[0, 'pivot']]);
        api.setCaption(
          'スタック先端 power=' +
            s.topPower +
            ' > 新パワー ' +
            s.newPower +
            ' のためマージします'
        );
        return;
      }
      if (s.kind === 'power_flush') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[0, 'pivot']]);
        api.setCaption(
          '残りスタック power=' + s.topPower + ' を現在のランとマージします'
        );
        return;
      }
      if (s.kind === 'run_ready') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'sorted'));
        api.setCaption(
          'ラン確定: 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（power=' +
            s.power +
            '）をスタックへ積みます'
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          'マージ: 左 [' +
            s.lo +
            '…' +
            s.mid +
            '] と 右 [' +
            (s.mid + 1) +
            '…' +
            s.hi +
            ']'
        );
        return;
      }
      if (s.kind === 'merge_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'compare'], [s.j, 'compare']]);
        api.setCaption('マージ比較: 位置 ' + s.i + ' と ' + s.j);
        return;
      }
      if (s.kind === 'merge_write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.writePos, 'write']]);
        api.setCaption('マージで確定: 位置 ' + s.writePos);
        return;
      }
      if (s.kind === 'merge_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '区間 ' + s.lo + ' … ' + s.hi + ' のマージが完了しました'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 240,
  });
});
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="power-sort-demo"
  data_prefix="power"
  script=sort_demo_js
%}

実装の複雑さはティムソートの 3 本ルールより読み取りやすく、理論的な保証も強い一方、パワー計算やマージ用バッファなどオーバーヘッドは残る。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000007 |        0.000120 |            1666 |            1672 |
|        512 |        0.000015 |        0.000418 |            1673 |            1680 |
|       1024 |        0.000033 |        0.000428 |            1685 |            1692 |
|       2048 |        0.000083 |        0.000455 |            1710 |            1716 |
|       4096 |        0.000168 |        0.000728 |            1758 |            1764 |
|       8192 |        0.000347 |        0.000672 |            1854 |            1860 |
|      16384 |        0.000741 |        0.000989 |            2050 |            2056 |
|      32768 |        0.001629 |        0.005818 |            2437 |            2444 |
|      65536 |        0.003547 |        0.009432 |            3200 |            3328 |
|     131072 |        0.007585 |        0.015037 |            5107 |            5112 |
|     262144 |        0.016980 |        0.120476 |            8691 |            8696 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="power" %}
