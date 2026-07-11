---
title:     デカルト木ソートで配列を並び替える
date:      2026-05-22 06:17:08 +0900
tags:      sort
sort_demo: true
---

## デカルト木ソートを使用する

デカルト木ソート (`cartesian tree sort`) は、配列からデカルト木を一度だけ構築し、根（部分木の最小値）を先頭に取り出しつつ左右部分木の結果をマージして昇順の並びを得る。

デカルト木は次の2条件を同時に満たす二分木である。

1.  **中順が元の配列順**: 左部分木 → 根 → 右部分木の順に走査すると、元の配列の左から右への並び（添字の昇順）になる。
2.  **ヒープ性**: 最小デカルト木では、各親の値は両方の子以下である（最大デカルト木では逆）。

入力配列が決まれば、値がすべて異なるときデカルト木の形は一意に定まる。整列では最小デカルト木を想定する。

素朴に「根を選んで再帰的に部分木を作る」と `O(n²)` になりうるが、単調スタック (`monotonic stack`) を使えば各添字はスタックに高々1回入り1回出るため、全体で `O(n)` 時間に木を構築できる。

添字 `i` を左から処理するときの典型形は次のとおりである。

1.  スタック上端より大きい値の添字を、値が `A[i]` 以下になるまで取り出す（最後に取り出した添字を `last` とする）。
2.  スタックが空でなければ、`A[i]` はスタック上端の右の子になる。
3.  `last` があれば、その添字は `i` の左の子になる。
4.  `i` をスタックに追加する。

```pseudocode
procedure build_cartesian_tree(A)
  stack = empty stack of indices
  for i from 0 to length(A) - 1
    last = null
    while stack not empty and A[stack.top] > A[i]
      last = stack.pop()
    if stack not empty
      right[stack.top] = i
    if last not null
      left[i] = last
    stack.push(i)
  return tree encoded by left[], right[], and stack[0] as root
```

構築後、各ノードについて根のキーを出力し、左右部分木から得たすでに昇順の列をマージする再帰的取出しで整列する。左右部分木は元配列の連続部分区間に対応するため、再帰の各段階で部分列は昇順に保たれる。

```pseudocode
procedure merge(L, R)
  // 2 つの昇順列を先頭から比較しながら連結する

procedure extract_sorted(node)
  if node is null
    return empty list
  left = extract_sorted(left[node])
  right = extract_sorted(right[node])
  return [A[node]] followed by merge(left, right)
```

スタックで `O(n)` 構築でき、素朴な取出しは `O(n log n)` となる。添字情報も使うため、比較ソートの下界とは前提が異なる。

クイックソートの分割木や、二分木ソートの「挿入順で形が変わる木」とも対比しやすい。範囲最小クエリ (`RMQ`) や最長増加部分列 (`LIS`) など、同じスタック構造が別問題でも登場する。

以下のデモでは、同値の棒が入れ替わらないよう、ヒープ比較を値が異なれば値、等しければ元の位置 `id` の辞書式順にしている（可視化上の安定化であり、一般のデカルト木ソートの性質を変えるものではない）。

