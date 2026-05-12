---
layout: post
title:  マージソートで配列を並び替える
date:   2026-05-03 08:31:07 +0900
tags:   sort
---

## マージソートを使用する

マージソート (`merge sort`) は、配列を半分に **分割** し、それぞれを再帰的にソートしてから、2つの **すでにソート済みの列を1本にマージ（併合）** することで全体を整列させる比較ソートである。分割の深さが O(log n) で、マージが線形時間なので、**最悪でも** O(n log n) で安定して動作する点が特徴である。

1.  **分割**: 区間 `[lo, hi]` の中央 `mid` で左半分 `[lo, mid]` と右半分 `[mid+1, hi]` に分ける。要素が1つだけならそのままソート済みとみなす。
2.  **再帰**: 左右それぞれに対して同じ手順を繰り返す。
3.  **マージ**: 左と右はそれぞれ昇順になっている前提で、先頭同士を比較しながら小さい方から確定させ、どちらか一方が尽きたら残りを順に連結する。結果は補助配列などに書き、`a[lo..hi]` へ写し戻す。

```pseudocode
procedure merge_sort(A, lo, hi)
  if lo >= hi then
    return
  mid = floor((lo + hi) / 2)
  merge_sort(A, lo, mid)
  merge_sort(A, mid + 1, hi)
  merge(A, lo, mid, hi)

procedure merge(A, lo, mid, hi)
  i = lo
  j = mid + 1
  k = 0
  while i <= mid and j <= hi
    if A[i] <= A[j] then
      B[k] = A[i]
      i = i + 1
    else
      B[k] = A[j]
      j = j + 1
    k = k + 1
  copy rest of left or right slice into B
  copy B back into A[lo .. hi]
```

時間計算量は常に **O(n log n)**。マージ用に **O(n)** の追加記憶領域が必要で、多くの実装は **安定ソート**（等しいキーの相対順序を保つ）である。インプレース志向のクイックソートと比べて余分なメモリは要するが、最悪時の挙動が予測しやすいため外部ソートの基礎にも使われる。

<!-- markdownlint-disable MD046 -->
<div id="merge-sort-demo" class="merge-sort-demo">
<style>
.merge-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.merge-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.merge-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.merge-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.merge-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.merge-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.merge-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.merge-sort-demo__bar[data-role="range"] {
  outline: 3px solid #3498db;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(52,152,219,.35), 0 2px 6px rgba(0,0,0,.18);
}
.merge-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.merge-sort-demo__bar[data-role="write"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(39,174,96,.35), 0 2px 6px rgba(0,0,0,.18);
}
.merge-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .merge-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .merge-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .merge-sort-demo__caption { color: #bbb; }
}
</style>
<div class="merge-sort-demo__toolbar">
  <button type="button" data-ms="shuffle">シャッフル</button>
  <button type="button" data-ms="play">自動再生</button>
  <button type="button" data-ms="pause" disabled>一時停止</button>
  <button type="button" data-ms="step">1ステップ</button>
