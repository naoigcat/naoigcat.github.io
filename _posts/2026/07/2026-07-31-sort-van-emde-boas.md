---
title:     ファンエンデボアスソートで配列を並び替える
date:      2026-07-31 06:49:55 +0900
tags:      sort
sort_demo: true
---

## ファンエンデボアスソートを使用する

ファンエンデボアスソート (`van emde boas sort`) は、整数宇宙 `[0, U)` 上のファン・エムデ・ボアス木（vEB 木）へキーを挿入し、最小値から順に後続（successor）をたどって取り出す非比較ソートである。

vEB 木は最小値・最大値を定数時間で返し、挿入・後続探索を `O(log log U)` で行う。そのため `n` 個のキーを整列する全体の時間は `O(n log log U)` になる。宇宙サイズ `U` が入力長 `n` に近い整数データでは、比較ソートの `Ω(n log n)` より漸近的に有利になりうる。

構造の要点は、宇宙を高位桁と低位桁に再帰的に分割することである。`U = 2^{2k}`（またはそれに近い 2 の冪）のとき、各ノードは次を持つ。

-   **min / max**: その部分宇宙に含まれる最小・最大キー（木全体から切り離して保持する）。
-   **cluster**: 低位桁用の部分木を `√U` 本（実際には上側平方根本）。キー `x` の高位 `high(x)` がクラスタ番号、低位 `low(x)` がクラスタ内の位置になる。
-   **summary**: 「どのクラスタが空でないか」を表す、宇宙サイズ `√U` の vEB 木。

空でないクラスタだけを遅延確保すれば、疎なキー集合でも全宇宙分の配列を一気に確保しなくてよい。重複キーは出現回数を別配列で数え、vEB 木にはユニークなオフセットだけを入れる。

1.  **値域の正規化**: 最小値 `min` を引き、オフセット `0 … max-min` へ写す。宇宙サイズ `U` は値域幅以上の最小の 2 の冪（ただし 2 以上）とする。
2.  **集計と挿入**: 各オフセットの出現回数を数え、回数が正のキーだけを vEB 木へ挿入する。
3.  **昇順取り出し**: 木の最小値から始め、`successor` で次のキーへ進みながら、出現回数ぶん出力配列へ書き戻す。

```pseudocode
procedure veb_insert(V, x)
  if V.min = NIL then
    V.min = V.max = x; return
  if x < V.min then swap x with V.min
  if V.u > 2 then
    h = high(x); l = low(x)
    if V.cluster[h] is empty then
      veb_insert(V.summary, h)
      V.cluster[h].min = V.cluster[h].max = l
    else
      veb_insert(V.cluster[h], l)
  if x > V.max then V.max = x

procedure veb_successor(V, x)
  if V.u = 2 then
    if x = 0 and V.max = 1 then return 1 else return NIL
  if V.min ≠ NIL and x < V.min then return V.min
  h = high(x); l = low(x)
  if low-part of cluster h has a key > l then
    return index(h, veb_successor(V.cluster[h], l))
  succ = veb_successor(V.summary, h)
  if succ = NIL then return NIL
  return index(succ, V.cluster[succ].min)

procedure van_emde_boas_sort(A)
  if length(A) ≤ 1 then return
  minVal = minimum(A); maxVal = maximum(A)
  span = maxVal - minVal + 1
  count[0..span-1] = 0
  for each x in A
    count[x - minVal] = count[x - minVal] + 1
  U = next_power_of_two(max(span, 2))
  V = empty vEB tree with universe U
  for v from 0 to span - 1
    if count[v] > 0 then veb_insert(V, v)
  idx = 0; cur = V.min
  while cur ≠ NIL
    repeat count[cur] times
      A[idx] = minVal + cur; idx = idx + 1
    cur = veb_successor(V, cur)
```

