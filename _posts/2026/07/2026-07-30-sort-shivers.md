---
title:     シバーズソートで配列を並び替える
date:      2026-07-30 00:20:44 +0900
tags:      sort
sort_demo: true
---

## シバーズソートを使用する

シバーズソート (`shivers sort`) は、入力にすでに存在する単調な連続区間（ラン）を検出し、ラン長の「レベル」に基づいてスタック最上段 2 本をいつ併合するかを決める自然マージソートである。

ティムソートより単純な、スタック上端 2 本だけを見て決めるマージ方針でありながら、入力長 `n` だけを見たときの最悪マージコストが `n log₂(n) + O(n)` に収まることが後に示された。

1.  **ランの検出**: 左から昇順または厳密な降順の連続区間を見つける。降順ランは反転して昇順にそろえる。
2.  **ランの拡張**: 長さが最小ラン長 `min_run` 未満なら挿入ソートで伸ばす（デモでは見やすさのため 4 に固定。計測実装では 32）。
3.  **レベルの計算**: ラン長 `r` に対し `ℓ = ⌊log₂(r)⌋`（パラメータ `c = 1`）をレベルとする。
4.  **スタックに従ったマージ**: ランを左から 1 本ずつ積み、スタック高さが 2 以上かつ `ℓ_h ≥ ℓ_{h-1}` なら最上段 2 本（`R_{h-1}` と `R_h`）を併合する。
5.  **仕上げ**: 入力のランをすべて積み終わったあと、スタックに 2 本以上残っていれば上から順に 2 本ずつ併合する。

条件 `ℓ_h ≥ ℓ_{h-1}` は `2^{⌊log₂|Y|⌋} ≤ |Z|`（`Y = R_{h-1}`、`Z = R_h`）と同値である。長さそのものではなく 2 の冪へ丸めたレベルで比較するため、スタック上のレベル列をほぼ狭義減少に保ちやすい。

一方で、新しく積んだランがスタック上の既存ランよりはるかに長くても即座に併合しうる。そのためラン数 `ρ` やラン長分布への適応性は弱く、最悪マージコストは `ω(n log₂(ρ))` になりうる（`n` に対しては最適に近い）。

```pseudocode
procedure level(r)  // c = 1
  return floor(log2(r))

procedure shivers_sort(A)
  runs := run_decomposition(A)  // 反転・min_run 拡張済み
  S := empty stack
  while true
    h := height(S)
    if h >= 2 and level(len(R_h)) >= level(len(R_{h-1}))
      merge R_{h-1} and R_h on S
    else if runs is not empty
      push next run from runs onto S
    else
      break
  while height(S) >= 2
    merge R_{h-1} and R_h on S
```

