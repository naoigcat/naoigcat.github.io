---
title:     鳩の巣ソートで配列を並び替える
date:      2026-07-19 20:15:56 +0900
tags:      sort
sort_demo: true
---

## 鳩の巣ソートを使用する

鳩の巣ソート (`pigeonhole sort`) は、鳩の巣原理に倣い、取りうる各キー値に対応する「巣」（穴）を用意し、入力要素をその巣へ直接仕分けてから、巣を昇順に走査して並べ直す。

キーの値域 `k = max - min + 1` が入力長 `n` と同程度かそれより小さい整数データに向く。要素同士を比較せず、値から巣のインデックスを決める。

1.  **値域の決定**: 配列の最小値 `min` と最大値 `max` から、巣の数 `k = max - min + 1` を求める。
2.  **巣の用意**: インデックス `0 … k - 1` に対応する空のリスト（巣）を `k` 個用意する。巣 `i` は値 `min + i` を受け取る。
3.  **仕分け**: 各要素 `x` を巣 `x - min` に追加する。同一値は同じ巣に複数入る。
4.  **回収**: 巣 `0, 1, …` の順に中身を左から配列へ書き戻す。

```pseudocode
procedure pigeonhole_sort(A)
  if length(A) = 0 then return
  minVal = minimum(A)
  maxVal = maximum(A)
  k = maxVal - minVal + 1
  holes[0..k-1] = empty lists
  for each x in A
    append x to holes[x - minVal]
  idx = 0
  for h from 0 to k - 1
    for each x in holes[h]
      A[idx] = x
      idx = idx + 1
```

値域幅 `k` が小さいとき `O(n + k)` となり、比較ソートの `Ω(n log n)` 下界を超えられる。巣ごとにリストを持つ実装は、同値の相対順序を保てる（安定ソート）。

