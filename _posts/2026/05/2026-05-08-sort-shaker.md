---
layout:    post
title:     シェーカーソートで配列を並び替える
date:      2026-05-08 06:16:01 +0900
tags:      sort
sort_demo: true
---

## シェーカーソートを使用する

シェーカーソート (`shaker sort`) は、カクテルシェイカーを振るようにデータが両端へ動いていく様子から **カクテルソート** (`cocktail sort`) とも呼ばれる比較ソートである。バブルソートと同様に隣り合う要素だけを入れ替えるが、**左から右**への走査と**右から左**への走査を交互に繰り返す点が異なる。

1.  **右方向の走査**: 左端から右端手前まで進み、`a[i] > a[i+1]` なら交換する。これでそのラウンドでは最大の要素が右端側へ寄る。
2.  **左方向の走査**: 右端から左端手前まで戻り、同様に逆順なら交換する。最小の要素が左端側へ寄る。
3.  **範囲の縮小**: 右方向のあと右端は確定した最大として比較範囲から外し、左方向のあと左端は確定した最小として外す。
4.  **終了条件**: ある走査で一度も交換が起きなければ全体がソート済みとして終了する。

「タートル問題」と呼ばれる現象で、バブルソートでは小さな値が左端へ届くのに多くのパスを要することがあるが、シェーカーソートでは逆向きの走査があるため、極端に左にしか進めない値も早めに動かしやすくなる。

時間計算量は最悪でも **O(n²)** で、空間計算量は **O(1)**。隣接交換のみなので **安定** なソートである。

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

実運用ではマージソートやクイックソートなどが選ばれることが多いが、実装が単純で挙動を視覚化しやすい教育的なアルゴリズムとして有用である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('shaker-sort-demo', function (root) {
  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var begin = 0;
    var end = a.length - 1;
    while (begin < end) {
      var swapped = false;
      var i;
      for (i = begin; i < end; i++) {
        steps.push({
          kind: 'compare',
          lo: i,
          hi: i + 1,
          phase: 'forward',
          arr: a.slice(),
        });
        if (a[i] > a[i + 1]) {
          var t = a[i];
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
      for (i = end; i > begin; i--) {
        steps.push({
          kind: 'compare',
          lo: i - 1,
          hi: i,
          phase: 'backward',
          arr: a.slice(),
        });
        if (a[i - 1] > a[i]) {
          var t2 = a[i - 1];
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
      var barsEl = api.barsEl;
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

{% include sort-demo/wrapper.html
  id="shaker-sort-demo"
  preset="shaker"
  data_prefix="shaker"
  script=sort_demo_js
%}

バブルソートと同じく **O(n²)** だが、データによっては逆向き走査によりステップ数が抑えられる場合がある。それでも大規模データ向けの第一選択にはならないことが多い。
