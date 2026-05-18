---
title:     比例拡張ソートで配列を並び替える
date:      2026-05-19 06:11:49 +0900
tags:      sort
sort_demo: true
---

## 比例拡張ソートを使用する

比例拡張ソート (`proportion extend sort`, **PESort**) は、**クイックソートの分割を土台にしつつ、整列済み接頭辞の中央値をピボットに使い、未整列部分の長さを比例定数 p で抑える**ことで、クイックソートの最悪 O(n²) を避けようとする比較ソートである。

2001 年に Jing-Chao Chen により提案された。

クイックソートは分割が 1 回の走査で済み、現代 CPU のメモリ階層と相性がよい。一方、ピボット選びが偏ると片側だけ巨大な部分問題が残り、最悪時間計算量が O(n²) になりうる。

PESort は **整列済み接頭辞 `S`** と **未整列部分 `U`** に区間を分けて考え、`|U|` が `p·|S|` を超える間は `S` と `U` の先頭 `p·|S|` 要素をまとめて整列して `S` を伸ばす。十分短い `U` だけが残ったら **`S` の中央値** をピボットに分割し、左右へ再帰する。サンプルソートに近い「小さな整列済み標本からピボットを得る」発想である。

1.  **接頭辞の初期化**: 先頭 1 要素（または少数要素）を整列済み接頭辞 `S` とみなす。
2.  **比例拡張**: `|U| > p·|S|` のあいだ、`S` と `U` の先頭 `p·|S|` 要素をまとめて整列し、結果を新しい `S` とする。
3.  **中央値ピボット**: `S` の中央値をピボットとして部分配列を分割する（実装では Lomuto 型などクイックソートと同様の分割が用いられる）。
4.  **再帰**: ピボットより小さい側・大きい側に同じ手順を適用する。十分短い区間は挿入ソートで仕上げる。

```pseudocode
procedure proportion_extend_sort(A, lo, hi, p)
  if hi - lo <= INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  s_end = lo
  while s_end < hi and (hi - s_end) > p * (s_end - lo + 1)
    chunk_end = min(s_end + p * (s_end - lo + 1), hi)
    proportion_extend_sort(A, lo, chunk_end, p)
    s_end = chunk_end
  median = lo + floor((s_end - lo) / 2)
  pivot = partition(A, lo, hi, median)
  proportion_extend_sort(A, lo, pivot - 1, p)
  proportion_extend_sort(A, pivot + 1, hi, p)
```

パラメータ `p` は「未整列部分 ÷ 整列済み接頭辞」の上限である（文献によって定義が異なるので実装時は論文・ソースの取り方に注意する）。`p ≈ 16` 付近で平均性能がよく、`p` を小さくすると最悪ケースが改善しやすい。`p` が無限大に近いとクイックソート、未整列部分が 1 要素に近いと二分探索挿入ソートに近い振る舞いになる。

最悪・平均とも **O(n log n)** 比較、補助領域は再帰スタックで **O(log n)** とされる。**安定ソートではない**。

以下のデモでは **`p = 2`**（小配列でも拡張フェーズが見えるよう意図的に小さくしている）、小区間閾値 4、分割は Lomuto 型である。青枠は整列済み接頭辞、紫は中央値ピボット、オレンジは比較、緑は交換を表す。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('proportion-extend-sort-demo', function (root) {
  /** デモ用に p を小さくし、拡張フェーズが視覚化されやすくしている（文献では p ≈ 16 前後が多い）。 */
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

    function peSort(lo, hi) {
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
        peSort(lo, chunkEnd);
        sEnd = chunkEnd;
      }

      const med = lo + Math.floor((sEnd - lo) / 2);
      steps.push({
        kind: 'median',
        lo: lo,
        sEnd: sEnd,
        med: med,
        partLo: lo,
        partHi: hi,
        arr: a.slice(),
      });
      steps.push({
        kind: 'part_start',
        lo: lo,
        hi: hi,
        pivot: med,
        arr: a.slice(),
      });
      const pIdx = partition(lo, hi, med);
      steps.push({ kind: 'part_end', pivot: pIdx, arr: a.slice() });
      peSort(lo, pIdx - 1);
      peSort(pIdx + 1, hi);
    }

    if (a.length > 0) {
      peSort(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-proportion',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '比例拡張ソートのデモ（p=2・青=整列済み接頭辞、紫=中央値、オレンジ=比較、緑=交換）',
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
      if (s.kind === 'median') {
        api.mountBars(barsEl, s.arr);
        const roles = [];
        for (let i = s.lo; i <= s.sEnd; i++) {
          roles.push([i, 'range']);
        }
        roles.push([s.med, 'pivot']);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '整列済み接頭辞（位置 ' +
            s.lo +
            ' … ' +
            s.sEnd +
            '）の中央値 位置 ' +
            s.med +
            ' をピボットに分割します'
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
        } else {
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
  id="proportion-extend-sort-demo"
  preset="proportion"
  data_prefix="proportion"
  script=sort_demo_js
%}

クイックソートやイントロソートと並べて読むと、「分割の速さ」と「最悪ケースの抑え方」のトレードオフが対比しやすい。
