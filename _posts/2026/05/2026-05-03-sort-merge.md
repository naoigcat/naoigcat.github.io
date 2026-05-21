---
title:     マージソートで配列を並び替える
date:      2026-05-03 08:31:07 +0900
tags:      sort
sort_demo: true
---

## マージソートを使用する

マージソート (`merge sort`) は、配列を半分に **分割** し、それぞれを再帰的にソートしてから、2つの **すでにソート済みの列を1本にマージ（併合）** することで全体を整列させる比較ソートである。分割の深さが O(log n) で、マージが線形時間なので、**最悪でも** O(n log n) で安定して動作する点が特徴である。

1.  **分割**: 区間 `[lo, hi]` の中央 `mid` で左半分 `[lo, mid]` と右半分 `[mid+1, hi]` に分ける。要素が1つだけならそのままソート済みとみなす。
2.  **再帰**: 左右それぞれに対して同じ手順を繰り返す。
3.  **マージ**: 左と右はそれぞれ昇順になっている前提で、先頭同士を比較しながら小さい方から確定させ、どちらか一方が尽きたら残りを順に連結する。結果は補助配列などに書き、`a[lo..hi]` へ写し戻す。

```pseudocode
procedure merge_sort(A, lo, hi)
  if lo >= hi then
    return
  mid = floor((lo + hi) / 2)
  merge_sort(A, lo, mid)
  merge_sort(A, mid + 1, hi)
  merge(A, lo, mid, hi)

procedure merge(A, lo, mid, hi)
  i = lo
  j = mid + 1
  k = 0
  while i <= mid and j <= hi
    if A[i] <= A[j] then
      B[k] = A[i]
      i = i + 1
    else
      B[k] = A[j]
      j = j + 1
    k = k + 1
  copy rest of left or right slice into B
  copy B back into A[lo .. hi]
```

時間計算量は常に **O(n log n)**。マージ用に **O(n)** の追加記憶領域が必要で、多くの実装は **安定ソート**（等しいキーの相対順序を保つ）である。インプレース志向のクイックソートと比べて余分なメモリは要するが、最悪時の挙動が予測しやすいため外部ソートの基礎にも使われる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('merge-sort-demo', function (root) {
  function buildDisplay(a, lo, tmp) {
    const d = a.slice();
    for (let t = 0; t < tmp.length; t++) {
      d[lo + t] = tmp[t];
    }
    return d;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function merge(lo, mid, hi) {
      steps.push({ kind: 'merge_start', lo: lo, mid: mid, hi: hi, arr: a.slice() });
      const tmp = [];
      let i = lo;
      let j = mid + 1;
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
    }

    function mergeSort(lo, hi) {
      if (lo >= hi) return;
      const mid = Math.floor((lo + hi) / 2);
      steps.push({ kind: 'split', lo: lo, hi: hi, mid: mid, arr: a.slice() });
      mergeSort(lo, mid);
      mergeSort(mid + 1, hi);
      merge(lo, mid, hi);
    }

    if (a.length > 0) {
      mergeSort(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k <= hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-merge',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'マージソートのデモ（分割・マージ対象は青、比較はオレンジ、確定書き込みは緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'split') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '分割: 区間 ' + s.lo + ' … ' + s.hi + '（中央 mid = ' + s.mid + '）'
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          'マージ開始: 左 [' +
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
        api.setCaption('比較: 位置 ' + s.i + ' と ' + s.j);
        return;
      }
      if (s.kind === 'merge_write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.writePos, 'write']]);
        api.setCaption('先頭から確定: 位置 ' + s.writePos);
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
    stepPauseMs: 220,
  });
});
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="merge-sort-demo"
  data_prefix="merge"
  script=sort_demo_js
%}

バブルソートの O(n²) と比べてデータが大きい場面では有利になりやすく、クイックソートの最悪 O(n²) と比べて時間計算量のわるい入力がない反面、補助配列など **余計なメモリ** を使うトレードオフがある。
