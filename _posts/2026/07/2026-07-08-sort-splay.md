---
title:     スプレイソートで配列を並び替える
date:      2026-07-08 01:53:01 +0900
tags:      sort
sort_demo: true
---

## スプレイソートを使用する

スプレイソート (`splay sort`) は、要素を順にスプレイ木へ挿入し、中順走査ですべてのキーを読み出して昇順にする。

スプレイ木は、参照したノードを根へ持ち上げる（スプレイ操作）自己調整二分探索木であり、直近にアクセスした要素へ素早く再び到達できる。

1.  **挿入**: 入力値を順にスプレイ木へ挿入する。各挿入のあと、挿入したキー（または探索経路上の最終ノード）が根へスプレイされる。
2.  **取出し**: 中順走査でキーを昇順に列挙し、配列へ書き込む。

```pseudocode
procedure splay_sort(elements)
  T = empty splay tree
  for x in elements
    insert_splay(T, x)
  return inorder_traversal(T)
```

スプレイ木の単一操作の最悪時間計算量は `O(n)` だが、任意の `m` 回の操作に対する償却時間計算量は `O(log n)` である（スプレイ木の償却解析）。`n` 個の挿入全体では償却 `O(n log n)`、中順走査は `O(n)` なので、合計は償却 `O(n log n)` となる。

素の二分探索木と異なり、スプレイ木は偏った入力でも木の高さを抑えやすい。一方、各挿入で回転が発生するため定数係数は AVL 木や赤黒木より大きくなりがちである。ノード用に `O(n)` の追加記憶域が必要で、入力配列だけをインプレースで整える実装ではない。

等しいキー同士の相対順序は木の実装や等値を左子・右子のどちらへ入れるかの規約に依存し、一般には安定ソートではない。次のデモでは、同じ値の棒が画面上で入れ替わらないよう、挿入の比較を値が異なれば値、等しければ元の位置 `id` の辞書式順にしている。これは可視化のための工夫であり、素のスプレイソートが安定であることを意味しない。

