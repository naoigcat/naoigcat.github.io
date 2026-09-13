---
title:     置換選択ソートで配列を並び替える
date:      2026-09-06 09:10:39 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## 置換選択ソートを使用する

置換選択ソート (`replacement selection sort`) は、限られた大きさの最小ヒープで入力を流し、平均でヒープ容量の約 2 倍の長さの整列済みランを生成し、それらをマージして全体を昇順にする整列である。

外部整列ではメモリに載らないファイルを扱うとき、単純にメモリ分だけ読んでクイックソートすると初期ラン長はメモリ容量 `M` に留まる。
置換選択では、出力した直前のキー以上の入力だけをヒープへ戻す（置換する）ことで、ランダム入力でも期待ラン長がおよそ `2M` になる。
昇順に近い入力ではさらに長くなり、最悪（厳密な降順）では `M` まで縮む。

本記事のデモとベンチマークでは、主記憶上の配列を入力ストリームとみなし、容量 `M` の最小ヒープでランを作ったあと、ラン同士をマージして配列へ書き戻す。

1.  **充填**: 入力から最大 `M` 個を読み、最小ヒープを構築する。
2.  **抽出と置換**: ヒープの最小を現在ランへ出力する。次の入力が直前の出力以上なら根へ入れて沈降（現在ランに残す）。小さければ次ラン用の待避領域へ置き、ヒープは縮む。
3.  **ラン区切り**: ヒープが空になったら現在ランを確定し、待避していた要素でヒープを組み直して次ランを始める。入力が尽きるまで繰り返す。
4.  **マージ**: できたランをマージし、1 本の昇順列にする。

```pseudocode
procedure sift_down(H, i)
  // 最小ヒープ条件を満たすよう H[i] を沈降

procedure generate_runs(input, M)
  H = first min(M, length(input)) elements; heapify_min(H)
  frozen = empty; run = empty; i = |H|
  while true
    if H is empty then
      if run nonempty then emit run; run = empty
      if frozen empty and i >= length(input) then break
      H = frozen; frozen = empty
      while i < length(input) and |H| < M
        append input[i] to H; i = i + 1
      heapify_min(H)
      continue
    out = extract_min(H)
    append out to run
    if i < length(input) then
      next = input[i]; i = i + 1
      if next >= out then insert next into H
      else append next to frozen
  return all emitted runs

procedure replacement_selection_sort(A)
  runs = generate_runs(A, M)
  A = merge_all(runs)
```

