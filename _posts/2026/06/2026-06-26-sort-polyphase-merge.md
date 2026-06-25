---
title:     ポリフェーズマージソートで配列を並び替える
date:      2026-06-26 00:15:26 +0900
tags:      sort
sort_demo: true
---

## ポリフェーズマージソートを使用する

ポリフェーズマージソート (`PolyPhase Merge Sort`) は、複数のテープ（またはファイル）に分散した整列済みランを、フィボナッチ分布に沿って段階的に併合していく外部整列アルゴリズムである。テープ本数が少ない環境でも、各パスでほぼすべてのテープを稼働させ、バランスマージよりパス数を抑えられる場合がある。

本記事のデモとベンチマークでは、3 本の仮想テープを主記憶上のベクタで模擬する。実際の外部整列では置換選択などで初期ランを作り、ラン数がフィボナッチ数でないときはダミーランで分布を調整する。

1.  **初期ラン生成**: 配列を固定長（例: 32 要素）の区間に区切り、各区間を整列してランとする。
2.  **フィボナッチ分布**: 3 本テープのうち 1 本を空け、残り 2 本へラン数比を連続するフィボナッチ数（例: `{2, 3}`, `{3, 5}`）に近づけるよう分配する。
3.  **ポリフェーズ併合**: 2 本のソーステープから先頭ランを 1 組ずつ取り出し、空きテープへマージする。
4.  **テープローテーション**: 出力テープの役割を循環させ、再び 2 本から 1 本への併合を繰り返す。
5.  **完了**: 全要素が 1 本のテープ上の 1 ランにまとまったら配列へ書き戻す。

```pseudocode
procedure create_runs(A, run_size)
  split A into chunks of run_size, sort each chunk into a run

procedure distribute_fibonacci(runs, tapes[3])
  target = smallest Fibonacci number >= length(runs)
  put runs on tape 1 and tape 2 in Fibonacci ratio; tape 0 empty

procedure polyphase_pass(tapes[3])
  while tape 1 and tape 2 both have runs
    merged = merge(tape1.pop_front(), tape2.pop_front())
    tape0.push_back(merged)
  rotate tape roles cyclically

procedure polyphase_merge_sort(A)
  runs = create_runs(A)
  tapes = distribute_fibonacci(runs)
  while total run count on all tapes > 1
    polyphase_pass(tapes)
  copy final run back into A
```

ラン数が理想的なフィボナッチ分布に一致するとき、3 テープ構成では併合パス数が最小化される。