1.  **構築**: 左から添字を処理し、スタックとの比較（オレンジ）とリンク付け（紫）を示す。木自体は内部データとして保持する。
2.  **取出し**: 根優先の再帰取出し＋マージで得た昇順に、配列上の棒をスワップ（緑）で並べ替えて視覚化する（実装では取出し結果を別バッファへ書くだけでよい）。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('cartesian-tree-sort-demo', function (root) {
  function cmp(a, b) {
    if (a.value !== b.value) return a.value < b.value ? -1 : 1;
    if (a.id !== b.id) return a.id < b.id ? -1 : 1;
    return 0;
  }

  function buildCartesianTree(ids, steps) {
    const n = ids.length;
    const left = new Array(n).fill(-1);
    const right = new Array(n).fill(-1);
    const stack = [];

    for (let i = 0; i < n; i++) {
      const item = ids[i];
      let last = -1;

      steps.push({
        kind: 'process',
        idx: i,
        value: item.value,
        caption: '添字 ' + i + '（値 ' + item.value + '）を処理'
      });

      while (stack.length > 0) {
        const top = stack[stack.length - 1];
        steps.push({
          kind: 'compare',
          idx: i,
          top: top,
          topValue: ids[top].value,
          caption:
            'スタック上端 添字 ' +
            top +
            '（値 ' +
            ids[top].value +
            '）と比較'
        });
        if (cmp(ids[top], item) > 0) {
          last = stack.pop();
          steps.push({
            kind: 'pop',
            idx: last,
            caption: 'pop: 添字 ' + last + ' をスタックから取り出す'
          });
        } else {
          break;
        }
      }

      if (stack.length > 0) {
        const parentIdx = stack[stack.length - 1];
        right[parentIdx] = i;
        steps.push({
          kind: 'link',
          idx: i,
          parent: parentIdx,
          side: 'right',
          caption:
            '添字 ' + i + ' を 添字 ' + parentIdx + ' の右の子にする'
        });
      }

      if (last !== -1) {
        left[i] = last;
        steps.push({
          kind: 'link',
          idx: i,
          parent: last,
          side: 'left',
          caption: '添字 ' + last + ' を 添字 ' + i + ' の左の子にする'
        });
      }

      stack.push(i);
      steps.push({
        kind: 'push',
        idx: i,
        caption: 'push: 添字 ' + i + ' をスタックへ'
      });
    }

    const root = stack.length > 0 ? stack[0] : -1;
    return { left: left, right: right, root: root };
  }

  function mergeSorted(leftList, rightList) {
    const out = [];
    let li = 0;
    let ri = 0;
    while (li < leftList.length && ri < rightList.length) {
      if (cmp(leftList[li], rightList[ri]) <= 0) {
        out.push(leftList[li++]);
      } else {
        out.push(rightList[ri++]);
      }
    }
    while (li < leftList.length) out.push(leftList[li++]);
    while (ri < rightList.length) out.push(rightList[ri++]);
    return out;
  }

  function extractSorted(node, left, right, ids) {
    if (node === -1) return [];
    const leftList = extractSorted(left[node], left, right, ids);
    const rightList = extractSorted(right[node], left, right, ids);
    return [ids[node]].concat(mergeSorted(leftList, rightList));
  }

  function generateSteps(vals) {
    const steps = [];
    const ids = vals.map(function (v, i) {
      return { value: v, id: i };
    });

    steps.push({
      kind: 'phase_build',
      arr: vals.slice()
    });

    const tree = buildCartesianTree(ids, steps);

    const sortedKeys = extractSorted(
      tree.root,
      tree.left,
      tree.right,
      ids
    );
    const sortedIds = sortedKeys.map(function (x) {
      return x.id;
    });

    steps.push({
      kind: 'phase_reorder',
      caption:
        '根優先取出し＋マージで得た昇順に並べ替えます（スワップで視覚化）'
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
      'デカルト木ソートの棒。左から現在の並びで位置0、1…の順です。'
    );
    DemoSort.syncBarsAccessibility(container);
  }

  function domIndexForOrig(container, origIndex) {
    const nodes = container.children;
    for (let ni = 0; ni < nodes.length; ni++) {
      if (nodes[ni].dataset.origIndex === String(origIndex)) {
        return ni;
      }
    }
    return -1;
  }

  function assignOrigRoles(container, pairs) {
    const mapped = [];
    for (let pi = 0; pi < pairs.length; pi++) {
      const domIdx = domIndexForOrig(container, pairs[pi][0]);
      if (domIdx !== -1) mapped.push([domIdx, pairs[pi][1]]);
    }
    DemoSort.assignRoles(container, mapped);
  }

  function setIndexRole(container, origIndex, role) {
    assignOrigRoles(container, [[origIndex, role]]);
  }

  function rebuildOrderFromPerm(api, perm) {
    api.permState = perm.slice();
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-cartesian',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'デカルト木ソート（単調スタック構築＋昇順取出し）。比較はオレンジ、リンクは紫、スワップは緑です。',
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
        'デカルト木ソート（単調スタック構築＋昇順取出し）。比較はオレンジ、リンクは紫、スワップは緑です。'
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase_build') {
        mountBars(barsEl, api.values, api.permState);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '1. 左から添字を処理し、単調スタックで最小デカルト木を構築します'
        );
        return;
      }
      if (s.kind === 'process') {
        mountBars(barsEl, api.values, api.permState);
        setIndexRole(barsEl, s.idx, 'cursor');
        api.setCaption(s.caption);
        return;
      }
      if (s.kind === 'compare') {
        mountBars(barsEl, api.values, api.permState);
        assignOrigRoles(barsEl, [
          [s.idx, 'compare'],
          [s.top, 'compare']
        ]);
        api.setCaption(s.caption);
        return;
      }
      if (s.kind === 'pop') {
        mountBars(barsEl, api.values, api.permState);
        setIndexRole(barsEl, s.idx, 'pivot');
        api.setCaption(s.caption);
        return;
      }
      if (s.kind === 'link') {
        mountBars(barsEl, api.values, api.permState);
        const linkRoles = [[s.idx, 'key']];
        if (s.parent !== undefined) linkRoles.push([s.parent, 'insert']);
        assignOrigRoles(barsEl, linkRoles);
        api.setCaption(s.caption);
        return;
      }
      if (s.kind === 'push') {
        mountBars(barsEl, api.values, api.permState);
        setIndexRole(barsEl, s.idx, 'heap');
        api.setCaption(s.caption);
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
      const step = api.steps[api.idx];
      if (!step) return 220;
      if (step.kind === 'swap') return 340;
      if (step.kind === 'compare') return 260;
      return 200;
    },
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="cartesian-tree-sort-demo"
  data_prefix="cartesian"
  script=sort_demo_js
%}

二分木ソートのように平衡木への挿入を繰り返すのではなく、配列と添字順から一度でデカルト木が定まる点が特徴である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000017 |        0.000588 |            1691 |            1708 |
|        512 |        0.000034 |        0.000408 |            1719 |            1740 |
|       1024 |        0.000068 |        0.000581 |            1770 |            1792 |
|       2048 |        0.000141 |        0.000546 |            1863 |            1892 |
|       4096 |        0.000288 |        0.000746 |            2036 |            2084 |
|       8192 |        0.000601 |        0.001540 |            2175 |            2304 |
|      16384 |        0.001261 |        0.001782 |            2835 |            3072 |
|      32768 |        0.002794 |        0.148427 |            4130 |            4480 |
|      65536 |        0.005823 |        0.016330 |            6594 |            7156 |
|     131072 |        0.011940 |        0.017344 |           11486 |           12660 |
|     262144 |        0.024275 |        0.042929 |           21272 |           23792 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="cartesian_tree" %}