</div>
<div class="merge-sort-demo__bars" data-ms="bars" aria-live="polite"></div>
<p class="merge-sort-demo__caption" data-ms="caption"></p>
<script src="{{ '/assets/js/demo-sort.js' | relative_url }}"></script>
<script>
(function () {
  var root = document.getElementById('merge-sort-demo');
  if (!root) return;
  var C = window.DemoSort;
  if (!C) return;

  function mountBars(container, values) {
    C.mountBars(container, values, 'merge-sort-demo__bar');
  }

  function buildDisplay(a, lo, tmp) {
    var d = a.slice();
    for (var t = 0; t < tmp.length; t++) {
      d[lo + t] = tmp[t];
    }
    return d;
  }

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];

    function merge(lo, mid, hi) {
      steps.push({ kind: 'merge_start', lo: lo, mid: mid, hi: hi, arr: a.slice() });
      var tmp = [];
      var i = lo;
      var j = mid + 1;
      while (i <= mid && j <= hi) {
        steps.push({
          kind: 'merge_compare',
          lo: lo,
          mid: mid,
          hi: hi,
          i: i,
          j: j,
          arr: buildDisplay(a, lo, tmp),
        });
        if (a[i] <= a[j]) {
          tmp.push(a[i]);
          i++;
        } else {
          tmp.push(a[j]);
          j++;
        }
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      while (i <= mid) {
        tmp.push(a[i]);
        i++;
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      while (j <= hi) {
        tmp.push(a[j]);
        j++;
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      for (var t = 0; t < tmp.length; t++) {
        a[lo + t] = tmp[t];
      }
      steps.push({ kind: 'merge_done', lo: lo, hi: hi, arr: a.slice() });
    }

    function mergeSort(lo, hi) {
      if (lo >= hi) return;
      var mid = Math.floor((lo + hi) / 2);
      steps.push({ kind: 'split', lo: lo, hi: hi, mid: mid, arr: a.slice() });
      mergeSort(lo, mid);
      mergeSort(mid + 1, hi);
      merge(lo, mid, hi);
    }

    if (a.length > 0) {
      mergeSort(0, a.length - 1);
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

  function setRange(container, lo, hi) {
    clearRoles(container);
    var nodes = container.children;
    for (var k = lo; k <= hi && k < nodes.length; k++) {
      nodes[k].setAttribute('data-role', 'range');
    }
  }

  function setCompare(container, i, j) {
    clearRoles(container);
    var nodes = container.children;
    if (nodes[i]) nodes[i].setAttribute('data-role', 'compare');
    if (nodes[j]) nodes[j].setAttribute('data-role', 'compare');
  }

  function setWrite(container, pos) {
    clearRoles(container);
    var nodes = container.children;
    if (nodes[pos]) nodes[pos].setAttribute('data-role', 'write');
  }

  var barsEl = root.querySelector('[data-ms="bars"]');
  var capEl = root.querySelector('[data-ms="caption"]');
  var btnShuffle = root.querySelector('[data-ms="shuffle"]');
  var btnPlay = root.querySelector('[data-ms="play"]');
  var btnPause = root.querySelector('[data-ms="pause"]');
  var btnStep = root.querySelector('[data-ms="step"]');

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
      'マージソートのデモ（分割・マージ対象は青、比較はオレンジ、確定書き込みは緑）';
    syncButtons();
  }

  async function applyStepForward() {
    if (busy || idx >= steps.length) return;
    busy = true;
    syncButtons();
    try {
      var s = steps[idx];
      idx++;

      if (s.kind === 'split') {
        mountBars(barsEl, s.arr);
        setRange(barsEl, s.lo, s.hi);
        capEl.textContent =
          '分割: 区間 ' + s.lo + ' … ' + s.hi + '（中央 mid = ' + s.mid + '）';
        return;
      }

      if (s.kind === 'merge_start') {
        mountBars(barsEl, s.arr);
        setRange(barsEl, s.lo, s.hi);
        capEl.textContent =
          'マージ開始: 左 [' + s.lo + '…' + s.mid + '] と 右 [' + (s.mid + 1) + '…' + s.hi + ']';
        return;
      }

      if (s.kind === 'merge_compare') {
        mountBars(barsEl, s.arr);
        setCompare(barsEl, s.i, s.j);
        capEl.textContent = '比較: 位置 ' + s.i + ' と ' + s.j;
        return;
      }

      if (s.kind === 'merge_write') {
        mountBars(barsEl, s.arr);
        setWrite(barsEl, s.writePos);
        capEl.textContent = '先頭から確定: 位置 ' + s.writePos;
        return;
      }

      if (s.kind === 'merge_done') {
        mountBars(barsEl, s.arr);
        clearRoles(barsEl);
        capEl.textContent =
          '区間 ' + s.lo + ' … ' + s.hi + ' のマージが完了しました';
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

  btnStep.addEventListener('click', function () {
    applyStepForward();
  });

  btnPlay.addEventListener('click', async function () {
    playing = true;
    cancelled = false;
    syncButtons();
    while (!cancelled && idx < steps.length) {
      await applyStepForward();
      await C.wait(220);
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

バブルソートの O(n²) と比べてデータが大きい場面では有利になりやすく、クイックソートの最悪 O(n²) と比べて時間計算量のわるい入力がない反面、補助配列など **余計なメモリ** を使うトレードオフがある。
