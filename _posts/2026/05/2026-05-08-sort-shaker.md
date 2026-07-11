---
title:     シェーカーソートで配列を並び替える
date:      2026-05-08 06:16:01 +0900
tags:      sort
sort_demo: true
---

## シェーカーソートを使用する

シェーカーソート (`shaker sort`) は、バブルソートと同様に隣り合う要素を入れ替えるが、左から右への走査と右から左への走査を交互に繰り返す。

カクテルシェイカーを振るようにデータが両端へ動くことからカクテルソート (`cocktail sort`) とも呼ばれる。

1.  **右方向の走査**: 左端から右端手前まで進み、`a[i] > a[i+1]` なら交換する。これでそのラウンドでは最大の要素が右端側へ寄る。
2.  **左方向の走査**: 右端から左端手前まで戻り、同様に逆順なら交換する。最小の要素が左端側へ寄る。
3.  **範囲の縮小**: 右方向のあと右端は確定した最大として比較範囲から外し、左方向のあと左端は確定した最小として外す。
4.  **終了条件**: ある走査で一度も交換が起きなければ全体がソート済みとして終了する。

```pseudocode
procedure shaker_sort(A)
  begin = 0
  end = length(A) - 1
  while begin < end
    swapped = false
    for i from begin to end - 1
      if A[i] > A[i + 1] then
        swap(A[i], A[i + 1])
        swapped = true
    end = end - 1
    if not swapped then
      break
    swapped = false
    for i from end down to begin + 1
      if A[i - 1] > A[i] then
        swap(A[i - 1], A[i])
        swapped = true
    begin = begin + 1
    if not swapped then
      break
```

最悪計算量 `O(n²)` だが、双方向走査でバブルソートの「タートル問題」を緩和しやすく、安定ソートである。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('shaker-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    let begin = 0;
    let end = a.length - 1;
    while (begin < end) {
      let swapped = false;
      for (let i = begin; i < end; i++) {
        steps.push({
          kind: 'compare',
          lo: i,
          hi: i + 1,
          phase: 'forward',
          arr: a.slice(),
        });
        if (a[i] > a[i + 1]) {
          const t = a[i];
          a[i] = a[i + 1];
          a[i + 1] = t;
          swapped = true;
          steps.push({
            kind: 'swap',
            lo: i,
            hi: i + 1,
            phase: 'forward',
            arr: a.slice(),
          });
        }
      }
      end--;
      if (!swapped) break;

      swapped = false;
      for (let i = end; i > begin; i--) {
        steps.push({
          kind: 'compare',
          lo: i - 1,
          hi: i,
          phase: 'backward',
          arr: a.slice(),
        });
        if (a[i - 1] > a[i]) {
          const t2 = a[i - 1];
          a[i - 1] = a[i];
          a[i] = t2;
          swapped = true;
          steps.push({
            kind: 'swap',
            lo: i - 1,
            hi: i,
            phase: 'backward',
            arr: a.slice(),
          });
        }
      }
      begin++;
      if (!swapped) break;
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function phaseLabel(p) {
    return p === 'backward' ? '逆方向（右→左）' : '順方向（左→右）';
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-shaker',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'シェーカーソートのデモ（左→右は順方向、右→左は逆方向の走査。比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          phaseLabel(s.phase) +
            ': 位置 ' +
            s.lo +
            ' と ' +
            s.hi +
            ' を比較'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption(phaseLabel(s.phase) + ': 交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          phaseLabel(s.phase) +
            ': 交換しました（位置 ' +
            s.lo +
            ' と ' +
            (s.lo + 1) +
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
  id="shaker-sort-demo"
  data_prefix="shaker"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[バブルソート](/2026/05/01/sort-bubble.html)は一方向の走査だけなところシェーカーソートは左右交互に走査し、逆順に近い入力では小さな値が左へ運ばれやすくなっている。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000038 |        0.000520 |            1662 |            1668 |
|        512 |        0.000121 |        0.000425 |            1666 |            1672 |
|       1024 |        0.000420 |        0.000734 |            1674 |            1680 |
|       2048 |        0.001524 |        0.001751 |            1690 |            1696 |
|       4096 |        0.005669 |        0.012543 |            1722 |            1728 |
|       8192 |        0.022262 |        0.053954 |            1786 |            1792 |
|      16384 |        0.107373 |        0.581424 |            1917 |            1924 |
|      32768 |        0.420701 |        1.401350 |            2178 |            2184 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="shaker" %}
