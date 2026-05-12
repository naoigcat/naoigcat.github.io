---
layout: post
title:  イントロソートで配列を並び替える
date:   2026-05-07 05:03:13 +0900
tags:   sort
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

C++ の `std::sort` や、一部言語ランタイムの汎用ソートが、クイックソート系＋フォールバックという構成をとることがある。教育的には [バブルソート](/2026/05/01/sort-bubble.html) のように単純な比較ソートと対比すると、「平均の速さ」と「最悪保証」を両立する設計意図が把握しやすい。

以下のデモでは **閾値・深さ計算を実装と揃えたうえで**、オレンジは比較、緑は交換、紫は確定したピボット、青系は挿入ソート中の強調、ヒープフェーズ開始時はキャプションで明示する。**昇順に近いデータ**ではクイックソートの分割が偏りやすく、**ヒープソートへの切り替え** が現れやすい。

<!-- markdownlint-disable MD046 -->
<div id="intro-sort-demo" class="intro-sort-demo">
<style>
.intro-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.intro-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.intro-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.intro-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.intro-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.intro-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.intro-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.intro-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.intro-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.intro-sort-demo__bar[data-role="pivot"] {
  outline: 3px solid #9b59b6;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(155,89,182,.35), 0 2px 6px rgba(0,0,0,.18);
}
.intro-sort-demo__bar[data-role="insert"] {
  outline: 3px solid #2980b9;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(41,128,185,.35), 0 2px 6px rgba(0,0,0,.18);
}
.intro-sort-demo__bar[data-role="heap"] {
  outline: 3px solid #16a085;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(22,160,133,.35), 0 2px 6px rgba(0,0,0,.18);
}
.intro-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .intro-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .intro-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .intro-sort-demo__caption { color: #bbb; }
}
</style>
<div class="intro-sort-demo__toolbar">
  <button type="button" data-is="shuffle">シャッフル</button>
  <button type="button" data-is="sorted">昇順データ（ヒープ切替が出やすい）</button>
  <button type="button" data-is="play">自動再生</button>
  <button type="button" data-is="pause" disabled>一時停止</button>
  <button type="button" data-is="step">1ステップ</button>
