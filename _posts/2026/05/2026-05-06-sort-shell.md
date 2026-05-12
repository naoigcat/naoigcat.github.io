---
layout: post
title:  シェルソートで配列を並び替える
date:   2026-05-06 07:48:33 +0900
tags:   sort
---

## シェルソートを使用する

シェルソート (`shell sort`) は、**間隔（ギャップ）** を取った部分列に対して挿入ソートを繰り返すことで、全体を整列させる比較ソートである。ギャップが大きいうちは離れた要素同士の交換で「粗く」並びを整え、ギャップを徐々に小さくしていくことで、最終的にギャップ 1 のとき通常の挿入ソートとして収束する。

1.  **ギャップ列の決定**: 例として初期ギャップを `⌊n/2⌋` とし、各フェーズで半分に縮小して最後に 1 にする（古典的な増分列）。実装では Knuth 列など別の増分列を選ぶことも多い。
2.  **ギャップごとの挿入ソート**: 現在のギャップ `g` について、インデックス `g, g+1, …, n-1` を順に見ていき、各位置の要素を左へ「`g` 離れた」要素との比較によって挿入位置へ運ぶ（要素が逆順なら交換し、`j >= g` になるまで繰り返す）。
3.  **繰り返し**: ギャップが 1 になるまで手順 2 を繰り返す。ギャップ 1 のフェーズは通常の挿入ソートと同じになる。

```pseudocode
procedure shell_sort(A)
  n = length(A)
  gap = floor(n / 2)
  while gap > 0
    for i from gap to n - 1
      j = i
      while j >= gap and A[j - gap] > A[j]
        swap(A[j], A[j - gap])
        j = j - gap
    gap = floor(gap / 2)
```

増分列によって最悪時間計算量は異なる。上記の「半分に縮小する」列では最悪 **O(n²)** と報告されているが、バブルソートのような単純な隣接交換のみの走査より早くなることが多い。

ギャップが大きいフェーズで要素が大きく動けるため、ギャップ 1 の段階での逆転数が抑えられやすいという直観がある。空間計算量は **O(1)** の追加領域で実装できる **インプレース** ソートである。**安定ではない**（等しいキーの相対順序が保証されない）ことが一般的である。

<!-- markdownlint-disable MD046 -->
<div id="shell-sort-demo" class="shell-sort-demo">
<style>
.shell-sort-demo {
  margin: 1.25rem 0;
  padding: 1rem;
  border: 1px solid rgba(128,128,128,.35);
  border-radius: 8px;
  background: var(--minima-brand-color-lightest, #f9f9f9);
}
.shell-sort-demo__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem 1rem;
  align-items: center;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}
.shell-sort-demo__toolbar button {
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  border: 1px solid rgba(0,0,0,.2);
  background: #fff;
  cursor: pointer;
  font: inherit;
}
.shell-sort-demo__toolbar button:hover {
  border-color: rgba(0,0,0,.45);
}
.shell-sort-demo__toolbar button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.shell-sort-demo__bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 6px;
  min-height: 140px;
  padding: 0.5rem;
}
.shell-sort-demo__bar {
  flex: 1 1 0;
  max-width: 48px;
  min-width: 28px;
  border-radius: 4px 4px 2px 2px;
  background: linear-gradient(180deg, #5b9bd5 0%, #2e75b6 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,.12);
  transition: box-shadow 0.15s ease, outline-color 0.15s ease;
  transform: translateX(0);
}
.shell-sort-demo__bar[data-role="compare"] {
  outline: 3px solid #e67e22;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px rgba(230,126,34,.35), 0 2px 6px rgba(0,0,0,.18);
}
.shell-sort-demo__bar[data-role="swap"] {
  outline: 3px solid #27ae60;
  outline-offset: 2px;
}
.shell-sort-demo__caption { margin-top: 0.5rem; font-size: 0.85rem; color: #555; text-align: center; min-height: 1.25em; }
@media (prefers-color-scheme: dark) {
  .shell-sort-demo { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.18); }
  .shell-sort-demo__toolbar button { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.25); color: inherit; }
  .shell-sort-demo__caption { color: #bbb; }
}
</style>
<div class="shell-sort-demo__toolbar">
  <button type="button" data-ss="shuffle">シャッフル</button>
  <button type="button" data-ss="play">自動再生</button>
  <button type="button" data-ss="pause" disabled>一時停止</button>
  <button type="button" data-ss="step">1ステップ</button>
</div>
<div class="shell-sort-demo__bars" data-ss="bars" aria-live="polite"></div>
<p class="shell-sort-demo__caption" data-ss="caption"></p>
<script src="{{ '/assets/js/demo-sort.js' | relative_url }}"></script>
<script>
(function () {
  var root = document.getElementById('shell-sort-demo');
  if (!root) return;
  var C = window.DemoSort;
  if (!C) return;

  function mountBars(container, values) {
    C.mountBars(container, values, 'shell-sort-demo__bar');
  }

  function generateSteps(initial) {
    var a = initial.slice();
    var steps = [];
    var n = a.length;
    var gap = Math.floor(n / 2);
    while (gap > 0) {
      steps.push({ kind: 'gap', gap: gap, arr: a.slice() });
      var i;
      for (i = gap; i < n; i++) {
        var j = i;
        while (j >= gap && a[j - gap] > a[j]) {
          steps.push({ kind: 'compare', lo: j - gap, hi: j, arr: a.slice() });
          var t = a[j];
          a[j] = a[j - gap];
          a[j - gap] = t;
          steps.push({ kind: 'swap', lo: j - gap, hi: j, arr: a.slice() });
          j -= gap;
        }
      }
      gap = Math.floor(gap / 2);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function setRoles(container, lo, hi, kind) {
    var nodes = container.children;
    for (var k = 0; k < nodes.length; k++) {
      nodes[k].removeAttribute('data-role');
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
      'シェルソートのデモ（ギャップ変更時はキャプションのみ更新。比較はオレンジ、交換は緑）';
    syncButtons();
  }

  async function applyStepForward() {
    if (busy || idx >= steps.length) return;
    busy = true;
    syncButtons();
    try {
      var s = steps[idx];
      idx++;

      if (s.kind === 'gap') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, null, null);
        capEl.textContent = 'ギャップ ' + s.gap + ' で間隔付き挿入ソートを実行します';
        return;
      }

      if (s.kind === 'compare') {
        mountBars(barsEl, s.arr);
        setRoles(barsEl, s.lo, s.hi, 'compare');
        capEl.textContent =
          '比較: 位置 ' + s.lo + ' と ' + s.hi + '（間隔 ' + (s.hi - s.lo) + '）';
        return;
      }

      if (s.kind === 'swap') {
        setRoles(barsEl, s.lo, s.hi, 'swap');
        capEl.textContent = '交換しています…';
        await C.flipSwap(barsEl, s.lo, s.hi);
        setRoles(barsEl, null, null);
        capEl.textContent = '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）';
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
      await C.wait(280);
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

バブルソートのように隣接要素だけを見るより早くなることがあり、実装もインプレースで比較的単純である。一方でクイックソートやマージソートと比べたときの平均的な速度や最悪ケースの見通しは増分列の選び方に依存するため、本番用途では言語標準のソート実装を利用するのが無難である。
