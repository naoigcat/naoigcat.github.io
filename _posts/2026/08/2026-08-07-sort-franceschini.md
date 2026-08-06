---
title:     フランチェスキーニソートで配列を並び替える
date:      2026-08-07 04:14:18 +0900
tags:      sort
sort_demo: true
---

## フランチェスキーニソートを使用する

フランチェスキーニソート (`Franceschini sort`) は比較回数・要素移動・補助記憶を同時に漸近最適へ近づけるインプレース整列の系統である。

古典的な未解決問題——最悪でも比較 `O(n log n)`・移動 `O(n)`・補助記憶 `O(1)` を両立できるか——に対し、肯定的な構成を与えたことで知られる。

安定版は同値の相対順序も保ちつつ同じ資源境界を狙う。実用上は定数倍と実装の重さからウィキソートやグレイルソートほどは使われないが、理論上の到達点として重要である。

下記のデモと計測コードは、フランチェスキーニソートが提案された論文の骨格を次のように簡略化した版である。

1.  **バッファの切り出し**: 順位おおよそ `n/4` の要素をピボットにし、厳密に小さい要素を先頭へ集める。左側（アクティブ）は約 `n/4`、右側（バッファ）は約 `3n/4` になる。
2.  **バッファ付き部分整列**: アクティブ区間をバッファ先頭と交換し、そこを高い分岐数の d 分木ヒープソートで整える。分岐数をおよそ `n^{1/4}` に取るとヒープの高さが定数に近く、要素あたりの移動が抑えられる。整列後、再び交換してアクティブ位置へ戻す。
3.  **残りへの再帰**: ピボット以上の未整列側へ同じ手順を繰り返す。左はすでに整っており、かつ右のどの要素より小さいので、連結した配列全体が昇順になる。
4.  **小さな入力**: 長さが小さいときは挿入ソート、または同じ d 分木ヒープへフォールバックする。

論文本体では、さらに標本とセグメント構造・ビット符号化（最小／最大要素ブロックの交換でポインタビットを作る）などで移動回数を `O(n)` に押し込む。計測コードはその外側の「四分割＋バッファ＋高分岐ヒープ」までを実装している。

