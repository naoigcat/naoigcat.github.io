---
title:     スムースソートで配列を並び替える
date:      2026-05-14 04:22:33 +0900
tags:      sort
sort_demo: true
---

## スムースソートを使う

スムースソート (`smooth sort`) は、レオナルド木を積み重ねた森を維持し、末尾を最大値として取り出していく。

ヒープソート (`heap sort`) と同様に最悪時間計算量は `O(n log n)` で、追加の補助記憶域は `O(1)` に抑えられるインプレースなアルゴリズムだが、入力がすでに昇順に近いほど作業量が少なくなる適応的 (adaptive) 性質を持つ。

通常の二分ヒープでは、根が配列の一端にあり、最大値を取り出すたびに根と末尾を交換してヒープを底側から縮めていく。この配置は「ヒープとしての整理」と「昇順に書き出す向き」が噛み合わず、すでにソート済みの入力でも一度ヒープ状に混ぜ直すため、最良でも必ず `O(n log n)` 程度の仕事が残る。

スムースソートでは、二分木ではなくレオナルド数に基づくレオナルド木を積み重ねた森を維持する。各木はヒープ条件を満たし、さらに各木の根の値は左から右へ弱い順（非減少）として並べる。そうすると常に右端が全体の最大になり、末尾から確定した最大値を「取り出す」処理がすでに整っている入力ではほとんど余計な比較を要しない。

レオナルド数 `L(k)` は

-   `L(0) = L(1) = 1`
-   `L(k) = L(k-2) + L(k-1) + 1`（`k ≥ 2`）

で定められ、`1, 1, 3, 5, 9, 15, …` と続く。サイズ `L(k)` のレオナルド木は、大きい方の子が左、小さい方が右になるよう二つのより小さいレオナルド木と根で構成される。

任意の長さ `n` は、高々 `O(log n)` 個の互いに異なるレオナルド数の和として表せる。スムースソートはこの性質を利用して森に含まれる木の本数を常に対数オーダーに抑え、整列済みに近い入力では `O(n)` に近づき、最悪計算量でも `O(n log n)` を保つ適応型ソートとなる。

1.  **森の表現**: 左から右へ根が非減少になるよう、互いに異なるサイズのレオナルド木を複数本並べた森を維持する。どの位置に木の根があるかはビットマスクと末尾木のサイズ（オフセット）で表す。
2.  **第1段階（構築）**: インデックス `i` を 1 から `n - 1` まで増やし、森の符号を更新したうえで新根位置 `i` に対し、単一木内の沈下 `sift_in` または隣木との整合 `interheap_sift` でヒープ条件を満たす。
3.  **第2段階（確定）**: 右端は常に全体の最大なので、`i` を `n - 1` から 2 まで減らしながら末尾木を縮小または 2 子木へ分割し、生じた根に `interheap_sift` を適用して森の不変条件を保つ。
4.  **終了**: 森に残る 2 要素以下は根が左から右へ非減少のため、すでに昇順であり追加の sift は不要。

