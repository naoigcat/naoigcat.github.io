---
title:     イントロソートで配列を並び替える
date:      2026-05-07 05:03:13 +0900
tags:      sort
sort_demo: true
---

## イントロソートを使用する

イントロソート (`introspective sort`) は、**クイックソートを主役にしつつ、再帰が深くなりすぎたらヒープソートに切り替え**、さらに **十分に短い部分配列では挿入ソート** で仕上げる、現実的な **ハイブリッド整列** である。

David R. Musser が 1997 年に提案し、最悪時間計算量を **O(n log n)** に保ちながら、平均的にはクイックソートに近い速度を狙える。

クイックソート単体は入力次第でピボット選びが偏り、再帰深度が O(n) になり **最悪 O(n²)** になり得る。

イントロソートは **許容する再帰の深さに上限**（多くの実装で **2·⌊log₂ n⌋** 前後）を設け、それを超えそうな区間だけヒープソートにフォールバックすることで、比較ソートとしての下界 **Ω(n log n)** に張り付いたまま、最悪ケースを回避する。

1.  **クイックソート**: 通常どおり分割と再帰を行う。
2.  **深さの監視**: 再帰の残り許容深度が 0 になった区間は、クイックソートを続けず **ヒープソート** で処理する。
3.  **小区間の挿入**: 要素数が閾値以下の部分配列は **挿入ソート** で済ませる（再帰オーバーヘッドとマージコストを抑える）。

```pseudocode
procedure introsort(A, lo, hi, depth_limit)
  if hi - lo <= INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  if depth_limit = 0 then
    heapsort(A, lo, hi)
    return
  p = partition(A, lo, hi)
  introsort(A, lo, p - 1, depth_limit - 1)
  introsort(A, p + 1, hi, depth_limit - 1)

procedure sort(A)
  introsort(A, 0, length(A) - 1, max(2 * floor(log2(length(A))), 1))
```

全体として **比較による最悪時間計算量は O(n log n)**（ヒープソート区間が支配的になりうる）、**追加メモリは実装次第だがヒープソート部分で O(1)** のインプレース志向を保ちやすい。**安定ソートではない** 場合が多い（ピボット型の分割・挿入ソートの交換が相対順序を変えうる）。

C++ の `std::sort` や、一部言語ランタイムの汎用ソートが、クイックソート系＋フォールバックという構成をとることがある。バブルソートのように単純な比較ソートと対比すると、「平均の速さ」と「最悪保証」を両立する設計意図が把握しやすい。

