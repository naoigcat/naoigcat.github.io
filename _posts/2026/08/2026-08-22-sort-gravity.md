---
title:     ビーズソートで配列を並び替える
date:      2026-08-22 05:59:19 +0900
tags:      sort
sort_demo: true
---

## ビーズソートを使用する

ビーズソート (`bead sort`, `gravity sort`) は、各正整数を「そろばんの玉（ビーズ）」として棒に載せ、重力で落下させたあとの段数を読み取ることで昇順に並べる。

デジタル実装では、棒 `j`（0 始まり）に載っているビーズ数を配列で数え、入力の各値 `x` について棒 `0 … x - 1` へ玉を 1 個ずつ載せたあと、下の段から順に「まだ玉がある棒の本数」を読み取る。

1.  **最大値の決定**: 配列の最大値 `max` を求め、棒の本数を `max` とする。
2.  **ビーズを載せる**: 各要素 `x` について、棒 `0` から `x - 1` までのビーズ数を 1 ずつ増やす（値が大きいほど多くの棒に玉が載る）。
3.  **重力（落下）**: 数え上げ実装では、棒ごとの合計がすでに「落下後」の積み上がりに相当する。
4.  **段の読み取り**: 下の段から、ビーズが残っている棒の本数を数え、その本数をソート結果の要素とする。読んだビーズは各棒から 1 個ずつ取り除く。

```pseudocode
procedure gravity_sort(A)
  if length(A) = 0 then return
  maxVal = maximum(A)
  if maxVal = 0 then return
  beads[0..maxVal-1] = 0
  for each x in A
    for j from 0 to x - 1
      beads[j] = beads[j] + 1
  for i from length(A) - 1 downto 0
    sum = 0
    for j from 0 to maxVal - 1
      if beads[j] = 0 then break
      sum = sum + 1
      beads[j] = beads[j] - 1
    A[i] = sum
```

正整数に限り、時間計算量はビーズの総数に比例して `O(n · max)`（または値の総和 `S` に対し `O(S)`）、補助空間は棒の本数ぶん `O(max)` である。入力が `1 … n` の順列なら `max = n` となり平均・最悪とも `O(n²)` になる。値から棒への載せ方は一意なので、同値の相対順序は入力順とは無関係（一般に不安定）。

物理的なそろばんモデルの説明や可視化には向くが、`max` が大きいと棒配列とビーズ操作のコストが急増するため、実務では [カウンティングソート](/2026/06/20/sort-counting.html) など値域依存の別手法の方が扱いやすいことが多い。

次の図は入力 `[3, 1, 4, 2]` をそろばんに見立てたイメージである。各数ぶんの玉を棒へ載せ、重力で落下させたあと、各段に並ぶ玉の個数を上から読むと昇順 `[1, 2, 3, 4]` になる。

<figure class="gravity-bead-demo" id="gravity-bead-demo" aria-label="ビーズソートの落下イメージ">
  <div class="gravity-bead-demo__toolbar">
    <button type="button" data-gravity-reset>リセット</button>
    <button type="button" data-gravity-play>自動再生</button>
    <button type="button" data-gravity-pause disabled>一時停止</button>
    <button type="button" data-gravity-step>ステップ</button>
  </div>
  <p class="gravity-bead-demo__caption" data-gravity-caption></p>
  <div class="gravity-bead-demo__stage" data-gravity-stage></div>
  <p class="gravity-bead-demo__result" data-gravity-result></p>
</figure>

