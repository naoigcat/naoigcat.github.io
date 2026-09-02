---
title:     ペアリングヒープソートで配列を並び替える
date:      2026-09-03 05:33:28 +0900
tags:      sort
sort_demo: true
---

## ペアリングヒープソートを使用する

ペアリングヒープソート (`pairing heap sort`) は、要素をペアリングヒープへ挿入したあと、最小値を繰り返し取り出して昇順にする整列である。

ペアリングヒープは、根が最小（または最大）となる多分岐木である。子は左子・右兄弟形式で並べ、ヒープ条件は「親のキーはどの子のキー以下」だけを課す。二項ヒープのように次数を揃えたり、フィボナッチヒープのようにランクを管理したりしない代わりに、**合併** と **子のペアリング** で構造を保つ。

1.  **合併**: 2 本のヒープの根を比較し、キーの大きい方を小さい方の最左の子にする。比較は 1 回で、償却的に `O(1)`。
2.  **挿入**: 単一節点のヒープを既存ヒープと合併する。
3.  **抽出**: 根を外し、その子たちを左から 2 本ずつ合併（第 1 パス）したあと、できたヒープを右から順に合併（第 2 パス）して新しい根を得る。償却的に `O(log n)`。
4.  **書き戻し**: 取り出したキーを配列の先頭から順に書けば昇順になる。

```pseudocode
procedure meld(H1, H2)
  if H1 is empty
    return H2
  if H2 is empty
    return H1
  if H1.key <= H2.key
    make H2 the leftmost child of H1
    return H1
  else
    make H1 the leftmost child of H2
    return H2

procedure two_pass_meld(children)   // children は兄弟リスト
  // 第1パス: 左から隣り合う 2 本を合併
  pairs = empty list
  while children is not empty
    a = take first child
    if children is empty
      append a to pairs
    else
      b = take first child
      append meld(a, b) to pairs
  // 第2パス: 右から順に合併
  H = empty
  for p in reverse(pairs)
    H = meld(p, H)
  return H

procedure pairing_heap_sort(A)
  H = empty pairing heap
  for x in A
    H = meld(H, singleton(x))
  for i from 0 to length(A) - 1
    A[i] = H.key
    H = two_pass_meld(children of H)
```

