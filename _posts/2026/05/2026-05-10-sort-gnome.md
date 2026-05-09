---
layout: post
title:  ノームソートで配列を並び替える
date:   2026-05-10 07:42:56 +0900
tags:   sort
---

## ノームソートを使用する

ノームソート (`gnome sort` / `stupid sort`) は、**直感に沿った単純なルールだけで**昇順へ整列させる比較ソートである。「庭のノームが並んだ植木鉢を、隣との大小関係を見ながら前後へ動きながら整える」様子になぞらえ、この名前が付いている説明がよくされている。

処理の状態は現在位置 `pos`（しばしば「ノームの足元」などと呼ぶ）だけでよいことから、状態機械として読みやすく、コードも短く書けるという利点がある。一方で、一般に最悪時間計算量は O(n²) であり、規模が大きいデータ向けではなく、概念的な説明や遊び的な題材として用いられることが多い。

1.  **`pos = 0` から始める**。配列の左端から眺めていく。
2.  **`pos == 0` または `A[pos] >= A[pos - 1]` のとき**：いま見ている並びがローカルに問題ないので **1ステップ進み**、`pos += 1` とする。
3.  **それ以外**：隣との順序が逆なので **隣どうしを交換し**、`pos -= 1` してひとつ戻って再チェックする（より左側とも整合させる）。
4.  **`pos == n`** になるまで繰り返す。

```pseudocode
procedure gnome_sort(A)
  pos = 0
  while pos < length(A)
    if pos = 0 or A[pos] >= A[pos - 1] then
      pos = pos + 1
    else
      swap(A[pos], A[pos - 1])
      pos = pos - 1
```

交換が `>` だけでトリガされる実装では、等しい値の相対順序は変わらないため **安定** なソートとして扱える。追加の配列を使わなければ空間計算量は O(1) である。すでにソート済みの列では比較しながら右へ進むだけなので **O(n)**、逆順に近い並びでは前後への往復が多く **O(n²)** になる。

<!-- markdownlint-disable MD046 -->
<div id="gnome-sort-demo" class="gnome-sort-demo">
<style>
.gnome-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.gnome-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.gnome-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.gnome-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.gnome-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.gnome-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.gnome-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.gnome-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.gnome-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.gnome-sort-demo__bar[data-role="cursor"] {
  outline: 3px solid #1abc9c;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(26,188,156,.35), 0 2px 6px rgba(0,0,0,.18);
}
.gnome-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555;
  text-align: center; min-height: 1.25em;
}
@media (prefers-color-scheme: dark) {
  .gnome-sort-demo { background: rgba(255,255,255,.06);
    border-color: rgba(255,255,255,.18);
  }
  .gnome-sort-demo__toolbar button { background: rgba(255,255,255,.08);
    border-color: rgba(255,255,255,.25); color: inherit;
  }
  .gnome-sort-demo__caption { color: #bbb; }
}
</style>
<div class="gnome-sort-demo__toolbar">
  <button type="button" data-gs="shuffle">シャッフル</button>
  <button type="button" data-gs="play">自動再生</button>
  <button type="button" data-gs="pause" disabled>一時停止</button>
  <button type="button" data-gs="step">1ステップ</button>
</div>
<div class="gnome-sort-demo__bars" data-gs="bars" aria-live="polite"></div>
<p class="gnome-sort-demo__caption" data-gs="caption"></p>
<script>
(function () {
  var root = document.getElementById('gnome-sort-demo');
  if (!root) return;

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var pos = 0;
    var n = a.length;
    while (pos < n) {
      if (pos === 0 || a[pos] >= a[pos - 1]) {
        steps.push({ kind: 'advance', pos: pos, arr: a.slice() });
        pos++;
      } else {
        steps.push({ kind: 'compare', lo: pos - 1, hi: pos, arr: a.slice() });
        var t = a[pos];
        a[pos] = a[pos - 1];
        a[pos - 1] = t;
        steps.push({ kind: 'swap', lo: pos - 1, hi: pos, arr: a.slice() });
        pos--;
      }
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
      bar.className = 'gnome-sort-demo__bar';
      var h = 28 + ((v - min) / span) * 92;
      bar.style.height = h + 'px';
      bar.setAttribute('title', String(v));
      container.appendChild(bar);
    });
  }

  function clearRoles(container) {
    var nodes = container.children;
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].removeAttribute('data-role');
    }
  }

  function setCompareOrSwap(container, lo, hi, kind) {
    clearRoles(container);
    var nodes = container.children;
    if (lo == null || hi == null) return;
    if (nodes[lo]) nodes[lo].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
    if (nodes[hi]) nodes[hi].setAttribute('data-role', kind === 'swap' ? 'swap' : 'compare');
  }

  function setCursor(container, idx) {
    clearRoles(container);
    var nodes = container.children;
    if (idx == null) return;
    if (nodes[idx]) nodes[idx].setAttribute('data-role', 'cursor');
  }

  var barsEl = root.querySelector('[data-gs="bars"]');
  var capEl = root.querySelector('[data-gs="caption"]');
  var btnShuffle = root.querySelector('[data-gs="shuffle"]');
  var btnPlay = root.querySelector('[data-gs="play"]');
  var btnPause = root.querySelector('[data-gs="pause"]');
  var btnStep = root.querySelector('[data-gs="step"]');

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
      'ノームソートのデモ（現在位置は水色枠／比較はオレンジ／交換は緑）';
    syncButtons();
  }

  async function applyStepForward() {
    if (busy || idx >= steps.length) return;
    busy = true;
    syncButtons();
    try {
      var s = steps[idx];
      idx++;

      if (s.kind === 'advance') {
        mountBars(barsEl, s.arr);
        setCursor(barsEl, s.pos);
        capEl.textContent =
          '前進（位置 ' + s.pos +
          ' とその左側は昇順になるまで見たので、ひとつ右へ進みます）';
        return;
      }

      if (s.kind === 'compare') {
        mountBars(barsEl, s.arr);
        setCompareOrSwap(barsEl, s.lo, s.hi, 'compare');
        capEl.textContent = '比較: 位置 ' + s.lo + ' と ' + s.hi;
        return;
      }

      if (s.kind === 'swap') {
        var prev = steps[idx - 2];
        var lo = prev && prev.kind === 'compare' ? prev.lo : s.lo;
        setCompareOrSwap(barsEl, lo, lo + 1, 'swap');
        capEl.textContent = '交換しています…';
        await flipAdjacentSwap(barsEl, lo);
        clearRoles(barsEl);
        capEl.textContent =
          '順序が逆だったので左へ（位置 ' + lo + ' を基準にもう一度見直します）';
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

バブルのように端へ値を運ぶより「小さい不整合が出るたびにすぐその場で直しにいく」挙動が特徴で、単純ながら規模が増えると時間が読みにくくなる側面もある。教材としては状態の種類が少なく、コードと動きの対応を追いやすいソートアルゴリズムといえる。