<script>
(function () {
  const root = document.getElementById('gravity-bead-demo');
  if (!root) return;

  const INPUT = [3, 1, 4, 2];
  const n = INPUT.length;
  const maxVal = Math.max.apply(null, INPUT);
  const INITIAL_CAPTION =
    'ビーズソートのイメージ（自動再生またはステップで進行）';
  const STEP_PAUSE_MS = 320;

  const captionEl = root.querySelector('[data-gravity-caption]');
  const stageEl = root.querySelector('[data-gravity-stage]');
  const resultEl = root.querySelector('[data-gravity-result]');
  const playBtn = root.querySelector('[data-gravity-play]');
  const pauseBtn = root.querySelector('[data-gravity-pause]');
  const stepBtn = root.querySelector('[data-gravity-step]');
  const resetBtn = root.querySelector('[data-gravity-reset]');
  const reduceMotion =
    window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  let beads = [];
  let tagEls = [];
  let heights = [];
  let steps = [];
  let idx = 0;
  let playing = false;
  let busy = false;
  let playGeneration = 0;

  const beadSize = () => {
    const raw = getComputedStyle(stageEl).getPropertyValue('--bead-size');
    return parseFloat(raw) || 22;
  };
  const levelGap = () => {
    const raw = getComputedStyle(stageEl).getPropertyValue('--level-gap');
    return parseFloat(raw) || 10;
  };
  const stepPx = () => beadSize() + levelGap();

  function wait(ms) {
    return new Promise(function (resolve) {
      window.setTimeout(resolve, ms);
    });
  }

  function setCaption(text) {
    captionEl.textContent = text;
  }

  function setResult(text) {
    resultEl.innerHTML = text;
  }

  function buildStage() {
    stageEl.innerHTML = '';
    const rods = [];
    for (let j = 0; j < maxVal; j++) {
      const rod = document.createElement('div');
      rod.className = 'gravity-bead-demo__rod';
      const label = document.createElement('span');
      label.className = 'gravity-bead-demo__rod-label';
      label.textContent = '棒' + (j + 1);
      rod.appendChild(label);
      stageEl.appendChild(rod);
      rods.push(rod);
    }

    const tags = document.createElement('div');
    tags.className = 'gravity-bead-demo__level-tags';
    tagEls = [];
    for (let level = 0; level < n; level++) {
      const tag = document.createElement('span');
      tag.className = 'gravity-bead-demo__level-tag';
      tag.dataset.level = String(level);
      tags.appendChild(tag);
      tagEls.push(tag);
    }
    stageEl.appendChild(tags);

    beads = [];
    for (let row = 0; row < n; row++) {
      const rowBeads = [];
      for (let rod = 0; rod < INPUT[row]; rod++) {
        const bead = document.createElement('span');
        bead.className = 'gravity-bead-demo__bead';
        bead.setAttribute('aria-hidden', 'true');
        bead.style.setProperty('--from-y', row * stepPx() + 'px');
        bead.style.setProperty('--to-y', (n - 1) * stepPx() + 'px');
        rods[rod].appendChild(bead);
        rowBeads.push(bead);
      }
      beads.push(rowBeads);
    }

    heights = new Array(maxVal);
    for (let j = 0; j < maxVal; j++) {
      heights[j] = 0;
    }
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < INPUT[i]; j++) {
        heights[j]++;
      }
    }

    const slotUsed = new Array(maxVal);
    for (let j = 0; j < maxVal; j++) {
      slotUsed[j] = 0;
    }
    for (let row = n - 1; row >= 0; row--) {
      for (let rod = 0; rod < beads[row].length; rod++) {
        const slot = slotUsed[rod];
        slotUsed[rod]++;
        beads[row][rod].style.setProperty(
          '--to-y',
          (n - 1 - slot) * stepPx() + 'px'
        );
        beads[row][rod].dataset.slot = String(slot);
        beads[row][rod].dataset.rod = String(rod);
      }
    }
  }

  function levelCount(level) {
    let count = 0;
    for (let j = 0; j < maxVal; j++) {
      if (heights[j] > level) count++;
    }
    return count;
  }

  function generateSteps() {
    const list = [];
    list.push({ kind: 'intro' });
    for (let row = 0; row < n; row++) {
      list.push({ kind: 'place', row: row, value: INPUT[row] });
    }
    list.push({ kind: 'fall' });
    const sorted = [];
    for (let level = n - 1; level >= 0; level--) {
      const value = levelCount(level);
      sorted.push(value);
      list.push({
        kind: 'read',
        level: level,
        value: value,
        sorted: sorted.slice(),
      });
    }
    list.push({ kind: 'done', sorted: sorted.slice() });
    return list;
  }

  function clearHighlights() {
    for (let row = 0; row < beads.length; row++) {
      for (let k = 0; k < beads[row].length; k++) {
        beads[row][k].classList.remove('is-highlight');
      }
    }
  }

  function highlightLevel(level) {
    clearHighlights();
    for (let row = 0; row < beads.length; row++) {
      for (let k = 0; k < beads[row].length; k++) {
        if (beads[row][k].dataset.slot === String(level)) {
          beads[row][k].classList.add('is-highlight');
        }
      }
    }
  }

  function resetBeads() {
    for (let row = 0; row < beads.length; row++) {
      for (let k = 0; k < beads[row].length; k++) {
        beads[row][k].classList.remove(
          'is-visible',
          'is-fallen',
          'is-highlight'
        );
      }
    }
    for (let t = 0; t < tagEls.length; t++) {
      tagEls[t].classList.remove('is-on');
      tagEls[t].textContent = '';
    }
    setResult('');
  }

  function applyStep(s) {
    if (s.kind === 'intro') {
      resetBeads();
      setCaption(
        '入力 [' +
          INPUT.join(', ') +
          '] を、各数ぶんの玉として棒の上に載せます'
      );
      return;
    }
    if (s.kind === 'place') {
      setCaption(
        '値 ' +
          s.value +
          ' → 棒 1〜' +
          s.value +
          ' に玉を 1 個ずつ載せます'
      );
      for (let k = 0; k < beads[s.row].length; k++) {
        beads[s.row][k].classList.add('is-visible');
      }
      return;
    }
    if (s.kind === 'fall') {
      setCaption('重力で各棒の玉が下へ落ち、すき間が埋まります');
      for (let row = 0; row < beads.length; row++) {
        for (let k = 0; k < beads[row].length; k++) {
          beads[row][k].classList.add('is-fallen');
        }
      }
      return;
    }
    if (s.kind === 'read') {
      highlightLevel(s.level);
      tagEls[s.level].textContent = '= ' + s.value;
      tagEls[s.level].classList.add('is-on');
      setCaption(
        '上から読む: この段の玉は ' + s.value + ' 個 → 値 ' + s.value
      );
      setResult(
        '読み取り中: <strong>[' +
          s.sorted.join(', ') +
          (s.sorted.length < n ? ', …' : '') +
          ']</strong>'
      );
      return;
    }
    if (s.kind === 'done') {
      clearHighlights();
      setCaption('すべての段を上から読むと、昇順の配列が得られます');
      setResult('結果: <strong>[' + s.sorted.join(', ') + ']</strong>');
    }
  }

  function syncButtons() {
    const atEnd = idx >= steps.length;
    playBtn.disabled = playing || atEnd || busy;
    pauseBtn.disabled = !playing;
    stepBtn.disabled = playing || atEnd || busy;
    resetBtn.disabled = playing || busy;
  }

  function softReset() {
    buildStage();
    steps = generateSteps();
    idx = 0;
    resetBeads();
    setCaption(INITIAL_CAPTION);
  }

  function rebuild() {
    playGeneration++;
    playing = false;
    busy = false;
    softReset();
    syncButtons();
  }

  async function applyStepForward() {
    if (busy || idx >= steps.length) return;
    busy = true;
    syncButtons();
    try {
      const s = steps[idx];
      idx++;
      applyStep(s);
      if (s.kind === 'fall' && !reduceMotion) {
        await wait(550);
      }
    } finally {
      busy = false;
      syncButtons();
    }
  }

  resetBtn.addEventListener('click', function () {
    if (playing || busy) return;
    rebuild();
  });

  playBtn.addEventListener('click', async function () {
    const generation = ++playGeneration;
    playing = true;
    syncButtons();
    while (playGeneration === generation && idx < steps.length) {
      await applyStepForward();
      if (playGeneration !== generation) break;
      await wait(STEP_PAUSE_MS);
    }
    if (playGeneration === generation) {
      playing = false;
      syncButtons();
    }
  });

  pauseBtn.addEventListener('click', function () {
    playGeneration++;
    playing = false;
    syncButtons();
  });

  stepBtn.addEventListener('click', function () {
    applyStepForward();
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', rebuild);
  } else {
    rebuild();
  }
})();
</script>

## 類似アルゴリズムとの相違点

[カウンティングソート](/2026/06/20/sort-counting.html)は値ごとの出現回数を数えて配置するのに対し、ビーズソートは「棒に玉を載せて落下させる」物理モデルで同じ情報を積み上げる。数え上げ実装では結果がカウンティングに近づくが、可視化と計算量の語り方が異なる。

[鳩の巣ソート](/2026/07/19/sort-pigeonhole.html)は値ごとの巣へ要素自体を入れる。[スリープソート](/2026/07/23/sort-sleep.html)も物理量（待ち時間）に値を写す比喩だが、こちらは空間上のビーズ配置を使う。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000036 |        0.000979 |               2 |               2 |
|        512 |        0.000085 |        0.000842 |               4 |               4 |
|       1024 |        0.000329 |        0.000580 |               8 |               8 |
|       2048 |        0.001237 |        0.001860 |              16 |              16 |
|       4096 |        0.004877 |        0.009350 |              32 |              32 |
|       8192 |        0.019105 |        0.028074 |              64 |              64 |
|      16384 |        0.072439 |        0.432758 |             128 |             128 |
|      32768 |        0.332877 |        0.615440 |             256 |             256 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="gravity" %}