```pseudocode
procedure dary_heap_sort(A)
  d = roughly length(A)^(1/4)
  build_max_heap_with_branching_d(A)
  for end from length(A)-1 down to 1
    swap A[0] with A[end]
    sift_down(A, 0, end-1, d)

procedure sort_with_buffer(Active, Buffer)
  // |Buffer| >= |Active|
  swap Active with Buffer[0 .. |Active|)
  dary_heap_sort(Buffer[0 .. |Active|))
  swap back

procedure franceschini_sort(A)
  n = length(A)
  if n is small then
    insertion_or_dary_heap_sort(A)
    return
  pivot = select_kth(A, floor(n/4))
  split = stable_gather of elements strictly < pivot to the front
  if split = 0 or split > n - split then
    dary_heap_sort(A)
    return
  sort_with_buffer(A[0 .. split), A[split .. n))
  franceschini_sort(A[split .. n))
```

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('franceschini-sort-demo', function (root) {
  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k <= hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function branchFactor(len) {
    if (len <= 2) {
      return 2;
    }
    let d = 2;
    while (d * d * d * d < len && d < 8) {
      d += 1;
    }
    return Math.max(2, d);
  }

  function insertionSortRange(a, lo, hi, steps) {
    for (let i = lo + 1; i <= hi; i++) {
      const key = a[i];
      let j = i;
      steps.push({ kind: 'compare', lo: j - 1, hi: j, arr: a.slice() });
      while (j > lo && a[j - 1] > key) {
        a[j] = a[j - 1];
        j -= 1;
        steps.push({ kind: 'write', pos: j, arr: a.slice() });
      }
      a[j] = key;
      if (j !== i) {
        steps.push({ kind: 'write', pos: j, arr: a.slice() });
      }
    }
  }

  function siftDown(a, root, end, d, base, steps) {
    let r = root;
    for (;;) {
      const first = r * d + 1;
      if (first > end) {
        break;
      }
      let best = first;
      const last = Math.min(first + d - 1, end);
      for (let child = first + 1; child <= last; child++) {
        steps.push({
          kind: 'compare',
          lo: base + child,
          hi: base + best,
          arr: a.slice(),
        });
        if (a[base + child] > a[base + best]) {
          best = child;
        }
      }
      steps.push({
        kind: 'compare',
        lo: base + r,
        hi: base + best,
        arr: a.slice(),
      });
      if (a[base + r] >= a[base + best]) {
        break;
      }
      const tmp = a[base + r];
      a[base + r] = a[base + best];
      a[base + best] = tmp;
      steps.push({
        kind: 'swap',
        lo: base + r,
        hi: base + best,
        arr: a.slice(),
      });
      r = best;
    }
  }

  function daryHeapSortRange(a, lo, hi, steps) {
    const n = hi - lo + 1;
    if (n <= 1) {
      return;
    }
    const d = branchFactor(n);
    steps.push({
      kind: 'phase',
      text: 'd 分木ヒープ構築（分岐数 ' + d + '）: [' + lo + '…' + hi + ']',
      lo: lo,
      hi: hi,
      arr: a.slice(),
    });
    const lastParent = Math.floor((n - 2) / d);
    for (let start = lastParent; start >= 0; start--) {
      siftDown(a, start, n - 1, d, lo, steps);
    }
    for (let end = n - 1; end >= 1; end--) {
      const tmp = a[lo];
      a[lo] = a[lo + end];
      a[lo + end] = tmp;
      steps.push({
        kind: 'swap',
        lo: lo,
        hi: lo + end,
        arr: a.slice(),
      });
      if (end > 1) {
        siftDown(a, 0, end - 1, d, lo, steps);
      }
    }
  }

  function sortWithBuffer(a, activeLo, activeHi, bufLo, steps) {
    const m = activeHi - activeLo + 1;
    steps.push({
      kind: 'phase',
      text:
        'バッファ交換: アクティブ [' +
        activeLo +
        '…' +
        activeHi +
        '] ↔ バッファ [' +
        bufLo +
        '…' +
        (bufLo + m - 1) +
        ']',
      lo: activeLo,
      hi: bufLo + m - 1,
      arr: a.slice(),
    });
    for (let i = 0; i < m; i++) {
      const tmp = a[activeLo + i];
      a[activeLo + i] = a[bufLo + i];
      a[bufLo + i] = tmp;
      steps.push({
        kind: 'swap',
        lo: activeLo + i,
        hi: bufLo + i,
        arr: a.slice(),
      });
    }
    if (m <= 4) {
      insertionSortRange(a, bufLo, bufLo + m - 1, steps);
    } else {
      daryHeapSortRange(a, bufLo, bufLo + m - 1, steps);
    }
    steps.push({
      kind: 'phase',
      text: '整列結果をアクティブ位置へ戻す',
      lo: activeLo,
      hi: bufLo + m - 1,
      arr: a.slice(),
    });
    for (let i = 0; i < m; i++) {
      const tmp = a[activeLo + i];
      a[activeLo + i] = a[bufLo + i];
      a[bufLo + i] = tmp;
      steps.push({
        kind: 'swap',
        lo: activeLo + i,
        hi: bufLo + i,
        arr: a.slice(),
      });
    }
    steps.push({
      kind: 'sorted_prefix',
      lo: activeLo,
      hi: activeHi,
      arr: a.slice(),
    });
  }

  function selectKth(a, left, right, k, steps) {
    while (left < right) {
      let lo = left;
      let hi = right;
      const mid = lo + Math.floor((hi - lo) / 2);
      if (a[hi] < a[lo]) {
        const t = a[lo];
        a[lo] = a[hi];
        a[hi] = t;
        steps.push({ kind: 'swap', lo: lo, hi: hi, arr: a.slice() });
      }
      if (a[mid] < a[lo]) {
        const t = a[lo];
        a[lo] = a[mid];
        a[mid] = t;
        steps.push({ kind: 'swap', lo: lo, hi: mid, arr: a.slice() });
      }
      if (a[hi] < a[mid]) {
        const t = a[mid];
        a[mid] = a[hi];
        a[hi] = t;
        steps.push({ kind: 'swap', lo: mid, hi: hi, arr: a.slice() });
      }
      const pivotIndex = mid;
      {
        const t = a[pivotIndex];
        a[pivotIndex] = a[hi];
        a[hi] = t;
      }
      steps.push({ kind: 'swap', lo: pivotIndex, hi: hi, arr: a.slice() });
      const pivot = a[hi];
      let store = left;
      for (let i = left; i < hi; i++) {
        steps.push({ kind: 'compare', lo: i, hi: hi, arr: a.slice() });
        if (a[i] < pivot) {
          const t = a[store];
          a[store] = a[i];
          a[i] = t;
          if (store !== i) {
            steps.push({ kind: 'swap', lo: store, hi: i, arr: a.slice() });
          }
          store += 1;
        }
      }
      {
        const t = a[store];
        a[store] = a[hi];
        a[hi] = t;
        steps.push({ kind: 'swap', lo: store, hi: hi, arr: a.slice() });
      }
      if (k === store) {
        return;
      }
      if (k < store) {
        right = store - 1;
      } else {
        left = store + 1;
      }
    }
  }

  function franceschiniRec(a, lo, hi, steps) {
    const n = hi - lo + 1;
    if (n <= 1) {
      return;
    }
    if (n <= 6) {
      steps.push({
        kind: 'phase',
        text: '小さな区間を挿入ソート: [' + lo + '…' + hi + ']',
        lo: lo,
        hi: hi,
        arr: a.slice(),
      });
      insertionSortRange(a, lo, hi, steps);
      steps.push({ kind: 'sorted_prefix', lo: lo, hi: hi, arr: a.slice() });
      return;
    }

    const rank = Math.floor(n / 4);
    steps.push({
      kind: 'phase',
      text:
        '順位 ' +
        rank +
        '（区間長 ' +
        n +
        ' の約 1/4）のピボットを選択: [' +
        lo +
        '…' +
        hi +
        ']',
      lo: lo,
      hi: hi,
      arr: a.slice(),
    });
    selectKth(a, lo, hi, lo + rank, steps);
    const pivot = a[lo + rank];
    steps.push({
      kind: 'pivot',
      pos: lo + rank,
      value: pivot,
      arr: a.slice(),
    });

    let split = lo;
    for (let i = lo; i <= hi; i++) {
      steps.push({ kind: 'compare', lo: i, hi: lo + rank, arr: a.slice() });
      if (a[i] < pivot) {
        if (split !== i) {
          const t = a[split];
          a[split] = a[i];
          a[i] = t;
          steps.push({ kind: 'swap', lo: split, hi: i, arr: a.slice() });
        }
        split += 1;
      }
    }

    const activeLen = split - lo;
    const bufLen = hi - split + 1;
    steps.push({
      kind: 'partition_done',
      lo: lo,
      split: split,
      hi: hi,
      pivot: pivot,
      arr: a.slice(),
    });

    if (activeLen === 0 || activeLen > bufLen) {
      steps.push({
        kind: 'phase',
        text: 'バッファ不足のため区間全体を d 分木ヒープソート',
        lo: lo,
        hi: hi,
        arr: a.slice(),
      });
      daryHeapSortRange(a, lo, hi, steps);
      steps.push({ kind: 'sorted_prefix', lo: lo, hi: hi, arr: a.slice() });
      return;
    }

    sortWithBuffer(a, lo, split - 1, split, steps);
    franceschiniRec(a, split, hi, steps);
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length === 0) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }
    franceschiniRec(a, 0, a.length - 1, steps);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-franceschini',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'フランチェスキーニソートのデモ（四分割・バッファ交換・d 分木ヒープ；比較はオレンジ）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        if (typeof s.lo === 'number' && typeof s.hi === 'number') {
          DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        } else {
          DemoSort.clearRoles(barsEl);
        }
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'pivot') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'pivot']]);
        api.setCaption('ピボット確定: 位置 ' + s.pos + ' の値 ' + s.value);
        return;
      }
      if (s.kind === 'partition_done') {
        api.mountBars(barsEl, s.arr);
        const pairs = rangePairs(s.lo, s.split - 1, 'range').concat(
          rangePairs(s.split, s.hi, 'heap')
        );
        DemoSort.assignRoles(barsEl, pairs);
        api.setCaption(
          '分割完了: アクティブ [' +
            s.lo +
            '…' +
            (s.split - 1) +
            ']（<' +
            s.pivot +
            '）、バッファ [' +
            s.split +
            '…' +
            s.hi +
            ']'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'swap') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption('交換: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption('書き込み: 位置 ' + s.pos);
        return;
      }
      if (s.kind === 'sorted_prefix') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'sorted'));
        api.setCaption('整列済み接頭辞: [' + s.lo + '…' + s.hi + ']');
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 200,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="franceschini-sort-demo"
  data_prefix="franceschini"
  script=sort_demo_js
