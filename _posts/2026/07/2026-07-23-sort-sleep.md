---
title:     スリープソートで配列を並び替える
date:      2026-07-23 23:39:38 +0900
tags:      sort
sort_demo: true
---

## スリープソートを使用する

スリープソート (`sleep sort`, `sleepsort`) は、各要素ごとに「値の大きさに比例した時間だけ待ってから取り出す」処理を並列に走らせ、小さい値ほど早く出力される性質を利用して昇順に並べるジョークアルゴリズムとして知られる。

1.  **待機の開始**: 配列 `A` の各要素 `A[i]` について、別スレッド（またはタイマー）を起動する。
2.  **スリープ**: スレッドは `A[i]` に比例した時間だけブロックする（実装ではミリ秒・マイクロ秒などに換算する）。
3.  **出力**: 待機が終わった要素を共有の出力列へ追加する。値が小さいほど早く終わるため、追加順は昇順になる。
4.  **結果**: すべてのスレッドが終了した時点の出力列が整列結果となる。

```pseudocode
procedure sleep_sort(A)
  output = empty concurrent queue
  for each value v in A in parallel
    sleep(duration proportional to v)
    append v to output
  return output
```

正の整数が有限範囲に収まり、スレッド（タイマー）を要素数だけ用意できると仮定したとき、壁時計時間はおおむね `O(max(A))` に比例する。スレッド生成は `O(n)`、出力用の記憶域も `O(n)` 要る。同値要素は待ち時間が衝突しうるため、実装では添字などでタイブレークする必要があり、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('sleep-sort-demo', function (root) {
  function wakeOrder(arr) {
    return arr
      .map(function (value, index) {
        return { value: value, index: index };
      })
      .sort(function (a, b) {
        return a.value - b.value || a.index - b.index;
      })
      .map(function (entry) {
        return entry.index;
      });
  }

  function rolePairs(indices, role) {
    return indices.map(function (i) {
      return [i, role];
    });
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    const allIndices = [];
    for (let i = 0; i < n; i++) {
      allIndices.push(i);
    }

    steps.push({ kind: 'init', arr: a.slice() });
    steps.push({ kind: 'sleep_all', arr: a.slice(), indices: allIndices.slice() });

    const order = wakeOrder(a);
    const awoken = [];
    order.forEach(function (idx) {
      steps.push({
        kind: 'wake',
        idx: idx,
        value: a[idx],
        arr: a.slice(),
        awoken: awoken.slice(),
      });
      awoken.push(idx);
      steps.push({
        kind: 'placed',
        idx: idx,
        arr: a.slice(),
        awoken: awoken.slice(),
      });
    });
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-sleep',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 4],
    initialCaption:
      'スリープソートのデモ（待機中は水色、目覚めはオレンジ、出力済みは整列済み色）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'init') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('各要素の待機タイマーを起動する前の配列');
        return;
      }
      if (s.kind === 'sleep_all') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rolePairs(s.indices, 'range'));
        api.setCaption(
          '各要素が値 ' +
            'に比例した時間スリープ中（小さい値ほど早く目覚める）'
        );
        return;
      }
      if (s.kind === 'wake') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rolePairs(s.awoken, 'sorted'));
        DemoSort.assignRoles(barsEl, [[s.idx, 'compare']]);
        api.setCaption(
          '値 ' + s.value + '（位置 ' + s.idx + '）が目覚め、出力列へ追加'
        );
        return;
      }
      if (s.kind === 'placed') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rolePairs(s.awoken, 'sorted'));
        api.setCaption(
          '出力済み ' + s.awoken.length + ' / ' + s.arr.length + ' 要素'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          rolePairs(
            s.arr.map(function (_v, i) {
              return i;
            }),
            'sorted'
          )
        );
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 320,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="sleep-sort-demo"
  data_prefix="sleep"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[スローソート](/2026/07/21/sort-slow.html)や[ストゥージソート](/2026/07/20/sort-stooge.html)は再帰的な比較・交換で意図的に遅くするが、
スリープソートは比較そのものを行わず、待ち時間の差だけに頼る。

要素数に比例してスレッド（タイマー）を立てる前提のため、通常の単一 CPU 上の比較ソートとは問題設定が異なる。

## 計算時間量および空間計算量を計測する

各要素が独立スレッドで待機する実装のため、他のソートより全体の計測時間が長くなる。
計測はサイズ 256 のみに限定している。

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.037359 |        0.076967 |            2406 |            2576 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="sleep" %}