```pseudocode
procedure insert_splay(T, x)
  if T is empty then
    T.root = new node(x)
    return
  splay(T, x)
  if x = T.root.key then
    increment count at T.root
  else if x < T.root.key then
    attach old left subtree of T.root to new node(x)
    make T.root the right child of new node(x)
    T.root = new node(x)
  else
    attach old right subtree of T.root to new node(x)
    make T.root the left child of new node(x)
    T.root = new node(x)
```

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('splay-sort-demo', function (root) {
  function cmp(a, b) {
    if (a.value !== b.value) return a.value < b.value ? -1 : 1;
    if (a.id !== b.id) return a.id < b.id ? -1 : 1;
    return 0;
  }

  function rotateRight(x) {
    const y = x.left;
    x.left = y.right;
    y.right = x;
    return y;
  }

  function rotateLeft(x) {
    const y = x.right;
    x.right = y.left;
    y.left = x;
    return y;
  }

  function splay(node, key) {
    if (!node) return null;
    const c = cmp(key, node.k);
    if (c < 0) {
      if (!node.left) return node;
      let left = node.left;
      const lc = cmp(key, left.k);
      if (lc < 0) {
        if (left.left) {
          left.left = splay(left.left, key);
          left = rotateRight(left);
        }
        node.left = left;
        return rotateRight(node);
      }
      if (lc > 0) {
        if (left.right) {
          left.right = splay(left.right, key);
          node.left = rotateLeft(left);
          return rotateRight(node);
        }
        node.left = left;
      } else {
        node.left = left;
      }
    } else if (c > 0) {
      if (!node.right) return node;
      let right = node.right;
      const rc = cmp(key, right.k);
      if (rc > 0) {
        if (right.right) {
          right.right = splay(right.right, key);
          right = rotateLeft(right);
        }
        node.right = right;
        return rotateLeft(node);
      }
      if (rc < 0) {
        if (right.left) {
          right.left = splay(right.left, key);
          node.right = rotateRight(right);
          return rotateLeft(node);
        }
        node.right = right;
      } else {
        node.right = right;
      }
    }
    return node;
  }

  function makeNode(item) {
    return { k: item, left: null, right: null };
  }

  function splayInsert(root, item) {
    if (!root) return makeNode(item);
    root = splay(root, item);
    const c = cmp(item, root.k);
    if (c === 0) return root;
    if (c < 0) {
      const newNode = makeNode(item);
      newNode.left = root.left;
      newNode.right = root;
      root.left = null;
      return newNode;
    }
    const newNode = makeNode(item);
    newNode.right = root.right;
    newNode.left = root;
    root.right = null;
    return newNode;
  }

  function inorderCollect(n, out) {
    if (!n) return;
    inorderCollect(n.left, out);
    out.push(n.k);
    inorderCollect(n.right, out);
  }

  function generateSteps(vals) {
    const steps = [];
    const ids = vals.map(function (v, i) {
      return { value: v, id: i };
    });

    steps.push({
      kind: 'phase_insert',
      arr: vals.slice()
    });

    let splayRoot = null;
    for (let i = 0; i < ids.length; i++) {
      steps.push({
        kind: 'insert',
        idx: i,
        value: vals[i],
        arr: vals.slice()
      });
      splayRoot = splayInsert(splayRoot, ids[i]);
    }

    const sortedKeys = [];
    inorderCollect(splayRoot, sortedKeys);
    const sortedIds = sortedKeys.map(function (x) {
      return x.id;
    });

    steps.push({
      kind: 'phase_reorder',
      caption: '中順走査の順（昇順）に並べ替えます（スワップで視覚化）'
    });

    const n = sortedIds.length;
    const perm = [];
    for (let pj = 0; pj < n; pj++) {
      perm[pj] = pj;
    }

    function posOf(origId, p) {
      for (let q = 0; q < p.length; q++) {
        if (p[q] === origId) {
          return q;
        }
      }
      return -1;
    }

    for (let tgt = 0; tgt < n - 1; tgt++) {
      const wantOrig = sortedIds[tgt];
      if (perm[tgt] === wantOrig) continue;
      const src = posOf(wantOrig, perm);
      steps.push({
        kind: 'swap',
        lo: tgt,
        hi: src,
        caption:
          '位置 ' + tgt + ' と ' + src + ' を入れ替え（整列済み順へ反映）'
      });
      const a = perm[tgt];
      const b = perm[src];
      perm[tgt] = b;
      perm[src] = a;
    }

    steps.push({ kind: 'done' });

    return steps;
  }

  function mountBars(container, values, orderByOriginalIndex) {
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }
    const max = Math.max.apply(null, values);
    const min = Math.min.apply(null, values);
    const span = Math.max(max - min, 1);
    let order;
    if (orderByOriginalIndex && orderByOriginalIndex.length === values.length) {
      order = orderByOriginalIndex.slice();
    } else {
      order = [];
      for (let ii = 0; ii < values.length; ii++) order.push(ii);
    }
    order.forEach(function (origIdx) {
      const v = values[origIdx];
      const bar = document.createElement('div');
      bar.className = 'sort-demo__bar';
      bar.dataset.origIndex = String(origIdx);
      const h = 28 + ((v - min) / span) * 92;
      bar.style.height = h + 'px';
      bar.setAttribute('title', String(v));
      container.appendChild(bar);
    });
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      'スプレイソートの棒。左から現在の並びで位置0、1…の順です。'
    );
    DemoSort.syncBarsAccessibility(container);
  }

  function setInsertRole(container, origIndex) {
    const nodes = container.children;
    let target = -1;
    for (let ni = 0; ni < nodes.length; ni++) {
      if (nodes[ni].dataset.origIndex === String(origIndex)) {
        target = ni;
        break;
      }
    }
    DemoSort.assignRoles(container, target === -1 ? [] : [[target, 'insert']]);
  }

  function rebuildOrderFromPerm(api, perm) {
    api.permState = perm.slice();
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-splay',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'スプレイソート（スプレイ木への挿入＋並び順の復元）。挿入は紫、スワップは緑です。',
    barClass: 'sort-demo__bar',
    rebuild: function (api, v) {
      api.values = v.slice();
      api.steps = generateSteps(api.values);
      api.idx = 0;
      const order = [];
      for (let oi = 0; oi < api.values.length; oi++) order.push(oi);
      rebuildOrderFromPerm(api, order);
      mountBars(api.barsEl, api.values, api.permState);
      api.setCaption(
        'スプレイソート（スプレイ木への挿入＋並び順の復元）。挿入は紫、スワップは緑です。'
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase_insert') {
        mountBars(barsEl, api.values, api.permState);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '1. 入力順に値をスプレイ木へ挿入していきます（木は内部のみ）'
        );
        return;
      }
      if (s.kind === 'insert') {
        mountBars(barsEl, api.values, api.permState);
        setInsertRole(barsEl, s.idx);
        api.setCaption(
          'スプレイ木に挿入: 入力位置 ' + s.idx + ' の値（' + s.value + '）'
        );
        return;
      }
      if (s.kind === 'phase_reorder') {
        mountBars(barsEl, api.values, api.permState);
        DemoSort.clearRoles(barsEl);
        api.setCaption(s.caption);
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換中… (' + s.caption + ')');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);

        const newPerm = [];
        for (let cj = 0; cj < barsEl.children.length; cj++) {
          newPerm.push(parseInt(barsEl.children[cj].dataset.origIndex, 10));
        }
        rebuildOrderFromPerm(api, newPerm);

        DemoSort.clearRoles(barsEl);
        api.setCaption('交換完了');
        return;
      }
      if (s.kind === 'done') {
        mountBars(barsEl, api.values, api.permState);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了（左から昇順）');
      }
    },
    stepPauseMs: function (api) {
      return api.idx < api.steps.length && api.steps[api.idx].kind === 'swap'
        ? 340
        : 220;
    },
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="splay-sort-demo"
  data_prefix="splay"
  script=sort_demo_js