以下のデモでは **閾値・深さ計算を実装と揃えたうえで**、オレンジは比較、緑は交換、紫は確定したピボット、青系は挿入ソート中の強調、ヒープフェーズ開始時はキャプションで明示する。**昇順に近いデータ**ではクイックソートの分割が偏りやすく、**ヒープソートへの切り替え** が現れやすい。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('intro-sort-demo', function (root) {
  /** デモ用に小区間閾値を小さめにし、クイックフェーズが視覚化されやすくしている（実装ではしばしばもう少し大きい）。 */
  const INSERTION_THRESHOLD = 4;

  function maxDepthLimit(n) {
    if (n <= 0) return 0;
    const floorLog2 = Math.floor(Math.log2(n));
    return Math.max(2 * floorLog2, 1);
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function partition(lo, hi) {
      const pivotVal = a[hi];
      let i = lo;
      for (let j = lo; j <= hi - 1; j++) {
        steps.push({ kind: 'compare', lo: j, hi: hi, arr: a.slice(), phase: 'quick' });
        if (a[j] < pivotVal) {
          if (i !== j) {
            const t = a[i];
            a[i] = a[j];
            a[j] = t;
            steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice(), phase: 'quick' });
          }
          i++;
        }
      }
      if (i !== hi) {
        const t2 = a[i];
        a[i] = a[hi];
        a[hi] = t2;
        steps.push({ kind: 'swap', lo: i, hi: hi, arr: a.slice(), phase: 'quick' });
      }
      return i;
    }

    function insertionSort(lo, hi) {
      for (let i = lo + 1; i <= hi; i++) {
        let j = i;
        while (j > lo) {
          steps.push({ kind: 'compare', lo: j - 1, hi: j, arr: a.slice(), phase: 'insert' });
          if (a[j - 1] > a[j]) {
            const t = a[j - 1];
            a[j - 1] = a[j];
            a[j] = t;
            steps.push({ kind: 'swap', lo: j - 1, hi: j, arr: a.slice(), phase: 'insert' });
            j--;
          } else {
            break;
          }
        }
      }
    }

    function siftDown(lo0, heapLen, startRel) {
      let i = startRel;
      while (true) {
        const l = 2 * i + 1;
        const r = 2 * i + 2;
        let largest = i;
        if (l < heapLen) {
          steps.push({
            kind: 'compare',
            lo: lo0 + largest,
            hi: lo0 + l,
            arr: a.slice(),
            phase: 'heap',
          });
          if (a[lo0 + l] > a[lo0 + largest]) largest = l;
        }
        if (r < heapLen) {
          steps.push({
            kind: 'compare',
            lo: lo0 + largest,
            hi: lo0 + r,
            arr: a.slice(),
            phase: 'heap',
          });
          if (a[lo0 + r] > a[lo0 + largest]) largest = r;
        }
        if (largest === i) break;
        const tmp = a[lo0 + i];
        a[lo0 + i] = a[lo0 + largest];
        a[lo0 + largest] = tmp;
        steps.push({
          kind: 'swap',
          lo: lo0 + i,
          hi: lo0 + largest,
          arr: a.slice(),
          phase: 'heap',
        });
        i = largest;
      }
    }

    function heapsortRange(lo0, hi0) {
      steps.push({ kind: 'heap_start', lo: lo0, hi: hi0, arr: a.slice() });
      const n = hi0 - lo0 + 1;
      for (let i = Math.floor(n / 2) - 1; i >= 0; i--) {
        siftDown(lo0, n, i);
      }
      for (let i = n - 1; i > 0; i--) {
        const t = a[lo0];
        a[lo0] = a[lo0 + i];
        a[lo0 + i] = t;
        steps.push({ kind: 'swap', lo: lo0, hi: lo0 + i, arr: a.slice(), phase: 'heap' });
        siftDown(lo0, i, 0);
      }
      steps.push({ kind: 'heap_done', lo: lo0, hi: hi0, arr: a.slice() });
    }

    function intro(lo, hi, depth) {
      if (lo >= hi) return;
      if (hi - lo <= INSERTION_THRESHOLD) {
        steps.push({
          kind: 'phase',
          text:
            '要素が ' +
            (hi - lo + 1) +
            ' 個以下のため、この範囲は挿入ソート（閾値 ' +
            INSERTION_THRESHOLD +
            ' 以下）',
          arr: a.slice(),
        });
        insertionSort(lo, hi);
        return;
      }
      if (depth === 0) {
        steps.push({
          kind: 'phase',
          text: '深さ上限に達したため、この範囲はヒープソートへ切り替え（最悪 O(n log n) を担保）',
          arr: a.slice(),
        });
        heapsortRange(lo, hi);
        return;
      }
      steps.push({ kind: 'part_start', lo: lo, hi: hi, depth: depth, arr: a.slice() });
      const p = partition(lo, hi);
      steps.push({ kind: 'part_end', pivot: p, depth: depth, arr: a.slice() });
      intro(lo, p - 1, depth - 1);
      intro(p + 1, hi, depth - 1);
    }

    if (a.length > 0) {
      intro(0, a.length - 1, maxDepthLimit(a.length));
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function rolePair(lo, hi, role) {
    if (lo == null || hi == null) return [];
    return [[lo, role], [hi, role]];
  }

  function phaseRole(kind, phase) {
    if (phase === 'insert') return 'insert';
    if (phase === 'heap') return 'heap';
    return kind === 'swap' ? 'swap' : 'compare';
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-intro',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'イントロソートのデモ（クイック／挿入／ヒープのハイブリッド。実線はフェーズに応じて色分け）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'heap_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ヒープソート開始: 位置 ' + s.lo + ' … ' + s.hi + ' の範囲を整列'
        );
        return;
      }
      if (s.kind === 'heap_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ヒープソート完了: 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            ' が整列しました'
        );
        return;
      }
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'クイックソート分割: 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（残り許容深度 ' +
            s.depth +
            '、右端をピボット）'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rolePair(s.lo, s.hi, phaseRole('compare', s.phase)));
        if (s.phase === 'insert') {
          api.setCaption('挿入ソート: 隣接要素を比較');
        } else if (s.phase === 'heap') {
          api.setCaption(
            'ヒープ: 位置 ' + s.lo + ' と ' + s.hi + ' を比較（ティールの枠）'
          );
        } else {
          api.setCaption(
            '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）'
          );
        }
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, rolePair(s.lo, s.hi, phaseRole('swap', s.phase)));
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          'ピボット確定: 位置 ' +
            s.pivot +
            '（残り許容深度はこの分割で 1 消費）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="intro-sort-demo"
  preset="intro"
  data_prefix="intro"
  script=sort_demo_js
%}

ピボット選択や閾値、切片アルゴリズムは実装ごとに異なるが、「**高速な平均ケース**としてのクイックソート」と「**保証された最悪効率**としてのヒープソート」を組み合わせるという発想は、整列アルゴリズムを実務レベルへ押し上げる典型的な一手である。
