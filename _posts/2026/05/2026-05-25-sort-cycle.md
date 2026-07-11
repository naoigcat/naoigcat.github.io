---
title:     サイクルソートで配列を並び替える
date:      2026-05-25 21:46:05 +0900
tags:      sort
sort_demo: true
---

## サイクルソートを使用する

サイクルソート (`cycle sort`) は、各要素が整列後に置かれる位置を数え、その位置へ1要素ずつ書き込むサイクル（循環）を繰り返して配列を整える。

隣同士の交換を何度も行うバブルソートと異なり、書き込み回数を抑えたい場面（書き込みが読み取りより高コストなメディアなど）で理論的に注目される。

1.  **サイクルの開始**: 未処理の左端を `start` とする。そこにある値を `item` として保持する。
2.  **目標位置の計算**: `start` より右側で `item` より小さい要素の個数を数え、`start` に足した位置を `pos`（書き込み先）とする。`pos == start` ならその要素はすでに正しい位置にあるので次へ進む。
3.  **1回目の書き込み**: `A[pos]` と `item` を入れ替える。`item` には追い出された値が入る。
4.  **サイクルの継続**: 追い出された `item` について手順2〜3を繰り返し、`pos` が再び `start` に戻るまで続ける。1サイクルで `start` の位置は確定する。
5.  **繰り返し**: `start` を1つ進め、配列末尾の手前まで繰り返す。

```pseudocode
procedure cycle_sort(A)
  n = length(A)
  for start from 0 to n - 2
    item = A[start]
    pos = start
    for i from start + 1 to n - 1
      if A[i] < item then
        pos = pos + 1
    if pos = start then
      continue
    while pos < n and A[pos] = item do
      pos = pos + 1
    swap(A[pos], item)
    while pos ≠ start
      pos = start
      for i from start + 1 to n - 1
        if A[i] < item then
          pos = pos + 1
      while pos < n and A[pos] = item do
        pos = pos + 1
      swap(A[pos], item)
```

等しい値が複数あるときは `while A[pos] = item` で **同値の衝突** を避け、同じ位置へ書き込まないようにする。
書き込み回数を抑えたい場面向けで、最悪計算量 `O(n²)` となり、インプレースだが一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('cycle-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    let item;
    let pos;
    let start;
    let i;
    let displaced;
    for (start = 0; start < n - 1; start++) {
      item = a[start];
      steps.push({
        kind: 'cycle_start',
        start: start,
        item: item,
        arr: a.slice()
      });
      pos = start;
      for (i = start + 1; i < n; i++) {
        if (a[i] < item) {
          pos++;
        }
      }
      if (pos === start) {
        continue;
      }
      while (pos < n && a[pos] === item) {
        pos++;
      }
      displaced = a[pos];
      a[pos] = item;
      item = displaced;
      steps.push({
        kind: 'write',
        from: pos,
        to: pos,
        start: start,
        item: item,
        arr: a.slice()
      });
      while (pos !== start) {
        pos = start;
        for (i = start + 1; i < n; i++) {
          if (a[i] < item) {
            pos++;
          }
        }
        while (pos < n && a[pos] === item) {
          pos++;
        }
        displaced = a[pos];
        a[pos] = item;
        item = displaced;
        steps.push({
          kind: 'write',
          from: pos,
          to: pos,
          start: start,
          item: item,
          arr: a.slice()
        });
      }
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function paintBarStates(container, sortedUpTo, highlight) {
    const pairs = [];
    for (let k = 0; k < sortedUpTo; k++) {
      pairs.push([k, 'sorted']);
    }
    if (highlight) {
      pairs.push([highlight.from, highlight.role], [highlight.to, highlight.role]);
    }
    DemoSort.assignRoles(container, pairs);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-cycle',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'サイクルソートのデモ（確定済みは紫、書き込み先は水色、移動は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'cycle_start') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.start, {
          from: s.start,
          to: s.start,
          role: 'cursor'
        });
        api.setCaption(
          'サイクル開始: 位置 ' +
            s.start +
            ' の値 ' +
            s.item +
            ' を正しい位置へ書き込みます'
        );
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.start, {
          from: s.to,
          to: s.from === s.to ? s.to : s.from,
          role: s.from === s.to ? 'write' : 'swap'
        });
        if (s.from === s.to) {
          api.setCaption(
            '位置 ' + s.to + ' へ書き込み（追い出された値 ' + s.item + '）'
          );
        } else {
          api.setCaption(
            '書き込み: 位置 ' +
              s.from +
              ' の値を位置 ' +
              s.to +
              ' へ（追い出された値 ' +
              s.item +
              '）'
          );
        }
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
  id="cycle-sort-demo"
  data_prefix="cycle"
  script=sort_demo_js
%}

クイックソートやマージソートのように漸近的に有利な手法と比べると、比較・書き込みともに二次時間になりやすく、一般用途では採用されにくい。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000014 |        0.000206 |            1662 |            1668 |
|        512 |        0.000060 |        0.000514 |            1665 |            1672 |
|       1024 |        0.000227 |        0.000730 |            1674 |            1680 |
|       2048 |        0.000898 |        0.001239 |            1690 |            1696 |
|       4096 |        0.003498 |        0.006040 |            1721 |            1728 |
|       8192 |        0.014015 |        0.024486 |            1786 |            1792 |
|      16384 |        0.055415 |        0.317743 |            1918 |            1924 |
|      32768 |        0.226216 |        0.496424 |            2178 |            2184 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="cycle" %}