```pseudocode
procedure sift_in(A, rootIdx, size)
  // インデックス size のレオナルド木 1 本の中でヒープ条件を満たすよう根から下げる。
  // L[k]=L[k-2]+L[k-1]+1、子方向は二分木のサイズにより左右どちらかへ潜る。
  if size < 2 then return
  tmp = A[rootIdx]
  r = rootIdx
  sz = size
  loop
    right = r - 1
    left = right - L[sz - 2]
    if A[right] < A[left]
      candidate = left
      nsz = sz - 1
    else
      candidate = right
      nsz = sz - 2
    if A[candidate] <= tmp then break
    A[r] = A[candidate]
    r = candidate
    sz = nsz
    if sz <= 1 then break
  A[r] = tmp

procedure interheap_sift(A, rootIdx, heap_state)
  // heap_state は「どの桁に木の根があるか」（マスク）と「現在見ている木の順 order」（オフセット）などを束ねたもの。
  tmp = A[rootIdx]
  r = rootIdx
  state = heap_state anchored at rootIdx
  loop while mask(state) <> 1
    maxValue = tmp
    if order(state) > 1 then
      right = r - 1
      left = right - L[order(state) - 2]
      maxValue = max(maxValue, A[left], A[right])
    next = r - L[order(state)]
    if A[next] <= maxValue then break
    A[r] = A[next]
    r = next
    // マスクを調整して左隣の木へカーソル移動
    march_one_tree_left(state)
  A[r] = tmp
  sift_in(A, r, order(state))

procedure smooth_sort(A)
  n = length(A)
  if n <= 1 then return
  heap_state ← initial_singleton_forest_encoding()
  // 第 1 段階（ヒープ化）
  for i = 1 to n - 1
    advance_leonardo_forest(heap_state, i)
    if wide_bottom_condition(i, heap_state, n) then sift_in(A, i, order_at_tail(heap_state)) else interheap_sift(A, i, heap_state)
  // 第 2 段階（右端から順に確定・森の更新）
  for i = n - 1 down to 2
    if order_at_tail(heap_state) < 2 then shrink_trailing_trees(heap_state)
    else
      split_rightmost_into_two_children(heap_state, i)
      for child_root c in newborn_pair_roots()
        interheap_sift(A, c, heap_state)
```

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('smooth-sort-demo', function (root) {
  const L = [
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177,
    287, 465, 753, 1219, 1973, 3193, 5167, 8361,
    13529, 21891, 35421, 57313, 92735, 150049,
    242785, 392835, 635621, 1028457, 1664079, 2692537,
    4356617, 7049155, 11405773, 18454929, 29860703,
    48315633, 78176337, 126491971, 204668309, 331160281,
    535828591, 866988873, 1402817465, 2269806339,
    3672623805
  ];

  function siftIn(A, rootIdx, size, steps) {
    if (size < 2) return;
    const tmp = A[rootIdx];
    let r = rootIdx;
    let sz = size;
    while (true) {
      const right = r - 1;
      const left = right - L[sz - 2];
      steps.push({ kind: 'compare', lo: left, hi: right, arr: A.slice() });
      let next;
      let nsz;
      if (A[right] < A[left]) {
        next = left;
        nsz = sz - 1;
      } else {
        next = right;
        nsz = sz - 2;
      }
      steps.push({ kind: 'compare', lo: next, hi: r, arr: A.slice() });
      if (A[next] <= tmp) break;
      A[r] = A[next];
      steps.push({ kind: 'state', arr: A.slice() });
      r = next;
      sz = nsz;
      if (sz <= 1) break;
    }
    A[r] = tmp;
    steps.push({ kind: 'state', arr: A.slice() });
  }

  function interheapSift(A, rootIdx, hsz, steps) {
    const tmp = A[rootIdx];
    let root = rootIdx;
    const h = { mask: hsz.mask, offset: hsz.offset };
    while (h.mask !== 1n) {
      let max = tmp;
      if (h.offset > 1) {
        const right = root - 1;
        const left = right - L[h.offset - 2];
        steps.push({ kind: 'compare', lo: left, hi: right, arr: A.slice() });
        if (max < A[left]) max = A[left];
        if (max < A[right]) max = A[right];
      }
      const next = root - L[h.offset];
      steps.push({ kind: 'compare', lo: next, hi: root, arr: A.slice() });
      if (A[next] <= max) break;
      A[root] = A[next];
      steps.push({ kind: 'state', arr: A.slice() });
      root = next;
      do {
        h.mask >>= 1n;
        h.offset++;
      } while (!(h.mask & 1n));
    }
    A[root] = tmp;
    steps.push({ kind: 'state', arr: A.slice() });
    siftIn(A, root, h.offset, steps);
  }

  function heapify(A, num, steps) {
    const hsz = { mask: 1n, offset: 1 };
    steps.push({
      kind: 'caption',
      text: '第1段階: Leonardo ヒープの森を構築中',
      arr: A.slice()
    });
    for (let i = 1; i < num; i++) {
      if (hsz.mask & 2n) {
        hsz.mask = (hsz.mask >> 2n) | 1n;
        hsz.offset += 2;
      } else if (hsz.offset === 1) {
        hsz.mask = (hsz.mask << 1n) | 1n;
        hsz.offset = 0;
      } else {
        hsz.mask = (hsz.mask << BigInt(hsz.offset - 1)) | 1n;
        hsz.offset = 1;
      }
      const wbf =
        (hsz.mask & 2n && i + 1 < num) ||
        (hsz.offset > 0 && BigInt(1 + i + L[hsz.offset - 1]) < BigInt(num));
      if (wbf) siftIn(A, i, hsz.offset, steps);
      else interheapSift(A, i, hsz, steps);
    }
    return hsz;
  }

  function extract(A, num, hsz, steps) {
    steps.push({
      kind: 'caption',
      text: '第2段階: 右端から最大を確定しつつ森を更新',
      arr: A.slice()
    });
    // i=1 はループ外: 森に残る 2 要素は「根が左から右へ非減少」の不変条件で
    // すでに昇順に並んでいるため、追加の sift は要らない。
    for (let i = num - 1; i > 1; i--) {
      if (hsz.offset < 2) {
        do {
          hsz.mask >>= 1n;
          hsz.offset++;
        } while (!(hsz.mask & 1n));
      } else {
        const ch1 = i - 1;
        const ch0 = ch1 - L[hsz.offset - 2];
        hsz.mask &= ~1n;
        for (let j = 0; j < 2; j++) {
          const ch = j === 0 ? ch0 : ch1;
          hsz.mask = (hsz.mask << 1n) | 1n;
          hsz.offset--;
          interheapSift(A, ch, hsz, steps);
        }
      }
    }
  }

  function generateSteps(initial) {
    const A = initial.slice();
    const steps = [];
    const n = A.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: A.slice() });
      return steps;
    }
    const hsz = heapify(A, n, steps);
    extract(A, n, hsz, steps);
    steps.push({ kind: 'done', arr: A.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-smooth',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'スムースソートのデモ（オレンジは比較、更新後の配列を順に表示）',
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
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.hi, 'compare']
        ]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'state') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('値の移動後');
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 240
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="smooth-sort-demo"
  data_prefix="smooth"
  script=sort_demo_js
%}

実装の複雑さと定数倍の大きさから、汎用ライブラリの `sort` として採用されることは稀である。

## 類似アルゴリズムとの相違点

[ヒープソート](/2026/05/04/sort-heap.html)と同様にインプレースで最悪計算量 `O(n log n)` だが、レオナルド木の森により整列済み入力では `O(n)` に近づく適応型ソートである。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000012 |        0.000442 |            1662 |            1668 |
|        512 |        0.000028 |        0.000354 |            1666 |            1672 |
|       1024 |        0.000061 |        0.000355 |            1674 |            1680 |
|       2048 |        0.000130 |        0.000469 |            1689 |            1696 |
|       4096 |        0.000285 |        0.000971 |            1721 |            1728 |
|       8192 |        0.000597 |        0.000918 |            1786 |            1792 |
|      16384 |        0.001261 |        0.002096 |            1918 |            1924 |
|      32768 |        0.002709 |        0.006676 |            2178 |            2184 |
|      65536 |        0.005773 |        0.010908 |            2690 |            2696 |
|     131072 |        0.012651 |        0.017563 |            3714 |            3720 |
|     262144 |        0.027944 |        0.070136 |            5762 |            5768 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="smooth" %}
