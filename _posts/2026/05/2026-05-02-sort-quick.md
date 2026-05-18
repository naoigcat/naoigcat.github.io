---
title:     クイックソートで配列を並び替える
date:      2026-05-02 01:56:15 +0900
tags:      sort
sort_demo: true
---

## クイックソートを使用する

クイックソート (`quick sort`) は、**基準値（ピボット）**を1つ選び、配列を「ピボットより小さい要素」と「ピボット以上の要素」に分ける **分割（partition）** を行い、その両側に同じ処理を再帰的に適用することで整列する比較ソートである。分割が一度の走査で済むため、平均的に高速に動作する。

1.  **ピボットの選択**: 部分配列の先頭・末尾・中央などから1要素をピボットとして選ぶ（実装により様々な選び方がある）。
2.  **分割**: ピボットを基準に、左側にピボット未満の要素、右側にピボット以上の要素が来るように要素を並べ替える。ピボット自体は最終的な位置に置かれる。
3.  **再帰**: ピボットの左側の部分配列と右側の部分配列に対して、要素が1つ以下になるまで手順1〜2を繰り返す。

```pseudocode
procedure quick_sort(A, lo, hi)
  if lo >= hi then
    return
  p = partition(A, lo, hi)
  quick_sort(A, lo, p - 1)
  quick_sort(A, p + 1, hi)

procedure partition(A, lo, hi)
  pivot = A[hi]
  i = lo
  for j from lo to hi - 1
    if A[j] < pivot then
      swap(A[i], A[j])
      i = i + 1
  swap(A[i], A[hi])
  return i
```

この疑似コードは **Lomuto の分割法（Lomuto partition scheme）**である。右端の要素をピボットにし、`i` を「ピボット未満の領域の次の位置」として進める。
`j` が走査している要素がピボットより小さければ `A[i]` と交換し、最後にピボットを `A[i]` に移す。これにより、`lo ... i - 1` にはピボット未満、`i + 1 ... hi` にはピボット以上の要素が残る。

Lomuto は境界が読みやすく、学習用の実装や可視化に向いている。一方で、Hoare の分割法に比べて交換回数が増えやすく、末尾をそのままピボットにすると昇順・降順に近い入力で分割が偏りやすい。実用ではランダムピボットや三点中央値などのピボット選択と組み合わせ、偏りを起こしにくくすることが多い。

期待時間計算量は O(n log n) で、ピボットの選び方が悪いと（すでにソート済みなど）最悪 O(n²) に落ちる。空間計算量は実装次第だが、再帰のスタックを除けば原則として O(1) の追加領域で済む **インプレース** の実装が多い。等しいキーの相対順序を保たない **不安定** なソートであることが一般的である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('quick-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    function partition(lo, hi) {
      const pivotVal = a[hi];
      let i = lo;
      for (let j = lo; j <= hi - 1; j++) {
        steps.push({ kind: 'compare', lo: j, hi: hi, arr: a.slice() });
        if (a[j] < pivotVal) {
          if (i !== j) {
            const t = a[i];
            a[i] = a[j];
            a[j] = t;
            steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice() });
          }
          i++;
        }
      }
      if (i !== hi) {
        const t2 = a[i];
        a[i] = a[hi];
        a[hi] = t2;
        steps.push({ kind: 'swap', lo: i, hi: hi, arr: a.slice() });
      }
      return i;
    }
    function quick(lo, hi) {
      if (lo >= hi) return;
      steps.push({ kind: 'part_start', lo: lo, hi: hi, arr: a.slice() });
      const p = partition(lo, hi);
      steps.push({ kind: 'part_end', pivot: p, arr: a.slice() });
      quick(lo, p - 1);
      quick(p + 1, hi);
    }
    if (a.length > 0) {
      quick(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'クイックソートのデモ（比較はオレンジ、交換は緑、確定したピボットは紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '分割: 部分配列 位置 ' + s.lo + ' … ' + s.hi + '（右端をピボット）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
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
  id="quick-sort-demo"
  preset="quick"
  data_prefix="quick"
  script=sort_demo_js
%}

バブルソートのような単純な O(n²) の手法と比べ、データ規模が大きいときの実効速度が有利になりやすい。標準ライブラリの `sort` では、言語・実装によってクイックソートに近い戦略が採用されていることも多い。
