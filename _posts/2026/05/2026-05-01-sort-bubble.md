---
layout: post
title:  バブルソートで配列を並び替える
date:   2026-05-01 00:56:20 +0900
tags:   sort
---

## バブルソートを使用する

バブルソート (`bubble sort`) は、隣り合う要素を比較し、順序が逆なら入れ替える操作を繰り返すことで、配列全体を昇順（または降順）に整列させる単純な比較ソートである。小さい（または大きい）値が「泡のように」一端へ浮き上がっていく様子からこの名前が付いている。

1.  **走査開始**: 配列の先頭から、隣り合う2要素 `(a[i], a[i+1])` を順に見ていく。
2.  **交換**: `a[i] > a[i+1]` のときだけ2つを入れ替える。そうでなければ何もしない。
3.  **走査終了**: 1回の始端から終端への走査が終わると、常に大きい方が終端へ押し出されるため最大の要素は必ず終端に移動する。
4.  **繰り返し**: 配列がソートされるまで上記の走査を繰り返す。最適化として、**すでに終端に固定された最大要素**は次の走査から比較対象から外してよい。

```pseudocode
procedure bubble_sort(A)
  n = length(A)
  for i from 0 to n - 1
    swapped = false
    for j from 0 to n - 2 - i
      if A[j] > A[j + 1] then
        swap(A[j], A[j + 1])
        swapped = true
    if not swapped then
      break
```

最悪時間計算量は O(n²) で、すでにソートされている場合は O(n) となる。空間計算量は O(1) で、安定なソートである（等しいキーの相対順序を保つ）。

<!-- markdownlint-disable MD046 -->
<div id="bubble-sort-demo" class="bubble-sort-demo">
<style>
.bubble-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.bubble-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.bubble-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.bubble-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.bubble-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.bubble-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.bubble-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.bubble-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.bubble-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.bubble-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .bubble-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .bubble-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .bubble-sort-demo__caption { color: #bbb; }
}
</style>
<div class="bubble-sort-demo__toolbar">
  <button type="button" data-bs="shuffle">シャッフル</button>
  <button type="button" data-bs="play">自動再生</button>
  <button type="button" data-bs="pause" disabled>一時停止</button>
  <button type="button" data-bs="step">1ステップ</button>
</div>
<div class="bubble-sort-demo__bars" data-bs="bars" aria-live="polite"></div>
<p class="bubble-sort-demo__caption" data-bs="caption"></p>
<script>
(function () {
  var root = document.getElementById('bubble-sort-demo');
  if (!root) return;

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var n = a.length;
    var i, j, swapped;
    for (i = 0; i < n - 1; i++) {
      swapped = false;
      for (j = 0; j < n - 1 - i; j++) {
        steps.push({ kind: 'compare', lo: j, hi: j + 1, arr: a.slice() });
        if (a[j] > a[j + 1]) {
          var t = a[j];
          a[j] = a[j + 1];
          a[j + 1] = t;
          swapped = true;
          steps.push({ kind: 'swap', lo: j, hi: j + 1, arr: a.slice() });
        }
      }
      if (!swapped) break;
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

  async function flipAdjacentSwap(container, lo) {
    var children = container.children;
    var first = children[lo];
    var second = children[lo + 1];
    if (!first || !second) return;

    var b1 = first.getBoundingClientRect();
    var b2 = second.getBoundingClientRect();

    container.insertBefore(second, first);

    var a1 = first.getBoundingClientRect();
    var a2 = second.getBoundingClientRect();

    var dx1 = b1.left - a1.left;
    var dx2 = b2.left - a2.left;
    first.style.transition = 'none';
    second.style.transition = 'none';
    first.style.transform = 'translateX(' + dx1 + 'px)';
    second.style.transform = 'translateX(' + dx2 + 'px)';

    await new Promise(function (r) {
      requestAnimationFrame(function () {
        requestAnimationFrame(r);
      });
    });

    var dur = '0.32s';
    first.style.transition = 'transform ' + dur + ' ease';
    second.style.transition = 'transform ' + dur + ' ease';
    first.style.transform = '';
    second.style.transform = '';

    await Promise.all([transitionPromise(first), transitionPromise(second)]);

    first.style.transition = '';
    second.style.transition = '';
    first.style.transform = '';
    second.style.transform = '';
  }

  function mountBars(container, values) {
    container.innerHTML = '';
    var max = Math.max.apply(null, values);
    var min = Math.min.apply(null, values);
    var span = Math.max(max - min, 1);
    values.forEach(function (v) {
      var bar = document.createElement('div');
      bar.className = 'bubble-sort-demo__bar';
      var h = 28 + ((v - min) / span) * 92;
      bar.style.height = h + 'px';
      bar.setAttribute('title', String(v));
      container.appendChild(bar);
    });
  }

  function setRoles(container, lo, hi, kind) {
    var nodes = container.children;
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].removeAttribute('data-role');
    }
    if (lo == null || hi == null) return;
    if (nodes[lo]) nodes[lo].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
    if (nodes[hi]) nodes[hi].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
  }

  var barsEl = root.querySelector('[data-bs="bars"]');
  var capEl = root.querySelector('[data-bs="caption"]');
  var btnShuffle = root.querySelector('[data-bs="shuffle"]');
  var btnPlay = root.querySelector('[data-bs="play"]');
  var btnPause = root.querySelector('[data-bs="pause"]');
  var btnStep = root.querySelector('[data-bs="step"]');

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
    capEl.textContent = 'バブルソートのデモ（比較はオレンジ、交換は緑の枠）';
    syncButtons();
  }

  async function applyStepForward() {
    if (busy || idx >= steps.length) return;
    busy = true;
    syncButtons();
    try {
      var s = steps[idx];
      idx++;

      if (s.kind === 'compare') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, s.lo, s.hi, 'compare');
        capEl.textContent = '比較: 位置 ' + s.lo + ' と ' + s.hi;
        return;
      }

      if (s.kind === 'swap') {
        var prev = steps[idx - 2];
        var lo = prev && prev.kind === 'compare' ? prev.lo : s.lo;
        setRoles(barsEl, lo, lo + 1, 'swap');
        capEl.textContent = '交換しています…';
        await flipAdjacentSwap(barsEl, lo);
        setRoles(barsEl, null, null);
        capEl.textContent = '交換しました（位置 ' + lo + ' と ' + (lo + 1) + '）';
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
      var pauseMs = 280;
      await wait(pauseMs);
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

説明は簡単で教育的な例としてよく用いられるが、実際の用途ではクイックソートやマージソートなどのより効率的なアルゴリズムが一般的に使用される。
