---
title:     左傾ヒープソートで配列を並び替える
date:      2026-09-04 05:40:30 +0900
tags:      sort
sort_demo: true
---

## 左傾ヒープソートを使用する

左傾ヒープソート (`leftist heap sort`) は、要素を左傾ヒープへ挿入したあと、最小値を繰り返し取り出して昇順にする整列である。

左傾ヒープは、根が最小（または最大）となる二分木である。ヒープ条件に加え、各節点の **ヌルパス長**（`null path length`, NPL）について左子の方が右子以上になるよう子を並べ替える（左傾性）。
NPL は「その節点から右の子だけを辿って最初の欠損に至るまでの辺数」で、葉は `0`、空木は `-1` とおく。右背骨の長さは `O(log n)` に抑えられ、合併が右背骨に沿って進むため速い。

1.  **合併**: 2 本のヒープの根を比較し、キーの大きい方を小さい方の右部分木と再帰的に合併する。
    終わったら左右の NPL を見て、左傾性が崩れていれば左右を入れ替え、根の NPL を「右子の NPL + 1」に更新する。最悪 `O(log n)`。
2.  **挿入**: 単一節点のヒープを既存ヒープと合併する。
3.  **抽出**: 根を外し、左右の子ヒープを合併して新しい根を得る。最悪 `O(log n)`。
4.  **書き戻し**: 取り出したキーを配列の先頭から順に書けば昇順になる。

```pseudocode
procedure npl(H)
  if H is empty
    return -1
  return H.npl

procedure merge(H1, H2)
  if H1 is empty
    return H2
  if H2 is empty
    return H1
  if H1.key > H2.key
    swap H1, H2
  H1.right = merge(H1.right, H2)
  if npl(H1.left) < npl(H1.right)
    swap H1.left, H1.right
  H1.npl = npl(H1.right) + 1
  return H1

procedure leftist_heap_sort(A)
  H = empty leftist heap
  for x in A
    H = merge(H, singleton(x))
  for i from 0 to length(A) - 1
    A[i] = H.key
    H = merge(H.left, H.right)
```

