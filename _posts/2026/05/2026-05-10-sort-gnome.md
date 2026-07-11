---
title:     ノームソートで配列を並び替える
date:      2026-05-10 07:42:56 +0900
tags:      sort
sort_demo: true
---

## ノームソートを使用する

ノームソート (`gnome sort` / `stupid sort`) は、現在位置から隣との大小関係を見ながら前後へ動き、昇順になるまで繰り返す。

庭のノームが植木鉢を整える様子になぞらえて名付けられたとされている。

処理の状態は現在位置 `pos`（しばしば「ノームの足元」などと呼ぶ）だけでよいことから、状態機械として読みやすく、コードも短く書けるという利点がある。

1.  **`pos = 0` から始める**。配列の左端から眺めていく。
2.  **`pos == 0` または `A[pos] >= A[pos - 1]` のとき**：いま見ている並びがローカルに問題ないので1ステップ進み、`pos += 1` とする。
3.  **それ以外**：隣との順序が逆なので隣どうしを交換し、`pos -= 1` してひとつ戻って再チェックする（より左側とも整合させる）。
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

整列済みなら `O(n)`、逆順に近いと `O(n²)` になり、安定ソートである。

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

{% include sort-demo.html
  id="gnome-sort-demo"
  data_prefix="gnome"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[シャトルソート](/2026/06/29/sort-shuttle.html)は走査ごとに整列済み接頭辞を広げる。ノームソートは単一の位置を前後に動かすだけで、不整合が見つかるたびにその場で直す。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000032 |        0.000535 |            1662 |            1668 |
|        512 |        0.000125 |        0.000815 |            1666 |            1672 |
|       1024 |        0.000504 |        0.003710 |            1674 |            1680 |
|       2048 |        0.001823 |        0.009579 |            1690 |            1696 |
|       4096 |        0.005960 |        0.027257 |            1722 |            1728 |
|       8192 |        0.018772 |        0.040192 |            1786 |            1792 |
|      16384 |        0.062021 |        0.131856 |            1918 |            1924 |
|      32768 |        0.246273 |        0.455311 |            2177 |            2184 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="gnome" %}
