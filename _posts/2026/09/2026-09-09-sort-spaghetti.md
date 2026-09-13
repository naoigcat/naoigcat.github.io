---
title:     スパゲッティソートで配列を並び替える
date:      2026-09-09 05:47:52 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## スパゲッティソートを使用する

スパゲッティソート (`spaghetti sort`) は、各正の数を未調理スパゲッティ棒の長さに見立てたアナログ寄りのソートである。棒を束ねて机へ立てると「いちばん長い棒が突き出る」物理現象を使い、長いものから順に取り出す。

1.  **棒の用意**: 入力の各値に比例した長さのスパゲッティを 1 本ずつ切る（前処理は $$O(n)$$）。
2.  **整列（アナログ）**: 束を机へ垂直に立て、下端をそろえる。この揃えは手・棒・机が並列に働くとみなし、モデル上は定数時間とする。
3.  **最長の取り出し**: 突き出た最長の棒を 1 本取り、降順の結果列へ追加する。残りがなくなるまで繰り返す（取り出しは `n` 回）。
4.  **昇順への変換**: 取り出し順は降順なので、必要なら反転して昇順にする。

```pseudocode
procedure spaghetti_sort(A)
  sticks = copy of A
  descending = empty list
  while sticks is not empty
    maxIdx = index of maximum in sticks
    append sticks[maxIdx] to descending
    remove sticks[maxIdx]
  reverse descending into A
```

アナログモデルでは揃えが $$O(1)$$、用意と取り出しが合わせて $$O(n)$$ とされる。一方、通常の逐次デジタル実装では最長探索が毎回線形なので全体は $$O(n^2)$$ になる。補助配列に棒をコピーするため空間は $$O(n)$$ である。同長の棒をどちらから取るかで相対順が変わりうるため、一般に不安定である。

物理的な長さ比較の比喩としては分かりやすいが、切断精度や本数の上限があり、実務のデジタル整列には向かない。デジタルでは [選択ソート](/2026/05/11/sort-selection.html) と同じく最大（または最小）を繰り返し選ぶ手続きに落ちる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('spaghetti-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;

    steps.push({ kind: 'init', arr: a.slice() });
    steps.push({ kind: 'align', arr: a.slice() });

    for (let size = n; size > 1; size--) {
      let maxIdx = 0;
      steps.push({ kind: 'round', size: size, arr: a.slice() });
      for (let i = 1; i < size; i++) {
        steps.push({
          kind: 'compare',
          lo: maxIdx,
          hi: i,
          size: size,
          arr: a.slice(),
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
        const t = a[maxIdx];
        a[maxIdx] = a[size - 1];
        a[size - 1] = t;
        steps.push({
          kind: 'swap',
          lo: maxIdx,
          hi: size - 1,
          size: size,
          arr: a.slice(),
        });
      }
      steps.push({
        kind: 'placed',
        size: size,
        arr: a.slice(),
      });
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

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-spaghetti',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 4],
    initialCaption:
      'スパゲッティソートのデモ（取り出し済みは紫、比較はオレンジ、取り出しは緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'init') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('各棒の長さが入力値。束ねて机へ立てる準備をする');
        return;
      }
      if (s.kind === 'align') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          s.arr.map(function (_v, i) {
            return [i, 'range'];
          })
        );
        api.setCaption('机へ立てて下端をそろえる（アナログでは定数時間の揃え）');
        return;
      }
      if (s.kind === 'round') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.size, []);
        api.setCaption(
          '残り ' + s.size + ' 本から、いちばん長いスパゲッティを探す'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.size, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption(
          '長さ比較: 位置 ' + s.lo + ' と 位置 ' + s.hi
        );
        return;
      }
      if (s.kind === 'found') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.size, [[s.maxIdx, 'cursor']]);
        api.setCaption(
          '最長は位置 ' + s.maxIdx + '（値 ' + s.arr[s.maxIdx] + '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        paintBarStates(barsEl, s.size, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('最長の棒を取り出し位置（右端側）へ移す');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        paintBarStates(barsEl, s.size - 1, []);
        return;
      }
      if (s.kind === 'placed') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.size - 1, []);
        api.setCaption(
          '取り出し済み: 右側 ' + (api.values.length - s.size + 1) + ' 本'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, 0, []);
        api.setCaption('ソート完了（長い棒から順に右側へ確定）');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="spaghetti-sort-demo"
  data_prefix="spaghetti"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[選択ソート](/2026/05/11/sort-selection.html)は未整列範囲から最小（または最大）を選んで確定位置と交換する。デジタル化したスパゲッティソートも最長の繰り返し選択に帰着するが、もともとの語りは物理的な長さ揃えを定数時間とみなす点で異なる。

[ビーズソート](/2026/08/22/sort-bead.html)や[スリープソート](/2026/07/23/sort-sleep.html)も物理量（玉の段・待ち時間）に値を写す比喩だが、スパゲッティソートは棒の突出長そのものを順序の鍵にする。

[パンケーキソート](/2026/05/27/sort-pancake.html)も最大を探して端へ運ぶが、使える操作が接頭辞の反転に限られる制約付き問題である。

## 時間計算量および空間計算量を計測する

デジタル実装は最長探索の繰り返しのため、平均・最悪とも $$O(n^2)$$ 相当の計測になる。

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000018 |        0.000081 |               4 |               4 |
|        512 |        0.000058 |        0.000175 |               8 |               8 |
|       1024 |        0.000207 |        0.000315 |              16 |              16 |
|       2048 |        0.000786 |        0.001482 |              32 |              32 |
|       4096 |        0.002978 |        0.006398 |              64 |              64 |
|       8192 |        0.011604 |        0.021015 |             128 |             128 |
|      16384 |        0.045712 |        0.104715 |             256 |             256 |
|      32768 |        0.233990 |        0.471986 |             512 |             512 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="spaghetti" %}