キー同士の大小比較は行わず、ビット分割と再帰的な summary 操作で順序を決める。同値は集計配列側でまとめて出力するため、入力を左から数えた実装では安定ソートになる。一方で補助構造は宇宙サイズに依存し、`U` が極端に大きいとメモリと定数倍が膨らむ。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('van-emde-boas-sort-demo', function (root) {
  function lowerSqrt(universe) {
    let k = 0;
    let u = universe;
    while (u > 1) {
      u >>= 1;
      k += 1;
    }
    return 1 << Math.floor(k / 2);
  }

  function nextPowerOfTwo(n) {
    let p = 1;
    while (p < n) {
      p <<= 1;
    }
    return Math.max(p, 2);
  }

  function createVeb(universe) {
    if (universe === 2) {
      return {
        universe: universe,
        min: null,
        max: null,
        summary: null,
        cluster: [],
      };
    }
    const lower = lowerSqrt(universe);
    const upper = universe / lower;
    const cluster = [];
    let i;
    for (i = 0; i < upper; i++) {
      cluster.push(null);
    }
    return {
      universe: universe,
      min: null,
      max: null,
      summary: createVeb(upper),
      cluster: cluster,
    };
  }

  function highOf(tree, x) {
    return Math.floor(x / lowerSqrt(tree.universe));
  }

  function lowOf(tree, x) {
    return x % lowerSqrt(tree.universe);
  }

  function indexOf(tree, high, low) {
    return high * lowerSqrt(tree.universe) + low;
  }

  function ensureCluster(tree, i) {
    if (!tree.cluster[i]) {
      tree.cluster[i] = createVeb(lowerSqrt(tree.universe));
    }
    return tree.cluster[i];
  }

  function emptyInsert(tree, x) {
    tree.min = x;
    tree.max = x;
  }

  function vebInsert(tree, x) {
    if (tree.min === null) {
      emptyInsert(tree, x);
      return;
    }
    let key = x;
    if (key < tree.min) {
      const old = tree.min;
      tree.min = key;
      key = old;
    }
    if (tree.universe > 2) {
      const h = highOf(tree, key);
      const l = lowOf(tree, key);
      const cluster = tree.cluster[h];
      if (!cluster || cluster.min === null) {
        vebInsert(tree.summary, h);
        emptyInsert(ensureCluster(tree, h), l);
      } else {
        vebInsert(ensureCluster(tree, h), l);
      }
    }
    if (key > tree.max) {
      tree.max = key;
    }
  }

  function vebSuccessor(tree, x) {
    if (tree.universe === 2) {
      if (x === 0 && tree.max === 1) {
        return 1;
      }
      return null;
    }
    if (tree.min !== null && x < tree.min) {
      return tree.min;
    }
    if (tree.min === null) {
      return null;
    }
    const h = highOf(tree, x);
    const l = lowOf(tree, x);
    const cluster = tree.cluster[h];
    if (cluster && cluster.max !== null && l < cluster.max) {
      return indexOf(tree, h, vebSuccessor(cluster, l));
    }
    const succCluster = vebSuccessor(tree.summary, h);
    if (succCluster === null) {
      return null;
    }
    return indexOf(tree, succCluster, tree.cluster[succCluster].min);
  }

  function vebDelete(tree, x) {
    if (tree.min === null) {
      return;
    }
    if (tree.min === tree.max) {
      tree.min = null;
      tree.max = null;
      return;
    }
    if (tree.universe === 2) {
      tree.min = x === 0 ? 1 : 0;
      tree.max = tree.min;
      return;
    }
    let key = x;
    if (key === tree.min) {
      const firstCluster = tree.summary.min;
      key = indexOf(tree, firstCluster, tree.cluster[firstCluster].min);
      tree.min = key;
    }
    const h = highOf(tree, key);
    const l = lowOf(tree, key);
    vebDelete(ensureCluster(tree, h), l);
    if (tree.cluster[h].min === null) {
      vebDelete(tree.summary, h);
      if (key === tree.max) {
        if (tree.summary.min === null) {
          tree.max = tree.min;
        } else {
          const sm = tree.summary.max;
          tree.max = indexOf(tree, sm, tree.cluster[sm].max);
        }
      }
    } else if (key === tree.max) {
      tree.max = indexOf(tree, h, tree.cluster[h].max);
    }
  }

  function collectKeys(tree) {
    const keys = [];
    let cur = tree.min;
    while (cur !== null) {
      keys.push(cur);
      cur = vebSuccessor(tree, cur);
    }
    return keys;
  }

  function snapshotVeb(tree, minVal, opts) {
    const options = opts || {};
    if (!tree) {
      return {
        empty: true,
        universe: options.universe || 2,
        minVal: minVal,
        activeValue: null,
        activeCluster: null,
        mode: options.mode || null,
      };
    }
    if (tree.min === null) {
      return {
        empty: true,
        universe: tree.universe,
        minVal: minVal,
        activeValue: options.activeValue != null ? options.activeValue : null,
        activeCluster:
          options.activeCluster != null ? options.activeCluster : null,
        mode: options.mode || null,
      };
    }
    const keys = collectKeys(tree);
    const lower = lowerSqrt(tree.universe);
    const clusterCount =
      tree.universe === 2 ? 0 : tree.universe / lower;
    const clusters = [];
    let h;
    for (h = 0; h < clusterCount; h++) {
      const members = [];
      let ki;
      for (ki = 0; ki < keys.length; ki++) {
        // ルートの min はクラスタへ格納しない（vEB 木の規約）
        if (keys[ki] === tree.min) {
          continue;
        }
        if (Math.floor(keys[ki] / lower) === h) {
          members.push(minVal + keys[ki]);
        }
      }
      const cluster = tree.cluster[h];
      const occupied = !!(cluster && cluster.min !== null);
      clusters.push({
        index: h,
        occupied: occupied,
        min: occupied ? minVal + indexOf(tree, h, cluster.min) : null,
        max: occupied ? minVal + indexOf(tree, h, cluster.max) : null,
        members: members,
      });
    }
    const summary = [];
    if (tree.summary && tree.summary.min !== null) {
      let s = tree.summary.min;
      while (s !== null) {
        summary.push(s);
        s = vebSuccessor(tree.summary, s);
      }
    }
    return {
      empty: false,
      universe: tree.universe,
      minVal: minVal,
      min: minVal + tree.min,
      max: minVal + tree.max,
      keys: keys.map(function (k) {
        return minVal + k;
      }),
      summary: summary,
      clusters: clusters,
      activeValue: options.activeValue != null ? options.activeValue : null,
      activeCluster:
        options.activeCluster != null ? options.activeCluster : null,
      mode: options.mode || null,
    };
  }

  function createVebView(demoRoot) {
    const section = document.createElement('section');
    section.className = 'sort-demo__tree veb-demo';

    const label = document.createElement('p');
    label.className = 'sort-demo__tree-label';
    label.textContent =
      '現在の vEB 木（紫: 操作中のキー、緑: 取り出し直後に空いた箇所）';

    const canvas = document.createElement('div');
    canvas.className = 'sort-demo__tree-canvas veb-demo__canvas';
    canvas.dataset.emptyText = 'まだ vEB 木は空です';
    canvas.setAttribute('role', 'img');

    section.appendChild(label);
    section.appendChild(canvas);

    const bars = demoRoot.querySelector('.sort-demo__bars');
    if (bars && bars.parentNode) {
      bars.parentNode.insertBefore(section, bars.nextSibling);
    } else {
      demoRoot.appendChild(section);
    }
    return canvas;
  }

  function chip(text, className) {
    const el = document.createElement('span');
    el.className = className;
    el.textContent = text;
    return el;
  }

  function renderVeb(view, snap) {
    if (!view) {
      return;
    }
    view.innerHTML = '';
    if (!snap) {
      view.classList.add('sort-demo__tree-canvas--empty');
      const empty = document.createElement('span');
      empty.className = 'sort-demo__tree-empty';
      empty.textContent = view.dataset.emptyText || 'まだ vEB 木は空です';
      view.appendChild(empty);
      view.setAttribute('aria-label', 'vEB 木。まだ木は空です。');
      return;
    }

    view.classList.remove('sort-demo__tree-canvas--empty');
    const wrap = document.createElement('div');
    wrap.className = 'veb-demo__panel';

    const header = document.createElement('div');
    header.className = 'veb-demo__header';
    if (snap.empty) {
      header.appendChild(chip('U = ' + snap.universe, 'veb-demo__meta'));
      header.appendChild(chip('min = —', 'veb-demo__meta'));
      header.appendChild(chip('max = —', 'veb-demo__meta'));
    } else {
      header.appendChild(chip('U = ' + snap.universe, 'veb-demo__meta'));
      header.appendChild(
        chip(
          'min = ' + snap.min,
          'veb-demo__meta' +
            (snap.activeValue === snap.min ? ' veb-demo__meta--active' : '')
        )
      );
      header.appendChild(
        chip(
          'max = ' + snap.max,
          'veb-demo__meta' +
            (snap.activeValue === snap.max && snap.activeValue !== snap.min
              ? ' veb-demo__meta--active'
              : '')
        )
      );
    }
    wrap.appendChild(header);

    const summaryRow = document.createElement('div');
    summaryRow.className = 'veb-demo__summary';
    const summaryLabel = document.createElement('span');
    summaryLabel.className = 'veb-demo__summary-label';
    summaryLabel.textContent = 'summary';
    summaryRow.appendChild(summaryLabel);
    if (snap.empty || !snap.summary || !snap.summary.length) {
      summaryRow.appendChild(chip('（空）', 'veb-demo__chip veb-demo__chip--muted'));
    } else {
      let si;
      for (si = 0; si < snap.summary.length; si++) {
        const idx = snap.summary[si];
        summaryRow.appendChild(
          chip(
            'C' + idx,
            'veb-demo__chip' +
              (snap.activeCluster === idx ? ' veb-demo__chip--active' : '')
          )
        );
      }
    }
    wrap.appendChild(summaryRow);

    const clusters = document.createElement('div');
    clusters.className = 'veb-demo__clusters';
    const clusterCount =
      snap.clusters && snap.clusters.length
        ? snap.clusters.length
        : snap.universe > 2
          ? snap.universe / lowerSqrt(snap.universe)
          : 0;

    if (clusterCount === 0) {
      const leaf = document.createElement('div');
      leaf.className = 'veb-demo__leaf';
      if (snap.empty) {
        leaf.appendChild(chip('葉宇宙（空）', 'veb-demo__chip veb-demo__chip--muted'));
      } else {
        let li;
        for (li = 0; li < snap.keys.length; li++) {
          const value = snap.keys[li];
          leaf.appendChild(
            chip(
              String(value),
              'veb-demo__chip' +
                (snap.activeValue === value ? ' veb-demo__chip--active' : '') +
                (snap.mode === 'extract' && snap.activeValue === value
                  ? ' veb-demo__chip--extract'
                  : '')
            )
          );
        }
      }
      clusters.appendChild(leaf);
    } else {
      let ci;
      for (ci = 0; ci < clusterCount; ci++) {
        const info =
          snap.clusters && snap.clusters[ci]
            ? snap.clusters[ci]
            : { index: ci, occupied: false, members: [] };
        const card = document.createElement('div');
        card.className =
          'veb-demo__cluster' +
          (info.occupied ? '' : ' veb-demo__cluster--empty') +
          (snap.activeCluster === info.index
            ? ' veb-demo__cluster--active'
            : '') +
          (snap.mode === 'extract' &&
          snap.activeCluster === info.index &&
          !info.occupied
            ? ' veb-demo__cluster--cleared'
            : '');

        const title = document.createElement('div');
        title.className = 'veb-demo__cluster-title';
        title.textContent =
          'C' +
          info.index +
          (info.occupied
            ? '  min=' + info.min + ' max=' + info.max
            : '  （未確保）');
        card.appendChild(title);

        const members = document.createElement('div');
        members.className = 'veb-demo__members';
        if (!info.occupied || !info.members.length) {
          members.appendChild(
            chip('—', 'veb-demo__chip veb-demo__chip--muted')
          );
        } else {
          let mi;
          for (mi = 0; mi < info.members.length; mi++) {
            const value = info.members[mi];
            members.appendChild(
              chip(
                String(value),
                'veb-demo__chip' +
                  (snap.activeValue === value
                    ? ' veb-demo__chip--active'
                    : '') +
                  (snap.mode === 'extract' && snap.activeValue === value
                    ? ' veb-demo__chip--extract'
                    : '')
              )
            );
          }
        }
        card.appendChild(members);
        clusters.appendChild(card);
      }
    }
    wrap.appendChild(clusters);
    view.appendChild(wrap);

    let aria = 'vEB 木。宇宙サイズ ' + snap.universe;
    if (snap.empty) {
      aria += '。まだキーはありません。';
    } else {
      aria +=
        '。最小 ' +
        snap.min +
        '、最大 ' +
        snap.max +
        '。キーは ' +
        snap.keys.join('、') +
        '。';
    }
    view.setAttribute('aria-label', aria);
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n === 0) {
      steps.push({ kind: 'done', arr: [], tree: null });
      return steps;
    }
    if (n === 1) {
      steps.push({
        kind: 'done',
        arr: a.slice(),
        tree: snapshotVeb(null, a[0], { universe: 2 }),
      });
      return steps;
    }

    const minVal = Math.min.apply(null, a);
    const maxVal = Math.max.apply(null, a);
    const span = maxVal - minVal + 1;
    const universe = nextPowerOfTwo(span);
    const count = new Array(span);
    let i;
    for (i = 0; i < span; i++) {
      count[i] = 0;
    }

    steps.push({
      kind: 'phase',
      phase: 'insert',
      arr: a.slice(),
      universe: universe,
      minVal: minVal,
      tree: snapshotVeb(null, minVal, { universe: universe, mode: 'insert' }),
    });

    for (i = 0; i < n; i++) {
      count[a[i] - minVal] += 1;
      steps.push({
        kind: 'count',
        i: i,
        value: a[i],
        arr: a.slice(),
        minVal: minVal,
        universe: universe,
        tree: snapshotVeb(null, minVal, {
          universe: universe,
          activeValue: a[i],
          mode: 'insert',
        }),
      });
    }

    const tree = createVeb(universe);
    steps.push({
      kind: 'phase',
      phase: 'build',
      arr: a.slice(),
      universe: universe,
      tree: snapshotVeb(tree, minVal, { mode: 'insert' }),
    });

    for (i = 0; i < span; i++) {
      if (count[i] > 0) {
        const value = minVal + i;
        const high = highOf(tree, i);
        const low = lowOf(tree, i);
        vebInsert(tree, i);
        // ルート min はクラスタ外。クラスタ内に載ったときだけ C* を強調する
        const activeCluster =
          universe > 2 && value !== minVal + tree.min ? high : null;
        steps.push({
          kind: 'insert',
          offset: i,
          value: value,
          high: high,
          low: low,
          arr: a.slice(),
          treeMin: minVal + tree.min,
          treeMax: minVal + tree.max,
          universe: universe,
          tree: snapshotVeb(tree, minVal, {
            activeValue: value,
            activeCluster: activeCluster,
            mode: 'insert',
          }),
        });
      }
    }

    steps.push({
      kind: 'phase',
      phase: 'extract',
      arr: a.slice(),
      treeMin: minVal + tree.min,
      treeMax: minVal + tree.max,
      universe: universe,
      tree: snapshotVeb(tree, minVal, { mode: 'extract' }),
    });

    const output = [];
    while (tree.min !== null) {
      const cur = tree.min;
      const value = minVal + cur;
      const high = universe > 2 ? highOf(tree, cur) : null;
      const before = snapshotVeb(tree, minVal, {
        activeValue: value,
        activeCluster: high,
        mode: 'extract',
      });

      let c;
      for (c = 0; c < count[cur]; c++) {
        output.push(value);
        steps.push({
          kind: 'extract',
          value: value,
          output: output.slice(),
          tree: before,
        });
      }

      vebDelete(tree, cur);
      steps.push({
        kind: 'tree_delete',
        value: value,
        output: output.slice(),
        tree: snapshotVeb(tree, minVal, {
          activeValue: value,
          activeCluster: high,
          mode: 'extract',
        }),
      });
    }

    steps.push({
      kind: 'done',
      arr: output.slice(),
      tree: snapshotVeb(tree, minVal, { universe: universe, mode: 'extract' }),
    });
    return steps;
  }

  const vebView = createVebView(root);

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-van-emde-boas',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '下の vEB 木へキーを挿入し、最小値を取り出して昇順へ並べます',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    afterRebuild: function () {
      renderVeb(vebView, null);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        renderVeb(vebView, s.tree);
        if (s.phase === 'insert') {
          api.setCaption(
            'フェーズ1: 宇宙サイズ U = ' +
              s.universe +
              ' の空の vEB 木を用意し、出現回数を集めます'
          );
        } else if (s.phase === 'build') {
          api.setCaption(
            'フェーズ2: ユニークキーを vEB 木へ挿入します（下図が木の状態）'
          );
        } else {
          api.setCaption(
            'フェーズ3: 最小値 ' +
              s.treeMin +
              ' から順に取り出し、木から削除します'
          );
        }
        return;
      }
      if (s.kind === 'count') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'cursor']]);
        renderVeb(vebView, s.tree);
        api.setCaption(
          '集計: 位置 ' +
            s.i +
            ' の値 ' +
            s.value +
            '（オフセット ' +
            (s.value - s.minVal) +
            '）を数えます'
        );
        return;
      }
      if (s.kind === 'insert') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        renderVeb(vebView, s.tree);
        api.setCaption(
          'vEB へ挿入: 値 ' +
            s.value +
            ' → high=' +
            s.high +
            ', low=' +
            s.low +
            '（min=' +
            s.treeMin +
            ', max=' +
            s.treeMax +
            '）'
        );
        return;
      }
      if (s.kind === 'extract') {
        api.mountBars(barsEl, s.output);
        DemoSort.assignRoles(barsEl, [[s.output.length - 1, 'write']]);
        renderVeb(vebView, s.tree);
        api.setCaption(
          '取り出し: 木の最小値 ' +
            s.value +
            ' を位置 ' +
            (s.output.length - 1) +
            ' へ書き込み'
        );
        return;
      }
      if (s.kind === 'tree_delete') {
        api.mountBars(barsEl, s.output);
        DemoSort.clearRoles(barsEl);
        renderVeb(vebView, s.tree);
        api.setCaption(
          '木から削除: 値 ' +
            s.value +
            ' を外し、次の最小値へ進みます'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        renderVeb(vebView, s.tree);
        api.setCaption('ソート完了（vEB 木は空）');
      }
    },
    stepPauseMs: function (api) {
      const step = api.steps[api.idx];
      if (!step) {
        return 280;
      }
      if (step.kind === 'insert' || step.kind === 'tree_delete') {
        return 340;
      }
      if (step.kind === 'extract') {
        return 260;
      }
      return 220;
    },
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="van-emde-boas-sort-demo"
  data_prefix="van-emde-boas"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[カウンティングソート](/2026/06/20/sort-counting.html) や [鳩の巣ソート](/2026/07/19/sort-pigeonhole.html) は値域 `k` に対し
