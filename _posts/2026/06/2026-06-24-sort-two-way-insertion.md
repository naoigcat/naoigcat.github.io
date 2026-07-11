---
title:     双方向挿入ソートで配列を並び替える
date:      2026-06-24 05:48:33 +0900
tags:      sort
sort_demo: true
---

## 双方向挿入ソートを使用する

双方向挿入ソート (`two-way insertion sort`) は、整列済み区間へ要素を取り込み、新しい値が最小側・最大側・中間のどれに当たるかで挿入方向を選ぶ。

挿入ソートと同系統の比較ソートである。

1.  **整列済み領域**: 先頭要素だけを整列済みとみなし、`last = 0` から始める。
2.  **左端への挿入**: 位置 `i` の値が `A[0]` より小さいとき、区間 `[0, last]` を右へ1つずつずらし、空いた先頭へ置く。
3.  **右端への挿入**: 値が `A[last]` 以上のとき、`last` を1つ伸ばし、右端側へシフトしてから `A[last]` に置く。
4.  **中間への挿入**: それ以外は `[0, last]` 内を線形探索し、見つけた位置の右側をシフトして挿入する。
5.  **終了**: すべての `i` について繰り返すと `[0, last]` が配列全体となり昇順になる。

```pseudocode
procedure two_way_insertion_sort(A)
  n = length(A)
  if n <= 1 then
    return
  last = 0
  for i from 1 to n - 1
    if A[i] < A[0] then
      key = A[i]
      for j from last down to 0
        A[j + 1] = A[j]
      A[0] = key
      last = last + 1
    else if A[i] >= A[last] then
      last = last + 1
      key = A[i]
      for j from i - 1 down to last
        A[j + 1] = A[j]
      A[last] = key
    else
      k = last
      while A[k] > A[i]
        k = k - 1
      key = A[i]
      for j from i - 1 down to k + 1
        A[j + 1] = A[j]
      A[k + 1] = key
      last = last + 1
```