ラン生成は各要素がヒープへ高々定数回出入りするため $$O(n \log M)$$、マージはラン数を `R` とすると概ね $$O(n \log R)$$ で、合計は $$O(n \log n)$$ 程度になる。
ヒープと待避・ラン用に $$O(M + n)$$ の追加領域が要り、一般に不安定である。デモでは `M = 4`、ベンチマークでは `M = 32` とする。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('replacement-selection-sort-demo', function (root) {
  const HEAP_SIZE = 4;
  const barClass = 'sort-demo__bar';

  function siftDown(heap, i, onStep) {
    const n = heap.length;
    while (true) {
      const left = 2 * i + 1;
      const right = left + 1;
      let smallest = i;
      if (left < n) {
        if (onStep) onStep('compare', i, left);
        if (heap[left] < heap[smallest]) smallest = left;
      }
      if (right < n) {
        if (onStep) onStep('compare', smallest, right);
        if (heap[right] < heap[smallest]) smallest = right;
      }
      if (smallest === i) break;
      const t = heap[i];
      heap[i] = heap[smallest];
      heap[smallest] = t;
      if (onStep) onStep('swap', i, smallest);
      i = smallest;
    }
  }

  function siftUp(heap, i, onStep) {
    while (i > 0) {
      const parent = Math.floor((i - 1) / 2);
      if (onStep) onStep('compare', i, parent);
      if (heap[i] >= heap[parent]) break;
      const t = heap[i];
      heap[i] = heap[parent];
      heap[parent] = t;
      if (onStep) onStep('swap', i, parent);
      i = parent;
    }
  }

  function heapTree(heap) {
    if (!heap.length) return null;
    function nodeAt(i) {
      if (i >= heap.length) return null;
      return {
        id: 'h' + i,
        value: heap[i],
        left: nodeAt(2 * i + 1),
        right: nodeAt(2 * i + 2)
      };
    }
    return nodeAt(0);
  }

  function mergeValues(left, right) {
    const out = [];
    let l = 0;
    let r = 0;
    while (l < left.length && r < right.length) {
      if (left[l] <= right[r]) {
        out.push(left[l]);
        l += 1;
      } else {
        out.push(right[r]);
        r += 1;
      }
    }
    while (l < left.length) {
      out.push(left[l]);
      l += 1;
    }
    while (r < right.length) {
      out.push(right[r]);
      r += 1;
    }
    return out;
  }

  function displayArr(doneRuns, run, frozen, unread) {
    const flat = [];
    for (let r = 0; r < doneRuns.length; r++) {
      for (let k = 0; k < doneRuns[r].length; k++) flat.push(doneRuns[r][k]);
    }
    return flat.concat(run).concat(frozen).concat(unread);
  }

  function regionRoles(doneLen, runLen, frozenLen, extra) {
    const pairs = [];
    for (let i = 0; i < doneLen; i++) pairs.push([i, 'sorted']);
    for (let i = 0; i < runLen; i++) pairs.push([doneLen + i, 'range']);
    const frozenBase = doneLen + runLen;
    for (let i = 0; i < frozenLen; i++) pairs.push([frozenBase + i, 'key']);
    if (extra) {
      for (let e = 0; e < extra.length; e++) pairs.push(extra[e]);
    }
    return pairs;
  }

  function doneFlatLen(doneRuns) {
    let n = 0;
    for (let r = 0; r < doneRuns.length; r++) n += doneRuns[r].length;
    return n;
  }

  function generateSteps(initial) {
    const steps = [];
    const n = initial.length;
    if (n <= 1) {
      steps.push({
        kind: 'done',
        arr: initial.slice(),
        tree: null,
        roles: []
      });
      return steps;
    }

    const m = Math.min(HEAP_SIZE, n);
    let i = 0;
    const heap = [];
    const doneRuns = [];
    let frozen = [];
    let run = [];
    let unread = initial.slice();

    // Bars never mirror heap-array order. Heap lives only in the tree, so sift
    // does not permute the bar chart. Bars are: done runs | current run | frozen | unread.
    function pushView(kind, text, extraRoles, activeId) {
      const doneLen = doneFlatLen(doneRuns);
      steps.push({
        kind: kind,
        text: text,
        arr: displayArr(doneRuns, run, frozen, unread),
        roles: regionRoles(doneLen, run.length, frozen.length, extraRoles || []),
        tree: heapTree(heap),
        activeId: activeId
      });
    }

    function animateSiftDown(start, phaseLabel) {
      const label = phaseLabel || 'ヒープ構築';
      siftDown(heap, start, function (op, a, b) {
        if (op === 'compare') {
          pushView(
            'compare',
            label + ': ヒープ位置 ' + a + ' と ' + b + ' を比較',
            [],
            'h' + a
          );
        } else {
          pushView(
            'sift',
            label + ': ヒープ位置 ' + a + ' と ' + b + ' を交換',
            [],
            'h' + b
          );
        }
      });
    }

    function animateSiftUp(start, phaseLabel) {
      const label = phaseLabel || '置換';
      siftUp(heap, start, function (op, a, b) {
        if (op === 'compare') {
          pushView(
            'compare',
            label + ': ヒープ位置 ' + a + ' と ' + b + ' を比較',
            [],
            'h' + a
          );
        } else {
          pushView(
            'sift',
            label + ': ヒープ位置 ' + a + ' と ' + b + ' を交換',
            [],
            'h' + b
          );
        }
      });
    }

    function animateHeapify(caption) {
      pushView('caption', caption, [], heap.length ? 'h0' : null);
      if (heap.length <= 1) return;
      for (let bi = Math.floor(heap.length / 2) - 1; bi >= 0; bi--) {
        pushView(
          'caption',
          'ヒープ構築: 内部ノード ' + bi + ' から sift-down',
          [],
          'h' + bi
        );
        animateSiftDown(bi, 'ヒープ構築');
      }
      pushView(
        'caption',
        '最小ヒープの構築完了（根が最小）',
        [],
        heap.length ? 'h0' : null
      );
    }

    function animateExtractMin() {
      const out = heap[0];
      pushView('extract', '最小 ' + out + ' をヒープから外す', [], 'h0');

      if (heap.length === 1) {
        heap.pop();
      } else {
        heap[0] = heap.pop();
        pushView(
          'caption',
          'ヒープ末尾を根へ移す（このあと sift-down）',
          [],
          heap.length ? 'h0' : null
        );
        if (heap.length > 1) {
          animateSiftDown(0, '再ヒープ化');
        }
      }

      run.push(out);
      const doneLen = doneFlatLen(doneRuns);
      pushView(
        'write',
        '最小 ' + out + ' を現在ランへ確定',
        [[doneLen + run.length - 1, 'write']],
        heap.length ? 'h0' : null
      );
      return out;
    }

    pushView(
      'caption',
      'メモリ容量 M=' +
        m +
        '。棒は確定ラン / 現在ラン / 待避 / 未読。ヒープは下の木のみ',
      [],
      null
    );

    while (i < n && heap.length < m) {
      const value = initial[i];
      i += 1;
      unread = initial.slice(i);
      heap.push(value);
      pushView(
        'fill',
        '充填: 未読の先頭 ' + value + ' をヒープへ（' + heap.length + '/' + m + '）',
        [],
        'h' + (heap.length - 1)
      );
    }
    animateHeapify('充填完了。木の上で sift-down して最小ヒープにする');

    while (true) {
      if (!heap.length) {
        if (run.length) {
          doneRuns.push(run.slice());
          run = [];
          pushView(
            'caption',
            'ラン #' + doneRuns.length + ' を確定',
            [],
            null
          );
        }
        if (!frozen.length && i >= n) break;

        for (let f = 0; f < frozen.length; f++) heap.push(frozen[f]);
        frozen = [];
        unread = initial.slice(i);
        pushView(
          'caption',
          '待避を次ラン用ヒープへ移す',
          [],
          heap.length ? 'h0' : null
        );
        while (i < n && heap.length < m) {
          const value = initial[i];
          i += 1;
          unread = initial.slice(i);
          heap.push(value);
          pushView(
            'fill',
            '再充填: 未読の先頭 ' +
              value +
              ' をヒープへ（' +
              heap.length +
              '/' +
              m +
              '）',
            [],
            'h' + (heap.length - 1)
          );
        }
        if (!heap.length) break;
        animateHeapify('待避と未読から次ラン用ヒープを再構築');
        continue;
      }

      const out = animateExtractMin();
      const doneLen = doneFlatLen(doneRuns);

      if (i < n) {
        const next = initial[i];
        i += 1;
        unread = initial.slice(i);
        if (next >= out) {
          heap.push(next);
          pushView(
            'replace',
            '置換: 次入力 ' + next + ' ≥ 直前出力 ' + out + ' → ヒープへ',
            [],
            'h' + (heap.length - 1)
          );
          if (heap.length > 1) {
            animateSiftUp(heap.length - 1, '置換');
          }
        } else {
          frozen.push(next);
          pushView(
            'freeze',
            '待避: 次入力 ' + next + ' < 直前出力 ' + out + ' → 次ラン用',
            [[doneLen + run.length + frozen.length - 1, 'key']],
            heap.length ? 'h0' : null
          );
        }
      }
    }

    let queue = doneRuns.map(function (r) {
      return r.slice();
    });
    steps.push({
      kind: 'caption',
      text: 'ラン生成完了（' + queue.length + ' 本）。ペアワイズマージへ',
      arr: queue.reduce(function (acc, r) {
        return acc.concat(r);
      }, []),
      roles: regionRoles(
        queue.reduce(function (s, r) {
          return s + r.length;
        }, 0),
        0,
        0,
        []
      ),
      tree: null,
      activeId: null
    });

    while (queue.length > 1) {
      const nextQ = [];
      let idx = 0;
      while (idx + 1 < queue.length) {
        const left = queue[idx];
        const right = queue[idx + 1];
        const merged = mergeValues(left, right);
        const before = [];
        for (let t = 0; t < nextQ.length; t++) {
          for (let k = 0; k < nextQ[t].length; k++) before.push(nextQ[t][k]);
        }
        const mid = before.length + left.length;
        const arr = before.concat(left).concat(right);
        for (let t = idx + 2; t < queue.length; t++) {
          for (let k = 0; k < queue[t].length; k++) arr.push(queue[t][k]);
        }
        steps.push({
          kind: 'merge',
          text: 'ラン同士をマージ（長さ ' + left.length + ' と ' + right.length + '）',
          arr: arr,
          roles: (function () {
            const pairs = [];
            for (let p = 0; p < before.length; p++) pairs.push([p, 'sorted']);
            for (let p = before.length; p < mid; p++) pairs.push([p, 'range']);
            for (let p = mid; p < mid + right.length; p++) pairs.push([p, 'cursor']);
            return pairs;
          })(),
          tree: null,
          activeId: null
        });
        nextQ.push(merged);
        const afterMerge = before.concat(merged);
        for (let t = idx + 2; t < queue.length; t++) {
          for (let k = 0; k < queue[t].length; k++) afterMerge.push(queue[t][k]);
        }
        steps.push({
          kind: 'merge-result',
          text: 'マージ結果（長さ ' + merged.length + '）',
          arr: afterMerge,
          roles: (function () {
            const pairs = [];
            for (let p = 0; p < before.length + merged.length; p++) {
              pairs.push([p, 'sorted']);
            }
            return pairs;
          })(),
          tree: null,
          activeId: null
        });
        idx += 2;
      }
      if (idx < queue.length) nextQ.push(queue[idx].slice());
      queue = nextQ;
    }

    const sorted = queue.length ? queue[0] : [];
    steps.push({
      kind: 'done',
      arr: sorted.slice(),
      tree: null,
      roles: []
    });
    return steps;
  }

  const treeView = DemoSort.createBinaryTreeView(root, {
    label: '現在の最小ヒープ（青: 根、紫: 注目ノード）。棒には載せない',
    emptyText: 'ヒープは空です'
  });

  function paintTree(tree, activeId) {
    DemoSort.renderBinaryTree(treeView, tree, {
      activeId: activeId,
      ariaLabel: '置換選択の最小ヒープ'
    });
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-replacement-selection',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 4, 7, 10, 12, 11],
    initialCaption:
      '置換選択ソートのデモ（棒: 確定ラン / 現在ラン / 待避 / 未読。ヒープは下の木）',
    barClass: barClass,
    generateSteps: generateSteps,
    afterRebuild: function () {
      paintTree(null, null);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      const prev = barsEl.dataset.lastArr || '';
      const next = (s.arr || []).join(',');
      // Remount only when the bar sequence actually changes.
      if (prev !== next) {
        api.mountBars(barsEl, s.arr);
        barsEl.dataset.lastArr = next;
      }
      if (s.kind === 'done') {
        DemoSort.clearRoles(barsEl);
        paintTree(null, null);
        api.setCaption('ソート完了');
        barsEl.dataset.lastArr = '';
        return;
      }
      DemoSort.assignRoles(barsEl, s.roles || []);
      paintTree(s.tree, s.activeId);
      api.setCaption(s.text);
    },
    stepPauseMs: 280
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="replacement-selection-sort-demo"
  data_prefix="replacement-selection"
  script=sort_demo_js
%}

外部整列の初期ラン生成として置換選択を使い、できたランを[ポリフェーズマージ](/2026/06/26/sort-polyphase-merge.html)などでマージするのが古典的な組み合わせである。メモリ全体をヒープに使えるならランは 1 本になり、振る舞いは最小ヒープからの連続抽出に近づく。

## 類似アルゴリズムとの相違点

[ヒープソート](/2026/05/04/sort-heap.html)は配列全体をヒープ化しインプレースで縮める。置換選択は容量 `M` の窓だけをヒープに保ち、ストリームからランを伸ばす。

[トーナメントソート](/2026/05/26/sort-tournament.html)や[敗者木ソート](/2026/08/26/sort-loser-tree.html)は「次の最小」を木で更新する構造が近く、外部マージの選択木としても使われる。置換選択はラン長を伸ばす生成法としての側面が強い。

[ストランドソート](/2026/05/16/sort-strand.html)も単調列を切り取ってマージするが、ヒープによる置換は行わず、1 回の走査で拾える非減少部分列に限る。

[ポリフェーズマージソート](/2026/06/26/sort-polyphase-merge.html)は固定長チャンクを初期ランとする実装が多い。置換選択で長い初期ランを渡せば、マージパス数をさらに抑えられる。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000022 |        0.001439 |               4 |               5 |
|        512 |        0.000045 |        0.001127 |              10 |              11 |
|       1024 |        0.000087 |        0.001155 |              20 |              23 |
|       2048 |        0.000185 |        0.003634 |              40 |              44 |
|       4096 |        0.000350 |        0.003149 |              81 |              86 |
|       8192 |        0.000734 |        0.004720 |             163 |             171 |
|      16384 |        0.002018 |        0.056631 |             326 |             336 |
|      32768 |        0.004071 |        0.037409 |             652 |             668 |
|      65536 |        0.007650 |        0.050894 |            1305 |            1332 |
|     131072 |        0.015410 |        0.096450 |            2609 |            2654 |
|     262144 |        0.032595 |        0.099702 |            5216 |            5291 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="replacement_selection" %}
