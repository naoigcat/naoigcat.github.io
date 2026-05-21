---
title:     ノームソートで配列を並び替える
date:      2026-05-10 07:42:56 +0900
tags:      sort
sort_demo: true
---

## ノームソートを使用する

ノームソート (`gnome sort` / `stupid sort`) は、**直感に沿った単純なルールだけで**昇順へ整列させる比較ソートである。「庭のノームが並んだ植木鉢を、隣との大小関係を見ながら前後へ動きながら整える」様子になぞらえ、この名前が付いている説明がよくされている。

処理の状態は現在位置 `pos`（しばしば「ノームの足元」などと呼ぶ）だけでよいことから、状態機械として読みやすく、コードも短く書けるという利点がある。一方で、一般に最悪時間計算量は O(n²) であり、規模が大きいデータ向けではなく、概念的な説明や遊び的な題材として用いられることが多い。

1.  **`pos = 0` から始める**。配列の左端から眺めていく。
2.  **`pos == 0` または `A[pos] >= A[pos - 1]` のとき**：いま見ている並びがローカルに問題ないので **1ステップ進み**、`pos += 1` とする。
3.  **それ以外**：隣との順序が逆なので **隣どうしを交換し**、`pos -= 1` してひとつ戻って再チェックする（より左側とも整合させる）。
4.  **`pos == n`** になるまで繰り返す。

```pseudocode
procedure gnome_sort(A)
  pos = 0
  while pos < length(A)
    if pos = 0 or A[pos] >= A[pos - 1] then
      pos = pos + 1
    else
      swap(A[pos], A[pos - 1])
      pos = pos - 1
```

交換が `>` だけでトリガされる実装では、等しい値の相対順序は変わらないため **安定** なソートとして扱える。追加の配列を使わなければ空間計算量は O(1) である。すでにソート済みの列では比較しながら右へ進むだけなので **O(n)**、逆順に近い並びでは前後への往復が多く **O(n²)** になる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('gnome-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    let pos = 0;
    const n = a.length;
    while (pos < n) {
      if (pos === 0 || a[pos] >= a[pos - 1]) {
        steps.push({ kind: 'advance', pos: pos, arr: a.slice() });
        pos++;
      } else {
        steps.push({ kind: 'compare', lo: pos - 1, hi: pos, arr: a.slice() });
        const t = a[pos];
        a[pos] = a[pos - 1];
        a[pos - 1] = t;
        steps.push({ kind: 'swap', lo: pos - 1, hi: pos, arr: a.slice() });
        pos--;
      }
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-gnome',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ノームソートのデモ（現在位置は水色枠／比較はオレンジ／交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'advance') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, s.pos == null ? [] : [[s.pos, 'cursor']]);
        api.setCaption(
          '前進（位置 ' +
            s.pos +
            ' とその左側は昇順になるまで見たので、ひとつ右へ進みます）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '順序が逆だったので左へ（位置 ' +
            s.lo +
            ' を基準にもう一度見直します）'
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
  id="gnome-sort-demo"
  data_prefix="gnome"
  script=sort_demo_js
%}

バブルソートのように端へ値を運ぶより「小さい不整合が出るたびにすぐその場で直しにいく」挙動が特徴で、単純ながら規模が増えると時間が読みにくくなる側面もある。状態の種類が少なく、コードと動きの対応を追いやすいソートアルゴリズムといえる。
