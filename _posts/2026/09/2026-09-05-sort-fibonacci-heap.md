---
title:     フィボナッチヒープソートで配列を並び替える
date:      2026-09-05 01:01:45 +0900
tags:      sort
sort_demo: true
---

## フィボナッチヒープソートを使用する

フィボナッチヒープソート (`fibonacci heap sort`) は、要素をフィボナッチヒープへ挿入したあと、最小値を繰り返し取り出して昇順にする整列である。

フィボナッチヒープは、根が最小となる木の森である。各木はヒープ条件（親のキーが子以下）を満たし、根リスト上では同じ次数（子の本数）の木が複数あってもよい。
二項ヒープと違い、挿入や合併では次数をすぐには揃えない。代わりに最小抽出のときに **統合（consolidate）** で同次数の木を結合し、結果として根の次数は高々 1 本になる。
木の形の上限がフィボナッチ数と結びつくためこの名がある。

1.  **挿入**: 各要素を次数 0 の単独の根として根リストへ加える。統合は行わない。償却的に `O(1)`。
2.  **抽出**: 根リストから最小キーの根を外し、その子たちを根リストへ移す。そのあと次数ごとの表で同次数の根を結合（キーの小さい方を親にする）して森を整える。償却的に `O(log n)`。
3.  **書き戻し**: 取り出したキーを配列の先頭から順に書けば昇順になる。

```pseudocode
procedure link(y, x)   // y.key >= x.key
  make y a child of x
  x.degree = x.degree + 1

procedure consolidate(H)
  // 次数 d ごとに高々 1 本の根が残るよう link で畳み込む
  for each root x in H
    while there is another root y with y.degree = x.degree
      if x.key > y.key
        swap x, y
      link(y, x)
  return the new root list

procedure fibonacci_heap_sort(A)
  H = empty fibonacci heap   // 根リスト
  for x in A
    add singleton(x) to root list of H
  for i from 0 to length(A) - 1
    m = minimum root in H
    remove m from root list
    add children of m to root list
    H = consolidate(H)
    A[i] = m.key
```

