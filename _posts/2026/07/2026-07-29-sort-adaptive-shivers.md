---
title:     適応型シバーズソートで配列を並び替える
date:      2026-07-29 22:11:12 +0900
tags:      sort
sort_demo: true
---

## 適応型シバーズソートを使用する

適応型シバーズソート (`adaptive shivers sort`) は、入力にすでに存在する単調な連続区間（ラン）を検出し、ラン長の「レベル」に基づいてマージ順を決める自然マージソートである。

ティムソートと同じく、スタック上端 3 本のラン長だけを見てマージを決める方針を保ちつつ、シバーズソート由来のレベル比較で最悪時のマージコストを抑えやすくした折衷案と捉えられる。マージコストがラン長エントロピーに対して `nH + O(n)` に収まることが示されている。

1.  **ランの検出**: 左から昇順または厳密な降順の連続区間を見つける。降順ランは反転して昇順にそろえる。
2.  **ランの拡張**: 長さが最小ラン長 `min_run` 未満なら挿入ソートで伸ばす（デモでは見やすさのため 4 に固定。計測実装では 32）。
3.  **レベルの計算**: ラン長 `r` に対し `ℓ = ⌊log₂(r)⌋`（パラメータ `c = 1`）をレベルとする。
4.  **スタックに従ったマージ**: ランを左から 1 本ずつ積み、スタック高さが 3 以上かつ `ℓ_{h-2} ≤ max{ℓ_{h-1}, ℓ_h}` なら上から 2 本目と 3 本目（`R_{h-2}` と `R_{h-1}`）を併合する。最上段 `R_h` はそのまま残す。
5.  **仕上げ**: 入力のランをすべて積み終わったあと、スタックに 2 本以上残っていれば上から順に 2 本ずつ併合する。

ティムソートはラン長そのものの大小関係でマージを決めるのに対し、適応型シバーズソートは長さを 2 の冪の段階（レベル）に丸めてから比較する。その結果、同程度の長さのランを早めにまとめる方針が明示的になり、最悪ケースの定数が改善しやすい。

```pseudocode
procedure level(r)  // c = 1
  return floor(log2(r))

procedure adaptive_shivers_sort(A)
  runs := run_decomposition(A)  // 反転・min_run 拡張済み
  S := empty stack
  while true
    h := height(S)
    if h >= 3 and level(len(R_{h-2})) <= max(level(len(R_{h-1})), level(len(R_h)))
      merge R_{h-2} and R_{h-1} on S
    else if runs is not empty
      push next run from runs onto S
    else
      break
  while height(S) >= 2
    merge R_{h-1} and R_h on S
```

安定ソートであり、整列済みに近い入力では検出した長いランを活かして `O(n)` に近づく。最悪でもマージソートと同程度の `O(n log n)` を保つ。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('adaptive-shivers-sort-demo', function (root) {
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
      if (h >= 3) {
        const left = stack[h - 3];
        const mid = stack[h - 2];
        const top = stack[h - 1];
        const ellLeft = runLevel(left.hi - left.lo + 1);
        const ellMid = runLevel(mid.hi - mid.lo + 1);
        const ellTop = runLevel(top.hi - top.lo + 1);
        steps.push({
          kind: 'level_check',
          leftLo: left.lo,
          leftHi: left.hi,
          midLo: mid.lo,
          midHi: mid.hi,
          topLo: top.lo,
          topHi: top.hi,
          ellLeft: ellLeft,
          ellMid: ellMid,
          ellTop: ellTop,
          shouldMerge: ellLeft <= Math.max(ellMid, ellTop),
          arr: a.slice(),
        });
        if (ellLeft <= Math.max(ellMid, ellTop)) {
          stack.pop();
          stack.pop();
          stack.pop();
          steps.push({
            kind: 'level_merge',
            leftLo: left.lo,
            leftHi: left.hi,
            midLo: mid.lo,
            midHi: mid.hi,
            ellLeft: ellLeft,
            ellMid: ellMid,
            ellTop: ellTop,
            arr: a.slice(),
          });
          const merged = merge(left.lo, left.hi, mid.lo, mid.hi);
          stack.push(merged);
          stack.push(top);
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
    dataAttr: 'data-adaptive-shivers',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '適応型シバーズソートのデモ（ラン・マージ対象は青、比較はオレンジ、交換・確定は緑、挿入キーは紫、レベル判定は黄）',
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
          ...rangePairs(s.leftLo, s.leftHi, 'range'),
          ...rangePairs(s.midLo, s.midHi, 'pivot'),
          ...rangePairs(s.topLo, s.topHi, 'key'),
        ]);
        api.setCaption(
          'レベル比較: ℓ=' +
            s.ellLeft +
            ',' +
            s.ellMid +
            ',' +
            s.ellTop +
            (s.shouldMerge
              ? ' → ℓ_{h-2} ≤ max のためマージ'
              : ' → 条件を満たさないので次のランへ')
        );
        return;
      }
      if (s.kind === 'level_merge') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          ...rangePairs(s.leftLo, s.leftHi, 'range'),
          ...rangePairs(s.midLo, s.midHi, 'key'),
        ]);
        api.setCaption(
          'R_{h-2} と R_{h-1} をマージ（ℓ=' +
            s.ellLeft +
            ',' +
            s.ellMid +
            ' / 最上段 ℓ=' +
            s.ellTop +
            ' は残す）'
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
  id="adaptive-shivers-sort-demo"
  data_prefix="adaptive-shivers"
  script=sort_demo_js
%}

ティムソートからの差し替えはマージ抑制条件をレベル比較に変える程度で済む一方、パワーソートのような中点ベースのパワー計算は不要で、実装と証明の両方が短い点が利点である。

## 類似アルゴリズムとの相違点

[ティムソート](/2026/05/23/sort-tim.html)はスタック上端のラン長そのものでマージを決める。[パワーソート](/2026/05/24/sort-power.html)は隣接ランの中点からパワーを求め、ほぼ最適な二分マージ木に沿う。

適応型シバーズソートはティムソート同様、スタック上端 3 本だけを見てマージを決めるが、長さを `⌊log₂(r)⌋` に丸めてから比較する。

[古典的なシバーズソート](/2026/07/30/sort-shivers.html)は条件成立時に最上段 2 本をマージするのに対し、適応型はティムソート寄りに `R_{h-2}` と `R_{h-1}` をマージして最上段を残す。その差が最悪マージコストの改善につながる。

[ナチュラルマージソート](/2026/07/28/sort-natural-merge.html)は自然ランを使うが、マージ順は単純なペア併合にとどまる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000009 |        0.000060 |              66 |              72 |
|        512 |        0.000020 |        0.000119 |              70 |              76 |
|       1024 |        0.000039 |        0.000103 |              74 |              80 |
|       2048 |        0.000090 |        0.000240 |              89 |              96 |
|       4096 |        0.000195 |        0.001333 |             106 |             112 |
|       8192 |        0.000447 |        0.000930 |             150 |             156 |
|      16384 |        0.000989 |        0.004583 |             142 |             152 |
|      32768 |        0.002105 |        0.005306 |             334 |             340 |
|      65536 |        0.004591 |        0.025612 |             751 |             792 |
|     131072 |        0.010018 |        0.032057 |            1559 |            1604 |
|     262144 |        0.024700 |        0.091013 |            3167 |            3212 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="adaptive_shivers" %}
