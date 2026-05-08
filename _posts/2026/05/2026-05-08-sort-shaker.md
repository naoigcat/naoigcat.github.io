---
layout: post
title:  シェーカーソートで配列を並び替える
date:   2026-05-08 06:16:01 +0900
tags:   sort
---

## シェーカーソートを使用する

シェーカーソート (`shaker sort`) は、カクテルシェイカーを振るようにデータが両端へ動いていく様子から **カクテルソート** (`cocktail sort`) とも呼ばれる比較ソートである。バブルソートと同様に隣り合う要素だけを入れ替えるが、**左から右**への走査と**右から左**への走査を交互に繰り返す点が異なる。

1.  **右方向の走査**: 左端から右端手前まで進み、`a[i] > a[i+1]` なら交換する。これでそのラウンドでは最大の要素が右端側へ寄る。
2.  **左方向の走査**: 右端から左端手前まで戻り、同様に逆順なら交換する。最小の要素が左端側へ寄る。
3.  **範囲の縮小**: 右方向のあと右端は確定した最大として比較範囲から外し、左方向のあと左端は確定した最小として外す。
4.  **終了条件**: ある走査で一度も交換が起きなければ全体がソート済みとして終了する。

「タートル問題」と呼ばれる現象で、バブルソートでは小さな値が左端へ届くのに多くのパスを要することがあるが、シェーカーソートでは逆向きの走査があるため、極端に左にしか進めない値も早めに動かしやすくなる。

時間計算量は最悪でも **O(n²)** で、空間計算量は **O(1)**。隣接交換のみなので **安定** なソートである。

```pseudocode
procedure shaker_sort(A)
  begin = 0
  end = length(A) - 1
  while begin < end
    swapped = false
    for i from begin to end - 1
      if A[i] > A[i + 1] then
        swap(A[i], A[i + 1])
        swapped = true
    end = end - 1
    if not swapped then
      break
    swapped = false
    for i from end down to begin + 1
      if A[i - 1] > A[i] then
        swap(A[i - 1], A[i])
        swapped = true
    begin = begin + 1
    if not swapped then
      break
```

実運用ではマージソートやクイックソートなどが選ばれることが多いが、実装が単純で挙動を視覚化しやすい教育的なアルゴリズムとして有用である。

<!-- markdownlint-disable MD046 -->
<div id="shaker-sort-demo" class="shaker-sort-demo">
<style>
.shaker-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.shaker-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.shaker-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.shaker-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.shaker-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.shaker-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.shaker-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.shaker-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.shaker-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.shaker-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .shaker-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .shaker-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .shaker-sort-demo__caption { color: #bbb; }
}
</style>
<div class="shaker-sort-demo__toolbar">
  <button type="button" data-ss="shuffle">シャッフル</button>
  <button type="button" data-ss="play">自動再生</button>
  <button type="button" data-ss="pause" disabled>一時停止</button>
  <button type="button" data-ss="step">1ステップ</button>
</div>
<div class="shaker-sort-demo__bars" data-ss="bars" aria-live="polite"></div>
<p class="shaker-sort-demo__caption" data-ss="caption"></p>
<script>
(function () {
  var root = document.getElementById('shaker-sort-demo');
  if (!root) return;

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var begin = 0;
    var end = a.length - 1;
    while (begin < end) {
      var swapped = false;
      var i;
      for (i = begin; i < end; i++) {
        steps.push({
          kind: 'compare',
          lo: i,
          hi: i + 1,
          phase: 'forward',
          arr: a.slice(),
        });
        if (a[i] > a[i + 1]) {
          var t = a[i];
          a[i] = a[i + 1];
          a[i + 1] = t;
          swapped = true;
          steps.push({
            kind: 'swap',
            lo: i,
            hi: i + 1,
            phase: 'forward',
            arr: a.slice(),
          });
        }
      }
      end--;
      if (!swapped) break;

      swapped = false;
      for (i = end; i > begin; i--) {
        steps.push({
          kind: 'compare',
          lo: i - 1,
          hi: i,
          phase: 'backward',
          arr: a.slice(),
        });
        if (a[i - 1] > a[i]) {
          var t2 = a[i - 1];
          a[i - 1] = a[i];
          a[i] = t2;
          swapped = true;
          steps.push({
            kind: 'swap',
            lo: i - 1,
            hi: i,
            phase: 'backward',
            arr: a.slice(),
          });
        }
      }
      begin++;
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
      bar.className = 'shaker-sort-demo__bar';
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

  var barsEl = root.querySelector('[data-ss="bars"]');
  var capEl = root.querySelector('[data-ss="caption"]');
  var btnShuffle = root.querySelector('[data-ss="shuffle"]');
  var btnPlay = root.querySelector('[data-ss="play"]');
  var btnPause = root.querySelector('[data-ss="pause"]');
  var btnStep = root.querySelector('[data-ss="step"]');

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
      'シェーカーソートのデモ（左→右は順方向、右→左は逆方向の走査。比較はオレンジ、交換は緑）';
    syncButtons();
  }

  function phaseLabel(p) {
    return p === 'backward' ? '逆方向（右→左）' : '順方向（左→右）';
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
        capEl.textContent =
          phaseLabel(s.phase) + ': 位置 ' + s.lo + ' と ' + s.hi + ' を比較';
        return;
      }

      if (s.kind === 'swap') {
        var prev = steps[idx - 2];
        var lo = prev && prev.kind === 'compare' ? prev.lo : s.lo;
        setRoles(barsEl, lo, lo + 1, 'swap');
        capEl.textContent = phaseLabel(s.phase) + ': 交換しています…';
        await flipAdjacentSwap(barsEl, lo);
        setRoles(barsEl, null, null);
        capEl.textContent =
          phaseLabel(s.phase) +
          ': 交換しました（位置 ' +
          lo +
          ' と ' +
          (lo + 1) +
          '）';
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

バブルソートと同じく **O(n²)** だが、データによっては逆向き走査によりステップ数が抑えられる場合がある。それでも大規模データ向けの第一選択にはならないことが多い。
