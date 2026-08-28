---
title:     二項ヒープソートで配列を並び替える
date:      2026-08-11 12:40:12 +0900
tags:      sort
sort_demo: true
---

## 二項ヒープソートを使用する

二項ヒープソート (`binomial heap sort`) は、要素を二項ヒープへ挿入したあと、最小値を繰り返し取り出して昇順にする整列である。

二項ヒープは、次数（階数）の異なる二項木を根リストとして並べた森である。次数 `k` の二項木 `B_k` はちょうど `2^k` 個の節点を持ち、根の子として `B_{k-1}, B_{k-2}, …, B_0` が並ぶ。各木はヒープ条件（親のキーが子以下）を満たし、根リスト上では同じ次数の木は高々 1 本になるよう、マージ時に二進加算と同じ要領で結合する。

1.  **挿入**: 各要素を次数 0 の木としてヒープへ加え、同じ次数の根があればキーの小さい方を親にして結合する。挿入 1 回は `O(log n)`、全体で `O(n log n)`。
2.  **抽出**: 根リストから最小キーの根を外し、その子たちを逆順につないで別ヒープとみなし、残りと合併する。最小を 1 つ得るたびに `O(log n)`、`n` 回で `O(n log n)`。
3.  **書き戻し**: 取り出したキーを配列の先頭から順に書けば昇順になる。

```pseudocode
procedure link(y, z)
  // y.degree = z.degree かつ z.key <= y.key のとき、y を z の最左の子にする
  make y the leftmost child of z
  z.degree = z.degree + 1

procedure merge_roots(H1, H2)
  return root lists of H1 and H2 merged by increasing degree

procedure union(H1, H2)
  H = merge_roots(H1, H2)
  // 同じ次数が隣り合う根を link で畳み込み（二進加算の繰り上がり）
  consolidate equal-degree roots in H
  return H

procedure binomial_heap_sort(A)
  H = empty binomial heap
  for x in A
    H = union(H, singleton_tree(x))
  for i from 0 to length(A) - 1
    (min, H) = extract_min(H)
    A[i] = min
```

最悪時間計算量は `O(n log n)` で、節点用に `O(n)` の追加記憶域が要る（インプレースではない）。等値キーの相対順序は結合時の規約に依存し、一般に不安定である。二分ヒープを配列上で動かす[ヒープソート](/2026/05/04/sort-heap.html)と比べ、ポインタ経由の合併はキャッシュ効率で劣りやすい一方、ヒープ同士の合併が自然に書ける点が優先度付きキューとしての強みになる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('binomial-heap-sort-demo', function (root) {
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

  function mergeRootLists(a, b) {
    const merged = [];
    let x = a;
    let y = b;
    while (x && y) {
      if (x.degree <= y.degree) {
        const n = x;
        x = x.sibling;
        n.sibling = null;
        merged.push(n);
      } else {
        const n = y;
        y = y.sibling;
        n.sibling = null;
        merged.push(n);
      }
    }
    while (x) {
      const n = x;
      x = x.sibling;
      n.sibling = null;
      merged.push(n);
    }
    while (y) {
      const n = y;
      y = y.sibling;
      n.sibling = null;
      merged.push(n);
    }
    return listToRoots(merged);
  }

  function consolidate(head) {
    const roots = rootsToList(head);
    let i = 0;
    while (i + 1 < roots.length) {
      if (roots[i].degree !== roots[i + 1].degree) {
        i += 1;
        continue;
      }
      if (
        i + 2 < roots.length &&
        roots[i + 2].degree === roots[i].degree
      ) {
        i += 1;
        continue;
      }
      const a = roots.splice(i, 1).shift();
      const b = roots.splice(i, 1).shift();
      const linked = a.key <= b.key ? link(b, a) : link(a, b);
      roots.splice(i, 0, linked);
    }
    return listToRoots(roots);
  }

  function union(h1, h2) {
    return consolidate(mergeRootLists(h1, h2));
  }

  function insertKey(heap, key, id) {
    const node = {
      key: key,
      id: id,
      degree: 0,
      child: null,
      sibling: null
    };
    return union(heap, node);
  }

  function reverseChildren(child) {
    let rev = null;
    let cur = child;
    while (cur) {
      const next = cur.sibling;
      cur.sibling = rev;
      rev = cur;
      cur = next;
    }
    return rev;
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
    const children = reverseChildren(minNode.child);
    return {
      key: minNode.key,
      id: minNode.id,
      heap: union(listToRoots(roots), children)
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
      text: '第1段階: 入力を順に二項ヒープへ挿入（同次数の根は link で結合）',
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
      text: '第2段階: 根リストの最小を繰り返し取り出して昇順へ書き出す',
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
      ariaLabel: '現在の二項ヒープ'
    });
  }

  const forestView = DemoSort.createBinaryTreeView(root, {
    label: '現在の二項ヒープ（青: 根、紫: 注目ノード。数字はキー）',
    emptyText: 'まだ二項ヒープは空です'
  });

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-binomial-heap',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '二項ヒープソートのデモ（棒の数字が配列、下の数字の木が二項ヒープ）',
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
            '） ' +
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
          '位置 ' + s.pos + ' を確定 ' + degreeText(s.degrees)
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
  id="binomial-heap-sort-demo"
  data_prefix="binomial-heap"
  script=sort_demo_js
%}

優先度付きキューとして二項ヒープを使う場面では、複数ヒープの合併が二進数の加算に対応する点がそのままアルゴリズムの骨格になる。整列用途ではその合併を「すべて挿入してからすべて取り出す」形に固定したものが二項ヒープソートである。

## 類似アルゴリズムとの相違点

[ヒープソート](/2026/05/04/sort-heap.html)は配列上の二分ヒープをインプレースで縮める。

[トーナメントソート](/2026/05/26/sort-tournament.html)も最小を繰り返し取り出すが、固定長のトーナメント木を更新する。

[二分木ソート](/2026/05/12/sort-tree.html)は探索木への挿入と中順走査で、ヒープ条件ではなく探索木条件を使う。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000137 |        0.002817 |               8 |               8 |
|        512 |        0.000270 |        0.000577 |              16 |              16 |
|       1024 |        0.000644 |        0.001087 |              32 |              32 |
|       2048 |        0.001387 |        0.002225 |              64 |              64 |
|       4096 |        0.003125 |        0.005242 |             128 |             128 |
|       8192 |        0.006309 |        0.009868 |             256 |             256 |
|      16384 |        0.013944 |        0.027110 |             512 |             512 |
|      32768 |        0.027132 |        0.071452 |            1024 |            1024 |
|      65536 |        0.066323 |        0.117900 |            2048 |            2048 |
|     131072 |        0.146329 |        0.252688 |            4096 |            4096 |
|     262144 |        0.261555 |        1.349849 |            8192 |            8192 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="binomial_heap" %}
