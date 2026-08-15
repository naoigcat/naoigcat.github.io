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
 * DemoSort.createBinaryTreeView(root, options?)
 * DemoSort.renderBinaryTree(view, tree, options?)
 * DemoSort.renderForest(view, roots, options?) — multiway tree forest (e.g. binomial heap)
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
    // Only the position prefix differs from the simple label, so keep the role
    // vocabulary in one place.
    return '位置' + index + '、' + DemoSort.barAccessibilityLabelSimple(valueText, role);
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

  function treeNodeLabel(node, options) {
    if (options && typeof options.nodeLabel === 'function') {
      return String(options.nodeLabel(node));
    }
    return node.value == null ? '' : String(node.value);
  }

  function svgElement(name) {
    return document.createElementNS('http://www.w3.org/2000/svg', name);
  }

  /**
   * Adds a compact binary-tree view below a demo's bars.
   * The returned canvas is deliberately separate from the bars so articles can
   * keep their array animation while exposing the structure that drives it.
   *
   * @param {HTMLElement} root
   * @param {object} [options]
   * @param {string} [options.label]
   * @param {string} [options.emptyText]
   * @returns {HTMLElement|null}
   */
  DemoSort.createBinaryTreeView = function (root, options) {
    if (!root || typeof document === 'undefined') return null;
    const config = options || {};
    const section = document.createElement('section');
    section.className = 'sort-demo__tree';

    const label = document.createElement('p');
    label.className = 'sort-demo__tree-label';
    label.textContent = config.label || '現在の二分木';

    const canvas = document.createElement('div');
    canvas.className = 'sort-demo__tree-canvas';
    canvas.dataset.emptyText = config.emptyText || 'まだ木は空です';
    canvas.setAttribute('role', 'img');

    section.appendChild(label);
    section.appendChild(canvas);

    const bars = root.querySelector('.sort-demo__bars');
    if (bars && bars.parentNode) {
      bars.parentNode.insertBefore(section, bars.nextSibling);
    } else {
      root.appendChild(section);
    }
    return canvas;
  };

  /**
   * Renders a binary tree snapshot. Nodes require `value`, `left`, and `right`;
   * `id` is optional but enables a stable active-node highlight.
   *
   * @param {HTMLElement|null} view
   * @param {object|null} tree
   * @param {object} [options]
   * @param {string|number} [options.activeId]
   * @param {string|number} [options.rootId]
   * @param {string} [options.ariaLabel]
   * @param {function(object):string} [options.nodeLabel]
   */
  DemoSort.renderBinaryTree = function (view, tree, options) {
    if (!view || typeof document === 'undefined') return;
    const config = options || {};
    const ariaLabel = config.ariaLabel || '二分木';
    view.innerHTML = '';

    if (!tree) {
      view.classList.add('sort-demo__tree-canvas--empty');
      const empty = document.createElement('span');
      empty.className = 'sort-demo__tree-empty';
      empty.textContent = view.dataset.emptyText || 'まだ木は空です';
      view.appendChild(empty);
      view.setAttribute('aria-label', ariaLabel + '。まだ木は空です。');
      return;
    }

    view.classList.remove('sort-demo__tree-canvas--empty');
    const entries = [];
    const positions = new Map();
    let nextOrder = 0;
    let maxDepth = 0;

    function visit(node, depth) {
      if (!node) return;
      visit(node.left, depth + 1);
      const entry = { node: node, depth: depth, order: nextOrder++ };
      entries.push(entry);
      positions.set(node, entry);
      if (depth > maxDepth) maxDepth = depth;
      visit(node.right, depth + 1);
    }

    visit(tree, 0);
    const width = Math.max(220, entries.length * 54 + 32);
    const height = Math.max(82, (maxDepth + 1) * 58 + 28);
    const svg = svgElement('svg');
    svg.classList.add('sort-demo__tree-svg');
    svg.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
    svg.setAttribute('width', String(width));
    svg.setAttribute('height', String(height));
    svg.setAttribute('aria-hidden', 'true');

    function position(entry) {
      return { x: 28 + entry.order * 54, y: 28 + entry.depth * 58 };
    }

    entries.forEach(function (entry) {
      const from = position(entry);
      [entry.node.left, entry.node.right].forEach(function (child) {
        const childEntry = positions.get(child);
        if (!childEntry) return;
        const to = position(childEntry);
        const edge = svgElement('line');
        edge.classList.add('sort-demo__tree-edge');
        edge.setAttribute('x1', String(from.x));
        edge.setAttribute('y1', String(from.y + 16));
        edge.setAttribute('x2', String(to.x));
        edge.setAttribute('y2', String(to.y - 16));
        svg.appendChild(edge);
      });
    });

    entries.forEach(function (entry) {
      const point = position(entry);
      const node = svgElement('g');
      const id = entry.node.id;
      const isActive =
        config.activeId != null && String(id) === String(config.activeId);
      const isRoot =
        entry.node === tree ||
        (config.rootId != null && String(id) === String(config.rootId));
      node.setAttribute(
        'class',
        'sort-demo__tree-node' +
          (isRoot ? ' sort-demo__tree-node--root' : '') +
          (isActive ? ' sort-demo__tree-node--active' : '')
      );

      const circle = svgElement('circle');
      circle.setAttribute('cx', String(point.x));
      circle.setAttribute('cy', String(point.y));
      circle.setAttribute('r', '17');

      const text = svgElement('text');
      text.setAttribute('x', String(point.x));
      text.setAttribute('y', String(point.y));
      text.setAttribute('text-anchor', 'middle');
      text.setAttribute('dy', '.35em');
      text.textContent = treeNodeLabel(entry.node, config);

      node.appendChild(circle);
      node.appendChild(text);
      svg.appendChild(node);
    });

    const values = entries
      .map(function (entry) {
        return treeNodeLabel(entry.node, config);
      })
      .join('、');
    view.setAttribute(
      'aria-label',
      ariaLabel +
        '。根は ' +
        treeNodeLabel(tree, config) +
        '。ノードは ' +
        values +
        '。'
    );
    view.appendChild(svg);
  };

  /**
   * Renders a forest of multiway trees. Each root is
   * `{ value, id?, children?: same[] }`. Roots are drawn left to right.
   *
   * @param {HTMLElement|null} view
   * @param {Array<object>|null} roots
   * @param {object} [options]
   * @param {string|number} [options.activeId]
   * @param {string} [options.ariaLabel]
   * @param {function(object):string} [options.nodeLabel]
   */
  DemoSort.renderForest = function (view, roots, options) {
    if (!view || typeof document === 'undefined') return;
    const config = options || {};
    const ariaLabel = config.ariaLabel || '森';
    view.innerHTML = '';

    if (!roots || !roots.length) {
      view.classList.add('sort-demo__tree-canvas--empty');
      const empty = document.createElement('span');
      empty.className = 'sort-demo__tree-empty';
      empty.textContent = view.dataset.emptyText || 'まだ木は空です';
      view.appendChild(empty);
      view.setAttribute('aria-label', ariaLabel + '。まだ木は空です。');
      return;
    }

    view.classList.remove('sort-demo__tree-canvas--empty');

    const gapUnits = 1.15;
    const unit = 54;
    const positions = new Map();
    let maxDepth = 0;
    const allNodes = [];

    function measure(node) {
      if (!node) return 0;
      const kids = node.children || [];
      if (!kids.length) return 1;
      let w = 0;
      for (let i = 0; i < kids.length; i++) {
        w += measure(kids[i]);
      }
      return Math.max(1, w);
    }

    function place(node, depth, left, isForestRoot) {
      if (!node) return;
      allNodes.push(node);
      if (depth > maxDepth) maxDepth = depth;
      const kids = node.children || [];
      if (!kids.length) {
        positions.set(node, {
          x: left + 0.5,
          depth: depth,
          isForestRoot: !!isForestRoot,
        });
        return;
      }
      let x = left;
      for (let i = 0; i < kids.length; i++) {
        const cw = measure(kids[i]);
        place(kids[i], depth + 1, x, false);
        x += cw;
      }
      const first = positions.get(kids[0]);
      const last = positions.get(kids[kids.length - 1]);
      positions.set(node, {
        x: (first.x + last.x) / 2,
        depth: depth,
        isForestRoot: !!isForestRoot,
      });
    }

    let cursor = 0;
    for (let r = 0; r < roots.length; r++) {
      const width = measure(roots[r]);
      place(roots[r], 0, cursor, true);
      cursor += width + gapUnits;
    }

    const widthPx = Math.max(220, cursor * unit + 32);
    const heightPx = Math.max(82, (maxDepth + 1) * 58 + 28);
    const svg = svgElement('svg');
    svg.classList.add('sort-demo__tree-svg');
    svg.setAttribute('viewBox', '0 0 ' + widthPx + ' ' + heightPx);
    svg.setAttribute('width', String(widthPx));
    svg.setAttribute('height', String(heightPx));
    svg.setAttribute('aria-hidden', 'true');

    function pointOf(node) {
      const entry = positions.get(node);
      return { x: 28 + entry.x * unit, y: 28 + entry.depth * 58 };
    }

    allNodes.forEach(function (node) {
      const kids = node.children || [];
      const from = pointOf(node);
      for (let i = 0; i < kids.length; i++) {
        const to = pointOf(kids[i]);
        const edge = svgElement('line');
        edge.classList.add('sort-demo__tree-edge');
        edge.setAttribute('x1', String(from.x));
        edge.setAttribute('y1', String(from.y + 16));
        edge.setAttribute('x2', String(to.x));
        edge.setAttribute('y2', String(to.y - 16));
        svg.appendChild(edge);
      }
    });

    allNodes.forEach(function (node) {
      const point = pointOf(node);
      const entry = positions.get(node);
      const g = svgElement('g');
      const id = node.id;
      const isActive =
        config.activeId != null && String(id) === String(config.activeId);
      g.setAttribute(
        'class',
        'sort-demo__tree-node' +
          (entry.isForestRoot ? ' sort-demo__tree-node--root' : '') +
          (isActive ? ' sort-demo__tree-node--active' : '')
      );

      const circle = svgElement('circle');
      circle.setAttribute('cx', String(point.x));
      circle.setAttribute('cy', String(point.y));
      circle.setAttribute('r', '17');

      const text = svgElement('text');
      text.setAttribute('x', String(point.x));
      text.setAttribute('y', String(point.y));
      text.setAttribute('text-anchor', 'middle');
      text.setAttribute('dy', '.35em');
      text.textContent = treeNodeLabel(node, config);

      g.appendChild(circle);
      g.appendChild(text);
      svg.appendChild(g);
    });

    const labels = roots
      .map(function (node) {
        return treeNodeLabel(node, config);
      })
      .join('、');
    view.setAttribute(
      'aria-label',
      ariaLabel + '。根は左から ' + labels + '。'
    );
    view.appendChild(svg);
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

  /**
   * Swaps the children at lo and lo + 1 with the same FLIP animation as
   * flipSwap. An adjacent swap is just a special case of flipSwap, so the
   * implementation is delegated to keep a single animation code path; the
   * name is kept because many articles call it directly.
   *
   * @param {HTMLElement} container
   * @param {number} lo
   * @returns {Promise<void>}
   */
  DemoSort.flipAdjacentSwap = function (container, lo) {
    return DemoSort.flipSwap(container, lo, lo + 1);
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
      // Reduced-motion path: DOM の並び替えだけを行う。data-role 属性は
      // ノードと一緒に移動するため、呼び出し側で role を残したい場合
      // （例: heap sort の preserve: ['sorted']）も正しい子に追従し、追加
      // 処理は不要。将来このブランチに別ステップを足す際は、role の付け直し
      // タイミングが通常パスと噛み合うか必ず確認すること。
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

  DemoSort.copyText = async function (text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }

    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.setAttribute('readonly', '');
    textarea.style.position = 'fixed';
    textarea.style.top = '-9999px';
    document.body.appendChild(textarea);
    textarea.select();
    // execCommand reports failure by returning false rather than throwing, so
    // callers would otherwise announce a copy that never happened.
    const copied = document.execCommand('copy');
    document.body.removeChild(textarea);
    if (!copied) throw new Error('copy command was rejected');
  };

  DemoSort.attachBenchmarkCopyButtons = function () {
    const buttons = document.querySelectorAll('[data-sort-benchmark-copy]');
    buttons.forEach(function (button) {
      const container = button.closest('[data-sort-benchmark-code]');
      const code = container && container.querySelector('pre code');
      if (!code) return;

      button.addEventListener('click', async function () {
        const originalText = button.textContent;
        button.disabled = true;
        try {
          await DemoSort.copyText(code.textContent);
          button.textContent = 'コピー済み';
        } catch (_err) {
          button.textContent = 'コピー失敗';
        } finally {
          setTimeout(function () {
            button.textContent = originalText;
            button.disabled = false;
          }, 1600);
        }
      });
    });
  };

  if (typeof document !== 'undefined') {
    document.addEventListener('DOMContentLoaded', function () {
      DemoSort.attachBenchmarkCopyButtons();
    });
  }

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
   * @param {function(api, newValues):void} [o.rebuild] Overrides default rebuild body (still resets playGeneration/playing/busy).
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
    let playGeneration = 0;
    let busy = false;

    // Demos reach the animation and shuffle helpers through DemoSort directly,
    // so `api` only carries what a step callback cannot get on its own.
    const api = {
      barsEl: barsEl,
      mountBars: function (container, vals) {
        DemoSort.mountBars(container, vals, barClass);
      },
      setCaption: function (t) {
        capEl.textContent = t;
      },
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
      playGeneration++;
      playing = false;
      busy = false;
      if (o.rebuild) {
        o.rebuild(api, v);
      } else {
        defaultRebuild(v);
      }
      syncButtons();
    }

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
      const generation = ++playGeneration;
      playing = true;
      syncButtons();
      while (playGeneration === generation && idx < steps.length) {
        await applyStepForward();
        if (playGeneration !== generation) break;
        let ms =
          typeof o.stepPauseMs === 'function'
            ? o.stepPauseMs(api)
            : o.stepPauseMs;
        if (ms == null) ms = 280;
        await DemoSort.wait(ms);
      }
      if (playGeneration === generation) {
        playing = false;
        syncButtons();
      }
    });

    ui.pause.addEventListener('click', function () {
      playGeneration++;
      playing = false;
      syncButtons();
    });

    rebuild(values);
  };

  global.DemoSort = DemoSort;
})(typeof window !== 'undefined' ? window : this);