償却時間計算量は挿入・合併が `O(1)`、最小抽出が `O(log n)` であり、全体では `O(n log n)` になる。節点用に `O(n)` の追加記憶域が要る（インプレースではない）。等値キーの相対順序は合併時の規約に依存し、一般に不安定である。実装が単純な一方で、ポインタ経由の多分岐木はキャッシュ効率では配列上の[ヒープソート](/2026/05/04/sort-heap.html)に劣りやすい。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('pairing-heap-sort-demo', function (root) {
  function meld(a, b) {
    if (!a) return b;
    if (!b) return a;
    if (a.key <= b.key) {
      b.sibling = a.child;
      a.child = b;
      return a;
    }
    a.sibling = b.child;
    b.child = a;
    return b;
  }

  function insertKey(heap, key, id) {
    const node = {
      key: key,
      id: id,
      child: null,
      sibling: null
    };
    return meld(heap, node);
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
      children: children
    };
  }

  function snapshotRoots(roots) {
    return roots.map(snapshotNode);
  }

  function snapshotHeap(heap) {
    if (!heap) return [];
    return [snapshotNode(heap)];
  }

  function siblingsToRoots(first) {
    const roots = [];
    let cur = first;
    while (cur) {
      const next = cur.sibling;
      cur.sibling = null;
      roots.push(cur);
      cur = next;
    }
    return roots;
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

  function pushRebuild(steps, base, text, forest, activeId, highlightIds) {
    steps.push({
      kind: 'rebuild',
      text: text,
      arr: base.arr,
      sortedUpTo: base.sortedUpTo,
      writePos: base.writePos,
      forest: forest,
      activeId: activeId,
      highlightIds: highlightIds || null
    });
  }

  function rebuildAfterExtract(steps, children, base) {
    const remaining = siblingsToRoots(children);

    pushRebuild(
      steps,
      base,
      '根を外し、子を森として並べる（ここから二パスで再構築）',
      snapshotRoots(remaining),
      null,
      null
    );

    if (!remaining.length) {
      return null;
    }

    const pairs = [];
    let i = 0;
    while (i < remaining.length) {
      if (i + 1 >= remaining.length) {
        const alone = remaining[i];
        pairs.push(alone);
        pushRebuild(
          steps,
          base,
          '第1パス: 端の 1 本（' + alone.key + '）はそのまま繰り越し',
          snapshotRoots(pairs.concat(remaining.slice(i + 1))),
          alone.id,
          [alone.id]
        );
        break;
      }

      const a = remaining[i];
      const b = remaining[i + 1];
      const rest = remaining.slice(i + 2);
      pushRebuild(
        steps,
        base,
        '第1パス: ' + a.key + ' と ' + b.key + ' を比較して合併',
        snapshotRoots(pairs.concat([a, b], rest)),
        a.id,
        [a.id, b.id]
      );
      const merged = meld(a, b);
      pairs.push(merged);
      pushRebuild(
        steps,
        base,
        '第1パス: 小さい方を親にして結合（新しい根 ' + merged.key + '）',
        snapshotRoots(pairs.concat(rest)),
        merged.id,
        [merged.id]
      );
      i += 2;
    }

    let result = null;
    const pending = pairs.slice();
    while (pending.length) {
      const p = pending.pop();
      if (!result) {
        result = p;
        pushRebuild(
          steps,
          base,
          '第2パス: 右端のヒープ（根 ' + result.key + '）から右→左へ畳み込み',
          snapshotRoots(pending.concat([result])),
          result.id,
          [result.id]
        );
        continue;
      }
      pushRebuild(
        steps,
        base,
        '第2パス: ' + p.key + ' と ' + result.key + ' を比較して合併',
        snapshotRoots(pending.concat([p, result])),
        p.id,
        [p.id, result.id]
      );
      result = meld(p, result);
      pushRebuild(
        steps,
        base,
        '第2パス: 小さい方を親にして結合（新しい根 ' + result.key + '）',
        snapshotRoots(pending.concat([result])),
        result.id,
        [result.id]
      );
    }

    return result;
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
      text: '第1段階: 入力を順にペアリングヒープへ挿入（根同士を合併）',
      arr: vals.slice(),
      sortedUpTo: 0,
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
        forest: snapshotHeap(heap),
        activeId: i
      });
    }

    steps.push({
      kind: 'caption',
      text: '第2段階: 根（最小）を繰り返し取り出し、子を二パスでペアリング',
      arr: vals.slice(),
      sortedUpTo: 0,
      forest: snapshotHeap(heap),
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
        forest: snapshotHeap(heap),
        activeId: winId
      });

      const children = heap.child;
      const key = heap.key;
      alive.delete(winId);
      sorted.push(key);
      const displayAfter = remainingDisplay(sorted, vals, alive);

      heap = rebuildAfterExtract(steps, children, {
        arr: displayAfter,
        sortedUpTo: pos + 1,
        writePos: pos
      });

      steps.push({
        kind: 'write',
        pos: pos,
        arr: displayAfter,
        sortedUpTo: pos + 1,
        forest: snapshotHeap(heap),
        activeId: heap ? heap.id : null
      });
    }

    steps.push({
      kind: 'done',
      arr: sorted.slice(),
      sortedUpTo: n,
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

  function paintForest(forest, activeId, highlightIds) {
    DemoSort.renderForest(forestView, forest && forest.length ? forest : null, {
      activeId: activeId,
      activeIds: highlightIds && highlightIds.length ? highlightIds : null,
      ariaLabel: '現在のペアリングヒープ'
    });
  }

  const forestView = DemoSort.createBinaryTreeView(root, {
    label: '現在のペアリングヒープ（青: 根、紫: 注目ノード。数字はキー）',
    emptyText: 'まだペアリングヒープは空です'
  });

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-pairing-heap',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ペアリングヒープソートのデモ（棒の数字が配列、下の数字の木がペアリングヒープ）',
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
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'insert') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, 0, [[s.idx, 'key']]);
        paintForest(s.forest, s.activeId);
        api.setCaption(
          '挿入: 位置 ' + s.idx + ' の値（' + s.value + '）を合併'
        );
        return;
      }
      if (s.kind === 'champion') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, [[s.winBar, 'cursor']]);
        paintForest(s.forest, s.activeId);
        api.setCaption(
          '根の最小（元の位置 ' +
            s.winId +
            '）を出力位置 ' +
            s.pos +
            ' へ'
        );
        return;
      }
      if (s.kind === 'rebuild') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, [[s.writePos, 'write']]);
        paintForest(s.forest, s.activeId, s.highlightIds);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        paint(barsEl, s.sortedUpTo, [[s.pos, 'write']]);
        paintForest(s.forest, s.activeId);
        api.setCaption('位置 ' + s.pos + ' を確定（再構築完了）');
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
  id="pairing-heap-sort-demo"
  data_prefix="pairing-heap"
  script=sort_demo_js
%}

優先度付きキューとしてのペアリングヒープは、合併が 1 比較で書け、減少キーも「切り離して再合併」で扱える点が実務寄りの実装で選ばれやすい。整列用途ではその操作を「すべて挿入してからすべて取り出す」形に固定したものがペアリングヒープソートである。

## 類似アルゴリズムとの相違点

[ヒープソート](/2026/05/04/sort-heap.html)は配列上の二分ヒープをインプレースで縮める。ペアリングヒープはポインタの多分岐木で、合併と子のペアリングが中心になる。

[二項ヒープソート](/2026/08/11/sort-binomial-heap.html)は次数の異なる二項木を二進加算のように結合する。ペアリングヒープは次数を持たず、抽出時に子を 2 本ずつペアにして畳み込む。

[弱ヒープソート](/2026/08/28/sort-weak-heap.html)は配列上の不完全木と逆ビットで比較回数を抑える。ヒープ同士の合併を第一級には扱わない。

[トーナメントソート](/2026/05/26/sort-tournament.html)も最小を繰り返し取り出すが、固定長のトーナメント木を更新する点が異なる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000018 |        0.000399 |               6 |               7 |
|        512 |        0.000039 |        0.000132 |              13 |              14 |
|       1024 |        0.000087 |        0.000370 |              27 |              28 |
|       2048 |        0.000177 |        0.000392 |              54 |              56 |
|       4096 |        0.000416 |        0.001518 |             110 |             112 |
|       8192 |        0.000897 |        0.002152 |             220 |             224 |
|      16384 |        0.002085 |        0.007597 |             442 |             448 |
|      32768 |        0.004604 |        0.012753 |             884 |             896 |
|      65536 |        0.012509 |        0.054332 |            1770 |            1792 |
|     131072 |        0.053413 |        0.492478 |            3540 |            3584 |
|     262144 |        0.065955 |        0.239336 |            7083 |            7168 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="pairing_heap" %}
