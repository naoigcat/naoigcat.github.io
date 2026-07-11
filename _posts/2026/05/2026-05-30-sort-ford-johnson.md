---
title:     マージ挿入ソートで配列を並び替える
date:      2026-05-30 11:39:28 +0900
tags:      sort
sort_demo: true
---

## マージ挿入ソートを使用する

マージ挿入ソート (`merge-insertion sort`) は、要素をペアに分け、各ペアの大きい方を再帰的に整列し、小さい方を二分探索で挿入する。

Ford-Johnson アルゴリズムとしても知られる。

要素をペアに分けて比較し、各ペアの大きい方を主系列 (main chain)、小さいを保留列 (pend) として分ける。主系列を再帰的に整列し、保留列の要素をヤーコプスタール数に基づく順序で二分探索挿入することで、比較回数の上界が抑えられる。

1.  **ペアリング**: 隣接要素を `⌊n/2⌋` 組のペアに分け、 `(小, 大)` の順に並べる。要素数が奇数なら最後の1要素は保留列に回す。
2.  **再帰**: 各ペアの大きい方だけを取り出し、同じ手順で再帰的に整列する。
3.  **主系列の形成**: 整列済みの大きい方の列の先頭に、先頭ペアの小さい方を置く。
4.  **保留列の挿入**: 残りの小さい方を、ヤーコプスタール数で決めた順序で1つずつ主系列へ二分探索挿入する。保留列の各要素は、対応するペアの大きい方より左の区間だけを探索範囲とする。

```pseudocode
procedure merge_insertion_sort(A)
  n = length(A)
  if n <= 1 then return
  if n = 2 then
    compare and swap A[0], A[1] if needed
    return
  form pairs (small, large) by comparing adjacent elements
  L = array of large values from each pair
  merge_insertion_sort(L)
  reorder pairs by sorted L
  chain = [small of first pair] followed by sorted larges
  pend = remaining smalls (and odd element if any)
  for each index i in jacobsthal_insertion_order(length(pend))
    limit = position of paired large for pend[i] in chain
    pos = binary_search(chain[0 .. limit), pend[i])
    insert pend[i] at pos in chain
  copy chain back into A
```

ヤーコプスタール数 `J` は `J₀ = 0`, `J₁ = 1`, `Jₙ = Jₙ₋₁ + 2Jₙ₋₂` で定義され、`J₂` 以降は `1, 3, 5, 11, 21, 43, …` と続く。

保留列の1番目から数えて `J₂`, `J₃`, … の位置を先に挿入し、各ヤーコプスタール番号の間にある残りを降順で埋める。たとえば保留列が6要素なら挿入順は `1, 3, 2, 5, 4, 6` となる。

