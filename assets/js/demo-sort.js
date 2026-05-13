/**
 * Sort bar demos: animation helpers, toolbar query, role markers, and shared
 * playback wiring. Depends on nothing; attaches DemoSort to window.
 * Swap animations honor prefers-reduced-motion: reduce (instant DOM reorder).
 *
 * DemoSort.boot(rootId, fn)
 * DemoSort.clearRoles(container)
 * DemoSort.assignRoles(container, pairs, opts?)
 * DemoSort.queryToolbar(root, dataAttr, extraRoles?)
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
    if (!values.length) return;
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
    if (!pairs) return;
    for (let i = 0; i < pairs.length; i++) {
      const idx = pairs[i][0];
      if (idx == null) continue;
      const node = nodes[idx];
      if (node) node.setAttribute('data-role', pairs[i][1]);
    }
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
   * @param {string[]} [extraRoles] Additional button roles (e.g. ['sorted']).
   */
  DemoSort.queryToolbar = function (root, dataAttr, extraRoles) {
    function sel(role) {
      return '[' + dataAttr + '="' + role + '"]';
    }
    const ui = {
      bars: root.querySelector(sel('bars')),
      caption: root.querySelector(sel('caption')),
      shuffle: root.querySelector(sel('shuffle')),
      play: root.querySelector(sel('play')),
      pause: root.querySelector(sel('pause')),
      step: root.querySelector(sel('step')),
    };
    const roles = extraRoles || [];
    for (let i = 0; i < roles.length; i++) {
      ui[roles[i]] = root.querySelector(sel(roles[i]));
    }
    return ui;
  };

  /**
   * Wires shuffle / play / pause / step and owns playback state.
   *
   * Provide either `generateSteps` (+ optional `prepareValues`, `afterRebuild`) or a full `rebuild`.
   *
   * @param {object} o
   * @param {HTMLElement} o.root
   * @param {string} o.dataAttr
   * @param {string[]} [o.extraRoles]
   * @param {number[]} o.initialValues
   * @param {string} o.initialCaption
   * @param {string} [o.barClass] Used by default mountBars helper on api.
   * @param {function(number[]):object[]} [o.generateSteps]
   * @param {function(api, newValues):void} [o.rebuild] Overrides default rebuild body (still resets cancelled/playing/busy).
   * @param {function(number[]):number[]} [o.prepareValues]
   * @param {function(api):void} [o.afterRebuild] After default rebuild (e.g. clear roles).
   * @param {function(api,step):Promise<void>} o.applyStep Called after consuming step (idx already advanced).
   * @param {number|function(api):number} [o.stepPauseMs=280]
   * @param {function({playing:boolean,busy:boolean}):boolean} [o.shuffleWhen] Return true if shuffle allowed.
   * @param {function(ui,state):void} [o.onSyncButtons] state = { playing, busy, atEnd, idx, steps }
   * @param {function(api,Error):void} [o.onStepError]
   * @param {object<string,function(api):void>} [o.extraBindings] Click handlers keyed by extra toolbar role.
   */
  DemoSort.attachPlayback = function (o) {
    if (!o || !o.root || !o.dataAttr) return;
    if (!o.rebuild && typeof o.generateSteps !== 'function') return;

    const ui = DemoSort.queryToolbar(o.root, o.dataAttr, o.extraRoles);
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
      values = o.prepareValues ? o.prepareValues(v) : v;
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
      if (o.onSyncButtons) {
        o.onSyncButtons(ui, {
          playing: playing,
          busy: busy,
          atEnd: atEnd,
          idx: idx,
          steps: steps,
        });
      }
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

    if (o.extraBindings) {
      Object.keys(o.extraBindings).forEach(function (key) {
        const btn = ui[key];
        const fn = o.extraBindings[key];
        if (btn && typeof fn === 'function') {
          btn.addEventListener('click', function () {
            fn(api);
          });
        }
      });
    }

    rebuild(values);
  };

  global.DemoSort = DemoSort;
})(typeof window !== 'undefined' ? window : this);
