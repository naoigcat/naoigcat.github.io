---
title:     シャトルソートで配列を並び替える
date:      2026-06-29 08:11:17 +0900
tags:      sort
sort_demo: true
---

## シャトルソートを使用する

シャトルソート (`shuttle sort`) は、各走査で新しい位置の要素を左方向へ隣接交換で運びながら、先頭側の整列済み区間をひとつずつ広げていく比較ソートである。値が左へ「往復するシャトル」のように見えることから名付けられた。

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

隣接交換のみで `>` のときだけ入れ替えるため安定なソートとして扱える。追加配列を使わなければ空間計算量は O(1) である。すでに昇順に近い入力では内側のループが早く終わり最良は O(n)、逆順に近い並びでは O(n²) になる。

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

走査単位で「どこまで整列済みか」がはっきりするため、挿入ソートの説明に隣接交換版を載せた教材と対応づけやすい。一方、ノームソートのように状態が一本のインデックスだけで表せるわけではない。

## ノームソート・シェーカーソートとの違い

[ノームソート](/2026/05/10/sort-gnome.html) も隣接交換で左へ戻りながら整列させる点は似ている。[シェーカーソート](/2026/05/08/sort-shaker.html) は文献によって **shuttle sort** と呼ばれることもあるが、ここで扱うシャトルソートとは走査の向きと整列済み区間の広げ方が異なる。

| 観点 | シャトルソート | ノームソート | シェーカーソート |
| --- | --- | --- | --- |
| 制御 | 外側の走査番号 `i` と内側の位置 `j` | 単一の現在位置 `pos` だけ | 左右端 `begin` / `end` と往復する走査 |
| 走査の向き | 各走査は左方向へのシャトルのみ | 前後どちらにも一歩ずつ | 右方向と左方向を交互に |
| 不変条件 | `i` 回目の走査完了後、先頭 `i + 1` 要素が整列済み | 走査という区切りはなく、`pos == n` で初めて全体完了 | ラウンドごとに端へ最大・最小が寄り、比較範囲が縮む |
| 戻り方 | 1 回の走査のうち `j` を左へ下げるだけ | 交換のたびに `pos -= 1` し、先頭付近まで戻りうる | 逆向き走査で小さな値も左端へ運びやすい |
| 典型の読み方 | 挿入ソートを隣接交換で写した形 | 庭のノームが一歩ずつ前後に歩く状態機械 | バブルソートに逆向き走査を足した形 |

ノームソートとの比較では、同じ入力でも走査の区切り方が違うため **比較・交換の回数は一致しない場合がある**。

シェーカーソートとの比較では、どちらも隣接交換だけで安定だが、シャトルソートは先頭側の整列済み区間を走査ごとに広げ、シェーカーソートは両端から未整列区間を狭めていく。

三つとも最悪・平均 O(n²)、整列済みに近い入力では O(n) に近づく。

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
