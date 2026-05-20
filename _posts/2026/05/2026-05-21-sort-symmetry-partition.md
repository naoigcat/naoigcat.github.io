---
title:     対称分割ソートで配列を並び替える
date:      2026-05-21 00:32:08 +0900
tags:      sort
sort_demo: true
---

## 対称分割ソートを使用する

対称分割ソート (`symmetry partition sort`, **SPSort**) は、**比例拡張ソート（PESort）の分割を土台にしつつ、整列済み標本を配列の両端へ置いてから未整列部分を分割する**ことで、クイックソートの最悪 O(n²) を避けつつ分割処理を速くする比較ソートである。

2007 年に Jing-Chao Chen により提案された。

PESort は整列済み接頭辞 `S` を左端に伸ばし、その中央値をピボットに未整列部分 `U` を分割する。

SPSort も同じ比例拡張の枠組みを使うが、分割に入る直前に `S` を中央値で左右に分け、**左半分 `L` を左端、右半分 `R` を右端**に置き、中央に `U` を残す **`L | U | R`** の形に整える。
`L` と `R` はそれぞれピボット未満・以上の要素群として働き、分割ループの **番兵（Sentinel）** になるため、境界チェックを減らしつつ走査を速くできる。

1.  **接頭辞の初期化**: 先頭 1 要素（または少数要素）を整列済み接頭辞 `S` とみなす。
2.  **比例拡張**: `|U| > p·|S|` のあいだ、`S` と `U` の先頭 `p·|S|` 要素をまとめて整列し、結果を新しい `S` とする（PESort と同様）。
3.  **対称配置**: `S` の中央値位置で左右に分け、右半分 `R` を配列右端へ移動して **`L | U | R`** にする。
4.  **中央値ピボット**: 中央値をピボットとして `U` を分割する（実装では Lomuto 型や 3 路分割などが用いられる）。
5.  **再帰**: 左側（`L` とピボット未満の部分）・右側（ピボット以上と `R`）に同じ手順を適用する。十分短い区間は挿入ソートで仕上げる。

```pseudocode
procedure symmetry_partition_sort(A, lo, hi, p)
  if hi - lo <= INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  s_end = lo
  while s_end < hi and (hi - s_end) > p * (s_end - lo + 1)
    chunk_end = min(s_end + p * (s_end - lo + 1), hi)
    symmetry_partition_sort(A, lo, chunk_end, p)
    s_end = chunk_end
  median = lo + floor((s_end - lo) / 2)
  r_len = s_end - median
  move A[median + 1 .. s_end] to A[hi - r_len + 1 .. hi]   // L | U | R
  pivot = partition(A, lo, hi, median)
  symmetry_partition_sort(A, lo, pivot - 1, p)
  symmetry_partition_sort(A, pivot + 1, hi, p)
```

パラメータ `p` は PESort と同じく「未整列部分 ÷ 整列済み接頭辞」の上限である。`p ≈ 16` 付近で平均性能がよく、小さくすると最悪ケースが改善しやすい。

Jing-Chao Chen の実装では **適応的な連続区間の検出** や **等値キー領域を持つ分割** も組み合わされ、部分整列済み入力への適応性が高い。

最悪・平均とも **O(n log n)** 比較、補助領域は再帰スタックで **O(log n)** とされる。**安定ソートではない**。

以下のデモでは **`p = 2`**（小配列でも拡張・対称配置が見えるよう意図的に小さくしている）、小区間閾値 4、分割は Lomuto 型である。