最悪時間計算量は `O(n log n)` であり、節点用に `O(n)` の追加記憶域が要る（インプレースではない）。等値キーの相対順序は合併時の規約に依存し、一般に不安定である。実装は二分木の合併として素直だが、ポインタ経由の木はキャッシュ効率では配列上の[ヒープソート](/2026/05/04/sort-heap.html)に劣りやすい。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('leftist-heap-sort-demo', function (root) {
  function npl(node) {
    return node ? node.npl : -1;
  }

  function merge(a, b) {
    if (!a) return b;
    if (!b) return a;
    let x = a;
    let y = b;
    if (x.key > y.key) {
      const t = x;
      x = y;
      y = t;
    }
    x.right = merge(x.right, y);
    if (npl(x.left) < npl(x.right)) {
      const t = x.left;
      x.left = x.right;
      x.right = t;
    }
    x.npl = npl(x.right) + 1;
    return x;
  }

  function insertKey(heap, key, id) {
    const node = {
      key: key,
      id: id,
      npl: 0,
      left: null,
      right: null
    };
    return merge(heap, node);
  }

  function snapshotNode(node) {
    if (!node) return null;
    return {
      id: node.id,
      value: node.key,
      npl: node.npl,
      left: snapshotNode(node.left),
      right: snapshotNode(node.right)
    };
  }

  function remainingDisplay(sorted, vals, alive) {
    const suffix = [];
    for (let idx = 0; idx < vals.length; idx++) {
      if (alive.has(idx)) suffix.push(vals[idx]);
    }
    return sorted.concat(suffix);
  }

  function barIndexOfId(sortedLen, alive, targetId, n) {
    let hi = sortedLen;
    for (let idx = 0; idx < n; idx++) {
      if (!alive.has(idx)) continue;
      if (idx === targetId) return hi;
      hi += 1;
    }
    return hi;
  }

  function generateSteps(vals) {
    const steps = [];
    const n = vals.length;
    if (n <= 1) {
      steps.push({
        kind: 'done',
        arr: vals.slice(),
        sortedUpTo: n,
        tree: null,
        activeId: null
      });
      return steps;
    }

    let heap = null;

    steps.push({
      kind: 'caption',
      text: '第1段階: 入力を順に左傾ヒープへ挿入（単一節点と合併）',
      arr: vals.slice(),
      sortedUpTo: 0,
      tree: null,
      activeId: null
    });

    for (let i = 0; i < n; i++) {
      heap = insertKey(heap, vals[i], i);
      steps.push({
        kind: 'insert',
        idx: i,
        value: vals[i],
        arr: vals.slice(),
        sortedUpTo: 0,
        tree: snapshotNode(heap),
        activeId: i
      });
    }

    steps.push({
      kind: 'caption',
      text: '第2段階: 根（最小）を外し、左右の子を合併して再構築',
      arr: vals.slice(),
      sortedUpTo: 0,
      tree: snapshotNode(heap),
      activeId: heap ? heap.id : null
    });

    const alive = new Set();
    for (let i = 0; i < n; i++) alive.add(i);
    const sorted = [];

    for (let pos = 0; pos < n; pos++) {
      const winId = heap.id;
      const displayBefore = remainingDisplay(sorted, vals, alive);
      steps.push({
        kind: 'champion',
        winBar: barIndexOfId(sorted.length, alive, winId, n),
        winId: winId,
        pos: pos,
        arr: displayBefore,
        sortedUpTo: pos,
        tree: snapshotNode(heap),
        activeId: winId
      });

      const left = heap.left;
      const right = heap.right;
      const key = heap.key;
      alive.delete(winId);
      sorted.push(key);
      const displayAfter = remainingDisplay(sorted, vals, alive);

      heap = merge(left, right);

      steps.push({
        kind: 'write',
        pos: pos,
        arr: displayAfter,
        sortedUpTo: pos + 1,
        tree: snapshotNode(heap),
        activeId: heap ? heap.id : null
      });
    }

    steps.push({
      kind: 'done',
      arr: sorted.slice(),
      sortedUpTo: n,
      tree: null,
      activeId: null
    });
    return steps;
  }

  function paint(container, sortedUpTo, pairs) {
    const all = [];
    for (let k = 0; k < sortedUpTo; k++) {
      all.push([k, 'sorted']);
    }
    for (const pair of pairs) {
      all.push(pair);
    }
    DemoSort.assignRoles(container, all);
  }

  function paintTree(tree, activeId) {
    DemoSort.renderBinaryTree(treeView, tree, {
      activeId: activeId,
      ariaLabel: '現在の左傾ヒープ'
    });
  }

  const treeView = DemoSort.createBinaryTreeView(root, {
    label: '現在の左傾ヒープ（青: 根、紫: 注目ノード。数字はキー）',
    emptyText: 'まだ左傾ヒープは空です'
  });

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-leftist-heap',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '左傾ヒープソートのデモ（棒の数字が配列、下の数字の木が左傾ヒープ）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    afterRebuild: function () {
      paintTree(null, null);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'caption') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, []);
        paintTree(s.tree, s.activeId);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'insert') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, 0, [[s.idx, 'key']]);
        paintTree(s.tree, s.activeId);
        api.setCaption(
          '挿入: 位置 ' + s.idx + ' の値（' + s.value + '）を合併'
        );
        return;
      }
      if (s.kind === 'champion') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, [[s.winBar, 'cursor']]);
        paintTree(s.tree, s.activeId);
        api.setCaption(
          '根の最小（元の位置 ' +
            s.winId +
            '）を出力位置 ' +
            s.pos +
            ' へ'
        );
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, [[s.pos, 'write']]);
        paintTree(s.tree, s.activeId);
        api.setCaption(
          '位置 ' + s.pos + ' を確定（左右の子を合併して再構築）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        paintTree(s.tree, null);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="leftist-heap-sort-demo"
  data_prefix="leftist-heap"
  script=sort_demo_js
%}

優先度付きキューとしての左傾ヒープは、合併を右背骨に沿って書ける点が二項ヒープより単純で、フィボナッチヒープほど複雑な遅延操作も要らない。整列用途ではその操作を「すべて挿入してからすべて取り出す」形に固定したものが左傾ヒープソートである。

## 類似アルゴリズムとの相違点

[ヒープソート](/2026/05/04/sort-heap.html)は配列上の二分ヒープをインプレースで縮める。左傾ヒープはポインタの二分木で、合併と左傾性の修復が中心になる。

[二項ヒープソート](/2026/08/11/sort-binomial-heap.html)は次数の異なる二項木を二進加算のように結合する。左傾ヒープは単一の二分木を保ち、NPL で右背骨の高さを抑える。

[ペアリングヒープソート](/2026/09/03/sort-pairing-heap.html)は多分岐木の合併と子の二パス・ペアリングを使う。左傾ヒープは常に二分木で、合併は右背骨の再帰である。

[弱ヒープソート](/2026/08/28/sort-weak-heap.html)は配列上の不完全木と逆ビットで比較回数を抑える。ヒープ同士の合併を第一級には扱わない。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000018 |        0.000194 |               8 |               8 |
|        512 |        0.000040 |        0.000261 |              16 |              16 |
|       1024 |        0.000086 |        0.000288 |              32 |              32 |
|       2048 |        0.000189 |        0.000407 |              64 |              64 |
|       4096 |        0.000424 |        0.001954 |             128 |             128 |
|       8192 |        0.000960 |        0.001728 |             256 |             256 |
|      16384 |        0.002188 |        0.004864 |             512 |             512 |
|      32768 |        0.005174 |        0.121067 |            1024 |            1024 |
|      65536 |        0.012176 |        0.046988 |            2048 |            2048 |
|     131072 |        0.032271 |        0.094475 |            4096 |            4096 |
|     262144 |        0.087888 |        0.504213 |            8192 |            8192 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="leftist_heap" %}
