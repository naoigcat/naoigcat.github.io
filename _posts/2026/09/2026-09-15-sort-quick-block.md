---
title:     ブロッククイックソートで配列を並び替える
date:      2026-09-15 04:59:45 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## ブロッククイックソートを使用する

ブロッククイックソート (`BlockQuicksort`) は分岐予測ミスを抑える分割を用いるクイックソートである。

[ホーア分割型クイックソート](/2026/08/14/sort-quick-hoare.html)と同じく左右から詰め合う分割だが、要素ごとの比較結果でその場で分岐して交換するのではなく、固定長のブロックをまとめて走査し、ずれている要素のオフセットをバッファに溜めてからまとめて交換する。

比較結果に依存する条件分岐をほぼ消し、平均の分岐予測ミスを $$\varepsilon n \log n + O(n)$$（ブロック長に依存する小さい $$\varepsilon$$）程度に抑えられることが示されている。

1.  **ピボットの選択**: 部分配列の中央付近の要素をピボットとし、いったん末尾へ退避する。
2.  **走査（scanning）**: 左右に長さ $$B$$（論文では 128）のブロックを取り、ピボットと比較する。左ブロックでは $$A[i] \ge \mathrm{pivot}$$ のオフセットを、右ブロックでは $$A[j] \le \mathrm{pivot}$$ のオフセットをバッファへ書く。加算には比較結果を整数化した値を使い、比較ごとの分岐を避ける。
3.  **再配置（rearrangement）**: 両バッファから $$\min(|L|,|R|)$$ 組を取り出し、対応する要素を交換する。空になった側のブロックだけポインタを進める。
4.  **残り**: 長さが $$2B$$ 以下になったら、残りを同じ要領で片付け、ピボットを境界へ戻す。
5.  **再帰**: ピボットより左・右を再帰する。十分短い区間は[挿入ソート](/2026/05/05/sort-insertion.html)で仕上げる。

```pseudocode
procedure block_quick_sort(A, lo, hi)
  if hi - lo < INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  p = block_partition(A, lo, hi)
  block_quick_sort(A, lo, p - 1)
  block_quick_sort(A, p + 1, hi)

procedure block_partition(A, lo, hi)
  // hi is inclusive; pivot moves to A[hi]
  swap(A[lo + floor((hi - lo) / 2)], A[hi])
  pivot = A[hi]
  begin = lo
  last = hi - 1
  numL = numR = startL = startR = 0
  while last - begin + 1 > 2B
    if numL = 0 then
      startL = 0
      for i = 0 .. B - 1
        offsetsL[numL] = i
        numL = numL + (A[begin + i] >= pivot)   // branchless increment
    if numR = 0 then
      startR = 0
      for i = 0 .. B - 1
        offsetsR[numR] = i
        numR = numR + (A[last - i] <= pivot)
    num = min(numL, numR)
    for j = 0 .. num - 1
      swap(A[begin + offsetsL[startL + j]], A[last - offsetsR[startR + j]])
    numL = numL - num; numR = numR - num
    startL = startL + num; startR = startR + num
    if numL = 0 then begin = begin + B
    if numR = 0 then last = last - B
  // finish remaining ≤ 2B elements (same buffers), then place pivot
  ...
  return pivot_index
```

平均計算量は通常のクイックソートと同様 $$O(n \log n)$$ で、ピボットが偏ると最悪 $$O(n^2)$$ になりうる。追加メモリはオフセット用の $$O(B)$$ と再帰スタック程度で、実質インプレースである。不安定である。