青枠は左端の整列済み標本 `L`、水色は右端の `R`、紫は中央値ピボット、オレンジは比較、緑は交換を表す。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('symmetry-partition-sort-demo', function (root) {
  /** デモ用に p を小さくし、拡張・対称配置が視覚化されやすくしている（文献では p ≈ 16 前後が多い）。 */
  const P = 2;
  const INSERTION_THRESHOLD = 4;

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function partition(lo, hi, pivotIdx) {
      const pivotVal = a[pivotIdx];
      if (pivotIdx !== hi) {
        const t0 = a[pivotIdx];
        a[pivotIdx] = a[hi];
        a[hi] = t0;
        steps.push({
          kind: 'swap',
          lo: pivotIdx,
          hi: hi,
          arr: a.slice(),
          phase: 'part',
        });
      }
      let i = lo;
      for (let j = lo; j <= hi - 1; j++) {
        steps.push({
          kind: 'compare',
          lo: j,
          hi: hi,
          arr: a.slice(),
          phase: 'part',
        });
        if (a[j] < pivotVal) {
          if (i !== j) {
            const t = a[i];
            a[i] = a[j];
            a[j] = t;
            steps.push({
              kind: 'swap',
              lo: i,
              hi: j,
              arr: a.slice(),
              phase: 'part',
            });
          }
          i++;
        }
      }
      if (i !== hi) {
        const t2 = a[i];
        a[i] = a[hi];
        a[hi] = t2;
        steps.push({
          kind: 'swap',
          lo: i,
          hi: hi,
          arr: a.slice(),
          phase: 'part',
        });
      }
      return i;
    }

    function insertionSort(lo, hi) {
      for (let i = lo + 1; i <= hi; i++) {
        let j = i;
        while (j > lo) {
          steps.push({
            kind: 'compare',
            lo: j - 1,
            hi: j,
            arr: a.slice(),
            phase: 'insert',
          });
          if (a[j - 1] > a[j]) {
            const t = a[j - 1];
            a[j - 1] = a[j];
            a[j] = t;
            steps.push({
              kind: 'swap',
              lo: j - 1,
              hi: j,
              arr: a.slice(),
              phase: 'insert',
            });
            j--;
          } else {
            break;
          }
        }
      }
    }

    function symmetryLayout(lo, sEnd, hi) {
      const med = lo + Math.floor((sEnd - lo) / 2);
      const rLen = sEnd - med;
      const rStart = med + 1;
      const rDest = hi - rLen + 1;
      steps.push({
        kind: 'symmetry_before',
        lo: lo,
        sEnd: sEnd,
        med: med,
        rStart: rStart,
        rDest: rDest,
        hi: hi,
        arr: a.slice(),
      });
      for (let i = 0; i < rLen; i++) {
        const from = rStart + i;
        const to = rDest + i;
        if (from !== to) {
          const t = a[from];
          a[from] = a[to];
          a[to] = t;
          steps.push({
            kind: 'swap',
            lo: from,
            hi: to,
            arr: a.slice(),
            phase: 'symmetry',
          });
        }
      }
      steps.push({
        kind: 'symmetry_after',
        lLo: lo,
        lHi: med,
        uLo: med + 1,
        uHi: hi - rLen,
        rLo: rDest,
        rHi: hi,
        med: med,
        arr: a.slice(),
      });
      return med;
    }

    function spSort(lo, hi) {
      const len = hi - lo + 1;
      if (len <= INSERTION_THRESHOLD) {
        steps.push({ kind: 'insert_start', lo: lo, hi: hi, arr: a.slice() });
        insertionSort(lo, hi);
        return;
      }

      let sEnd = lo;
      while (sEnd < hi && hi - sEnd > P * (sEnd - lo + 1)) {
        const chunkEnd = Math.min(sEnd + P * (sEnd - lo + 1), hi);
        steps.push({
          kind: 'extend',
          lo: lo,
          sEnd: sEnd,
          chunkEnd: chunkEnd,
          arr: a.slice(),
        });
        spSort(lo, chunkEnd);
        sEnd = chunkEnd;
      }

      const med = symmetryLayout(lo, sEnd, hi);
      steps.push({
        kind: 'part_start',
        lo: lo,
        hi: hi,
        pivot: med,
        arr: a.slice(),
      });
      const pIdx = partition(lo, hi, med);
      steps.push({ kind: 'part_end', pivot: pIdx, arr: a.slice() });
      spSort(lo, pIdx - 1);
      spSort(pIdx + 1, hi);
    }

    if (a.length > 0) {
      spSort(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-symmetry',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '対称分割ソートのデモ（p=2・青=L、水色=R、紫=中央値、オレンジ=比較、緑=交換）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'extend') {
        api.mountBars(barsEl, s.arr);
        const roles = [];
        for (let i = s.lo; i <= s.sEnd; i++) {
          roles.push([i, 'range']);
        }
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '比例拡張: 接頭辞 位置 ' +
            s.lo +
            ' … ' +
            s.sEnd +
            ' と未整列の先頭を位置 ' +
            s.chunkEnd +
            ' まで整列します'
        );
        return;
      }
      if (s.kind === 'insert_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '挿入ソート: 部分配列 位置 ' + s.lo + ' … ' + s.hi
        );
        return;
      }
      if (s.kind === 'symmetry_before') {
        api.mountBars(barsEl, s.arr);
        const roles = [];
        for (let i = s.lo; i <= s.med; i++) {
          roles.push([i, 'range']);
        }
        for (let i = s.rStart; i <= s.sEnd; i++) {
          roles.push([i, 'sorted']);
        }
        roles.push([s.med, 'pivot']);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '対称配置: 整列済み接頭辞を L（左）と R（右）に分け、R を右端へ移します'
        );
        return;
      }
      if (s.kind === 'symmetry_after') {
        api.mountBars(barsEl, s.arr);
        const roles = [];
        for (let i = s.lLo; i <= s.lHi; i++) {
          roles.push([i, 'range']);
        }
        for (let i = s.rLo; i <= s.rHi; i++) {
          roles.push([i, 'sorted']);
        }
        roles.push([s.med, 'pivot']);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          'L | U | R 配置完了（L: 位置 ' +
            s.lLo +
            ' … ' +
            s.lHi +
            '、U: ' +
            s.uLo +
            ' … ' +
            s.uHi +
            '、R: ' +
            s.rLo +
            ' … ' +
            s.rHi +
            '）'
        );
        return;
      }
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          '分割: 部分配列 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（中央値を右端へ移してから走査）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        const roles = [[s.lo, s.phase === 'insert' ? 'insert' : 'compare']];
        if (s.phase === 'part') {
          roles.push([s.hi, 'pivot']);
        } else if (s.phase === 'insert') {
          roles.push([s.hi, 'insert']);
        }
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          s.phase === 'insert'
            ? '挿入ソートで比較: 位置 ' + s.lo + ' と ' + s.hi
            : '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換しています…');
        if (Math.abs(s.lo - s.hi) === 1) {
          await DemoSort.flipAdjacentSwap(barsEl, Math.min(s.lo, s.hi));
        } else {
          await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        }
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          'ピボット確定: 位置 ' +
            s.pivot +
            ' に小さい値群と大きい値群が分かれました'
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

{% include sort-demo/wrapper.html
  id="symmetry-partition-sort-demo"
  preset="symmetry"
  data_prefix="symmetry"
  script=sort_demo_js
%}

比例拡張ソートの記事と並べて読むと、「整列済み標本を左端だけに置くか、両端に置いて番兵にするか」の違いが対比しやすい。
