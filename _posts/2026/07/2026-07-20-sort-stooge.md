---
title:     ストゥージソートで配列を並び替える
date:      2026-07-20 09:13:15 +0900
tags:      sort
sort_demo: true
---

## ストゥージソートを使用する

ストゥージソート (`stooge sort`) は、区間の両端を比較して必要なら入れ替えたあと、先頭 2/3・末尾 2/3・再び先頭 2/3 の順に同じ処理を再帰的に繰り返して昇順に整える。

アメリカのコメディトリオ「スリースタージーズ」になぞらえて名付けられた、意図的に非効率な整列アルゴリズムとして知られる。

1.  **両端の比較**: 部分配列 `A[lo .. hi]` について `A[lo] > A[hi]` なら入れ替える。
2.  **基底**: 要素数が 2 以下ならここで終了する。
3.  **三分割**: `t = ⌊(hi - lo + 1) / 3⌋` とし、次の 3 回の再帰をこの順で行う。
    -   `stooge_sort(A, lo, hi - t)` — 先頭 2/3
    -   `stooge_sort(A, lo + t, hi)` — 末尾 2/3
    -   `stooge_sort(A, lo, hi - t)` — 先頭 2/3 をもう一度
4.  **全体**: 配列全体 `[0 .. n-1]` に対して上記を適用する。

```pseudocode
procedure stooge_sort(A, lo, hi)
  if A[lo] > A[hi] then
    swap(A[lo], A[hi])
  if hi - lo + 1 <= 2 then
    return
  t = floor((hi - lo + 1) / 3)
  stooge_sort(A, lo, hi - t)
  stooge_sort(A, lo + t, hi)
  stooge_sort(A, lo, hi - t)
```

最悪計算量は `O(n^{log 3 / log 1.5}) ≈ O(n^{2.709})` で、`O(n²)` より遅く `O(n³)` よりは速い。
再帰の深さは `O(log n)` だが、同じ区間を何度も整え直すため実時間は非常に大きい。一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('stooge-sort-demo', function (root) {
  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k <= hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function stoogeRange(a, lo, hi, steps) {
    steps.push({ kind: 'call_start', lo: lo, hi: hi, arr: a.slice() });
    steps.push({ kind: 'compare', lo: lo, hi: hi, arr: a.slice() });
    if (a[lo] > a[hi]) {
      const t = a[lo];
      a[lo] = a[hi];
      a[hi] = t;
      steps.push({ kind: 'swap', lo: lo, hi: hi, arr: a.slice() });
    }
    if (hi - lo + 1 <= 2) {
      steps.push({ kind: 'base_case', lo: lo, hi: hi, arr: a.slice() });
      return;
    }
    const t = Math.floor((hi - lo + 1) / 3);
    steps.push({
      kind: 'phase',
      phase: 1,
      lo: lo,
      hi: hi,
      subLo: lo,
      subHi: hi - t,
      arr: a.slice(),
    });
    stoogeRange(a, lo, hi - t, steps);
    steps.push({
      kind: 'phase',
      phase: 2,
      lo: lo,
      hi: hi,
      subLo: lo + t,
      subHi: hi,
      arr: a.slice(),
    });
    stoogeRange(a, lo + t, hi, steps);
    steps.push({
      kind: 'phase',
      phase: 3,
      lo: lo,
      hi: hi,
      subLo: lo,
      subHi: hi - t,
      arr: a.slice(),
    });
    stoogeRange(a, lo, hi - t, steps);
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }
    stoogeRange(a, 0, a.length - 1, steps);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-stooge',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ストゥージソートのデモ（対象区間は水色、両端比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'call_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '再帰呼び出し: 部分配列 位置 ' + s.lo + ' … ' + s.hi
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('両端比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '両端を交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'base_case') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '要素数 ' +
            (s.hi - s.lo + 1) +
            ' の区間 [' +
            s.lo +
            '…' +
            s.hi +
            '] — これ以上分割しない'
        );
        return;
      }
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          rangePairs(s.subLo, s.subHi, 'range')
        );
        const labels = {
          1: '第1段: 先頭 2/3 [' + s.subLo + '…' + s.subHi + '] を整列',
          2: '第2段: 末尾 2/3 [' + s.subLo + '…' + s.subHi + '] を整列',
          3: '第3段: 先頭 2/3 [' + s.subLo + '…' + s.subHi + '] を再整列',
        };
        api.setCaption(labels[s.phase]);
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
  id="stooge-sort-demo"
  data_prefix="stooge"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ノームソート](/2026/05/10/sort-gnome.html)や[バブルソート](/2026/05/01/sort-bubble.html)は局所的な交換を繰り返すが、
ストゥージソートは同じ部分区間に対して 3 回の再帰を必ず行う。
[クイックソート](/2026/05/02/sort-quick.html)も再帰的だが、ピボット分割で区間が実質的に縮むのに対し、
本アルゴリズムは末尾 2/3 の整列のあと先頭 2/3 をもう一度整え直す点が特徴的である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.004877 |        0.014977 |              61 |              68 |
|        512 |        0.041077 |        0.168336 |              58 |              64 |
|       1024 |        0.119005 |        0.451214 |              58 |              64 |
|       2048 |        1.069047 |        2.254418 |              58 |              64 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="stooge" %}