%}

二分木ソートと同様、配列上の並びは挿入フェーズでは動かず、整列結果は中順走査で得る。スプレイ木は「直近に触ったキーが根に来る」という局所性を活かした辞書やキャッシュの実装でよく使われるが、一度だけ全要素を整列する用途では回転のオーバーヘッドから、配列を直接いじるクイックソートやマージソートのほうが実用的なことが多い。

## 計算量のまとめ

| 区分 | 時間計算量 | 空間計算量 | 備考 |
| --- | --- | --- | --- |
| 最悪（単一操作） | `O(n)` | `O(n)` | 1 回の挿入・探索 |
| 償却（`n` 回挿入） | `O(n log n)` | `O(n)` | スプレイ木の償却解析 |
| 中順走査 | `O(n)` | — | 整列結果の取出し |
| 安定性 | — | — | 一般に不安定 |

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000018 |        0.001084 |            1694 |            1700 |
|        512 |        0.000040 |        0.000717 |            1710 |            1716 |
|       1024 |        0.000082 |        0.000487 |            1746 |            1752 |
|       2048 |        0.000184 |        0.000626 |            1817 |            1824 |
|       4096 |        0.000405 |        0.001059 |            1961 |            1968 |
|       8192 |        0.000925 |        0.004044 |            2249 |            2256 |
|      16384 |        0.002123 |        0.007383 |            2702 |            2708 |
|      32768 |        0.005260 |        0.018099 |            3780 |            3812 |
|      65536 |        0.014622 |        0.038418 |            6083 |            6116 |
|     131072 |        0.033458 |        0.142269 |           10692 |           10724 |
|     262144 |        0.078169 |        0.180472 |           19908 |           20052 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="splay" %}
