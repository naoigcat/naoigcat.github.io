---
title:     弱ヒープソートで配列を並び替える
date:      2026-08-28 23:11:26 +0900
tags:      sort
sort_demo: true
---

## 弱ヒープソートを使用する

弱ヒープソート (`weak-heap sort`) は、配列を弱ヒープ（`weak heap`）に整えたあと、根（最大値）と末尾を入れ替えてヒープを縮めていく整列である。
手順は[ヒープソート](/2026/05/04/sort-heap.html)と同じだが、二分ヒープより緩い順序条件と、左右の子の役割を示す逆ビット（`reverse bit`）を使う点が異なる。

弱ヒープを二分木として見ると次を満たし、この記事では根が最大となる最大ヒープ形となるように構築する。

1.  **根は左の子を持たない**（右の子だけを持つ）。
2.  **各節点の値は、その右部分木に属するすべての値以上**である（左の子側＝兄弟列には直接の大小を課さない）。
3.  葉は最下層かそのひとつ上にだけ現れる（完全二分木と同じ配置）。

配列表現では、節点 `i` の逆ビット `r[i]` が「左の子」と「右の子」のどちらを `2i` / `2i+1` に割り当てるかを決める。`r[i] = 0` なら左の子は `2i`、右の子は `2i+1`、`r[i] = 1` なら入れ替わる。根（`i = 0`）は常に右の子 `1` だけを見る。

多分岐ヒープとして見ると、右の子は「最初の子」、左の子は「次の兄弟」に対応し、二項ヒープの木を 1 本の不完全木にまとめた形になる。ある節点 `j` の多分岐上の親を**区別祖先**（`distinguished ancestor`）と呼び、ヒープ条件は「区別祖先の値が `j` の値以上」に落ちる。

1.  **構築**: 逆ビットをすべて 0 にし、末尾から 1 まで各節点 `j` をその区別祖先と **結合** する。結合は 1 回の比較で、子の方が大きければ交換し、子側の逆ビットを反転する。全体でちょうど `n - 1` 回の比較で弱ヒープになる。
2.  **抽出**: 根とヒープ末尾を交換して最大値を確定する。
3.  **沈降**: 新しい根について、右部分木の左背骨を葉まで下り、そこから親へ遡りながら根と結合を繰り返す。二分ヒープの沈降が各段で最大 2 比較なのに対し、弱ヒープでは高さぶんの比較で足りる。
4.  **反復**: ヒープ長が 2 になるまで手順 2〜3 を繰り返し、最後に残った 2 要素を入れ替えて昇順を完成する。

```pseudocode
procedure distinguished_ancestor(r, j)
  while (j & 1) = r[j >> 1]
    j = j >> 1
  return j >> 1

procedure join(A, r, i, j)   // i は区別祖先、最大ヒープ
  if A[i] < A[j]
    flip r[j]
    swap A[i], A[j]

procedure weak_heap_sort(A)
  n = length(A)
  r[0..n) = 0
  for j from n - 1 down to 1
    join(A, r, distinguished_ancestor(r, j), j)
  for end from n - 1 down to 2
    swap A[0], A[end]
    x = 1                         // 根の右の子
    while 2 * x + r[x] < end      // 右部分木の左背骨を下る
      x = 2 * x + r[x]
    while x > 0
      join(A, r, 0, x)
      x = x >> 1
  swap A[0], A[1]
```

