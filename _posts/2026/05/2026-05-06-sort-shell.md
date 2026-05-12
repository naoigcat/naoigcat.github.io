---
layout: post
title:  シェルソートで配列を並び替える
date:   2026-05-06 07:48:33 +0900
tags:   sort
---

## シェルソートを使用する

シェルソート (`shell sort`) は、**間隔（ギャップ）** を取った部分列に対して挿入ソートを繰り返すことで、全体を整列させる比較ソートである。ギャップが大きいうちは離れた要素同士の交換で「粗く」並びを整え、ギャップを徐々に小さくしていくことで、最終的にギャップ 1 のとき通常の挿入ソートとして収束する。

1.  **ギャップ列の決定**: 例として初期ギャップを `⌊n/2⌋` とし、各フェーズで半分に縮小して最後に 1 にする（古典的な増分列）。実装では Knuth 列など別の増分列を選ぶことも多い。
2.  **ギャップごとの挿入ソート**: 現在のギャップ `g` について、インデックス `g, g+1, …, n-1` を順に見ていき、各位置の要素を左へ「`g` 離れた」要素との比較によって挿入位置へ運ぶ（要素が逆順なら交換し、`j >= g` になるまで繰り返す）。
3.  **繰り返し**: ギャップが 1 になるまで手順 2 を繰り返す。ギャップ 1 のフェーズは通常の挿入ソートと同じになる。

```pseudocode
procedure shell_sort(A)
  n = length(A)
  gap = floor(n / 2)
  while gap > 0
    for i from gap to n - 1
      j = i
      while j >= gap and A[j - gap] > A[j]
        swap(A[j], A[j - gap])
        j = j - gap
    gap = floor(gap / 2)
```

増分列によって最悪時間計算量は異なる。上記の「半分に縮小する」列では最悪 **O(n²)** と報告されているが、バブルソートのような単純な隣接交換のみの走査より早くなることが多い。

ギャップが大きいフェーズで要素が大きく動けるため、ギャップ 1 の段階での逆転数が抑えられやすいという直観がある。空間計算量は **O(1)** の追加領域で実装できる **インプレース** ソートである。**安定ではない**（等しいキーの相対順序が保証されない）ことが一般的である。

{% capture sort_demo_js %}
<script>
(function () {
  var root = document.getElementById('shell-sort-demo');
  if (!root) return;
  var DemoSort = window.DemoSort;
  if (!DemoSort || !DemoSort.attachPlayback) return;

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var n = a.length;
    var gap = Math.floor(n / 2);
    while (gap > 0) {
      steps.push({ kind: 'gap', gap: gap, arr: a.slice() });
      var i;
      for (i = gap; i < n; i++) {
        var j = i;
        while (j >= gap && a[j - gap] > a[j]) {
          steps.push({ kind: 'compare', lo: j - gap, hi: j, arr: a.slice() });
          var t = a[j];
          a[j] = a[j - gap];
          a[j - gap] = t;
          steps.push({ kind: 'swap', lo: j - gap, hi: j, arr: a.slice() });
          j -= gap;
        }
      }
      gap = Math.floor(gap / 2);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function setRoles(container, lo, hi, kind) {
    var nodes = container.children;
    for (var k = 0; k < nodes.length; k++) {
      nodes[k].removeAttribute('data-role');
    }
    if (lo == null || hi == null) return;
    if (nodes[lo]) nodes[lo].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
    if (nodes[hi]) nodes[hi].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-ss',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'シェルソートのデモ（ギャップ変更時はキャプションのみ更新。比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      var barsEl = api.barsEl;
      if (s.kind === 'gap') {
        api.mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null);
        api.setCaption(
          'ギャップ ' + s.gap + ' で間隔付き挿入ソートを実行します'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        setRoles(barsEl, s.lo, s.hi, 'compare');
        api.setCaption(
          '比較: 位置 ' +
            s.lo +
            ' と ' +
            s.hi +
            '（間隔 ' +
            (s.hi - s.lo) +
            '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        setRoles(barsEl, s.lo, s.hi, 'swap');
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        setRoles(barsEl, null, null);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
})();
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="shell-sort-demo"
  preset="shell"
  data_prefix="ss"
  script=sort_demo_js
%}

バブルソートのように隣接要素だけを見るより早くなることがあり、実装もインプレースで比較的単純である。一方でクイックソートやマージソートと比べたときの平均的な速度や最悪ケースの見通しは増分列の選び方に依存するため、本番用途では言語標準のソート実装を利用するのが無難である。
