---
layout: post
title:  クイックソートで配列を並び替える
date:   2026-05-02 01:56:15 +0900
tags:   sort
---

## クイックソートを使用する

クイックソート (`quick sort`) は、**基準値（ピボット）**を1つ選び、配列を「ピボットより小さい要素」と「ピボット以上の要素」に分ける **分割（partition）** を行い、その両側に同じ処理を再帰的に適用することで整列する比較ソートである。分割が一度の走査で済むため、平均的に高速に動作する。

1.  **ピボットの選択**: 部分配列の先頭・末尾・中央などから1要素をピボットとして選ぶ（実装により様々な選び方がある）。
2.  **分割**: ピボットを基準に、左側にピボット未満の要素、右側にピボット以上の要素が来るように要素を並べ替える。ピボット自体は最終的な位置に置かれる。
3.  **再帰**: ピボットの左側の部分配列と右側の部分配列に対して、要素が1つ以下になるまで手順1〜2を繰り返す。

```pseudocode
procedure quick_sort(A, lo, hi)
  if lo >= hi then
    return
  p = partition(A, lo, hi)
  quick_sort(A, lo, p - 1)
  quick_sort(A, p + 1, hi)

procedure partition(A, lo, hi)
  pivot = A[hi]
  i = lo
  for j from lo to hi - 1
    if A[j] < pivot then
      swap(A[i], A[j])
      i = i + 1
  swap(A[i], A[hi])
  return i
```

期待時間計算量は O(n log n) で、ピボットの選び方が悪いと（すでにソート済みなど）最悪 O(n²) に落ちる。空間計算量は実装次第だが、再帰のスタックを除けば原則として O(1) の追加領域で済む **インプレース** の実装が多い。等しいキーの相対順序を保たない **不安定** なソートであることが一般的である。

<!-- markdownlint-disable MD046 -->
<div id="quick-sort-demo" class="quick-sort-demo">
<style>
.quick-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.quick-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.quick-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.quick-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.quick-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.quick-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.quick-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.quick-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.quick-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.quick-sort-demo__bar[data-role="pivot"] {
  outline: 3px solid #9b59b6;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(155,89,182,.35), 0 2px 6px rgba(0,0,0,.18);
}
.quick-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .quick-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .quick-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .quick-sort-demo__caption { color: #bbb; }
}
</style>
<div class="quick-sort-demo__toolbar">
  <button type="button" data-qs="shuffle">シャッフル</button>
  <button type="button" data-qs="play">自動再生</button>
  <button type="button" data-qs="pause" disabled>一時停止</button>
  <button type="button" data-qs="step">1ステップ</button>