%}

デモでは小さな配列向けに分岐数と閾値を下げている。本番の計測コードはより大きい入力で同じ骨格を動かす。

## 類似アルゴリズムとの相違点

[ウィキソート](/2026/05/31/sort-wiki.html)・[グレイルソート](/2026/06/01/sort-grail.html)・[コタソート](/2026/06/07/sort-kota.html)も原地安定な `O(n log n)` を狙うブロックマージ系だが、内部バッファやキータグで隣接ランを併合する。フランチェスキーニソートは順位分割でバッファ領域を切り出し、高分岐ヒープなどで移動回数そのものを漸近的に減らす点が異なる。

[ヒープソート](/2026/05/04/sort-heap.html)の二分ヒープは移動が `Θ(n log n)` になりやすい。こちらは分岐数を大きくして高さを抑え、論文の「移動 `O(n)`」側の直感に寄せている。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000009 |        0.000053 |              70 |              76 |
|        512 |        0.000020 |        0.000071 |              58 |              64 |
|       1024 |        0.000040 |        0.000103 |              66 |              72 |
|       2048 |        0.000091 |        0.000353 |              74 |              80 |
|       4096 |        0.000185 |        0.000335 |              62 |              68 |
|       8192 |        0.000426 |        0.004516 |              74 |              80 |
|      16384 |        0.000959 |        0.005731 |              62 |              68 |
|      32768 |        0.002238 |        0.014780 |              58 |              64 |
|      65536 |        0.005032 |        0.013629 |              78 |              84 |
|     131072 |        0.011317 |        0.035816 |              74 |              80 |
|     262144 |        0.025697 |        0.048032 |              57 |              64 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="franceschini" %}