</div>
<div class="intro-sort-demo__bars" data-is="bars" aria-live="polite"></div>
<p class="intro-sort-demo__caption" data-is="caption"></p>
<script src="{{ '/assets/js/demo-sort.js' | relative_url }}"></script>
<script>
(function () {
  var root = document.getElementById('intro-sort-demo');
  if (!root) return;
  var C = window.DemoSort;
  if (!C) return;

  function mountBars(container, values) {
    C.mountBars(container, values, 'intro-sort-demo__bar');
  }

  /** デモ用に小区間閾値を小さめにし、クイックフェーズが視覚化されやすくしている（実装ではしばしばもう少し大きい）。 */
  var INSERTION_THRESHOLD = 4;

  function maxDepthLimit(n) {
    if (n <= 1) return 0;
    return Math.floor(2 * Math.log2(n));
  }

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];

    function partition(lo, hi) {
      var pivotVal = a[hi];
      var i = lo;
      var j;
      for (j = lo; j <= hi - 1; j++) {
        steps.push({ kind: 'compare', lo: j, hi: hi, arr: a.slice(), phase: 'quick' });
        if (a[j] < pivotVal) {
          if (i !== j) {
            var t = a[i];
            a[i] = a[j];
            a[j] = t;
            steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice(), phase: 'quick' });
          }
          i++;
        }
      }
      if (i !== hi) {
        var t2 = a[i];
        a[i] = a[hi];
        a[hi] = t2;
        steps.push({ kind: 'swap', lo: i, hi: hi, arr: a.slice(), phase: 'quick' });
      }
      return i;
    }

    function insertionSort(lo, hi) {
      var i, j;
      for (i = lo + 1; i <= hi; i++) {
        j = i;
        while (j > lo) {
          steps.push({ kind: 'compare', lo: j - 1, hi: j, arr: a.slice(), phase: 'insert' });
          if (a[j - 1] > a[j]) {
            var t = a[j - 1];
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

    function siftDown(lo0, heapLen, root) {
      while (true) {
        var left = 2 * root + 1;
        var right = 2 * root + 2;
        var largest = root;
        if (left < heapLen && a[lo0 + left] > a[lo0 + largest]) largest = left;
        if (right < heapLen && a[lo0 + right] > a[lo0 + largest]) largest = right;
        if (largest === root) break;
        steps.push({ kind: 'heap_compare', lo: lo0 + root, hi: lo0 + largest, arr: a.slice() });
        var tmp = a[lo0 + root];
        a[lo0 + root] = a[lo0 + largest];
        a[lo0 + largest] = tmp;
        steps.push({ kind: 'swap', lo: lo0 + root, hi: lo0 + largest, arr: a.slice(), phase: 'heap' });
        root = largest;
      }
    }

    function heapsortRange(lo0, hi0) {
      steps.push({ kind: 'heap_start', lo: lo0, hi: hi0, arr: a.slice() });
      var n = hi0 - lo0 + 1;
      var i;
      for (i = Math.floor(n / 2) - 1; i >= 0; i--) {
        siftDown(lo0, n, i);
      }
      for (i = n - 1; i > 0; i--) {
        var t = a[lo0];
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
      var p = partition(lo, hi);
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

  function clearRoles(container) {
    var nodes = container.children;
    for (var k = 0; k < nodes.length; k++) {
      nodes[k].removeAttribute('data-role');
    }
  }

  function setRoles(container, lo, hi, kind, phase) {
    clearRoles(container);
    if (lo == null || hi == null) return;
    var nodes = container.children;
    if (kind === 'pivot' && lo === hi && nodes[lo]) {
      nodes[lo].setAttribute('data-role', 'pivot');
      return;
    }
    var swapOrCmp = kind === 'swap' ? 'swap' : 'compare';
    if (phase === 'insert') swapOrCmp = 'insert';
    if (phase === 'heap') swapOrCmp = 'heap';
    if (nodes[lo]) nodes[lo].setAttribute('data-role', swapOrCmp);
    if (nodes[hi]) nodes[hi].setAttribute('data-role', swapOrCmp);
  }

  var barsEl = root.querySelector('[data-is="bars"]');
  var capEl = root.querySelector('[data-is="caption"]');
  var btnShuffle = root.querySelector('[data-is="shuffle"]');
  var btnSorted = root.querySelector('[data-is="sorted"]');
  var btnPlay = root.querySelector('[data-is="play"]');
  var btnPause = root.querySelector('[data-is="pause"]');
  var btnStep = root.querySelector('[data-is="step"]');

  var values = [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15];
  var steps = [];
  var idx = 0;
  var playing = false;
  var cancelled = false;
  var busy = false;

  function syncButtons() {
    var atEnd = idx >= steps.length;
    btnPlay.disabled = playing || atEnd || busy;
    btnPause.disabled = !playing;
    btnStep.disabled = playing || atEnd || busy;
    btnShuffle.disabled = playing;
    btnSorted.disabled = playing;
  }

  function rebuild(v) {
    values = v;
    steps = generateSteps(values);
    idx = 0;
    cancelled = true;
    playing = false;
    busy = false;
    mountBars(barsEl, steps[0] ? steps[0].arr : values);
    capEl.textContent =
      'イントロソートのデモ（クイック／挿入／ヒープのハイブリッド。実線はフェーズに応じて色分け）';
    syncButtons();
  }

  async function applyStepForward() {
    if (busy || idx >= steps.length) return;
    busy = true;
    syncButtons();
    try {
      var s = steps[idx];
      idx++;

      if (s.kind === 'phase') {
        mountBars(barsEl, s.arr);
        clearRoles(barsEl);
        capEl.textContent = s.text;
        return;
      }

      if (s.kind === 'heap_start') {
        mountBars(barsEl, s.arr);
        clearRoles(barsEl);
        capEl.textContent =
          'ヒープソート開始: 位置 ' + s.lo + ' … ' + s.hi + ' の範囲を整列';
        return;
      }

      if (s.kind === 'heap_done') {
        mountBars(barsEl, s.arr);
        clearRoles(barsEl);
        capEl.textContent =
          'ヒープソート完了: 位置 ' + s.lo + ' … ' + s.hi + ' が整列しました';
        return;
      }

      if (s.kind === 'heap_compare') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, s.lo, s.hi, 'compare', 'heap');
        capEl.textContent = 'ヒープ: 親子関係を調整中（ティールの枠）';
        return;
      }

      if (s.kind === 'part_start') {
        mountBars(barsEl, s.arr);
        clearRoles(barsEl);
        capEl.textContent =
          'クイックソート分割: 位置 ' +
          s.lo +
          ' … ' +
          s.hi +
          '（残り許容深度 ' +
          s.depth +
          '、右端をピボット）';
        return;
      }

      if (s.kind === 'compare') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, s.lo, s.hi, 'compare', s.phase);
        if (s.phase === 'insert') {
          capEl.textContent = '挿入ソート: 隣接要素を比較';
        } else {
          capEl.textContent =
            '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）';
        }
        return;
      }

      if (s.kind === 'swap') {
        setRoles(barsEl, s.lo, s.hi, 'swap', s.phase);
        capEl.textContent = '交換しています…';
        await C.flipSwap(barsEl, s.lo, s.hi);
        clearRoles(barsEl);
        capEl.textContent =
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）';
        return;
      }

      if (s.kind === 'part_end') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, s.pivot, s.pivot, 'pivot');
        capEl.textContent =
          'ピボット確定: 位置 ' +
          s.pivot +
          '（残り許容深度はこの分割で 1 消費）';
        return;
      }

      if (s.kind === 'done') {
        mountBars(barsEl, s.arr);
        clearRoles(barsEl);
        capEl.textContent = 'ソート完了';
      }
    } finally {
      busy = false;
      syncButtons();
    }
  }

  btnShuffle.addEventListener('click', function () {
    rebuild(C.shuffleCopy(values));
  });

  btnSorted.addEventListener('click', function () {
    var arr = values.slice().sort(function (x, y) {
      return x - y;
    });
    rebuild(arr);
  });

  btnStep.addEventListener('click', function () {
    applyStepForward();
  });

  btnPlay.addEventListener('click', async function () {
    playing = true;
    cancelled = false;
    syncButtons();
    while (!cancelled && idx < steps.length) {
      await applyStepForward();
      await C.wait(260);
    }
    playing = false;
    syncButtons();
  });

  btnPause.addEventListener('click', function () {
    cancelled = true;
    playing = false;
    syncButtons();
  });

  rebuild(values);
})();
</script>
</div>
<!-- markdownlint-enable MD046 -->

ピボット選択や閾値、切片アルゴリズムは実装ごとに異なるが、「**高速な平均ケース**としてのクイックソート」と「**保証された最悪効率**としてのヒープソート」を組み合わせるという発想は、整列アルゴリズムを実務レベルへ押し上げる典型的な一手である。