一般の入力ではダミーラン（空ラン）で分布を補い、テープの待機時間を減らす。時間計算量は通常`O(n log n)` 程度だが、I/O 待ちとバッファ管理のコストが支配的になる。主記憶シミュレーションではラン用ベクタとマージ用バッファに `O(n)` の追加空間を要し、マージの比較規則上は安定ソートにできる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('polyphase-merge-sort-demo', function (root) {
  const RUN_SIZE = 4;
  const NUM_TAPES = 3;
  const barClass = 'sort-demo__bar';
  const RUN_COLOR_CLASSES = [
    'sort-demo-polyphase__run--color-0',
    'sort-demo-polyphase__run--color-1',
    'sort-demo-polyphase__run--color-2',
    'sort-demo-polyphase__run--color-3',
    'sort-demo-polyphase__run--color-4',
    'sort-demo-polyphase__run--color-5',
    'sort-demo-polyphase__run--color-6',
    'sort-demo-polyphase__run--color-7',
  ];
  const DUMMY_COLOR = 'rgba(128, 128, 128, 0.38)';

  function tapeDisplayName(slot) {
    return 'テープ' + (slot + 1);
  }

  function cloneRoles(roles) {
    return {
      outputSlot: roles.outputSlot,
      inputSlots: roles.inputSlots.slice(),
    };
  }

  function nextRoles(tapes, currentOutputSlot) {
    for (let s = 0; s < 3; s++) {
      if (tapes[s].length === 0) {
        return {
          outputSlot: s,
          inputSlots: [0, 1, 2].filter(function (x) {
            return x !== s;
          }),
        };
      }
    }
    const next = (currentOutputSlot + 1) % 3;
    return {
      outputSlot: next,
      inputSlots: [0, 1, 2].filter(function (x) {
        return x !== next;
      }),
    };
  }

  function copyRun(run) {
    return {
      id: run.id,
      values: run.values.slice(),
      dummy: !!run.dummy,
      colorIndex: run.colorIndex,
      sourceColors: run.sourceColors
        ? run.sourceColors.slice()
        : run.colorIndex >= 0
          ? [run.colorIndex]
          : [],
    };
  }

  function cloneRuns(runs) {
    return runs.map(copyRun);
  }

  function cloneTapes(tapes) {
    return tapes.map(function (tape) {
      return tape.map(copyRun);
    });
  }

  function valueSpan(values) {
    const flat = [];
    values.forEach(function (v) {
      if (typeof v === 'number' && !Number.isNaN(v)) flat.push(v);
    });
    if (!flat.length) return { min: 0, max: 1, span: 1 };
    const min = Math.min.apply(null, flat);
    const max = Math.max.apply(null, flat);
    return { min: min, max: max, span: Math.max(max - min, 1) };
  }

  function stamp(base, extra) {
    const o = typeof base === 'object' && base !== null ? base : {};
    if (extra) {
      Object.keys(extra).forEach(function (k) {
        o[k] = extra[k];
      });
    }
    return o;
  }

  function tapeIsEmpty(tapeRuns, isOutTape, merge) {
    if (isOutTape && merge && merge.active && merge.outRun.length > 0) {
      return false;
    }
    return !tapeRuns || tapeRuns.length === 0;
  }

  function prefersReducedMotion() {
    if (typeof window === 'undefined' || !window.matchMedia) return false;
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

  function flyBarRects(from, to, scale, val) {
    if (!from || !to || prefersReducedMotion()) {
      return Promise.resolve();
    }
    const ghost = mkBar(val, scale, 'write');
    ghost.style.position = 'fixed';
    ghost.style.left = from.left + 'px';
    ghost.style.top = from.top + 'px';
    ghost.style.width = from.width + 'px';
    ghost.style.height = from.height + 'px';
    ghost.style.margin = '0';
    ghost.style.zIndex = '1000';
    ghost.style.pointerEvents = 'none';
    ghost.style.boxSizing = 'border-box';
    ghost.style.transition = 'left 0.32s ease, top 0.32s ease, width 0.32s ease, height 0.32s ease';
    document.body.appendChild(ghost);
    return nextFrame().then(function () {
      ghost.style.left = to.left + 'px';
      ghost.style.top = to.top + 'px';
      ghost.style.width = to.width + 'px';
      ghost.style.height = to.height + 'px';
      return new Promise(function (resolve) {
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
        }, 400);
      });
    });
  }

  function findRunHeadBar(container, tapeIdx) {
    const tape = container.querySelector(
      '.sort-demo-polyphase__tape[data-tape-idx="' + tapeIdx + '"]'
    );
    if (!tape) return null;
    const head =
      tape.querySelector('.sort-demo-polyphase__run-bars [data-role="compare"]') ||
      tape.querySelector('.sort-demo-polyphase__run-bars .sort-demo__bar');
    return head;
  }

  function findOutputBar(container, tapeIdx, writeIdx) {
    const tape = container.querySelector(
      '.sort-demo-polyphase__tape[data-tape-idx="' + tapeIdx + '"]'
    );
    if (!tape) return null;
    const outRun = tape.querySelector('.sort-demo-polyphase__run--out');
    if (!outRun) return null;
    const bars = outRun.querySelectorAll('.sort-demo__bar');
    return bars[writeIdx] || bars[bars.length - 1] || null;
  }

  function barHeight(val, scale) {
    return 28 + ((val - scale.min) / scale.span) * 92;
  }

  function runSourceColors(run) {
    if (run.dummy) return [];
    if (run.sourceColors && run.sourceColors.length) return run.sourceColors.slice();
    if (run.colorIndex >= 0) return [run.colorIndex];
    return [];
  }

  function collectUsedColorIndices(tapes) {
    const used = new Set();
    tapes.forEach(function (tape) {
      tape.forEach(function (run) {
        if (run.dummy) return;
        runSourceColors(run).forEach(function (c) {
          used.add(c);
        });
        if (run.colorIndex >= 0) used.add(run.colorIndex);
      });
    });
    return used;
  }

  function pickMergedColor(leftRun, rightRun, tapes) {
    const left = runSourceColors(leftRun);
    const right = runSourceColors(rightRun);
    const combined = left.concat(right).filter(function (c, i, arr) {
      return arr.indexOf(c) === i;
    });
    if (!combined.length) return { colorIndex: -1, sourceColors: [] };
    if (combined.length === 1) {
      return { colorIndex: combined[0], sourceColors: combined };
    }
    const used = collectUsedColorIndices(tapes);
    combined.forEach(function (c) {
      used.add(c);
    });
    let idx = 0;
    while (used.has(idx)) idx += 1;
    return { colorIndex: idx, sourceColors: combined };
  }

  function applyRunColorClass(runEl, run) {
    RUN_COLOR_CLASSES.forEach(function (cls) {
      runEl.classList.remove(cls);
    });
    runEl.classList.remove('sort-demo-polyphase__run--color-merged');
    if (run.dummy) return;
    if (run.colorIndex >= 0 && run.colorIndex < RUN_COLOR_CLASSES.length) {
      runEl.classList.add(RUN_COLOR_CLASSES[run.colorIndex]);
    } else {
      runEl.classList.add('sort-demo-polyphase__run--color-merged');
    }
  }

  function mkBar(val, scale, role) {
    const bar = document.createElement('div');
    bar.className = barClass;
    bar.style.height = barHeight(val, scale) + 'px';
    bar.setAttribute('title', String(val));
    if (role) bar.setAttribute('data-role', role);
    bar.setAttribute(
      'aria-label',
      DemoSort.barAccessibilityLabelSimple(String(val), role)
    );
    return bar;
  }

  function renderRunBars(runEl, values, scale, rolesByIdx) {
    values.forEach(function (val, bi) {
      const role = rolesByIdx ? rolesByIdx[bi] : null;
      runEl.appendChild(mkBar(val, scale, role));
    });
  }

  function appendDummyRun(parent) {
    const runEl = document.createElement('div');
    runEl.className =
      'sort-demo-polyphase__run sort-demo-polyphase__run--dummy';
    runEl.style.background = DUMMY_COLOR;
    const lab = document.createElement('span');
    lab.className =
      'sort-demo-polyphase__run-label sort-demo-polyphase__run-label--dummy';
    lab.textContent = 'ダミー';
    runEl.appendChild(lab);
    parent.appendChild(runEl);
    return runEl;
  }

  function appendValueRun(parent, run, values, scale, rolesByIdx, extraClass) {
    const runEl = document.createElement('div');
    runEl.className = 'sort-demo-polyphase__run';
    if (extraClass) runEl.classList.add(extraClass);
    if (run.dummy) {
      runEl.style.background = DUMMY_COLOR;
    } else {
      applyRunColorClass(runEl, run);
    }
    const barsWrap = document.createElement('div');
    barsWrap.className = 'sort-demo-polyphase__run-bars';
    renderRunBars(barsWrap, values, scale, rolesByIdx);
    runEl.appendChild(barsWrap);
    parent.appendChild(runEl);
    return runEl;
  }

  function mountFlatView(container, values, rangeValues, rolesByIdx) {
    container.innerHTML = '';
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      'ソート対象の配列。棒の高さは値の大小、左から右へ位置0、1の順です。'
    );
    const wrap = document.createElement('div');
    wrap.className = 'sort-demo-polyphase-wrap';
    const stage = document.createElement('div');
    stage.className = 'sort-demo-polyphase__stage sort-demo-polyphase__stage--flat';
    const spacer = document.createElement('div');
    spacer.className = 'sort-demo-polyphase__label-spacer';
    spacer.setAttribute('aria-hidden', 'true');
    const row = document.createElement('div');
    row.className = 'sort-demo-polyphase__flat-row';
    row.setAttribute('role', 'list');
    const scale = valueSpan(rangeValues || values);
    values.forEach(function (val, i) {
      const role = rolesByIdx ? rolesByIdx[i] : null;
      row.appendChild(mkBar(val, scale, role));
    });
    stage.appendChild(spacer);
    stage.appendChild(row);
    wrap.appendChild(stage);
    container.appendChild(wrap);
    DemoSort.syncBarsAccessibility(row);
  }

  async function animateSplitIntoRuns(container, flatValues, runsStep) {
    mountFlatView(container, flatValues, flatValues);
    const flatBars = Array.from(
      container.querySelectorAll('.sort-demo-polyphase__flat-row .sort-demo__bar')
    );
    if (flatBars.length !== flatValues.length || prefersReducedMotion()) {
      mountPolyphaseView(container, runsStep);
      return;
    }
    container.scrollLeft = 0;
    const rects = flatBars.map(function (b) {
      return b.getBoundingClientRect();
    });

    mountPolyphaseView(container, runsStep);
    container.scrollLeft = 0;

    const newBars = Array.from(
      container.querySelectorAll('.sort-demo-polyphase__runs-row .sort-demo__bar')
    );
    if (newBars.length !== flatBars.length) return;

    newBars.forEach(function (bar, i) {
      const after = bar.getBoundingClientRect();
      const before = rects[i];
      const dx = before.left - after.left;
      bar.style.transition = 'none';
      bar.style.transform = 'translateX(' + dx + 'px)';
    });
    void container.offsetHeight;

    await nextFrame();
    newBars.forEach(function (bar) {
      bar.style.transition = 'transform 0.38s ease';
      bar.style.transform = 'translateX(0)';
    });
    await Promise.all(
      newBars.map(function (bar) {
        return DemoSort.transitionPromise(bar);
      })
    );
    newBars.forEach(function (bar) {
      bar.style.transition = '';
      bar.style.transform = '';
    });
  }

  function alignPolyphaseScroll(container) {
    requestAnimationFrame(function () {
      const maxScroll = container.scrollWidth - container.clientWidth;
      container.scrollLeft = maxScroll > 0 ? maxScroll / 2 : 0;
    });
  }

  function mountPolyphaseView(container, s) {
    container.innerHTML = '';
    container.setAttribute('role', 'group');
    container.setAttribute(
      'aria-label',
      'ポリフェーズマージソートの現在の状態（ランまたはテープ）。'
    );

    const wrap = document.createElement('div');
    wrap.className = 'sort-demo-polyphase-wrap';
    const scale = valueSpan(s.rangeValues || []);

    if (s.mode === 'flat') {
      mountFlatView(container, s.values, s.rangeValues);
      return;
    }

    if (s.mode === 'runs') {
      const stage = document.createElement('div');
      stage.className = 'sort-demo-polyphase__stage';
      const spacer = document.createElement('div');
      spacer.className = 'sort-demo-polyphase__label-spacer';
      spacer.setAttribute('aria-hidden', 'true');
      stage.appendChild(spacer);
      const row = document.createElement('div');
      row.className = 'sort-demo-polyphase__runs-row';
      s.runs.forEach(function (run, ri) {
        const runEl = document.createElement('div');
        runEl.className = 'sort-demo-polyphase__run';
        runEl.setAttribute('data-run-idx', String(ri));
        if (run.dummy) runEl.classList.add('sort-demo-polyphase__run--dummy');
        if (run.dummy) {
          runEl.style.background = DUMMY_COLOR;
        } else {
          applyRunColorClass(runEl, run);
        }

        if (run.dummy) {
          const lab = document.createElement('span');
          lab.className =
            'sort-demo-polyphase__run-label sort-demo-polyphase__run-label--dummy';
          lab.textContent = 'ダミー';
          runEl.appendChild(lab);
        } else {
          const roles = {};
          if (typeof s.activeRun === 'number' && ri === s.activeRun) {
            if (s.kind === 'run_key' && typeof s.keyLocalIdx === 'number') {
              roles[s.keyLocalIdx] = 'key';
            }
            if (s.kind === 'run_compare' || s.kind === 'run_swap') {
              roles[s.compareLocalLo] = s.kind === 'run_swap' ? 'swap' : 'compare';
              roles[s.compareLocalHi] = s.kind === 'run_swap' ? 'swap' : 'compare';
            }
          }
          const barsWrap = document.createElement('div');
          barsWrap.className = 'sort-demo-polyphase__run-bars';
          renderRunBars(barsWrap, run.values, scale, roles);
          runEl.appendChild(barsWrap);
        }
        row.appendChild(runEl);
      });
      stage.appendChild(row);
      wrap.appendChild(stage);
      container.appendChild(wrap);
      return;
    }

    const tapesRow = document.createElement('div');
    tapesRow.className = 'sort-demo-polyphase__tapes';
    const merge = s.merge;

    const inputLeft = s.inputSlots ? s.inputSlots[0] : 0;
    const inputRight = s.inputSlots ? s.inputSlots[1] : 1;

    for (let displaySlot = 0; displaySlot < 3; displaySlot++) {
      const tapeEl = document.createElement('div');
      tapeEl.className = 'sort-demo-polyphase__tape';
      tapeEl.setAttribute('data-tape-idx', String(displaySlot));
      const tapeRuns = s.tapes && s.tapes[displaySlot] ? s.tapes[displaySlot] : [];
      const isOutTape =
        merge && merge.active && merge.outTape === displaySlot;
      const isEmpty = tapeIsEmpty(tapeRuns, isOutTape, merge);

      if (isEmpty) {
        tapeEl.classList.add('sort-demo-polyphase__tape--empty');
      }

      const label = document.createElement('div');
      label.className = 'sort-demo-polyphase__tape-label';
      label.textContent = tapeDisplayName(displaySlot);
      tapeEl.appendChild(label);

      const runsWrap = document.createElement('div');
      runsWrap.className = 'sort-demo-polyphase__tape-runs';

      tapeRuns.forEach(function (run, ri) {
        const isLeftFront =
          merge &&
          merge.active &&
          ri === 0 &&
          displaySlot === inputLeft &&
          merge.leftRun.id === run.id;
        const isRightFront =
          merge &&
          merge.active &&
          ri === 0 &&
          displaySlot === inputRight &&
          merge.rightRun.id === run.id;
        const isMergeFront = isLeftFront || isRightFront;

        if (run.dummy) {
          appendDummyRun(runsWrap);
          return;
        }

        let values = run.values.slice();
        let rolesByIdx = null;
        let skipRun = false;

        if (isMergeFront) {
          values = isLeftFront
            ? merge.leftRemain.slice()
            : merge.rightRemain.slice();
          if (!values.length) skipRun = true;
        }

        if (skipRun) return;
        if (!values.length) return;

        if (merge && merge.active && s.kind === 'merge_compare' && isMergeFront) {
          rolesByIdx = { 0: 'compare' };
        }

        if (
          merge &&
          merge.active &&
          s.kind === 'merge_write' &&
          isMergeFront &&
          values.length
        ) {
          rolesByIdx = { 0: 'compare' };
        }

        appendValueRun(runsWrap, run, values, scale, rolesByIdx, null);
      });

      if (isOutTape && merge && merge.active) {
        const rolesByIdx = {};
        if (s.kind === 'merge_write' && merge.outRun.length) {
          rolesByIdx[merge.outRun.length - 1] = 'write';
        }
        appendValueRun(
          runsWrap,
          {
            colorIndex:
              typeof merge.outColorIndex === 'number' ? merge.outColorIndex : -1,
            sourceColors: merge.outSourceColors
              ? merge.outSourceColors.slice()
              : [],
            dummy: false,
            id: 'out',
            values: merge.outRun,
          },
          merge.outRun,
          scale,
          rolesByIdx,
          'sort-demo-polyphase__run--out'
        );
      }

      tapeEl.appendChild(runsWrap);
      tapesRow.appendChild(tapeEl);
    }

    wrap.appendChild(tapesRow);
    container.appendChild(wrap);
    alignPolyphaseScroll(container);
  }

  function mergeView(
    leftRun,
    rightRun,
    leftRemain,
    rightRemain,
    outRun,
    outTape,
    outColor
  ) {
    return {
      active: true,
      leftRun: copyRun(leftRun),
      rightRun: copyRun(rightRun),
      leftRemain: leftRemain.slice(),
      rightRemain: rightRemain.slice(),
      outRun: outRun.slice(),
      outTape: outTape,
      outColorIndex: outColor ? outColor.colorIndex : -1,
      outSourceColors: outColor ? outColor.sourceColors.slice() : [],
    };
  }

  function mergeRuns(
    leftRun,
    rightRun,
    tapes,
    outputSlot,
    inputLeft,
    inputRight,
    roles,
    steps,
    meta
  ) {
    const lv = leftRun.dummy ? [] : leftRun.values.slice();
    const rv = rightRun.dummy ? [] : rightRun.values.slice();
    let i = 0;
    let j = 0;
    const outValues = [];

    function pushTapeStep(kind, extra) {
      steps.push(
        stamp(
          {
            kind: kind,
            mode: 'tapes',
            tapes: cloneTapes(tapes),
            outputSlot: roles.outputSlot,
            inputSlots: roles.inputSlots.slice(),
            rangeValues: meta.rangeValues,
          },
          extra
        )
      );
    }

    const outColor = pickMergedColor(leftRun, rightRun, tapes);

    pushTapeStep('merge_start', {
      merge: mergeView(leftRun, rightRun, lv, rv, [], outputSlot, outColor),
    });

    while (i < lv.length && j < rv.length) {
      const pickLeft = lv[i] <= rv[j];
      pushTapeStep('merge_compare', {
        merge: mergeView(
          leftRun,
          rightRun,
          lv.slice(i),
          rv.slice(j),
          outValues,
          outputSlot,
          outColor
        ),
        pickLeft: pickLeft,
        leftHead: lv[i],
        rightHead: rv[j],
      });
      outValues.push(pickLeft ? lv[i] : rv[j]);
      if (pickLeft) i += 1;
      else j += 1;
      pushTapeStep('merge_write', {
        merge: mergeView(
          leftRun,
          rightRun,
          lv.slice(i),
          rv.slice(j),
          outValues,
          outputSlot,
          outColor
        ),
        writeValue: outValues[outValues.length - 1],
        writeIdx: outValues.length - 1,
        pickLeft: pickLeft,
      });
    }
    while (i < lv.length) {
      pushTapeStep('merge_compare', {
        merge: mergeView(
          leftRun,
          rightRun,
          lv.slice(i),
          rv.slice(j),
          outValues,
          outputSlot,
          outColor
        ),
        pickLeft: true,
        remainder: 'left',
      });
      outValues.push(lv[i]);
      i += 1;
      pushTapeStep('merge_write', {
        merge: mergeView(
          leftRun,
          rightRun,
          lv.slice(i),
          rv.slice(j),
          outValues,
          outputSlot,
          outColor
        ),
        writeValue: outValues[outValues.length - 1],
        writeIdx: outValues.length - 1,
        pickLeft: true,
      });
    }
    while (j < rv.length) {
      pushTapeStep('merge_compare', {
        merge: mergeView(
          leftRun,
          rightRun,
          lv.slice(i),
          rv.slice(j),
          outValues,
          outputSlot,
          outColor
        ),
        pickLeft: false,
        remainder: 'right',
      });
      outValues.push(rv[j]);
      j += 1;
      pushTapeStep('merge_write', {
        merge: mergeView(
          leftRun,
          rightRun,
          lv.slice(i),
          rv.slice(j),
          outValues,
          outputSlot,
          outColor
        ),
        writeValue: outValues[outValues.length - 1],
        writeIdx: outValues.length - 1,
        pickLeft: false,
      });
    }

    const mergeColor = outColor;
    const mergedRun = {
      id: 'merged-' + steps.length,
      values: outValues.slice(),
      dummy: outValues.length === 0,
      colorIndex: mergeColor.colorIndex,
      sourceColors: mergeColor.sourceColors,
    };
    tapes[outputSlot].push(mergedRun);
    tapes[inputLeft].shift();
    tapes[inputRight].shift();

    steps.push(
      stamp({
        kind: 'merge_done',
        mode: 'tapes',
        tapes: cloneTapes(tapes),
        outputSlot: roles.outputSlot,
        inputSlots: roles.inputSlots.slice(),
        merge: null,
        mergedRun: outValues.slice(),
        rangeValues: meta.rangeValues,
        consumedDummy: leftRun.dummy || rightRun.dummy,
      })
    );
    return mergedRun;
  }

  function nextFibAtLeast(n) {
    let prev = 1;
    let curr = 1;
    while (curr < n) {
      const next = prev + curr;
      prev = curr;
      curr = next;
    }
    return { prev: prev, target: curr };
  }

  function distributeFibonacci(runs, steps, meta) {
    const tapes = [[], [], []];
    const roles = { outputSlot: 2, inputSlots: [0, 1] };
    const n = runs.length;
    if (n === 0) {
      return { tapes: tapes, roles: roles };
    }
    if (n === 1) {
      tapes[0].push(copyRun(runs[0]));
      steps.push(
        stamp({
          kind: 'distribute',
          mode: 'tapes',
          tapes: cloneTapes(tapes),
          outputSlot: roles.outputSlot,
          inputSlots: roles.inputSlots.slice(),
          rangeValues: meta.rangeValues,
          onTape1: 1,
          onTape2: 0,
          dummies: 0,
        })
      );
      return { tapes: tapes, roles: roles };
    }

    const fib = nextFibAtLeast(n);
    const dummies = fib.target - n;
    const onTape2 = Math.max(0, fib.prev - dummies);
    const onTape1 = fib.target - onTape2;

    for (let idx = 0; idx < onTape1; idx++) {
      tapes[0].push(copyRun(runs[idx]));
    }
    for (let idx = onTape1; idx < n; idx++) {
      tapes[1].push(copyRun(runs[idx]));
    }
    for (let d = 0; d < dummies; d++) {
      tapes[1].push({
        id: 'dummy-' + d,
        values: [],
        dummy: true,
        colorIndex: -1,
      });
    }

    steps.push(
      stamp({
        kind: 'distribute',
        mode: 'tapes',
        tapes: cloneTapes(tapes),
        outputSlot: roles.outputSlot,
        inputSlots: roles.inputSlots.slice(),
        rangeValues: meta.rangeValues,
        onTape1: onTape1,
        onTape2: onTape2,
        dummies: dummies,
      })
    );
    return { tapes: tapes, roles: roles };
  }

  function countRuns(tapes) {
    let c = 0;
    for (let t = 0; t < tapes.length; t++) {
      c += tapes[t].length;
    }
    return c;
  }

  function polyphasePass(tapes, roles, steps, passNo, meta) {
    let merged = false;
    steps.push(
      stamp({
        kind: 'pass_start',
        mode: 'tapes',
        passNo: passNo,
        tapes: cloneTapes(tapes),
        outputSlot: roles.outputSlot,
        inputSlots: roles.inputSlots.slice(),
        rangeValues: meta.rangeValues,
      })
    );
    const inA = roles.inputSlots[0];
    const inB = roles.inputSlots[1];
    while (tapes[inA].length > 0 && tapes[inB].length > 0) {
      const left = tapes[inA][0];
      const right = tapes[inB][0];
      mergeRuns(
        left,
        right,
        tapes,
        roles.outputSlot,
        inA,
        inB,
        roles,
        steps,
        meta
      );
      merged = true;
      steps.push(
        stamp({
          kind: 'pass_merge',
          mode: 'tapes',
          passNo: passNo,
          tapes: cloneTapes(tapes),
          outputSlot: roles.outputSlot,
          inputSlots: roles.inputSlots.slice(),
          rangeValues: meta.rangeValues,
        })
      );
    }
    return merged;
  }

  function mergeAllRemaining(tapes, roles, steps, meta) {
    const all = [];
    for (let t = 0; t < tapes.length; t++) {
      for (let r = 0; r < tapes[t].length; r++) {
        all.push({ run: tapes[t][r], slot: t });
      }
    }
    while (all.length > 1) {
      const a = all.shift();
      const b = all.shift();
      const tmpTapes = [[], [], []];
      tmpTapes[a.slot] = [a.run];
      tmpTapes[b.slot] = [b.run];
      const tmpRoles = {
        outputSlot: [0, 1, 2].find(function (s) {
          return s !== a.slot && s !== b.slot;
        }),
        inputSlots: [a.slot, b.slot],
      };
      mergeRuns(
        a.run,
        b.run,
        tmpTapes,
        tmpRoles.outputSlot,
        a.slot,
        b.slot,
        tmpRoles,
        steps,
        meta
      );
      all.push({ run: tmpTapes[tmpRoles.outputSlot][0], slot: tmpRoles.outputSlot });
    }
    return all[0] && !all[0].run.dummy ? all[0].run.values.slice() : [];
  }

  function pushRunsStep(steps, kind, runs, meta, extra) {
    steps.push(
      stamp(
        {
          kind: kind,
          mode: 'runs',
          runs: cloneRuns(runs),
          rangeValues: meta.rangeValues,
        },
        extra
      )
    );
  }

  function generateSteps(initial) {
    const steps = [];
    const runs = [];
    const a = initial.slice();
    const meta = { rangeValues: initial.slice() };

    steps.push(
      stamp({
        kind: 'flat',
        mode: 'flat',
        values: initial.slice(),
        rangeValues: meta.rangeValues,
      })
    );

    for (let r = 0; r < initial.length / RUN_SIZE; r++) {
      const start = r * RUN_SIZE;
      const end = start + RUN_SIZE;
      runs.push({
        id: 'run-' + r,
        values: a.slice(start, end),
        dummy: false,
        colorIndex: r,
        sourceColors: [r],
      });
    }

    pushRunsStep(steps, 'split_runs', runs, meta, null);

    for (let r = 0; r < runs.length; r++) {
      const start = r * RUN_SIZE;
      const end = start + RUN_SIZE;
      pushRunsStep(steps, 'run_start', runs, meta, { activeRun: r });

      for (let i = start + 1; i < end; i++) {
        const localKey = i - start;
        pushRunsStep(steps, 'run_key', runs, meta, {
          activeRun: r,
          keyLocalIdx: localKey,
        });
        let j = i;
        while (j > start) {
          pushRunsStep(steps, 'run_compare', runs, meta, {
            activeRun: r,
            compareLocalLo: j - 1 - start,
            compareLocalHi: j - start,
          });
          if (a[j - 1] > a[j]) {
            pushRunsStep(steps, 'run_swap', runs, meta, {
              activeRun: r,
              compareLocalLo: j - 1 - start,
              compareLocalHi: j - start,
            });
            const t = a[j];
            a[j] = a[j - 1];
            a[j - 1] = t;
            runs[r].values = a.slice(start, end);
            j -= 1;
          } else {
            break;
          }
        }
      }
      runs[r].values = a.slice(start, end);
      pushRunsStep(steps, 'run_done', runs, meta, { activeRun: r });
    }

    const withDummy = cloneRuns(runs);
    withDummy.push({
      id: 'dummy-0',
      values: [],
      dummy: true,
      colorIndex: -1,
    });
    steps.push(
      stamp({
        kind: 'dummy_add',
        mode: 'runs',
        runs: withDummy,
        rangeValues: meta.rangeValues,
      })
    );

    const dist = distributeFibonacci(runs, steps, meta);
    let tapes = dist.tapes;
    let roles = cloneRoles(dist.roles);
    let passNo = 1;
    let idle = 0;
    while (countRuns(tapes) > 1) {
      if (polyphasePass(tapes, roles, steps, passNo, meta)) {
        roles = nextRoles(tapes, roles.outputSlot);
        steps.push(
          stamp({
            kind: 'rotate',
            mode: 'tapes',
            passNo: passNo,
            tapes: cloneTapes(tapes),
            outputSlot: roles.outputSlot,
            inputSlots: roles.inputSlots.slice(),
            rangeValues: meta.rangeValues,
          })
        );
        idle = 0;
        passNo += 1;
      } else {
        idle += 1;
        if (idle > NUM_TAPES * 4) {
          break;
        }
        roles = nextRoles(tapes, roles.outputSlot);
        steps.push(
          stamp({
            kind: 'rotate',
            mode: 'tapes',
            passNo: passNo,
            tapes: cloneTapes(tapes),
            outputSlot: roles.outputSlot,
            inputSlots: roles.inputSlots.slice(),
            rangeValues: meta.rangeValues,
          })
        );
      }
    }

    let finalRun;
    if (countRuns(tapes) === 1) {
      for (let t = 0; t < tapes.length; t++) {
        if (tapes[t].length === 1 && !tapes[t][0].dummy) {
          finalRun = tapes[t][0].values.slice();
          break;
        }
      }
    }
    if (!finalRun) {
      finalRun = mergeAllRemaining(tapes, roles, steps, meta);
    }

    steps.push(
      stamp({
        kind: 'done',
        mode: 'flat',
        values: finalRun,
        rangeValues: finalRun,
        finalRun: finalRun,
      })
    );
    return steps;
  }

  function tapeCaption(tapes) {
    return (
      tapeDisplayName(0) +
      '=' +
      tapes[0].length +
      ' ラン, ' +
      tapeDisplayName(1) +
      '=' +
      tapes[1].length +
      ' ラン, ' +
      tapeDisplayName(2) +
      '=' +
      tapes[2].length +
      ' ラン'
    );
  }

  function roleCaption(roles) {
    return (
      '出力=' +
      tapeDisplayName(roles.outputSlot) +
      ', 入力=' +
      tapeDisplayName(roles.inputSlots[0]) +
      '・' +
      tapeDisplayName(roles.inputSlots[1])
    );
  }

  const initialCaption =
    'ポリフェーズマージソート（16要素を4ランに分け、3本のテープで併合）';

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-polyphase-merge',
    initialValues: [8, 3, 12, 1, 6, 14, 2, 15, 5, 11, 9, 4, 13, 7, 10, 0],
    initialCaption: initialCaption,
    barClass: barClass,
    generateSteps: generateSteps,
    rebuild: function (api, v) {
      api.values = v;
      api.steps = generateSteps(v.slice());
      api.idx = 0;
      const first = api.steps[0];
      mountPolyphaseView(api.barsEl, first);
      api.setCaption(initialCaption);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      const stepIdx = api.idx - 1;

      if (s.kind === 'run_swap') {
        mountPolyphaseView(barsEl, s);
        const runBars = barsEl.querySelector(
          '.sort-demo-polyphase__run[data-run-idx="' +
            s.activeRun +
            '"] .sort-demo-polyphase__run-bars'
        );
        if (runBars) {
          api.setCaption('ラン内で要素を交換しています…');
          await DemoSort.flipAdjacentSwap(runBars, s.compareLocalLo);
        }
        api.setCaption(
          'ラン内で要素を交換しました（位置 ' +
            s.compareLocalLo +
            ' と ' +
            s.compareLocalHi +
            '）'
        );
        return;
      }

      if (s.kind === 'split_runs') {
        const prevS = stepIdx > 0 ? api.steps[stepIdx - 1] : null;
        if (prevS && prevS.kind === 'flat') {
          api.setCaption('16要素を4要素ずつの4ランに分割しています…');
          await animateSplitIntoRuns(barsEl, prevS.values, s);
        } else {
          mountPolyphaseView(barsEl, s);
        }
        api.setCaption('16要素を4要素ずつの4ランに分割しました（背景色で区別）');
        return;
      }

      if (s.kind === 'merge_write') {
        const prevS = stepIdx > 0 ? api.steps[stepIdx - 1] : null;
        const inSlots = s.inputSlots || [0, 1];
        const srcTape =
          s.pickLeft === false ||
          (s.pickLeft == null && prevS && prevS.pickLeft === false)
            ? inSlots[1]
            : inSlots[0];
        const outTape = s.outputSlot != null ? s.outputSlot : 2;
        const scale = valueSpan(s.rangeValues || []);
        if (
          prevS &&
          (prevS.kind === 'merge_compare' || prevS.kind === 'merge_write') &&
          !prefersReducedMotion()
        ) {
          mountPolyphaseView(barsEl, prevS);
          await nextFrame();
          const fromEl = findRunHeadBar(barsEl, srcTape);
          const fromRect = fromEl ? fromEl.getBoundingClientRect() : null;
          mountPolyphaseView(barsEl, s);
          await nextFrame();
          const toEl = findOutputBar(barsEl, outTape, s.writeIdx);
          const toRect = toEl ? toEl.getBoundingClientRect() : null;
          if (fromRect && toRect) {
            await flyBarRects(fromRect, toRect, scale, s.writeValue);
          }
        } else {
          mountPolyphaseView(barsEl, s);
        }
      } else {
        mountPolyphaseView(barsEl, s);
      }

      if (s.kind === 'flat') {
        api.setCaption('ソート前の16要素（まだランに分割していません）');
      } else if (s.kind === 'run_start') {
        api.setCaption(
          'ラン ' + (s.activeRun + 1) + ' を内部整列します'
        );
      } else if (s.kind === 'run_key') {
        api.setCaption('挿入キーをラン内の正しい位置へ移動します');
      } else if (s.kind === 'run_compare') {
        api.setCaption('ラン内で隣接要素を比較しています');
      } else if (s.kind === 'run_done') {
        api.setCaption(
          'ラン ' + (s.activeRun + 1) + ' の整列が完了しました'
        );
      } else if (s.kind === 'dummy_add') {
        api.setCaption(
          'フィボナッチ分布用のグレーのダミーランを追加（合計5ラン・テープ2へ配置予定）'
        );
      } else if (s.kind === 'distribute') {
        api.setCaption(
          '5ランを ' +
            s.onTape1 +
            '・' +
            s.onTape2 +
            ' に分けてテープ1・テープ2へ配置（テープ3は空・点線枠）'
        );
      } else if (s.kind === 'pass_start') {
        api.setCaption(
          'ポリフェーズ併合パス ' +
            s.passNo +
            ': ' +
            tapeCaption(s.tapes) +
            '（' +
            roleCaption({ outputSlot: s.outputSlot, inputSlots: s.inputSlots }) +
            '）'
        );
      } else if (s.kind === 'merge_start') {
        api.setCaption(
          tapeDisplayName(s.inputSlots[0]) +
            '・' +
            tapeDisplayName(s.inputSlots[1]) +
            'の先頭ランを併合し、' +
            tapeDisplayName(s.outputSlot) +
            'へ書き込みます'
        );
      } else if (s.kind === 'merge_compare') {
        if (s.remainder === 'left') {
          api.setCaption(
            '左ランの残り先頭 ' + s.merge.leftRemain[0] + ' を比較・書き込み'
          );
        } else if (s.remainder === 'right') {
          api.setCaption(
            '右ランの残り先頭 ' + s.merge.rightRemain[0] + ' を比較・書き込み'
          );
        } else {
          api.setCaption(
            '先頭要素 ' +
              s.leftHead +
              ' と ' +
              s.rightHead +
              ' を比較 → ' +
              (s.pickLeft ? s.leftHead : s.rightHead) +
              ' を書き込み'
          );
        }
      } else if (s.kind === 'merge_write') {
        api.setCaption(
          '値 ' +
            s.writeValue +
            ' を' +
            tapeDisplayName(s.outputSlot) +
            'へ書き込み'
        );
      } else if (s.kind === 'merge_done') {
        api.setCaption(
          '併合完了: 新しい1ラン（' +
            s.mergedRun.length +
            ' 要素）を' +
            tapeDisplayName(s.outputSlot) +
            'へ追加' +
            (s.consumedDummy ? '（ダミーランは消滅）' : '')
        );
      } else if (s.kind === 'pass_merge') {
        api.setCaption('パス内併合後: ' + tapeCaption(s.tapes));
      } else if (s.kind === 'rotate') {
        api.setCaption(
          '出力先を' +
            tapeDisplayName(s.outputSlot) +
            'に切り替え（' +
            roleCaption({ outputSlot: s.outputSlot, inputSlots: s.inputSlots }) +
            '）。各テープ列のランはその列に留まります'
        );
      } else if (s.kind === 'done') {
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="polyphase-merge-sort-demo"
  data_prefix="polyphase-merge"
  script=sort_demo_js
%}

テープドライブが高価だった時代のポリフェーズマージは、限られた I/O チャネルを稼働させ続ける典型例として学ぶ価値がある。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000005 |        0.000084 |            1674 |            1680 |
|        512 |        0.000012 |        0.000105 |            1690 |            1696 |
|       1024 |        0.000025 |        0.000778 |            1714 |            1720 |
|       2048 |        0.000056 |        0.000471 |            1777 |            1784 |
|       4096 |        0.000119 |        0.000597 |            1866 |            1872 |
|       8192 |        0.000285 |        0.000756 |            2047 |            2048 |
|      16384 |        0.000581 |        0.001235 |            2431 |            2432 |
|      32768 |        0.001276 |        0.001561 |            3199 |            3200 |
|      65536 |        0.004290 |        0.019015 |            4680 |            4684 |
|     131072 |        0.009340 |        0.038067 |            7738 |            7744 |
|     262144 |        0.022799 |        0.065756 |           12457 |           12460 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="polyphase_merge" %}