デモではブロック長を $$B = 4$$ に下げ、走査と再配置が見えるようにしている（計測コードは $$B = 128$$）。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('block-quick-sort-demo', function (root) {
  const BLOCK = 4;
  const INSERTION_THRESHOLD = 4;

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

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
            j -= 1;
          } else {
            break;
          }
        }
      }
    }

    function blockPartition(lo, hi) {
      const mid = lo + Math.floor((hi - lo) / 2);
      {
        const t = a[mid];
        a[mid] = a[hi];
        a[hi] = t;
      }
      steps.push({
        kind: 'pivot_place',
        lo,
        hi,
        pivot: hi,
        arr: a.slice(),
      });
      const pivot = a[hi];
      let begin = lo;
      let last = hi - 1;
      const offsetsL = new Array(BLOCK);
      const offsetsR = new Array(BLOCK);
      let numL = 0;
      let numR = 0;
      let startL = 0;
      let startR = 0;

      const scanLeft = (count) => {
        startL = 0;
        numL = 0;
        const marked = [];
        for (let i = 0; i < count; i++) {
          offsetsL[numL] = i;
          const bad = !(a[begin + i] < pivot);
          numL += bad ? 1 : 0;
          if (bad) marked.push(begin + i);
        }
        steps.push({
          kind: 'scan',
          side: 'L',
          begin,
          last,
          pivot: hi,
          block: count,
          marked: marked.slice(),
          arr: a.slice(),
        });
      };

      const scanRight = (count) => {
        startR = 0;
        numR = 0;
        const marked = [];
        for (let i = 0; i < count; i++) {
          offsetsR[numR] = i;
          const bad = !(pivot < a[last - i]);
          numR += bad ? 1 : 0;
          if (bad) marked.push(last - i);
        }
        steps.push({
          kind: 'scan',
          side: 'R',
          begin,
          last,
          pivot: hi,
          block: count,
          marked: marked.slice(),
          arr: a.slice(),
        });
      };

      const rearrange = (shiftL, shiftR) => {
        const num = Math.min(numL, numR);
        for (let j = 0; j < num; j++) {
          const li = begin + offsetsL[startL + j];
          const ri = last - offsetsR[startR + j];
          const t = a[li];
          a[li] = a[ri];
          a[ri] = t;
          steps.push({
            kind: 'swap',
            lo: li,
            hi: ri,
            pivot: hi,
            arr: a.slice(),
            phase: 'block',
          });
        }
        numL -= num;
        numR -= num;
        startL += num;
        startR += num;
        if (numL === 0) begin += shiftL;
        if (numR === 0) last -= shiftR;
      };

      while (begin <= last && last - begin + 1 > 2 * BLOCK) {
        if (numL === 0) scanLeft(BLOCK);
        if (numR === 0) scanRight(BLOCK);
        rearrange(BLOCK, BLOCK);
      }

      let shiftL;
      let shiftR;
      if (numL === 0 && numR === 0) {
        const len = last - begin + 1;
        shiftL = Math.floor(len / 2);
        shiftR = len - shiftL;
        startL = 0;
        startR = 0;
        numL = 0;
        numR = 0;
        const markedL = [];
        const markedR = [];
        for (let i = 0; i < shiftL; i++) {
          offsetsL[numL] = i;
          const badL = !(a[begin + i] < pivot);
          numL += badL ? 1 : 0;
          if (badL) markedL.push(begin + i);
          offsetsR[numR] = i;
          const badR = !(pivot < a[last - i]);
          numR += badR ? 1 : 0;
          if (badR) markedR.push(last - i);
        }
        if (shiftL < shiftR) {
          offsetsR[numR] = shiftR - 1;
          const badR = !(pivot < a[last - (shiftR - 1)]);
          numR += badR ? 1 : 0;
          if (badR) markedR.push(last - (shiftR - 1));
        }
        steps.push({
          kind: 'scan',
          side: 'both',
          begin,
          last,
          pivot: hi,
          block: len,
          marked: markedL.concat(markedR),
          arr: a.slice(),
        });
      } else if (numR !== 0) {
        shiftL = last - begin + 1 - BLOCK;
        shiftR = BLOCK;
        scanLeft(shiftL);
      } else {
        shiftL = BLOCK;
        shiftR = last - begin + 1 - BLOCK;
        scanRight(shiftR);
      }
      rearrange(shiftL, shiftR);

      let pivotPos;
      if (numL !== 0) {
        let lowerI = startL + numL - 1;
        let upper = last - begin;
        while (lowerI >= startL && offsetsL[lowerI] === upper) {
          upper -= 1;
          lowerI -= 1;
        }
        while (lowerI >= startL) {
          const x = begin + upper;
          const y = begin + offsetsL[lowerI];
          const t = a[x];
          a[x] = a[y];
          a[y] = t;
          steps.push({
            kind: 'swap',
            lo: x,
            hi: y,
            pivot: hi,
            arr: a.slice(),
            phase: 'finish',
          });
          upper -= 1;
          lowerI -= 1;
        }
        pivotPos = begin + upper + 1;
      } else if (numR !== 0) {
        let lowerI = startR + numR - 1;
        let upper = last - begin;
        while (lowerI >= startR && offsetsR[lowerI] === upper) {
          upper -= 1;
          lowerI -= 1;
        }
        while (lowerI >= startR) {
          const x = last - upper;
          const y = last - offsetsR[lowerI];
          const t = a[x];
          a[x] = a[y];
          a[y] = t;
          steps.push({
            kind: 'swap',
            lo: x,
            hi: y,
            pivot: hi,
            arr: a.slice(),
            phase: 'finish',
          });
          upper -= 1;
          lowerI -= 1;
        }
        pivotPos = last - upper;
      } else {
        pivotPos = begin;
      }
      {
        const t = a[hi];
        a[hi] = a[pivotPos];
        a[pivotPos] = t;
      }
      steps.push({
        kind: 'part_end',
        lo,
        hi,
        pivot: pivotPos,
        arr: a.slice(),
      });
      return pivotPos;
    }

    function blockQuick(lo, hi) {
      if (lo >= hi) return;
      if (hi - lo < INSERTION_THRESHOLD) {
        insertionSort(lo, hi);
        return;
      }
      const p = blockPartition(lo, hi);
      if (p > lo) blockQuick(lo, p - 1);
      if (p < hi) blockQuick(p + 1, hi);
    }

    if (a.length > 0) {
      blockQuick(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-block-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ブロッククイックソートのデモ（走査で印を付けた要素はオレンジ、交換は緑、ピボットは紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'pivot_place') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          'ピボットを末尾へ退避（部分配列 ' + s.lo + ' … ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'scan') {
        api.mountBars(barsEl, s.arr);
        const roles = s.marked.map((i) => [i, 'compare']);
        roles.push([s.pivot, 'pivot']);
        DemoSort.assignRoles(barsEl, roles);
        const sideLabel =
          s.side === 'L' ? '左ブロック' : s.side === 'R' ? '右ブロック' : '残り両側';
        api.setCaption(
          sideLabel +
            'を走査（B=' +
            s.block +
            '）: ずれている ' +
            s.marked.length +
            ' 件をバッファへ'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption('挿入ソート: 隣接を比較');
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        const phase =
          s.phase === 'insert'
            ? '挿入'
            : s.phase === 'finish'
              ? '仕上げ'
              : 'ブロック再配置';
        api.setCaption(phase + 'で交換しています…');
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
          '分割完了: ピボットは位置 ' +
            s.pivot +
            '（左右を再帰）'
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
  id="block-quick-sort-demo"
  data_prefix="block-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ホーア分割](/2026/08/14/sort-quick-hoare.html)は左右ポインタを 1 要素ずつ進め、比較のたびに「進む／止めて交換」の分岐が起きる。ブロック分割は走査と交換を分離し、比較結果をオフセットバッファへ畳み込む。

[ロムート分割](/2026/05/02/sort-quick-lomuto.html)は片方向の境界更新が中心で、やはり比較ごとの分岐が多い。[パターン撃退型クイックソート](/2026/07/27/sort-pattern-defeating-quick.html)は偏った入力や等値だらけへの耐性を足すハイブリッドであり、分岐予測そのものへの対策ではない。

[デュアルピボット](/2026/07/26/sort-dual-pivot-quick.html)や[サンプルソート](/2026/05/20/sort-sample.html)はピボット数やバケツ分けでスキャン効率を上げる系統で、BlockQuicksort の「定数サイズバッファによる分岐削減」とは直交する改良である。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size | Average time (s) | Maximum time (s) | Average memory (KiB) | Maximum memory (KiB) |
|-----------:|-----------------:|-----------------:|---------------------:|---------------------:|
|        256 |         0.000004 |         0.000081 |                    0 |                    0 |
|        512 |         0.000008 |         0.000041 |                    0 |                    0 |
|       1024 |         0.000017 |         0.000069 |                    0 |                    0 |
|       2048 |         0.000034 |         0.000078 |                    0 |                    0 |
|       4096 |         0.000070 |         0.000131 |                    0 |                    0 |
|       8192 |         0.000144 |         0.000461 |                    0 |                    0 |
|      16384 |         0.000295 |         0.000438 |                    0 |                    0 |
|      32768 |         0.000612 |         0.001124 |                    0 |                    0 |
|      65536 |         0.001264 |         0.001921 |                    0 |                    0 |
|     131072 |         0.002624 |         0.006469 |                    0 |                    0 |
|     262144 |         0.005401 |         0.011292 |                    0 |                    0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="quick_block" %}