最悪時間計算量は `O(n log n)` である。構築は `n - 1` 比較、抽出フェーズの比較回数はおよそ `n ⌈log₂ n⌉` 前後に抑えられ、通常のヒープソート（沈降で最大約 `2 n log n` 比較）より比較が少なくなりやすい。
逆ビットに `O(n)` ビットの追加領域が要る（厳密なインプレースではない）。等値の扱いは結合時の規約依存で、一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('weak-heap-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    const r = new Array(n).fill(0);

    function getFlag(x) {
      return r[x];
    }

    function flipFlag(x) {
      r[x] ^= 1;
    }

    function distinguishedAncestor(j) {
      while ((j & 1) === getFlag(j >> 1)) {
        j >>= 1;
      }
      return j >> 1;
    }

    function join(i, j, phase, sortedFrom, heapEnd) {
      steps.push({
        kind: 'compare',
        lo: i,
        hi: j,
        arr: a.slice(),
        phase: phase,
        sortedFrom: sortedFrom,
        heapEnd: heapEnd,
      });
      if (a[i] < a[j]) {
        flipFlag(j);
        steps.push({
          kind: 'swap',
          lo: i,
          hi: j,
          arr: a.slice(),
          phase: phase,
          sortedFrom: sortedFrom,
          heapEnd: heapEnd,
          flipped: j,
        });
        const t = a[i];
        a[i] = a[j];
        a[j] = t;
      }
    }

    steps.push({
      kind: 'caption',
      text: '弱ヒープを構築: 各節点を区別祖先と結合（比較 1 回）',
      arr: a.slice(),
      sortedFrom: null,
    });

    for (let j = n - 1; j >= 1; j--) {
      const g = distinguishedAncestor(j);
      join(g, j, 'build', null, n);
    }

    for (let end = n - 1; end >= 2; end--) {
      steps.push({
        kind: 'swap',
        lo: 0,
        hi: end,
        arr: a.slice(),
        phase: 'extract',
        sortedFrom: end + 1,
        heapEnd: end + 1,
        rootSwap: true,
        markSortedBeforeSwap: end + 1,
        markSortedAfterSwap: end,
      });
      const t = a[0];
      a[0] = a[end];
      a[end] = t;

      let x = 1;
      while (2 * x + getFlag(x) < end) {
        x = 2 * x + getFlag(x);
      }
      steps.push({
        kind: 'caption',
        text: '右部分木の左背骨の先端（位置 ' + x + '）から根へ結合で沈降',
        arr: a.slice(),
        sortedFrom: end,
      });
      while (x > 0) {
        join(0, x, 'extract', end, end);
        x >>= 1;
      }
      steps.push({
        kind: 'sorted_tick',
        arr: a.slice(),
        sortedFrom: end,
        heapEnd: end,
      });
    }

    steps.push({
      kind: 'swap',
      lo: 0,
      hi: 1,
      arr: a.slice(),
      phase: 'extract',
      sortedFrom: 2,
      heapEnd: 2,
      rootSwap: true,
      markSortedBeforeSwap: 2,
      markSortedAfterSwap: 1,
    });
    const t = a[0];
    a[0] = a[1];
    a[1] = t;

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function paintSortedSuffix(container, sortedFrom) {
    const pairs = [];
    if (sortedFrom != null) {
      for (let i = sortedFrom; i < container.children.length; i++) {
        pairs.push([i, 'sorted']);
      }
    }
    DemoSort.assignRoles(container, pairs);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-weak-heap',
    initialValues: [8, 7, 4, 5, 2, 6, 9, 3, 11, 1],
    initialCaption:
      '弱ヒープソートのデモ（比較はオレンジ、交換は緑、ソート済み領域は紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    afterRebuild: function (api) {
      DemoSort.clearRoles(api.barsEl);
    },
    shuffleWhen: function (st) {
      return !st.playing && !st.busy;
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'caption') {
        api.mountBars(barsEl, s.arr);
        paintSortedSuffix(barsEl, s.sortedFrom);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintSortedSuffix(barsEl, s.sortedFrom);
        DemoSort.assignRoles(
          barsEl,
          [
            [s.lo, 'compare'],
            [s.hi, 'compare'],
          ],
          { preserve: ['sorted'] }
        );
        const ph =
          s.phase === 'build' ? '（構築）' : '（抽出後の沈降）';
        api.setCaption(
          '結合' + ph + ': 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
        );
        return;
      }
      if (s.kind === 'swap') {
        if (s.phase === 'extract' && s.rootSwap) {
          paintSortedSuffix(barsEl, s.markSortedBeforeSwap);
        } else {
          paintSortedSuffix(barsEl, s.sortedFrom);
        }
        DemoSort.assignRoles(
          barsEl,
          [
            [s.lo, 'swap'],
            [s.hi, 'swap'],
          ],
          { preserve: ['sorted'] }
        );
        let msg = s.rootSwap
          ? '根と末尾を交換しています…'
          : '結合: 大きい方を区別祖先側へ上げています…';
        if (s.flipped != null) {
          msg += '（位置 ' + s.flipped + ' の逆ビットを反転）';
        }
        api.setCaption(msg);
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        if (s.phase === 'extract' && s.rootSwap) {
          paintSortedSuffix(barsEl, s.markSortedAfterSwap);
        } else {
          paintSortedSuffix(barsEl, s.sortedFrom);
        }
        api.setCaption('交換しました（位置 ' + s.lo + ' と ' + s.hi + '）');
        return;
      }
      if (s.kind === 'sorted_tick') {
        api.mountBars(barsEl, s.arr);
        paintSortedSuffix(barsEl, s.sortedFrom);
        api.setCaption(
          '位置 ' + s.sortedFrom + ' 以降を確定（ソート済み）'
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
  id="weak-heap-sort-demo"
  data_prefix="weak-heap"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ヒープソート](/2026/05/04/sort-heap.html)は親子両方にヒープ条件を課し、沈降で最大 2 比較／段を使う。弱ヒープは右部分木だけに大小を課し、逆ビットで左右を入れ替えられるため、沈降の比較回数をおよそ半分に近づけられる。

[二項ヒープソート](/2026/08/11/sort-binomial-heap.html)は次数の異なる二項木の森として合併する。完全な弱ヒープ（要素数 `2^k`）は単一の二項木と同型だが、弱ヒープは不完全な 1 本の木のまま扱う。

[トーナメントソート](/2026/05/26/sort-tournament.html)や[敗者木ソート](/2026/08/26/sort-loser-tree.html)は比較結果を木に蓄えて最小を繰り返し取り出す方式で、配列上の弱ヒープ構築＋末尾確定とは手順が異なる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000011 |        0.000127 |               0 |               0 |
|        512 |        0.000025 |        0.007365 |               0 |               0 |
|       1024 |        0.000051 |        0.000589 |               0 |               0 |
|       2048 |        0.000109 |        0.000357 |               0 |               0 |
|       4096 |        0.000233 |        0.010780 |               0 |               0 |
|       8192 |        0.000514 |        0.001743 |               1 |               1 |
|      16384 |        0.001121 |        0.008392 |               2 |               2 |
|      32768 |        0.002406 |        0.008379 |               4 |               4 |
|      65536 |        0.005158 |        0.007401 |               8 |               8 |
|     131072 |        0.011057 |        0.016855 |              16 |              16 |
|     262144 |        0.023785 |        0.097358 |              32 |              32 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="weak_heap" %}