</div>
<div class="quick-sort-demo__bars" data-qs="bars" aria-live="polite"></div>
<p class="quick-sort-demo__caption" data-qs="caption"></p>
<script>
(function () {
  var root = document.getElementById('quick-sort-demo');
  if (!root) return;

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    function partition(lo, hi) {
      var pivotVal = a[hi];
      var i = lo;
      var j;
      for (j = lo; j <= hi - 1; j++) {
        steps.push({ kind: 'compare', lo: j, hi: hi, arr: a.slice() });
        if (a[j] < pivotVal) {
          if (i !== j) {
            var t = a[i];
            a[i] = a[j];
            a[j] = t;
            steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice() });
          }
          i++;
        }
      }
      if (i !== hi) {
        var t2 = a[i];
        a[i] = a[hi];
        a[hi] = t2;
        steps.push({ kind: 'swap', lo: i, hi: hi, arr: a.slice() });
      }
      return i;
    }
    function quick(lo, hi) {
      if (lo >= hi) return;
      steps.push({ kind: 'part_start', lo: lo, hi: hi, arr: a.slice() });
      var p = partition(lo, hi);
      steps.push({ kind: 'part_end', pivot: p, arr: a.slice() });
      quick(lo, p - 1);
      quick(p + 1, hi);
    }
    if (a.length > 0) {
      quick(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function wait(ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  }

  function transitionPromise(el) {
    return new Promise(function (resolve) {
      function done(e) {
        if (e.propertyName !== 'transform') return;
        el.removeEventListener('transitionend', done);
        resolve();
      }
      el.addEventListener('transitionend', done);
      setTimeout(function () {
        el.removeEventListener('transitionend', done);
        resolve();
      }, 600);
    });
  }

  function swapDomIndices(parent, i, j) {
    if (i === j) return;
    var el1 = parent.children[i];
    var el2 = parent.children[j];
    var marker = document.createTextNode('');
    parent.insertBefore(marker, el1);
    parent.insertBefore(el1, el2.nextSibling);
    parent.insertBefore(el2, marker);
    parent.removeChild(marker);
  }

  async function flipSwap(container, i, j) {
    if (i === j) return;
    if (i > j) {
      var tmp = i;
      i = j;
      j = tmp;
    }
    var elI = container.children[i];
    var elJ = container.children[j];
    if (!elI || !elJ) return;

    var bI = elI.getBoundingClientRect();
    var bJ = elJ.getBoundingClientRect();

    swapDomIndices(container, i, j);

    var aI = elI.getBoundingClientRect();
    var aJ = elJ.getBoundingClientRect();

    var dxI = bI.left - aI.left;
    var dxJ = bJ.left - aJ.left;
    elI.style.transition = 'none';
    elJ.style.transition = 'none';
    elI.style.transform = 'translateX(' + dxI + 'px)';
    elJ.style.transform = 'translateX(' + dxJ + 'px)';

    await new Promise(function (r) {
      requestAnimationFrame(function () {
        requestAnimationFrame(r);
      });
    });

    var dur = '0.32s';
    elI.style.transition = 'transform ' + dur + ' ease';
    elJ.style.transition = 'transform ' + dur + ' ease';
    elI.style.transform = '';
    elJ.style.transform = '';

    await Promise.all([transitionPromise(elI), transitionPromise(elJ)]);

    elI.style.transition = '';
    elJ.style.transition = '';
    elI.style.transform = '';
    elJ.style.transform = '';
  }

  function mountBars(container, values) {
    container.innerHTML = '';
    if (!values.length) return;
    var max = Math.max.apply(null, values);
    var min = Math.min.apply(null, values);
    var span = Math.max(max - min, 1);
    values.forEach(function (v) {
      var bar = document.createElement('div');
      bar.className = 'quick-sort-demo__bar';
      var h = 28 + ((v - min) / span) * 92;
      bar.style.height = h + 'px';
      bar.setAttribute('title', String(v));
      container.appendChild(bar);
    });
  }

  function setRoles(container, lo, hi, kind) {
    var nodes = container.children;
    for (var k = 0; k < nodes.length; k++) {
      nodes[k].removeAttribute('data-role');
    }
    if (lo == null || hi == null) return;
    if (kind === 'pivot' && lo === hi && nodes[lo]) {
      nodes[lo].setAttribute('data-role', 'pivot');
      return;
    }
    if (nodes[lo]) nodes[lo].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
    if (nodes[hi]) nodes[hi].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
  }

  var barsEl = root.querySelector('[data-qs="bars"]');
  var capEl = root.querySelector('[data-qs="caption"]');
  var btnShuffle = root.querySelector('[data-qs="shuffle"]');
  var btnPlay = root.querySelector('[data-qs="play"]');
  var btnPause = root.querySelector('[data-qs="pause"]');
  var btnStep = root.querySelector('[data-qs="step"]');

  var values = [5, 2, 8, 1, 9, 3, 6];
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
      'クイックソートのデモ（比較はオレンジ、交換は緑、確定したピボットは紫）';
    syncButtons();
  }

  async function applyStepForward() {
    if (busy || idx >= steps.length) return;
    busy = true;
    syncButtons();
    try {
      var s = steps[idx];
      idx++;

      if (s.kind === 'part_start') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null);
        capEl.textContent = '分割: 部分配列 位置 ' + s.lo + ' … ' + s.hi + '（右端をピボット）';
        return;
      }

      if (s.kind === 'compare') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, s.lo, s.hi, 'compare');
        capEl.textContent =
          '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）';
        return;
      }

      if (s.kind === 'swap') {
        setRoles(barsEl, s.lo, s.hi, 'swap');
        capEl.textContent = '交換しています…';
        await flipSwap(barsEl, s.lo, s.hi);
        setRoles(barsEl, null, null);
        capEl.textContent = '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）';
        return;
      }

      if (s.kind === 'part_end') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, s.pivot, s.pivot, 'pivot');
        capEl.textContent =
          'ピボット確定: 位置 ' + s.pivot + ' に小さい値群と大きい値群が分かれました';
        return;
      }

      if (s.kind === 'done') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null);
        capEl.textContent = 'ソート完了';
      }
    } finally {
      busy = false;
      syncButtons();
    }
  }

  btnShuffle.addEventListener('click', function () {
    var arr = values.slice();
    for (var i = arr.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var t = arr[i];
      arr[i] = arr[j];
      arr[j] = t;
    }
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
      await wait(280);
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

バブルソートのような単純な O(n²) の手法と比べ、データ規模が大きいときの実効速度が有利になりやすい。標準ライブラリの `sort` では、言語・実装によってクイックソートに近い戦略が採用されていることも多い。
