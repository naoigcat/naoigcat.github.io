/**
 * Sort bar demos: animation helpers, toolbar query, role markers, and shared
 * playback wiring. Depends on nothing; attaches DemoSort to window.
 * Swap animations honor prefers-reduced-motion: reduce (instant DOM reorder).
 *
 * DemoSort.boot(rootId, fn)
 * DemoSort.clearRoles(container) — updates bar aria-labels after clearing roles
 * DemoSort.assignRoles(container, pairs, opts?) — updates bar aria-labels after roles change
 * DemoSort.barAccessibilityLabel(index, valueText, role?)
 * DemoSort.barAccessibilityLabelSimple(valueText, role?)
 * DemoSort.syncBarsAccessibility(container)
 * DemoSort.queryToolbar(root, dataAttr)
 * DemoSort.attachPlayback(options) — see implementation for option shape.
 */
(function (global) {
  'use strict';

  /** @returns {boolean} */
  function prefersReducedMotion() {
    if (typeof window === 'undefined' || !window.matchMedia) return false;
    try {
      return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    } catch (_e) {
      return false;
    }
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

  const DemoSort = {};

  /** Japanese phrases for `data-role` on bars (exposed to assistive tech). */
  const BAR_ROLE_LABEL_JA = {
    compare: '比較対象',
    swap: '交換対象',
    pivot: 'ピボット',
    sorted: '整列済み',
    cursor: 'カーソル',
    insert: '挿入',
    key: '挿入キー',
    range: '対象範囲',
    write: '確定の書き込み',
    gap: '空きマス',
    heap: 'ヒープ化の対象',
  };

  /**
   * Accessible name for one bar in a left-to-right array (0-based index).
   * @param {number} index
   * @param {string} valueText numeric value as string, or title text
   * @param {string|null} role `data-role` token or null
   */
  DemoSort.barAccessibilityLabel = function (index, valueText, role) {
    const parts = ['位置' + index];
    if (role === 'gap') {
      parts.push(BAR_ROLE_LABEL_JA.gap);
    } else {
      parts.push('値 ' + valueText);
    }
    if (role && role !== 'gap') {
      const ja = BAR_ROLE_LABEL_JA[role];
      if (ja) parts.push(ja);
    }
    return parts.join('、');
  };

  /**
   * Label for a bar outside a simple linear list (e.g. patience piles).
   * @param {string} valueText
   * @param {string|null} role
   */
  DemoSort.barAccessibilityLabelSimple = function (valueText, role) {
    const parts = [];
    if (role === 'gap') {
      parts.push(BAR_ROLE_LABEL_JA.gap);
    } else {
      parts.push('値 ' + valueText);
    }
    if (role && role !== 'gap') {
      const ja = BAR_ROLE_LABEL_JA[role];
      if (ja) parts.push(ja);
    }
    return parts.join('、');
  };

  /**
   * Updates listitem roles and aria-label on each direct child bar of `container`.
   * Skips nodes without `title` that are not `.sort-demo__bar` (e.g. patience layout wrapper).
   *
   * @param {HTMLElement} container
   */
  DemoSort.syncBarsAccessibility = function (container) {
    if (!container) return;
    const nodes = container.children;
    for (let i = 0; i < nodes.length; i++) {
      const el = nodes[i];
      const title = el.getAttribute('title');
      const isBar = el.classList && el.classList.contains('sort-demo__bar');
      if (title == null && !isBar) continue;
      const role = el.getAttribute('data-role');
      const valueText = title != null ? title : '';
      el.setAttribute('role', 'listitem');
      el.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(i, valueText, role)
      );
    }
  };

  DemoSort.wait = function (ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  };

  DemoSort.transitionPromise = transitionPromise;

  DemoSort.swapDomIndices = function (parent, i, j) {
    if (i === j) return;
    const el1 = parent.children[i];
    const el2 = parent.children[j];
    const marker = document.createTextNode('');
    parent.insertBefore(marker, el1);
    parent.insertBefore(el1, el2.nextSibling);
    parent.insertBefore(el2, marker);
    parent.removeChild(marker);
  };

  DemoSort.mountBars = function (container, values, barClass) {
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      'ソート対象の配列。棒の高さは値の大小、左から右へ位置0、1の順です。'
    );
    const max = Math.max.apply(null, values);
    const min = Math.min.apply(null, values);
    const span = Math.max(max - min, 1);
    values.forEach(function (v) {
      const bar = document.createElement('div');
      bar.className = barClass;
      const h = 28 + ((v - min) / span) * 92;
      bar.style.height = h + 'px';
      bar.setAttribute('title', String(v));
      container.appendChild(bar);
    });
    DemoSort.syncBarsAccessibility(container);
  };

  DemoSort.shuffleCopy = function (arr) {
    const copy = arr.slice();
    for (let i = copy.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const t = copy[i];
      copy[i] = copy[j];
      copy[j] = t;
    }
    return copy;
  };

  DemoSort.flipAdjacentSwap = async function (container, lo) {
    const children = container.children;
    const first = children[lo];
    const second = children[lo + 1];
    if (!first || !second) return;

    if (prefersReducedMotion()) {
      // Reduced-motion path: DOM の並び替えだけを行い、要素自身の
      // data-role 属性はノードと一緒に移動する。呼び出し側で role を
      // 残したい場合（例: heap sort の preserve: ['sorted']）は正しい
      // 子に追従するため追加処理は不要だが、将来このブランチに「即時
      // ステップを追加する」変更を入れる際は、role の付け直しタイミング
      // が通常パスと噛み合うか必ず確認すること。
      container.insertBefore(second, first);
      return;
    }

    const b1 = first.getBoundingClientRect();
    const b2 = second.getBoundingClientRect();

    container.insertBefore(second, first);

    const a1 = first.getBoundingClientRect();
    const a2 = second.getBoundingClientRect();

    const dx1 = b1.left - a1.left;
    const dx2 = b2.left - a2.left;
    first.style.transition = 'none';
    second.style.transition = 'none';
    first.style.transform = 'translateX(' + dx1 + 'px)';
    second.style.transform = 'translateX(' + dx2 + 'px)';

    await new Promise(function (r) {
      requestAnimationFrame(function () {
        requestAnimationFrame(r);
      });
    });

    const dur = '0.32s';
    first.style.transition = 'transform ' + dur + ' ease';
    second.style.transition = 'transform ' + dur + ' ease';
    first.style.transform = '';
    second.style.transform = '';

    await Promise.all([
      transitionPromise(first),
      transitionPromise(second),
    ]);

    first.style.transition = '';
    second.style.transition = '';
    first.style.transform = '';
    second.style.transform = '';
  };

  DemoSort.flipSwap = async function (container, i, j) {
    if (i === j) return;
    if (i > j) {
      const tmp = i;
      i = j;
      j = tmp;
    }
    const elI = container.children[i];
    const elJ = container.children[j];
    if (!elI || !elJ) return;

    if (prefersReducedMotion()) {
      // Reduced-motion path: data-role の扱いは flipAdjacentSwap と同じ
      // 前提（属性はノードと共に移動する）に依存する。将来このブランチに
      // 別ステップを足す場合は role の付け直しタイミングに注意。
      DemoSort.swapDomIndices(container, i, j);
      return;
    }

    const bI = elI.getBoundingClientRect();
    const bJ = elJ.getBoundingClientRect();

    DemoSort.swapDomIndices(container, i, j);

    const aI = elI.getBoundingClientRect();
    const aJ = elJ.getBoundingClientRect();

    const dxI = bI.left - aI.left;
    const dxJ = bJ.left - aJ.left;
    elI.style.transition = 'none';
    elJ.style.transition = 'none';
    elI.style.transform = 'translateX(' + dxI + 'px)';
    elJ.style.transform = 'translateX(' + dxJ + 'px)';

    await new Promise(function (r) {
      requestAnimationFrame(function () {
        requestAnimationFrame(r);
      });
    });

    const dur = '0.32s';
    elI.style.transition = 'transform ' + dur + ' ease';
    elJ.style.transition = 'transform ' + dur + ' ease';
    elI.style.transform = '';
    elJ.style.transform = '';

    await Promise.all([
      transitionPromise(elI),
      transitionPromise(elJ),
    ]);

    elI.style.transition = '';
    elJ.style.transition = '';
    elI.style.transform = '';
    elJ.style.transform = '';
  };

  /**
   * Removes data-role from every immediate child of container.
   * @param {HTMLElement} container
   */
  DemoSort.clearRoles = function (container) {
    if (!container) return;
    const nodes = container.children;
    for (let i = 0; i < nodes.length; i++) {
      nodes[i].removeAttribute('data-role');
    }
    DemoSort.syncBarsAccessibility(container);
  };

  /**
   * Clears existing data-role attributes (optionally preserving some), then
   * applies a list of [index, role] assignments to immediate children.
   *
   * @param {HTMLElement} container
   * @param {Array<[number, string]>} [pairs] Indices to mark; entries with a null index are skipped.
   * @param {object} [opts]
   * @param {string[]} [opts.preserve] Existing role values to keep (e.g. ['sorted']).
   */
  DemoSort.assignRoles = function (container, pairs, opts) {
    if (!container) return;
    const options = opts || {};
    const preserve = options.preserve;
    const nodes = container.children;
    for (let i = 0; i < nodes.length; i++) {
      const current = nodes[i].getAttribute('data-role');
      if (current == null) continue;
      if (!preserve || preserve.indexOf(current) === -1) {
        nodes[i].removeAttribute('data-role');
      }
    }
    if (!pairs) {
      DemoSort.syncBarsAccessibility(container);
      return;
    }
    for (let i = 0; i < pairs.length; i++) {
      const idx = pairs[i][0];
      if (idx == null) continue;
      const node = nodes[idx];
      if (node) node.setAttribute('data-role', pairs[i][1]);
    }
    DemoSort.syncBarsAccessibility(container);
  };

  /**
   * Boots a demo by id once DemoSort is ready.
   * Returns silently if the root element does not exist or attachPlayback is missing.
   *
   * @param {string} rootId
   * @param {function(HTMLElement):void} fn
   */
  DemoSort.boot = function (rootId, fn) {
    if (typeof document === 'undefined') return;
    if (typeof DemoSort.attachPlayback !== 'function') return;
    const root = document.getElementById(rootId);
    if (!root) return;
    fn(root);
  };

  /**
   * @param {HTMLElement} root
   * @param {string} dataAttr Full attribute name (e.g. 'data-bs').
   */
  DemoSort.queryToolbar = function (root, dataAttr) {
    function sel(role) {
      return '[' + dataAttr + '="' + role + '"]';
    }
    return {
      bars: root.querySelector(sel('bars')),
      caption: root.querySelector(sel('caption')),
      shuffle: root.querySelector(sel('shuffle')),
      play: root.querySelector(sel('play')),
      pause: root.querySelector(sel('pause')),
      step: root.querySelector(sel('step')),
    };
  };

  /**
   * Wires shuffle / play / pause / step and owns playback state.
   *
   * Provide either `generateSteps` (+ optional `afterRebuild`) or a full `rebuild`.
   *
   * @param {object} o
   * @param {HTMLElement} o.root
   * @param {string} o.dataAttr
   * @param {number[]} o.initialValues
   * @param {string} o.initialCaption
   * @param {string} [o.barClass] Used by default mountBars helper on api.
   * @param {function(number[]):object[]} [o.generateSteps]
   * @param {function(api, newValues):void} [o.rebuild] Overrides default rebuild body (still resets cancelled/playing/busy).
   * @param {function(api):void} [o.afterRebuild] After default rebuild (e.g. clear roles).
   * @param {function(api,step):Promise<void>} o.applyStep Called after consuming step (idx already advanced).
   * @param {number|function(api):number} [o.stepPauseMs=280]
   * @param {function({playing:boolean,busy:boolean}):boolean} [o.shuffleWhen] Return true if shuffle allowed.
   * @param {function(api,Error):void} [o.onStepError]
   */
  DemoSort.attachPlayback = function (o) {
    if (!o || !o.root || !o.dataAttr) return;
    if (!o.rebuild && typeof o.generateSteps !== 'function') return;

    const ui = DemoSort.queryToolbar(o.root, o.dataAttr);
    const barsEl = ui.bars;
    const capEl = ui.caption;
    if (!barsEl || !capEl || !ui.shuffle || !ui.play || !ui.pause || !ui.step) {
      return;
    }

    const barClass = o.barClass || '';

    let values = (o.initialValues || []).slice();
    let steps = [];
    let idx = 0;
    let playing = false;
    let cancelled = false;
    let busy = false;

    const api = {
      ui: ui,
      barsEl: barsEl,
      mountBars: function (container, vals) {
        DemoSort.mountBars(container, vals, barClass);
      },
      setCaption: function (t) {
        capEl.textContent = t;
      },
      wait: DemoSort.wait,
      shuffleCopy: DemoSort.shuffleCopy,
      flipSwap: DemoSort.flipSwap,
      flipAdjacentSwap: DemoSort.flipAdjacentSwap,
      rebuild: function () {},
      applyStepForward: function () {},
    };

    Object.defineProperty(api, 'values', {
      get: function () {
        return values;
      },
      set: function (v) {
        values = v;
      },
      enumerable: true,
    });
    Object.defineProperty(api, 'steps', {
      get: function () {
        return steps;
      },
      set: function (s) {
        steps = s;
      },
      enumerable: true,
    });
    Object.defineProperty(api, 'idx', {
      get: function () {
        return idx;
      },
      set: function (i) {
        idx = i;
      },
      enumerable: true,
    });

    function defaultRebuild(v) {
      values = v;
      steps = o.generateSteps(values);
      idx = 0;
      api.mountBars(barsEl, steps[0] ? steps[0].arr : values);
      api.setCaption(o.initialCaption);
      if (o.afterRebuild) o.afterRebuild(api);
    }

    function syncButtons() {
      const atEnd = idx >= steps.length;
      ui.play.disabled = playing || atEnd || busy;
      ui.pause.disabled = !playing;
      ui.step.disabled = playing || atEnd || busy;
      const shuffleOk =
        o.shuffleWhen != null
          ? o.shuffleWhen({ playing: playing, busy: busy })
          : !playing && !busy;
      ui.shuffle.disabled = !shuffleOk;
    }

    function rebuild(v) {
      cancelled = true;
      playing = false;
      busy = false;
      if (o.rebuild) {
        o.rebuild(api, v);
      } else {
        defaultRebuild(v);
      }
      syncButtons();
    }

    api.rebuild = rebuild;

    async function applyStepForward() {
      if (busy || idx >= steps.length) return;
      busy = true;
      syncButtons();
      try {
        const s = steps[idx];
        idx++;
        await o.applyStep(api, s);
      } catch (err) {
        if (o.onStepError) o.onStepError(api, err);
        else console.error(err);
      } finally {
        busy = false;
        syncButtons();
      }
    }

    api.applyStepForward = applyStepForward;

    ui.shuffle.addEventListener('click', function () {
      const st = { playing: playing, busy: busy };
      if (o.shuffleWhen != null && !o.shuffleWhen(st)) return;
      if (o.shuffleWhen == null && (playing || busy)) return;
      rebuild(DemoSort.shuffleCopy(values));
    });

    ui.step.addEventListener('click', function () {
      applyStepForward();
    });

    ui.play.addEventListener('click', async function () {
      playing = true;
      cancelled = false;
      syncButtons();
      while (!cancelled && idx < steps.length) {
        await applyStepForward();
        let ms =
          typeof o.stepPauseMs === 'function'
            ? o.stepPauseMs(api)
            : o.stepPauseMs;
        if (ms == null) ms = 280;
        await DemoSort.wait(ms);
      }
      playing = false;
      syncButtons();
    });

    ui.pause.addEventListener('click', function () {
      cancelled = true;
      playing = false;
      syncButtons();
    });

    rebuild(values);
  };

  global.DemoSort = DemoSort;
})(typeof window !== 'undefined' ? window : this);