償却時間計算量は全体で `O(n log n)` であり、節点用に `O(n)` の追加記憶域が要る（インプレースではない）。等値キーの相対順序は結合時の規約に依存し、一般に不安定である。減少キーや削除を多用する優先度付きキューでは償却性能が強みになるが、整列だけなら統合のコストが毎回の抽出に乗り、ポインタ経由の森はキャッシュ効率では配列上の[ヒープソート](/2026/05/04/sort-heap.html)に劣りやすい。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('fibonacci-heap-sort-demo', function (root) {
  function link(child, parent) {
    child.sibling = parent.child;
    parent.child = child;
    parent.degree += 1;
    return parent;
  }

  function rootsToList(head) {
    const roots = [];
    let cur = head;
    while (cur) {
      const next = cur.sibling;
      cur.sibling = null;
      roots.push(cur);
      cur = next;
    }
    return roots;
  }

  function listToRoots(roots) {
    let head = null;
    let prev = null;
    for (const node of roots) {
      node.sibling = null;
      if (!head) head = node;
      else prev.sibling = node;
      prev = node;
    }
    return head;
  }

  function consolidate(head) {
    const roots = rootsToList(head);
    if (!roots.length) return null;
    const degreeTable = [];

    for (let r = 0; r < roots.length; r++) {
      let x = roots[r];
      while (true) {
        const d = x.degree;
        while (degreeTable.length <= d) degreeTable.push(null);
        if (!degreeTable[d]) {
          degreeTable[d] = x;
          break;
        }
        let y = degreeTable[d];
        degreeTable[d] = null;
        if (x.key > y.key) {
          const t = x;
          x = y;
          y = t;
        }
        x = link(y, x);
      }
    }

    const out = [];
    for (let i = 0; i < degreeTable.length; i++) {
      if (degreeTable[i]) out.push(degreeTable[i]);
    }
    return listToRoots(out);
  }

  function insertKey(heap, key, id) {
    const node = {
      key: key,
      id: id,
      degree: 0,
      child: null,
      sibling: null
    };
    node.sibling = heap;
    return node;
  }

  function snapshotNode(node) {
    const children = [];
    let child = node.child;
    while (child) {
      children.push(snapshotNode(child));
      child = child.sibling;
    }
    return {
      id: node.id,
      value: node.key,
      degree: node.degree,
      children: children
    };
  }

  function snapshotForest(head) {
    const roots = [];
    let cur = head;
    while (cur) {
      roots.push(snapshotNode(cur));
      cur = cur.sibling;
    }
    return roots;
  }

  function forestDegrees(head) {
    const deg = [];
    let cur = head;
    while (cur) {
      deg.push(cur.degree);
      cur = cur.sibling;
    }
    return deg;
  }

  function extractMin(heap) {
    if (!heap) {
      return { key: null, id: null, heap: null };
    }
    const roots = rootsToList(heap);
    let minI = 0;
    for (let i = 1; i < roots.length; i++) {
      if (roots[i].key < roots[minI].key) minI = i;
    }
    const minNode = roots.splice(minI, 1).shift();
    const children = rootsToList(minNode.child);
    for (let i = 0; i < children.length; i++) {
      roots.push(children[i]);
    }
    return {
      key: minNode.key,
      id: minNode.id,
      heap: consolidate(listToRoots(roots))
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
        forest: [],
        activeId: null
      });
      return steps;
    }

    let heap = null;

    steps.push({
      kind: 'caption',
      text: '第1段階: 入力を順に根リストへ挿入（この段階では統合しない）',
      arr: vals.slice(),
      sortedUpTo: 0,
      degrees: [],
      forest: [],
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
        degrees: forestDegrees(heap),
        forest: snapshotForest(heap),
        activeId: i
      });
    }

    steps.push({
      kind: 'caption',
      text: '第2段階: 根リストの最小を取り出し、同次数の木を統合する',
      arr: vals.slice(),
      sortedUpTo: 0,
      degrees: forestDegrees(heap),
      forest: snapshotForest(heap),
      activeId: null
    });

    const alive = new Set();
    for (let i = 0; i < n; i++) alive.add(i);
    const sorted = [];

    for (let pos = 0; pos < n; pos++) {
      let minRootId = heap.id;
      let minKey = heap.key;
      let cur = heap.sibling;
      while (cur) {
        if (cur.key < minKey) {
          minKey = cur.key;
          minRootId = cur.id;
        }
        cur = cur.sibling;
      }

      const displayBefore = remainingDisplay(sorted, vals, alive);
      steps.push({
        kind: 'champion',
        winBar: barIndexOfId(sorted.length, alive, minRootId, n),
        winId: minRootId,
        pos: pos,
        arr: displayBefore,
        sortedUpTo: pos,
        degrees: forestDegrees(heap),
        forest: snapshotForest(heap),
        activeId: minRootId
      });

      const ex = extractMin(heap);
      heap = ex.heap;
      alive.delete(ex.id);
      sorted.push(ex.key);

      steps.push({
        kind: 'write',
        pos: pos,
        arr: remainingDisplay(sorted, vals, alive),
        sortedUpTo: pos + 1,
        degrees: forestDegrees(heap),
        forest: snapshotForest(heap),
        activeId: null
      });
    }

    steps.push({
      kind: 'done',
      arr: sorted.slice(),
      sortedUpTo: n,
      degrees: [],
      forest: [],
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

  function degreeText(degrees) {
    if (!degrees || !degrees.length) {
      return '（空の森）';
    }
    return '根の次数: [' + degrees.join(', ') + ']';
  }

  function paintForest(forest, activeId) {
    DemoSort.renderForest(forestView, forest && forest.length ? forest : null, {
      activeId: activeId,
      ariaLabel: '現在のフィボナッチヒープ'
    });
  }

  const forestView = DemoSort.createBinaryTreeView(root, {
    label: '現在のフィボナッチヒープ（青: 根、紫: 注目ノード。数字はキー）',
    emptyText: 'まだフィボナッチヒープは空です'
  });

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-fibonacci-heap',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'フィボナッチヒープソートのデモ（棒の数字が配列、下の数字の木がフィボナッチヒープ）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    afterRebuild: function () {
      paintForest([], null);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'caption') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, []);
        paintForest(s.forest, s.activeId);
        api.setCaption(s.text + ' ' + degreeText(s.degrees));
        return;
      }
      if (s.kind === 'insert') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, 0, [[s.idx, 'key']]);
        paintForest(s.forest, s.activeId);
        api.setCaption(
          '挿入: 位置 ' +
            s.idx +
            ' の値（' +
            s.value +
            '）を根リストへ ' +
            degreeText(s.degrees)
        );
        return;
      }
      if (s.kind === 'champion') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, [[s.winBar, 'cursor']]);
        paintForest(s.forest, s.activeId);
        api.setCaption(
          '根リストの最小（元の位置 ' +
            s.winId +
            '）を出力位置 ' +
            s.pos +
            ' へ ' +
            degreeText(s.degrees)
        );
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, [[s.pos, 'write']]);
        paintForest(s.forest, s.activeId);
        api.setCaption(
          '位置 ' + s.pos + ' を確定（子を根へ移し同次数を統合） ' + degreeText(s.degrees)
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        paintForest(s.forest, null);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="fibonacci-heap-sort-demo"
  data_prefix="fibonacci-heap"
  script=sort_demo_js
%}

優先度付きキューとしてのフィボナッチヒープは、挿入・合併・減少キーが償却的にほぼ定数時間で書ける点が理論上の強みである。整列用途では減少キーを使わず、「すべて挿入してからすべて取り出す」形に固定したものがフィボナッチヒープソートである。

## 類似アルゴリズムとの相違点

[ヒープソート](/2026/05/04/sort-heap.html)は配列上の二分ヒープをインプレースで縮める。フィボナッチヒープはポインタの森で、抽出時の統合が中心になる。

[二項ヒープソート](/2026/08/11/sort-binomial-heap.html)は挿入のたびに同次数を結合する。フィボナッチヒープは挿入を遅延し、抽出時にまとめて統合する。

[ペアリングヒープソート](/2026/09/03/sort-pairing-heap.html)は多分岐木の合併と子の二パス・ペアリングを使う。フィボナッチヒープは次数表による統合で森を整える。

[左傾ヒープソート](/2026/09/04/sort-leftist-heap.html)は単一の二分木とヌルパス長で左傾性を保つ。フィボナッチヒープは複数の根を持つ森である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000067 |        0.000307 |              10 |              10 |
|        512 |        0.000152 |        0.000372 |              20 |              20 |
|       1024 |        0.000337 |        0.000992 |              40 |              40 |
|       2048 |        0.000754 |        0.002167 |              80 |              80 |
|       4096 |        0.001687 |        0.003353 |             160 |             160 |
|       8192 |        0.003736 |        0.008631 |             320 |             320 |
|      16384 |        0.007950 |        0.017043 |             640 |             640 |
|      32768 |        0.017218 |        0.056944 |            1280 |            1280 |
|      65536 |        0.035678 |        0.123685 |            2560 |            2560 |
|     131072 |        0.085601 |        0.420435 |            5120 |            5120 |
|     262144 |        0.193887 |        0.415481 |           10240 |           10240 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="fibonacci_heap" %}