比較回数が理論的下界に近い `O(n log n)` となるが、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('ford-johnson-sort-demo', function (root) {
  function jacobsthalOrder(m) {
    if (m === 0) {
      return [];
    }
    const js = [0, 1];
    while (js[js.length - 1] < m) {
      js.push(js[js.length - 1] + 2 * js[js.length - 2]);
    }
    const order = [];
    const used = new Array(m).fill(false);
    let prevJ = 0;
    for (let ji = 1; ji < js.length; ji++) {
      const j = js[ji];
      if (j > m) {
        break;
      }
      if (j > prevJ) {
        for (let idx = j - 1; idx >= prevJ; idx--) {
          if (idx < m && !used[idx]) {
            order.push(idx);
            used[idx] = true;
          }
        }
        prevJ = j;
      }
    }
    for (let idx = m - 1; idx >= 0; idx--) {
      if (!used[idx]) {
        order.push(idx);
      }
    }
    return order;
  }

  function reorderPairs(pairs, sortedLarges) {
    const out = [];
    const taken = new Array(pairs.length).fill(false);
    for (const lg of sortedLarges) {
      for (let i = 0; i < pairs.length; i++) {
        if (!taken[i] && pairs[i][1] === lg) {
          out.push(pairs[i]);
          taken[i] = true;
          break;
        }
      }
    }
    return out;
  }

  function sortLarges(values) {
    const n = values.length;
    if (n <= 1) {
      return values.slice();
    }
    if (n === 2) {
      const a = values.slice();
      if (a[0] > a[1]) {
        const t = a[0];
        a[0] = a[1];
        a[1] = t;
      }
      return a;
    }
    const pairCount = Math.floor(n / 2);
    const pairs = [];
    for (let i = 0; i < pairCount; i++) {
      let small = values[2 * i];
      let large = values[2 * i + 1];
      if (small > large) {
        const t = small;
        small = large;
        large = t;
      }
      pairs.push([small, large]);
    }
    const odd = n % 2 === 1 ? values[n - 1] : null;
    const sortedLarges = sortLarges(pairs.map(function (p) {
      return p[1];
    }));
    const sortedPairs = reorderPairs(pairs, sortedLarges);
    const chain = [sortedPairs[0][0]].concat(
      sortedPairs.map(function (p) {
        return p[1];
      })
    );
    const pendingPairs = sortedPairs.slice(1);
    if (odd !== null) {
      pendingPairs.push([odd, null]);
    }
    const pending = pendingPairs.map(function (p) {
      return p[0];
    });
    for (const idx of jacobsthalOrder(pending.length)) {
      const val = pending[idx];
      const pairedLarge = pendingPairs[idx][1];
      let limit = chain.length;
      if (pairedLarge !== null) {
        const pos = chain.indexOf(pairedLarge);
        limit = pos >= 0 ? pos : chain.length;
      }
      let lo = 0;
      let hi = limit;
      while (lo < hi) {
        const mid = Math.floor((lo + hi) / 2);
        if (chain[mid] < val) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      chain.splice(lo, 0, val);
    }
    return chain;
  }

  function generateSteps(initial) {
    const work = initial.slice();
    const steps = [];
    const n = work.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: work.slice() });
      return steps;
    }

    const pairCount = Math.floor(n / 2);
    const pairs = [];
    for (let i = 0; i < pairCount; i++) {
      const lo = 2 * i;
      const hi = lo + 1;
      steps.push({ kind: 'pair_compare', lo: lo, hi: hi, arr: work.slice() });
      if (work[lo] > work[hi]) {
        const t = work[lo];
        work[lo] = work[hi];
        work[hi] = t;
        steps.push({ kind: 'pair_swap', lo: lo, hi: hi, arr: work.slice() });
      }
      pairs.push([work[lo], work[hi]]);
    }

    const odd = n % 2 === 1 ? work[n - 1] : null;
    const larges = pairs.map(function (p) {
      return p[1];
    });

    steps.push({
      kind: 'caption',
      text:
        '各ペアの大きい方 [' +
        larges.join(', ') +
        '] を再帰的にマージ挿入ソート',
      arr: work.slice(),
    });

    const sortedLarges = sortLarges(larges);
    const sortedPairs = reorderPairs(pairs, sortedLarges);

    steps.push({
      kind: 'caption',
      text: '大きい方の整列結果: [' + sortedLarges.join(', ') + ']',
      arr: work.slice(),
    });

    const chain = [sortedPairs[0][0]].concat(
      sortedPairs.map(function (p) {
        return p[1];
      })
    );

    steps.push({
      kind: 'chain_init',
      arr: chain.slice(),
      text:
        '主系列を形成: 先頭ペアの小さい方 ' +
        sortedPairs[0][0] +
        ' の後に整列済みの大きい方を並べる',
    });

    const pendingPairs = sortedPairs.slice(1);
    if (odd !== null) {
      pendingPairs.push([odd, null]);
    }
    const pending = pendingPairs.map(function (p) {
      return p[0];
    });
    const order = jacobsthalOrder(pending.length);

    if (pending.length > 0) {
      steps.push({
        kind: 'caption',
        text:
          '保留列 [' +
          pending.join(', ') +
          '] をヤコブスタール順 (' +
          order.map(function (i) {
            return i + 1;
          }).join(', ') +
          ') で二分探索挿入',
        arr: chain.slice(),
      });
    }

    for (const idx of order) {
      const val = pending[idx];
      const pairedLarge = pendingPairs[idx][1];
      let limit = chain.length;
      if (pairedLarge !== null) {
        const pos = chain.indexOf(pairedLarge);
        limit = pos >= 0 ? pos : chain.length;
      }
      let lo = 0;
      let hi = limit;
      while (lo < hi) {
        const mid = Math.floor((lo + hi) / 2);
        steps.push({
          kind: 'insert_compare',
          mid: mid,
          key: val,
          searchLo: lo,
          searchHi: limit,
          arr: chain.slice(),
        });
        if (chain[mid] < val) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      chain.splice(lo, 0, val);
      steps.push({
        kind: 'insert_place',
        pos: lo,
        key: val,
        arr: chain.slice(),
      });
    }

    steps.push({ kind: 'done', arr: chain.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-ford-johnson',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'マージ挿入ソートのデモ（ペア比較はオレンジ、交換は緑、挿入探索はオレンジ、確定挿入は書き込み色）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'caption') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'pair_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('ペア比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'pair_swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('ペア内で交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ペア内で小さい方を左へ置きました');
        return;
      }
      if (s.kind === 'chain_init') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'insert_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.mid, 'compare']]);
        api.setCaption(
          '二分探索: 挿入値 ' +
            s.key +
            ' と位置 ' +
            s.mid +
            ' を比較（探索範囲 ' +
            s.searchLo +
            ' … ' +
            (s.searchHi - 1) +
            '）'
        );
        return;
      }
      if (s.kind === 'insert_place') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption(
          '保留値 ' + s.key + ' を位置 ' + s.pos + ' に挿入しました'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="ford-johnson-sort-demo"
  data_prefix="ford-johnson"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[挿入ソート](/2026/05/05/sort-insertion.html)の `O(n²)` 比較を、ペアリングと主系列への二分挿入で抑える。実装は複雑だが比較回数の最小化が目的である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000048 |        0.000962 |            1682 |            1688 |
|        512 |        0.000128 |        0.001177 |            1702 |            1708 |
|       1024 |        0.000406 |        0.001633 |            1738 |            1744 |
|       2048 |        0.001584 |        0.022723 |            1802 |            1808 |
|       4096 |        0.005493 |        0.037684 |            1930 |            1936 |
|       8192 |        0.019735 |        0.054744 |            2122 |            2128 |
|      16384 |        0.066834 |        0.556116 |            2559 |            2560 |
|      32768 |        0.282587 |        1.051091 |            3587 |            3592 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="ford_johnson" %}
