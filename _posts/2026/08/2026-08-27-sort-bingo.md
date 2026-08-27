---
title:     ビンゴソートで配列を並び替える
date:      2026-08-27 07:37:28 +0900
tags:      sort
sort_demo: true
---

## ビンゴソートを使用する

ビンゴソート (`bingo sort`) は、[選択ソート](/2026/05/11/sort-selection.html)の変形で、未整列範囲の最小値（ビンゴ）を一度見つけたら、その値と等しい要素をすべて確定位置へまとめて移し、次のビンゴを同じ走査の中で探す。

選択ソートが「要素ごと」に未整列範囲を走査するのに対し、ビンゴソートは「相異なる値ごと」に 1 回の走査で足りる。重複が多い入力では走査回数が減り、同値だらけのデータでは選択ソートより速くなりやすい。名前は、目的の値が現れたときに「ビンゴ！」と叫ぶイメージに由来する。

1.  **初回のビンゴ**: 配列全体の最小値を `bingo`、最大値を `largest` とする。`nextBingo` をいったん `largest` に置き、書き込み位置 `nextPos` を `0` から始める。
2.  **同値の配置と次値の探索**: `nextPos` から末尾まで走査する。`A[i] = bingo` なら `A[i]` と `A[nextPos]` を交換して `nextPos` を進める。それ以外で `A[i] < nextBingo` なら `nextBingo` を更新する（次パスで使う次の最小値候補）。
3.  **次のビンゴへ**: 1 パス終了後に `bingo = nextBingo` とし、`nextBingo` を再び `largest` に戻す。
4.  **終了条件**: `bingo < nextBingo` のあいだ手順 2〜3 を繰り返す。最後に残る最大値の塊は、より小さい値がすべて左側へ寄った時点で既に正しい位置にあるため、明示的な最終パスは不要である。

```pseudocode
procedure bingo_sort(A)
  n = length(A)
  if n <= 1 then return
  bingo = minimum(A)
  largest = maximum(A)
  nextBingo = largest
  nextPos = 0
  while bingo < nextBingo
    startPos = nextPos
    for i from startPos to n - 1
      if A[i] = bingo then
        swap(A[i], A[nextPos])
        nextPos = nextPos + 1
      else if A[i] < nextBingo then
        nextBingo = A[i]
    bingo = nextBingo
    nextBingo = largest
```

最悪・平均は相異なる値の個数を `m` として `Θ(n m)`（すべて相異なれば選択ソートと同じ `Θ(n²)`）、最良は `Θ(n + m²)` とされる。追加配列は不要（インプレース）で、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('bingo-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    let bingo = Math.min(...a);
    const largest = Math.max(...a);
    let nextBingo = largest;
    let nextPos = 0;

    steps.push({
      kind: 'caption',
      text: '最小値 ' + bingo + ' を最初のビンゴ、最大値 ' + largest + ' を上限とします',
      arr: a.slice(),
      sortedUpTo: 0,
      bingo: bingo,
    });

    while (bingo < nextBingo) {
      const startPos = nextPos;
      steps.push({
        kind: 'round',
        bingo: bingo,
        sortedUpTo: nextPos,
        arr: a.slice(),
      });
      for (let i = startPos; i < n; i++) {
        steps.push({
          kind: 'compare',
          lo: nextPos,
          hi: i,
          sortedUpTo: nextPos,
          bingo: bingo,
          arr: a.slice(),
        });
        if (a[i] === bingo) {
          if (i !== nextPos) {
            const t = a[i];
            a[i] = a[nextPos];
            a[nextPos] = t;
            steps.push({
              kind: 'swap',
              lo: nextPos,
              hi: i,
              sortedUpTo: nextPos,
              bingo: bingo,
              arr: a.slice(),
            });
          }
          nextPos += 1;
        } else if (a[i] < nextBingo) {
          nextBingo = a[i];
          steps.push({
            kind: 'next',
            hi: i,
            sortedUpTo: nextPos,
            bingo: bingo,
            nextBingo: nextBingo,
            arr: a.slice(),
          });
        }
      }
      bingo = nextBingo;
      nextBingo = largest;
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function paintBarStates(container, sortedCount, pairs) {
    const all = [];
    for (let k = 0; k < sortedCount; k++) {
      all.push([k, 'sorted']);
    }
    for (const pair of pairs) {
      all.push(pair);
    }
    DemoSort.assignRoles(container, all);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-bingo',
    initialValues: [5, 2, 8, 2, 9, 3, 5, 8, 4, 3, 7, 5, 4, 9, 1],
    initialCaption:
      'ビンゴソートのデモ（確定済みは紫、比較はオレンジ、交換は緑。同値がまとめて確定する）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'caption') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, []);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'round') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, []);
        api.setCaption(
          'ビンゴ ' + s.bingo + ' と等しい要素を左端へ集め、次の最小値も探します'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption(
          '比較: 書き込み位置 ' + s.lo + ' と 位置 ' + s.hi + '（ビンゴ ' + s.bingo + '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        paintBarStates(barsEl, s.sortedUpTo, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('ビンゴを確定位置へ交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        paintBarStates(barsEl, s.sortedUpTo, []);
        api.setCaption(
          '位置 ' + s.lo + ' にビンゴ ' + s.bingo + ' を確定しました'
        );
        return;
      }
      if (s.kind === 'next') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [[s.hi, 'compare']]);
        api.setCaption(
          '次のビンゴ候補を ' + s.nextBingo + ' に更新（位置 ' + s.hi + '）'
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
  id="bingo-sort-demo"
  data_prefix="bingo"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[選択ソート](/2026/05/11/sort-selection.html)は最小を 1 要素ずつ確定するため、重複があってもほぼ毎回フル走査が要る。ビンゴソートは同値をまとめて確定し、走査回数を相異なる値の個数に近づける。[カウンティングソート](/2026/06/20/sort-counting.html)も重複に強いが、値域幅ぶんの計数配列を使う非比較ソートであり、ビンゴソートは比較ベースのインプレース変形である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000031 |        0.002546 |               0 |               0 |
|        512 |        0.000110 |        0.000295 |               0 |               0 |
|       1024 |        0.000450 |        0.006707 |               0 |               0 |
|       2048 |        0.001870 |        0.013609 |               0 |               0 |
|       4096 |        0.007102 |        0.031042 |               0 |               0 |
|       8192 |        0.028429 |        0.078459 |               0 |               0 |
|      16384 |        0.115358 |        0.276796 |               0 |               0 |
|      32768 |        0.568974 |        1.921136 |               0 |               0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="bingo" %}
