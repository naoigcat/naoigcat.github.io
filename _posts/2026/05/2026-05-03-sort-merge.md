---
title:     マージソートで配列を並び替える
date:      2026-05-03 08:31:07 +0900
tags:      sort
sort_demo: true
---

## マージソートを使用する

マージソート (`merge sort`) は、配列を半分に分割し、それぞれを再帰的にソートしてから、2つのソート済み列を1本にマージする。

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

分割の深さが `O(log n)` で、マージが線形時間なので最悪計算量は `O(n log n)` で安定して動作する。

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

{% include sort-demo.html
  id="merge-sort-demo"
  data_prefix="merge"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)はインプレースだが最悪計算量 `O(n²)` になり得る。マージは `O(n)` の追加領域を使う代わりに入力に依らず `O(n log n)` である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000009 |        0.000046 |               2 |               2 |
|        512 |        0.000019 |        0.000074 |               4 |               4 |
|       1024 |        0.000039 |        0.000218 |               8 |               8 |
|       2048 |        0.000082 |        0.000437 |              16 |              16 |
|       4096 |        0.000174 |        0.000435 |              32 |              32 |
|       8192 |        0.000374 |        0.000675 |              64 |              64 |
|      16384 |        0.000785 |        0.001476 |             128 |             128 |
|      32768 |        0.001693 |        0.013247 |             256 |             256 |
|      65536 |        0.003581 |        0.005191 |             512 |             512 |
|     131072 |        0.007531 |        0.010286 |            1024 |            1024 |
|     262144 |        0.015841 |        0.021259 |            2048 |            2048 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="merge" %}
