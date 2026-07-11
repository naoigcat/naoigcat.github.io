---
title:     パンケーキソートで配列を並び替える
date:      2026-05-27 17:08:06 +0900
tags:      sort
sort_demo: true
---

## パンケーキソートを使用する

パンケーキソート (`pancake sort`) は、配列の先頭から任意の位置までを一度に反転（フリップ）できる操作だけを使って整列する。

スパチュラで積み重ねたパンケーキの上面から何枚かをひっくり返すイメージから名付けられた。

1.  **未整列の範囲**: 長さ `size` の接頭辞 `A[0 .. size-1]` に注目する（最初は `size = n`）。
2.  **最大の探索**: その範囲で最大要素の位置 `maxIdx` を見つける。
3.  **先頭へ**: `maxIdx ≠ 0` なら `A[0 .. maxIdx]` を反転し、最大を先頭へ運ぶ。
4.  **確定位置へ**: `A[0 .. size-1]` を反転し、最大を範囲の末尾（整列後の正しい位置）へ運ぶ。
5.  **繰り返し**: `size` を1つ減らし、`size = 2` まで繰り返す。

```pseudocode
procedure flip(A, end)
  for lo from 0 to end - 1
    swap(A[lo], A[end - lo])

procedure pancake_sort(A)
  n = length(A)
  for size from n down to 2
    maxIdx = index of maximum in A[0 .. size - 1]
    if maxIdx != size - 1 then
      if maxIdx != 0 then
        flip(A, maxIdx)
      flip(A, size - 1)
```

反転1回は **O(k)**（`k` は反転長）の要素移動を伴う。素朴な実装では各ラウンドで最大を線形探索するため、最悪でも平均でも **O(n²)** の時間になりやすい。

追加配列を使わなければ **空間計算量は O(1)** のインプレースソートである。反転は等しい値の相対順序を入れ替えうるため、一般に **不安定** なソートとして扱われる。

操作が「接頭辞の反転」に限定されるという制約下での整列問題として知られ、フリップ回数を最小化する研究（パンケーキ問題）とも結びつく。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('pancake-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;

    function flipRange(hi, purpose, sortedFrom) {
      steps.push({
        kind: 'flip_start',
        hi: hi,
        purpose: purpose,
        sortedFrom: sortedFrom,
        arr: a.slice(),
      });
      let lo = 0;
      let end = hi;
      while (lo < end) {
        steps.push({
          kind: 'flip_compare',
          lo: lo,
          hi: end,
          sortedFrom: sortedFrom,
          arr: a.slice(),
        });
        const t = a[lo];
        a[lo] = a[end];
        a[end] = t;
        steps.push({
          kind: 'flip_swap',
          lo: lo,
          hi: end,
          sortedFrom: sortedFrom,
          arr: a.slice(),
        });
        lo++;
        end--;
      }
      steps.push({
        kind: 'flip_done',
        hi: hi,
        purpose: purpose,
        sortedFrom: sortedFrom,
        arr: a.slice(),
      });
    }

    for (let size = n; size > 1; size--) {
      let maxIdx = 0;
      steps.push({ kind: 'round', size: size, arr: a.slice() });
      for (let i = 1; i < size; i++) {
        steps.push({
          kind: 'find_compare',
          lo: maxIdx,
          hi: i,
          arr: a.slice(),
          size: size,
        });
        if (a[i] > a[maxIdx]) {
          maxIdx = i;
        }
      }
      steps.push({
        kind: 'found',
        maxIdx: maxIdx,
        size: size,
        arr: a.slice(),
      });
      if (maxIdx !== size - 1) {
        if (maxIdx !== 0) {
          flipRange(maxIdx, 'to_front', size);
        }
        flipRange(size - 1, 'to_place', size);
      }
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function paintBarStates(container, sortedFrom, pairs) {
    const all = [];
    for (let k = sortedFrom; k < container.children.length; k++) {
      all.push([k, 'sorted']);
    }
    for (const pair of pairs) {
      all.push(pair);
    }
    DemoSort.assignRoles(container, all);
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
    dataAttr: 'data-pancake',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'パンケーキソートのデモ（確定済みは紫、探索はオレンジ、反転範囲は青、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'round') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.size, []);
        api.setCaption(
          '長さ ' + s.size + ' の接頭辞で最大を探し、末尾へ送ります'
        );
        return;
      }
      if (s.kind === 'find_compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.size, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption(
          '最大候補 位置 ' + s.lo + ' と 位置 ' + s.hi + ' を比較'
        );
        return;
      }
      if (s.kind === 'found') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.size, [[s.maxIdx, 'cursor']]);
        api.setCaption(
          '最大は位置 ' + s.maxIdx + '（接頭辞 0 … ' + (s.size - 1) + '）'
        );
        return;
      }
      if (s.kind === 'flip_start') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(
          barsEl,
          s.sortedFrom,
          rangePairs(0, s.hi, 'range')
        );
        api.setCaption(
          (s.purpose === 'to_front'
            ? '先頭へ: '
            : '確定位置へ: ') +
            '位置 0 … ' +
            s.hi +
            ' を反転'
        );
        return;
      }
      if (s.kind === 'flip_compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedFrom, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption('反転: 位置 ' + s.lo + ' と ' + s.hi + ' を交換');
        return;
      }
      if (s.kind === 'flip_swap') {
        paintBarStates(barsEl, s.sortedFrom, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('反転のため交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '反転のため交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'flip_done') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedFrom, []);
        api.setCaption(
          (s.purpose === 'to_front'
            ? '先頭への反転完了'
            : '確定位置への反転完了') +
            '（0 … ' +
            s.hi +
            '）'
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
  id="pancake-sort-demo"
  data_prefix="pancake"
  script=sort_demo_js
%}

接頭辞の反転だけという制約は人工的だが、許される操作が少ない状況での整列や、フリップ回数の最小化といった組合せ論的な側面を学ぶ題材として有用である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000039 |        0.000432 |            1662 |            1668 |
|        512 |        0.000165 |        0.001256 |            1666 |            1672 |
|       1024 |        0.000585 |        0.003192 |            1674 |            1680 |
|       2048 |        0.002193 |        0.023284 |            1690 |            1696 |
|       4096 |        0.007713 |        0.033231 |            1722 |            1728 |
|       8192 |        0.028133 |        0.335716 |            1786 |            1792 |
|      16384 |        0.103849 |        0.432677 |            1917 |            1924 |
|      32768 |        0.458149 |        1.456860 |            2178 |            2184 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="pancake" %}