整列済みに近い入力では右端への追記が多く、逆順に近いと左端への挿入が多くなる。最悪計算量 `O(n²)` となる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('two-way-insertion-sort-demo', function (root) {
  function sortedRoles(last) {
    const pairs = [];
    for (let idx = 0; idx <= last; idx++) {
      pairs.push([idx, 'sorted']);
    }
    return pairs;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    let display = a.slice();
    const steps = [];
    const n = a.length;
    if (n === 0) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    function pushShiftStep(j, last, keyIdx) {
      const arrBefore = display.slice();
      a[j + 1] = a[j];
      const visual = display.slice();
      const t = visual[j];
      visual[j] = visual[j + 1];
      visual[j + 1] = t;
      display = visual.slice();
      steps.push({
        kind: 'shift',
        lo: j,
        last: last,
        arrBefore: arrBefore,
        arr: visual,
        keyIdx: keyIdx,
      });
    }

    let last = 0;
    for (let i = 1; i < n; i++) {
      const key = a[i];
      display = a.slice();
      steps.push({
        kind: 'seg_start',
        i: i,
        last: last,
        arr: a.slice(),
        keyIdx: i,
      });

      if (a[i] < a[0]) {
        steps.push({
          kind: 'branch',
          branch: 'left',
          i: i,
          last: last,
          arr: a.slice(),
          keyIdx: i,
        });
        for (let j = last; j >= 0; j--) {
          pushShiftStep(j, last, 0);
        }
        a[0] = key;
        last++;
        display = a.slice();
        steps.push({
          kind: 'place',
          pos: 0,
          last: last,
          arr: a.slice(),
        });
      } else if (a[i] >= a[last]) {
        steps.push({
          kind: 'branch',
          branch: 'right',
          i: i,
          last: last,
          arr: a.slice(),
          keyIdx: i,
        });
        last++;
        for (let j = i - 1; j >= last; j--) {
          pushShiftStep(j, last, last);
        }
        a[last] = key;
        display = a.slice();
        steps.push({
          kind: 'place',
          pos: last,
          last: last,
          arr: a.slice(),
        });
      } else {
        let k = last;
        while (a[k] > a[i]) {
          steps.push({
            kind: 'search_compare',
            lo: k,
            hi: i,
            last: last,
            arr: a.slice(),
            keyIdx: i,
          });
          k--;
        }
        const pos = k + 1;
        steps.push({
          kind: 'search_done',
          pos: pos,
          last: last,
          arr: a.slice(),
          keyIdx: i,
        });
        for (let j = i - 1; j > k; j--) {
          pushShiftStep(j, last, pos);
        }
        a[pos] = key;
        last++;
        display = a.slice();
        steps.push({
          kind: 'place',
          pos: pos,
          last: last,
          arr: a.slice(),
        });
      }
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-two-way-insertion',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '双方向挿入ソートのデモ（灰が整列済み、紫が挿入キー、オレンジが比較、緑がシフト）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    onStepError: function (api, err) {
      console.error('Step execution error:', err);
      api.setCaption('エラーが発生しました');
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'seg_start') {
        api.mountBars(barsEl, s.arr);
        const roles = sortedRoles(s.last).concat([[s.keyIdx, 'key']]);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '位置 ' +
            s.i +
            ' の要素を整列済み区間 [0, ' +
            s.last +
            '] へ取り込みます（紫が対象）'
        );
        return;
      }
      if (s.kind === 'branch') {
        api.mountBars(barsEl, s.arr);
        const roles = sortedRoles(s.last).concat([[s.keyIdx, 'key']]);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          s.branch === 'left'
            ? 'キーは先頭 ' + s.arr[0] + ' より小さいため、左端へ挿入します'
            : 'キーは末尾 ' + s.arr[s.last] + ' 以上のため、右端へ挿入します'
        );
        return;
      }
      if (s.kind === 'search_compare') {
        api.mountBars(barsEl, s.arr);
        const roles = sortedRoles(s.last)
          .concat([
            [s.lo, 'compare'],
            [s.hi, 'compare'],
          ]);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '中間挿入: 位置 ' + s.lo + ' とキー（位置 ' + s.hi + '）を比較しています'
        );
        return;
      }
      if (s.kind === 'search_done') {
        api.mountBars(barsEl, s.arr);
        const roles = sortedRoles(s.last).concat([[s.pos, 'insert'], [s.keyIdx, 'key']]);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption('挿入位置 ' + s.pos + ' が決まりました。シフトします');
        return;
      }
      if (s.kind === 'shift') {
        const roles = sortedRoles(s.last).concat([
          [s.lo, 'swap'],
          [s.lo + 1, 'swap'],
        ]);
        api.mountBars(barsEl, s.arrBefore);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption('位置 ' + s.lo + ' の値を右へずらしています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, roles);
        return;
      }
      if (s.kind === 'place') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, sortedRoles(s.last));
        api.setCaption(
          '位置 ' + s.pos + ' にキーを配置しました（整列済み区間は [0, ' + s.last + ']）'
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
  id="two-way-insertion-sort-demo"
  data_prefix="two-way-insertion"
  script=sort_demo_js
%}

二分挿入ソートが比較回数を削るのに対し、双方向挿入ソートは整列済み区間の両端への追記を早めに分岐させる。どちらも大域的な二次時間は避けられないが、入力の偏りによっては通常の挿入ソートよりステップが少なくなる場合がある。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000012 |        0.000649 |            1662 |            1668 |
|        512 |        0.000048 |        0.000613 |            1666 |            1672 |
|       1024 |        0.000184 |        0.002053 |            1673 |            1680 |
|       2048 |        0.000713 |        0.005327 |            1690 |            1696 |
|       4096 |        0.002678 |        0.009174 |            1721 |            1728 |
|       8192 |        0.010626 |        0.024431 |            1786 |            1792 |
|      16384 |        0.041445 |        0.142906 |            1918 |            1924 |
|      32768 |        0.170173 |        0.729362 |            2177 |            2184 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="two_way_insertion" %}