安定ソートであり、最悪でもマージソートと同程度の `O(n log n)` を保つ。ただし整列済みに近い入力でも、適応型シバーズソートやパワーソートほどラン長エントロピーに追従する保証はない。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('shivers-sort-demo', function (root) {
  const MIN_RUN = 4;

  function runLevel(len) {
    return Math.floor(Math.log2(len));
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
    const pending = [];
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

      const end = Math.max(Math.min(start + MIN_RUN, n), runEnd + 1);
      const level = runLevel(end - start);
      pending.push({ lo: start, hi: end - 1, level: level });
      steps.push({
        kind: 'run_ready',
        lo: start,
        hi: end - 1,
        level: level,
        arr: a.slice(),
      });
      return end;
    }

    let pos = 0;
    while (pos < n) {
      pos = prepareRun(pos);
    }

    let next = 0;
    while (true) {
      const h = stack.length;
      if (h >= 2) {
        const mid = stack[h - 2];
        const top = stack[h - 1];
        const ellMid = runLevel(mid.hi - mid.lo + 1);
        const ellTop = runLevel(top.hi - top.lo + 1);
        steps.push({
          kind: 'level_check',
          midLo: mid.lo,
          midHi: mid.hi,
          topLo: top.lo,
          topHi: top.hi,
          ellMid: ellMid,
          ellTop: ellTop,
          shouldMerge: ellTop >= ellMid,
          arr: a.slice(),
        });
        if (ellTop >= ellMid) {
          stack.pop();
          stack.pop();
          steps.push({
            kind: 'level_merge',
            midLo: mid.lo,
            midHi: mid.hi,
            topLo: top.lo,
            topHi: top.hi,
            ellMid: ellMid,
            ellTop: ellTop,
            arr: a.slice(),
          });
          stack.push(merge(mid.lo, mid.hi, top.lo, top.hi));
          continue;
        }
      }
      if (next < pending.length) {
        const run = pending[next++];
        stack.push(run);
        steps.push({
          kind: 'stack_push',
          lo: run.lo,
          hi: run.hi,
          level: run.level,
          arr: a.slice(),
        });
        continue;
      }
      break;
    }

    while (stack.length >= 2) {
      const right = stack.pop();
      const left = stack.pop();
      steps.push({
        kind: 'flush_merge',
        leftLo: left.lo,
        leftHi: left.hi,
        rightLo: right.lo,
        rightHi: right.hi,
        arr: a.slice(),
      });
      stack.push(merge(left.lo, left.hi, right.lo, right.hi));
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-shivers',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'シバーズソートのデモ（ラン・マージ対象は青、比較はオレンジ、交換・確定は緑、挿入キーは紫、レベル判定は黄）',
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
      if (s.kind === 'run_ready') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'sorted'));
        api.setCaption(
          'ラン確定: 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（level=' +
            s.level +
            '）'
        );
        return;
      }
      if (s.kind === 'stack_push') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          'スタックへ積む: 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（level=' +
            s.level +
            '）'
        );
        return;
      }
      if (s.kind === 'level_check') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          ...rangePairs(s.midLo, s.midHi, 'range'),
          ...rangePairs(s.topLo, s.topHi, 'pivot'),
        ]);
        api.setCaption(
          'レベル比較: ℓ_{h-1}=' +
            s.ellMid +
            ', ℓ_h=' +
            s.ellTop +
            (s.shouldMerge
              ? ' → ℓ_h ≥ ℓ_{h-1} のため最上段 2 本をマージ'
              : ' → 条件を満たさないので次のランへ')
        );
        return;
      }
      if (s.kind === 'level_merge') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          ...rangePairs(s.midLo, s.midHi, 'range'),
          ...rangePairs(s.topLo, s.topHi, 'key'),
        ]);
        api.setCaption(
          'R_{h-1} と R_h をマージ（ℓ=' +
            s.ellMid +
            ',' +
            s.ellTop +
            '）'
        );
        return;
      }
      if (s.kind === 'flush_merge') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          ...rangePairs(s.leftLo, s.leftHi, 'range'),
          ...rangePairs(s.rightLo, s.rightHi, 'key'),
        ]);
        api.setCaption('残りスタックの上 2 本をマージします');
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

{% include sort-demo.html
  id="shivers-sort-demo"
  data_prefix="shivers"
  script=sort_demo_js
%}

実装の核は「長さをレベルに丸めてから最上段 2 本を比べる」だけであり、ティムソートの 3 本比較やパワーソートの中点ベースのパワー計算より短い。その単純さの代償として、ラン構造への適応性は後続の改良版に譲る。

## 類似アルゴリズムとの相違点

[ティムソート](/2026/05/23/sort-tim.html)はスタック上端のラン長そのものでマージを決める。[パワーソート](/2026/05/24/sort-power.html)は隣接ランの中点からパワーを求め、ほぼ最適な二分マージ木に沿う。

シバーズソートはレベル比較を使う点で適応型シバーズソートと同じだが、マージの判定も併合もスタック上端 2 本（`R_{h-1}` と `R_h`）だけに限る方針である。

[適応型シバーズソート](/2026/07/29/sort-adaptive-shivers.html)はティムソート寄りに `R_{h-2}` と `R_{h-1}` をマージして最上段を残し、マージコストをラン長エントロピーに対して `nH + O(n)` へ近づけた。

[ナチュラルマージソート](/2026/07/28/sort-natural-merge.html)は自然ランを使うが、マージ順は単純なペア併合にとどまる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000005 |        0.000051 |               2 |               2 |
|        512 |        0.000012 |        0.000201 |               4 |               4 |
|       1024 |        0.000026 |        0.000161 |               8 |               8 |
|       2048 |        0.000056 |        0.000329 |              17 |              17 |
|       4096 |        0.000122 |        0.000370 |              34 |              34 |
|       8192 |        0.000272 |        0.000511 |              68 |              68 |
|      16384 |        0.000600 |        0.001070 |             136 |             136 |
|      32768 |        0.001296 |        0.004676 |             272 |             272 |
|      65536 |        0.002811 |        0.007996 |             544 |             544 |
|     131072 |        0.006030 |        0.010749 |            1088 |            1088 |
|     262144 |        0.012796 |        0.019367 |            2176 |            2176 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="shivers" %}
