---
title:     シャトルソートで配列を並び替える
date:      2026-06-29 08:11:17 +0900
tags:      sort
sort_demo: true
---

## シャトルソートを使用する

シャトルソート (`shuttle sort`) は、各走査で新しい位置の要素を左方向へ隣接交換で運びながら、先頭側の整列済み区間をひとつずつ広げていく。

値が左へ「往復するシャトル」のように見えることから名付けられた。

1.  **整列済み領域**: 最初は先頭要素だけを整列済みとみなす。
2.  **`i` 回目の走査**: インデックス `i` の要素をキーと見て、`A[i-1] > A[i]` なら隣接交換し `i` を左へ進める。順序が正しくなるまで繰り返す。
3.  **走査完了**: `i` 回目の走査の終わりで `[0, i]` が昇順に整列済みとなる。
4.  **終了**: `i = n - 1` まで走査を繰り返す。

```pseudocode
procedure shuttle_sort(A)
  n = length(A)
  for i from 1 to n - 1
    j = i
    while j > 0 and A[j - 1] > A[j] then
      swap(A[j - 1], A[j])
      j = j - 1
```

整列済みに近い入力では `O(n)` に近づき、安定ソートである。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('shuttle-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    for (let i = 1; i < n; i++) {
      steps.push({
        kind: 'scan_start',
        scan: i,
        keyIdx: i,
        arr: a.slice(),
      });
      let j = i;
      while (j > 0) {
        steps.push({
          kind: 'compare',
          lo: j - 1,
          hi: j,
          scan: i,
          arr: a.slice(),
          keyIdx: j,
        });
        if (a[j - 1] > a[j]) {
          const t = a[j];
          a[j] = a[j - 1];
          a[j - 1] = t;
          steps.push({
            kind: 'swap',
            lo: j - 1,
            hi: j,
            scan: i,
            arr: a.slice(),
            keyIdx: j - 1,
          });
          j--;
        } else {
          break;
        }
      }
      steps.push({
        kind: 'scan_done',
        scan: i,
        arr: a.slice(),
      });
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-shuttle',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'シャトルソートのデモ（走査中の値は紫／比較はオレンジ／交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'scan_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.keyIdx, 'key']]);
        api.setCaption(
          '第 ' +
            s.scan +
            ' 走査：位置 ' +
            s.keyIdx +
            ' の要素を左の整列済み区間へシャトルします（紫）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '第 ' + s.scan + ' 走査 — 比較: 位置 ' + s.lo + ' と ' + s.hi
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('第 ' + s.scan + ' 走査 — 交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '第 ' +
            s.scan +
            ' 走査 — 左へシャトル（位置 ' +
            s.keyIdx +
            ' の値を運んでいます）'
        );
        return;
      }
      if (s.kind === 'scan_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '第 ' +
            s.scan +
            ' 走査完了（先頭 ' +
            (s.scan + 1) +
            ' 要素が整列済み）'
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
  id="shuttle-sort-demo"
  data_prefix="shuttle"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ノームソート](/2026/05/10/sort-gnome.html)は単一位置を前後へ動かす。[シェーカーソート](/2026/05/08/sort-shaker.html)は両端から未整列区間を狭める。シャトルは走査ごとに先頭側の整列済み区間を 1 つずつ広げる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000008 |        0.000039 |            1678 |            1684 |
|        512 |        0.000026 |        0.000070 |            1682 |            1688 |
|       1024 |        0.000088 |        0.000167 |            1690 |            1696 |
|       2048 |        0.000342 |        0.000419 |            1706 |            1712 |
|       4096 |        0.001334 |        0.002223 |            1738 |            1744 |
|       8192 |        0.005492 |        0.020039 |            1801 |            1808 |
|      16384 |        0.021904 |        0.074351 |            1934 |            1940 |
|      32768 |        0.071984 |        0.137185 |            2194 |            2200 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="shuttle" %}