`O(n + k)` で直接バケットを走査する。本アルゴリズムはバケット配列を線形走査する代わりに、vEB 木の
`O(log log U)` 操作で「次に小さいキー」だけをたどる。[ツリーソート](/2026/05/12/sort-tree.html) が比較で二分探索木を育てるのに対し、
ここでは宇宙のビット分割が順序を決める。[トライソート](/2026/07/11/sort-trie.html) の桁トライとも「桁で空間を割る」点は近いが、
summary による空クラスタのスキップが vEB 木の特徴である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000015 |        0.000058 |              27 |              27 |
|        512 |        0.000029 |        0.000098 |              55 |              55 |
|       1024 |        0.000060 |        0.000168 |             111 |             111 |
|       2048 |        0.000117 |        0.000287 |             222 |             222 |
|       4096 |        0.000221 |        0.000444 |             429 |             429 |
|       8192 |        0.000505 |        0.001049 |             859 |             859 |
|      16384 |        0.000924 |        0.001833 |            1734 |            1734 |
|      32768 |        0.001911 |        0.003886 |            3469 |            3469 |
|      65536 |        0.005080 |        0.008338 |            7185 |            7185 |
|     131072 |        0.011295 |        0.018199 |           14371 |           14371 |
|     262144 |        0.022125 |        0.042553 |           28695 |           28695 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="van_emde_boas" %}