整数のように値域が狭いデータや、キーがそのままインデックスになる場合に向く。`k` が極端に大きいと巣の配列だけでメモリを大量に消費するため、汎用の比較ソートへ切り替える判断が必要になる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('pigeonhole-sort-demo', function (root) {
  const HOLE_MIN = 1;
  const HOLE_MAX = 10;
  const HOLE_SPAN = HOLE_MAX - HOLE_MIN + 1;
  const DEMO_LEN = 15;
  const DEMO_MIN = HOLE_MIN;
  const DEMO_MAX = HOLE_MAX;
  const DEMO_INITIAL = [5, 2, 8, 1, 9, 3, 6, 10, 4, 7, 2, 5, 10, 8, 1];

  function prefersReducedMotion() {
    if (!window.matchMedia) return false;
    try {
      return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    } catch (_e) {
      return false;
    }
  }

  function nextFrame() {
    return new Promise(function (resolve) {
      requestAnimationFrame(function () {
        requestAnimationFrame(resolve);
      });
    });
  }

  function valueScale(values) {
    if (!values.length) {
      return { min: 0, max: 1, span: 1 };
    }
    const min = Math.min.apply(null, values);
    const max = Math.max.apply(null, values);
    return { min: min, max: max, span: Math.max(max - min, 1) };
  }

  function barHeightPx(value, scale) {
    return 28 + ((value - scale.min) / scale.span) * 92;
  }

  function scaledBarHeight(value, scale) {
    return barHeightPx(value, scale) + 'px';
  }

  function elementRect(el) {
    if (!el) return null;
    const box = el.getBoundingClientRect();
    return {
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
    };
  }

  function barRectFromEl(el) {
    return elementRect(el);
  }

  function syncBarWidth(wrap) {
    const track = wrap.querySelector('[data-pigeonhole-track="input"]');
    if (!track) return;
    let slot = track.firstElementChild;
    while (slot) {
      const bar = slot.querySelector('.sort-demo__bar:not([data-role="gap"])');
      if (bar) {
        const w = bar.getBoundingClientRect().width;
        if (w > 0) {
          wrap.style.setProperty('--pigeonhole-bar-width', w + 'px');
        }
        return;
      }
      slot = slot.nextElementSibling;
    }
  }

  function outputSlotRect(slotEl, wrap) {
    if (!slotEl) return null;
    const bar = slotEl.querySelector('.sort-demo__bar:not([data-role="gap"])');
    if (bar) {
      return barRectFromEl(bar);
    }
    const box = slotEl.getBoundingClientRect();
    const barWidth = parseFloat(
      (wrap && wrap.style.getPropertyValue('--pigeonhole-bar-width')) || ''
    );
    const w = barWidth > 0 ? barWidth : box.width;
    return {
      left: box.left + (box.width - w) / 2,
      top: box.bottom - (wrap ? wrap.querySelector('.pigeonhole-demo__track')?.getBoundingClientRect().height || box.height : box.height),
      width: w,
      height: box.height,
    };
  }

  function cloneHoles(holes) {
    return holes.map(function (hole) {
      return hole.slice();
    });
  }

  function mkBar(value, scale, role) {
    const bar = document.createElement('div');
    bar.className = 'sort-demo__bar';
    bar.style.height = scaledBarHeight(value, scale);
    bar.setAttribute('title', String(value));
    if (role) {
      bar.setAttribute('data-role', role);
    }
    return bar;
  }

  function mkHoleBar(value, scale, role) {
    const bar = document.createElement('div');
    bar.className = 'sort-demo__bar';
    bar.style.height = scaledBarHeight(value, scale);
    bar.setAttribute('aria-hidden', 'true');
    if (role) {
      bar.setAttribute('data-role', role);
    }
    return bar;
  }

  function mkBarStack(value, scale, role, inputIdx) {
    const stack = document.createElement('div');
    stack.className = 'sort-demo__bar-stack';
    if (value == null) {
      stack.classList.add('sort-demo__bar-stack--empty');
    }
    if (inputIdx != null) {
      stack.dataset.inputIdx = String(inputIdx);
    }
    stack.setAttribute('role', 'listitem');

    const label = document.createElement('span');
    label.className = 'sort-demo__bar-value';
    label.textContent = value == null ? '' : String(value);

    const bar = document.createElement('div');
    bar.className = 'sort-demo__bar';
    if (value == null) {
      bar.setAttribute('data-role', 'gap');
      bar.style.height = '0';
    } else {
      bar.style.height = scaledBarHeight(value, scale);
      bar.setAttribute('title', String(value));
      if (role) {
        bar.setAttribute('data-role', role);
      }
    }

    stack.appendChild(label);
    stack.appendChild(bar);
    return stack;
  }

  function ensureLayout(barsEl) {
    let wrap = barsEl.querySelector('.pigeonhole-demo');
    if (wrap) {
      return wrap;
    }
    barsEl.innerHTML = '';
    wrap = document.createElement('div');
    wrap.className = 'pigeonhole-demo';

    const inputSection = document.createElement('section');
    inputSection.className = 'pigeonhole-demo__section';
    const inputLabel = document.createElement('p');
    inputLabel.className = 'pigeonhole-demo__section-label';
    inputLabel.dataset.pigeonholeSection = 'input';
    inputLabel.textContent = '入力';
    const inputTrack = document.createElement('div');
    inputTrack.className = 'pigeonhole-demo__track pigeonhole-demo__input';
    inputTrack.dataset.pigeonholeTrack = 'input';
    inputSection.appendChild(inputLabel);
    inputSection.appendChild(inputTrack);

    const holesSection = document.createElement('section');
    holesSection.className = 'pigeonhole-demo__section';
    const holesLabel = document.createElement('p');
    holesLabel.className = 'pigeonhole-demo__section-label';
    holesLabel.textContent = '巣（値ごとの穴）';
    const holesTrack = document.createElement('div');
    holesTrack.className = 'pigeonhole-demo__holes';
    holesTrack.dataset.pigeonholeTrack = 'holes';
    holesSection.appendChild(holesLabel);
    holesSection.appendChild(holesTrack);

    wrap.appendChild(inputSection);
    wrap.appendChild(holesSection);
    barsEl.appendChild(wrap);
    return wrap;
  }

  function mountPigeonholeDemo(barsEl, view) {
    const wrap = ensureLayout(barsEl);
    const scale = valueScale(view.fullArr.length ? view.fullArr : [1]);
    const inputTrack = wrap.querySelector('[data-pigeonhole-track="input"]');
    const holesTrack = wrap.querySelector('[data-pigeonhole-track="holes"]');
    const inputLabel = wrap.querySelector('[data-pigeonhole-section="input"]');
    const movedThrough = view.movedThroughIdx == null ? -1 : view.movedThroughIdx;
    const outputMode = !!view.outputMode;
    const holes = view.holes || [];
    const span = HOLE_SPAN;
    const minVal = HOLE_MIN;

    inputLabel.textContent = outputMode ? '出力' : '入力';
    inputTrack.innerHTML = '';
    holesTrack.innerHTML = '';

    const slotCount = Math.max(view.fullArr.length, 1);
    inputTrack.style.gridTemplateColumns =
      'repeat(' + slotCount + ', minmax(0, 1fr))';

    if (outputMode) {
      const out = view.outputArr || [];
      inputTrack.setAttribute('role', 'list');
      inputTrack.setAttribute(
        'aria-label',
        'ソート後の配列。棒の高さは値の大小、左から右へ位置0、1の順です。'
      );
      let o;
      for (o = 0; o < slotCount; o++) {
        const role =
          view.highlightOutputIdx === o
            ? view.highlightRole || 'write'
            : null;
        const stack = mkBarStack(
          o < out.length ? out[o] : null,
          scale,
          role
        );
        if (view.hideOutputBarIdx === o) {
          const bar = stack.querySelector('.sort-demo__bar:not([data-role="gap"])');
          if (bar) {
            bar.style.visibility = 'hidden';
          }
        }
        inputTrack.appendChild(stack);
      }
    } else {
      inputTrack.setAttribute('role', 'list');
      inputTrack.setAttribute(
        'aria-label',
        'ソート前の配列。棒の高さは値の大小、左から右へ位置0、1の順です。'
      );
      let i;
      for (i = 0; i < slotCount; i++) {
        const v = i <= movedThrough ? null : view.fullArr[i];
        const role =
          view.highlightInputIdx === i ? view.highlightRole || 'cursor' : null;
        inputTrack.appendChild(mkBarStack(v, scale, role, i));
      }
    }

    let h;
    for (h = 0; h < span; h++) {
      const holeEl = document.createElement('div');
      holeEl.className = 'pigeonhole-demo__hole';
      if (view.activeHoleIdx === h) {
        holeEl.classList.add('pigeonhole-demo__hole--active');
      }
      holeEl.dataset.holeIdx = String(h);

      const holeLabel = document.createElement('span');
      holeLabel.className = 'pigeonhole-demo__hole-label';
      holeLabel.textContent = String(minVal + h);

      const stackEl = document.createElement('div');
      stackEl.className = 'pigeonhole-demo__hole-stack';
      stackEl.dataset.holeStack = String(h);
      stackEl.setAttribute('role', 'list');
      stackEl.setAttribute(
        'aria-label',
        '値 ' + (minVal + h) + ' の巣'
      );

      const holeBars = holes[h] || [];
      let j;
      for (j = 0; j < holeBars.length; j++) {
        const bar = mkHoleBar(holeBars[j], scale);
        if (
          view.hideHoleBar &&
          view.hideHoleBar.holeIdx === h &&
          view.hideHoleBar.stackPos === j
        ) {
          bar.style.visibility = 'hidden';
        }
        stackEl.appendChild(bar);
      }

      holeEl.appendChild(stackEl);
      holeEl.appendChild(holeLabel);
      holesTrack.appendChild(holeEl);
    }

    syncBarWidth(wrap);
  }

  function findInputBar(wrap, idx) {
    return wrap.querySelector(
      '[data-input-idx="' + idx + '"] .sort-demo__bar:not([data-role="gap"])'
    );
  }

  function findHoleStack(wrap, holeIdx) {
    return wrap.querySelector('[data-hole-stack="' + holeIdx + '"]');
  }

  function findHoleBar(wrap, holeIdx, stackPos) {
    const stack = findHoleStack(wrap, holeIdx);
    if (!stack) return null;
    const bars = stack.querySelectorAll('.sort-demo__bar');
    return bars[stackPos] || null;
  }

  function findOutputSlot(wrap, outputIdx) {
    const track = wrap.querySelector('[data-pigeonhole-track="input"]');
    if (!track) return null;
    return track.children[outputIdx] || null;
  }

  function findOutputBar(wrap, outputIdx) {
    const slot = findOutputSlot(wrap, outputIdx);
    if (!slot) return null;
    return slot.querySelector('.sort-demo__bar:not([data-role="gap"])');
  }

  function findOutputLanding(wrap, outputIdx) {
    return outputSlotRect(findOutputSlot(wrap, outputIdx), wrap);
  }

  async function flyBarRects(fromRect, toRect, value, scale, role) {
    if (!fromRect || !toRect || prefersReducedMotion()) {
      return;
    }
    const h = fromRect.height;
    const w = fromRect.width;
    const ghost = mkBar(value, scale, role || 'write');
    ghost.style.position = 'fixed';
    ghost.style.left = fromRect.left + 'px';
    ghost.style.top = fromRect.top + 'px';
    ghost.style.width = w + 'px';
    ghost.style.height = h + 'px';
    ghost.style.margin = '0';
    ghost.style.zIndex = '1000';
    ghost.style.pointerEvents = 'none';
    ghost.style.boxSizing = 'border-box';
    ghost.style.transition = 'left 0.34s ease, top 0.34s ease';
    document.body.appendChild(ghost);
    await nextFrame();
    ghost.style.left = toRect.left + 'px';
    ghost.style.top = toRect.top + 'px';
    await new Promise(function (resolve) {
      function done(e) {
        if (e.propertyName !== 'left' && e.propertyName !== 'top') return;
        ghost.removeEventListener('transitionend', done);
        ghost.remove();
        resolve();
      }
      ghost.addEventListener('transitionend', done);
      setTimeout(function () {
        ghost.removeEventListener('transitionend', done);
        if (ghost.parentNode) ghost.remove();
        resolve();
      }, 450);
    });
  }

  function demoValues() {
    const a = [];
    let v;
    for (v = HOLE_MIN; v <= HOLE_MAX; v++) {
      a.push(v);
    }
    while (a.length < DEMO_LEN) {
      a.push(
        DEMO_MIN + Math.floor(Math.random() * (DEMO_MAX - DEMO_MIN + 1))
      );
    }
    let i = a.length;
    while (i > 1) {
      const j = Math.floor(Math.random() * i);
      i--;
      const t = a[i];
      a[i] = a[j];
      a[j] = t;
    }
    return a;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    const minVal = HOLE_MIN;
    const maxVal = HOLE_MAX;
    const span = HOLE_SPAN;
    const holes = [];
    let h;
    for (h = 0; h < span; h++) {
      holes.push([]);
    }

    steps.push({
      kind: 'phase',
      phase: 'init',
      fullArr: a.slice(),
      minVal: minVal,
      maxVal: maxVal,
      span: span,
      holes: cloneHoles(holes),
      movedThroughIdx: -1,
    });

    let i;
    for (i = 0; i < n; i++) {
      const v = a[i];
      const holeIdx = v - minVal;
      steps.push({
        kind: 'assign_scan',
        idx: i,
        value: v,
        holeIdx: holeIdx,
        fullArr: a.slice(),
        minVal: minVal,
        span: span,
        holes: cloneHoles(holes),
        movedThroughIdx: i - 1,
      });
      holes[holeIdx].push(v);
      steps.push({
        kind: 'assign_move',
        idx: i,
        value: v,
        holeIdx: holeIdx,
        fullArr: a.slice(),
        minVal: minVal,
        span: span,
        holes: cloneHoles(holes),
        movedThroughIdx: i,
        holeStackPos: holes[holeIdx].length - 1,
      });
    }

    steps.push({
      kind: 'assign_all_done',
      fullArr: a.slice(),
      minVal: minVal,
      span: span,
      holes: cloneHoles(holes),
      movedThroughIdx: n - 1,
    });

    steps.push({
      kind: 'phase',
      phase: 'collect',
      fullArr: a.slice(),
      minVal: minVal,
      span: span,
      holes: cloneHoles(holes),
      movedThroughIdx: n - 1,
      outputArr: [],
    });

    const workingHoles = cloneHoles(holes);
    const output = [];
    for (h = 0; h < span; h++) {
      while (workingHoles[h].length > 0) {
        const value = workingHoles[h][0];
        steps.push({
          kind: 'collect_scan',
          holeIdx: h,
          value: value,
          fullArr: a.slice(),
          minVal: minVal,
          span: span,
          holes: cloneHoles(workingHoles),
          outputArr: output.slice(),
        });
        workingHoles[h].shift();
        output.push(value);
        steps.push({
          kind: 'collect_move',
          holeIdx: h,
          value: value,
          fullArr: a.slice(),
          minVal: minVal,
          span: span,
          holes: cloneHoles(workingHoles),
          outputArr: output.slice(),
          outputIdx: output.length - 1,
        });
      }
    }

    steps.push({
      kind: 'done',
      arr: output.slice(),
      fullArr: a.slice(),
      minVal: minVal,
      span: span,
      holes: cloneHoles(workingHoles),
      outputArr: output.slice(),
    });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-pigeonhole',
    initialValues: DEMO_INITIAL.slice(),
    initialCaption:
      '鳩の巣ソートのデモ（入力から下の巣へ移動し、巣から出力へ回収します）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    rebuild: function (api) {
      const vals = demoValues();
      api.values = vals;
      api.steps = generateSteps(vals);
      api.idx = 0;
      const first = api.steps[0];
      if (first && first.kind === 'phase' && first.phase === 'init') {
        mountPigeonholeDemo(api.barsEl, {
          fullArr: first.fullArr,
          minVal: first.minVal,
          holes: first.holes,
          movedThroughIdx: first.movedThroughIdx,
        });
      } else {
        api.mountBars(api.barsEl, vals);
      }
      api.setCaption(
        '鳩の巣ソートのデモ（入力から下の巣へ移動し、巣から出力へ回収します）'
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      const wrap = ensureLayout(barsEl);
      const scale = valueScale(s.fullArr || s.arr || [1]);

      if (s.kind === 'phase') {
        if (s.phase === 'init') {
          mountPigeonholeDemo(barsEl, {
            fullArr: s.fullArr,
            minVal: s.minVal,
            holes: s.holes,
            movedThroughIdx: s.movedThroughIdx,
          });
          api.setCaption(
            'フェーズ1: 値域 [' +
              s.minVal +
              ', ' +
              s.maxVal +
              '] に ' +
              s.span +
              ' 個の巣を入力の下に用意します'
          );
          return;
        }
        mountPigeonholeDemo(barsEl, {
          outputMode: true,
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          outputArr: s.outputArr || [],
          movedThroughIdx: s.movedThroughIdx,
        });
        api.setCaption('フェーズ2: 巣を昇順に走査し、出力へ回収します');
        return;
      }

      if (s.kind === 'assign_scan') {
        mountPigeonholeDemo(barsEl, {
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          movedThroughIdx: s.movedThroughIdx,
          highlightInputIdx: s.idx,
          highlightRole: 'cursor',
        });
        api.setCaption(
          '仕分け: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' → 巣 ' +
            (s.minVal + s.holeIdx)
        );
        return;
      }

      if (s.kind === 'assign_move') {
        const holesBefore = cloneHoles(s.holes);
        holesBefore[s.holeIdx].pop();

        mountPigeonholeDemo(barsEl, {
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: holesBefore,
          movedThroughIdx: s.movedThroughIdx - 1,
          highlightInputIdx: s.idx,
          highlightRole: 'cursor',
          activeHoleIdx: s.holeIdx,
        });
        await nextFrame();

        const fromEl = findInputBar(wrap, s.idx);
        const fromRect = barRectFromEl(fromEl);

        mountPigeonholeDemo(barsEl, {
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          movedThroughIdx: s.movedThroughIdx,
          activeHoleIdx: s.holeIdx,
          hideHoleBar: {
            holeIdx: s.holeIdx,
            stackPos: s.holeStackPos,
          },
        });
        await nextFrame();

        const toEl = findHoleBar(wrap, s.holeIdx, s.holeStackPos);
        const toRect = barRectFromEl(toEl);

        if (fromRect && toRect) {
          await flyBarRects(fromRect, toRect, s.value, scale, 'write');
        }

        mountPigeonholeDemo(barsEl, {
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          movedThroughIdx: s.movedThroughIdx,
          activeHoleIdx: s.holeIdx,
        });
        api.setCaption(
          '値 ' +
            s.value +
            ' を巣 ' +
            (s.minVal + s.holeIdx) +
            ' へ移しました'
        );
        return;
      }

      if (s.kind === 'assign_all_done') {
        mountPigeonholeDemo(barsEl, {
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          movedThroughIdx: s.movedThroughIdx,
        });
        api.setCaption('仕分け完了: すべての要素が巣へ入りました');
        return;
      }

      if (s.kind === 'collect_scan') {
        mountPigeonholeDemo(barsEl, {
          outputMode: true,
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          outputArr: s.outputArr || [],
          activeHoleIdx: s.holeIdx,
        });
        const holeBar = findHoleBar(wrap, s.holeIdx, 0);
        if (holeBar) {
          holeBar.setAttribute('data-role', 'cursor');
        }
        api.setCaption(
          '回収: 巣 ' +
            (s.minVal + s.holeIdx) +
            ' から値 ' +
            s.value +
            ' を取り出します'
        );
        return;
      }

      if (s.kind === 'collect_move') {
        const holesWithItem = cloneHoles(s.holes);
        holesWithItem[s.holeIdx].unshift(s.value);

        mountPigeonholeDemo(barsEl, {
          outputMode: true,
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: holesWithItem,
          outputArr: (s.outputArr || []).slice(0, -1),
          activeHoleIdx: s.holeIdx,
        });
        await nextFrame();

        const fromEl = findHoleBar(wrap, s.holeIdx, 0);
        const fromRect = barRectFromEl(fromEl);

        mountPigeonholeDemo(barsEl, {
          outputMode: true,
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          outputArr: s.outputArr,
          activeHoleIdx: s.holeIdx,
          hideOutputBarIdx: s.outputIdx,
        });
        await nextFrame();

        const toEl = findOutputBar(wrap, s.outputIdx);
        const toRect = barRectFromEl(toEl);

        if (fromRect && toRect) {
          await flyBarRects(fromRect, toRect, s.value, scale, 'write');
        }

        mountPigeonholeDemo(barsEl, {
          outputMode: true,
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          outputArr: s.outputArr,
          highlightOutputIdx: s.outputIdx,
          highlightRole: 'write',
        });
        api.setCaption(
          '回収: 値 ' +
            s.value +
            ' を位置 ' +
            s.outputIdx +
            ' に配置しました'
        );
        return;
      }

      if (s.kind === 'done') {
        mountPigeonholeDemo(barsEl, {
          outputMode: true,
          fullArr: s.fullArr,
          minVal: s.minVal,
          holes: s.holes,
          outputArr: s.outputArr || s.arr,
        });
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 320,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="pigeonhole-sort-demo"
  data_prefix="pigeonhole"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[カウンティングソート](/2026/06/20/sort-counting.html)は出現回数を数えてから配置するのに対し、鳩の巣ソートは値ごとの巣（リスト）へ要素を直接入れる。実装が一致することも多い。

[バケットソート](/2026/06/23/sort-bucket.html)は値域を等幅の区間に分割するのに対し、鳩の巣ソートは取りうる各値に 1 巣ずつ割り当てる。[自己インデックスソート](/2026/07/07/sort-self-indexed.html)はキーをソート空間のアドレスとみなす枠組みが異なる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000010 |        0.000096 |              78 |              84 |
|        512 |        0.000021 |        0.000429 |              94 |             100 |
|       1024 |        0.000035 |        0.000154 |             134 |             140 |
|       2048 |        0.000078 |        0.005159 |             218 |             224 |
|       4096 |        0.000195 |        0.000387 |             346 |             352 |
|       8192 |        0.000332 |        0.001164 |             458 |             472 |
|      16384 |        0.000633 |        0.001572 |            1028 |            1060 |
|      32768 |        0.001410 |        0.013615 |            2159 |            2192 |
|      65536 |        0.002924 |        0.016952 |            4467 |            4500 |
|     131072 |        0.007082 |        0.052990 |            9086 |            9164 |
|     262144 |        0.015778 |        0.070310 |           18309 |           18376 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="pigeonhole" %}
