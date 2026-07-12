---
title:     バーストソートで配列を並び替える
date:      2026-07-12 23:59:19 +0900
tags:      sort
sort_demo: true
---

## バーストソートを使用する

バーストソート (`burstsort`) は、キャッシュ効率を意識した文字列整列向けのアルゴリズムである。共通接頭辞をトライ木で管理し、まだ細分化していない末尾部分をバケットへ集める。バケットが閾値を超えたら「バースト」して下位桁へトライを伸ばし、小さなバケットだけ挿入ソートなどで仕上げる。

本記事では整数キーを十進桁ごとに扱う簡略版を示す。[トライソート](/2026/07/11/sort-trie.html)と同様に MSD（最上位桁優先）の区分付けだが、最初から木全体を構築するのではなく、バケットが膨らんだときだけ子ノードへ展開する点が異なる。

1.  **バケットへの挿入**: 各要素を根のバケットへ追加する。ノードがすでにトライ化していれば、現行桁 `d = (x / exp) % 10` に従い子へ降り、`exp` を 10 で割って繰り返す。
2.  **バースト**: 葉バケットの要素数が閾値 `B`（ここでは 16、デモでは 4）を超え、かつ `exp > 0` なら、バケット内の全要素を現行桁で 10 分割し子ノードへ再配分する。
3.  **葉の整列**: これ以上桁を分けられないノード（`exp = 0`）や、閾値以下に収まったバケットは挿入ソートで昇順にする。
4.  **収集**: 子 `0..9` の順に深さ優先走査し、整列済みバケットを左から連結して出力する。

```pseudocode
procedure burst_sort(A)
  if length(A) = 0 then return
  maxVal = maximum(A)
  exp = highest_digit_weight(maxVal)
  root = burst node with empty bucket
  for each x in A
    burst_insert(root, x, exp)
  out = empty list
  burst_collect(root, out)   // children 0..9, then sort each bucket
  A = out
```

桁数を `w` とすると挿入と収集はともに `O(n · w)` であり、補助記憶域は `O(n)` となる。葉バケットを挿入ソートで仕上げるため安定ソートである。

以下のデモでは 2 桁の整数 20 個の乱数を使い、閾値を 4 に固定している。「シャッフル」で別の並びに差し替えられます。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('burst-sort-demo', function (root) {
  const BURST_THRESHOLD = 4;
  const ARRAY_LEN = 20;
  let bucketBarWidthObserver;

  function randomTwoDigitArray(len) {
    const a = [];
    let i;
    for (i = 0; i < len; i++) {
      a.push(Math.floor(Math.random() * 90) + 10);
    }
    return a;
  }

  function demoValues() {
    return randomTwoDigitArray(ARRAY_LEN);
  }

  function valueScale(values) {
    if (!values.length) {
      return { min: 10, max: 99, span: 89 };
    }
    const min = Math.min.apply(null, values);
    const max = Math.max.apply(null, values);
    return { min: min, max: max, span: Math.max(max - min, 1) };
  }

  function applySlotGrid(container, count) {
    container.style.gridTemplateColumns =
      'repeat(' + count + ', minmax(0, 1fr))';
    container.style.gap = count > 15 ? '4px' : '6px';
    container.style.width = '100%';
  }

  function maxExp(maxVal) {
    let exp = 1;
    while (exp * 10 <= maxVal) {
      exp *= 10;
    }
    return exp;
  }

  function digitName(exp) {
    if (exp === 1) {
      return '1の位';
    }
    if (exp === 10) {
      return '10の位';
    }
    return '桁の重み ' + exp;
  }

  function makeBurstNode() {
    return { children: {}, bucket: [] };
  }

  function isTrie(node) {
    return Object.keys(node.children).length > 0;
  }

  function bucketLabel(key) {
    if (key === 'root') {
      return '根バケット';
    }
    if (key.indexOf('-') === -1) {
      return '10の位=' + key;
    }
    const dash = key.indexOf('-');
    return '10の位=' + key.slice(0, dash) + '・1の位=' + key.slice(dash + 1);
  }

  function pathToKey(path) {
    if (!path.length) {
      return 'root';
    }
    if (path.length === 1) {
      return String(path[0]);
    }
    return path[0] + '-' + path[1];
  }

  function makeEmptyState() {
    const state = { root: [] };
    let d;
    let e;
    for (d = 0; d < 10; d++) {
      state[String(d)] = [];
      for (e = 0; e < 10; e++) {
        state[d + '-' + e] = [];
      }
    }
    return state;
  }

  function cloneState(state) {
    const copy = {};
    let k;
    for (k in state) {
      if (Object.prototype.hasOwnProperty.call(state, k)) {
        copy[k] = state[k].slice();
      }
    }
    return copy;
  }

  function bucketShortLabel(key) {
    if (key === 'root') {
      return '根';
    }
    if (key.indexOf('-') === -1) {
      return key;
    }
    const dash = key.indexOf('-');
    return key.slice(0, dash) + '\u00b7' + key.slice(dash + 1);
  }

  function bucketTier(key) {
    if (key === 'root') {
      return 'root';
    }
    if (key.indexOf('-') === -1) {
      return 'tens';
    }
    return 'ones';
  }

  function orderedBucketKeys(state) {
    const keys = [];
    if (state.root.length) {
      keys.push('root');
    }
    let d;
    for (d = 0; d < 10; d++) {
      const key = String(d);
      if (state[key].length) {
        keys.push(key);
      }
    }
    for (d = 0; d < 10; d++) {
      let e;
      for (e = 0; e < 10; e++) {
        const key = d + '-' + e;
        if (state[key].length) {
          keys.push(key);
        }
      }
    }
    return keys;
  }

  function buildInputSlots(fullArr, movedThroughIdx) {
    const slots = [];
    let i;
    for (i = 0; i < fullArr.length; i++) {
      if (i <= movedThroughIdx) {
        slots.push(null);
      } else {
        slots.push(fullArr[i]);
      }
    }
    return slots;
  }

  function buildOutputSlots(outArr, slotCount) {
    const slots = [];
    let i;
    for (i = 0; i < slotCount; i++) {
      slots.push(i < outArr.length ? outArr[i] : null);
    }
    return slots;
  }

  function scaledBarHeight(value, scale, compact) {
    const baseH = compact ? 12 : 28;
    const rangeH = compact ? 36 : 92;
    return baseH + ((value - scale.min) / scale.span) * rangeH + 'px';
  }

  function appendBarSlots(container, slots, scale, opts) {
    const options = opts || {};
    const compact = options.compact;
    container.innerHTML = '';
    container.setAttribute('role', 'list');
    container.setAttribute('aria-label', options.ariaLabel || '棒グラフ');
    let i;
    for (i = 0; i < slots.length; i++) {
      const v = slots[i];
      const stack = document.createElement('div');
      stack.className = 'sort-demo__bar-stack';
      stack.setAttribute('role', 'listitem');

      const label = document.createElement('span');
      label.className = 'sort-demo__bar-value';

      const bar = document.createElement('div');
      bar.className = 'sort-demo__bar';

      if (v == null) {
        stack.classList.add('sort-demo__bar-stack--empty');
        label.textContent = '\u00a0';
        bar.style.visibility = 'hidden';
        bar.style.height = '0px';
        stack.setAttribute(
          'aria-label',
          DemoSort.barAccessibilityLabel(i, '未配置', null)
        );
      } else {
        stack.setAttribute('title', String(v));
        label.textContent = String(v);
        bar.style.height = scaledBarHeight(v, scale, compact);
        stack.setAttribute(
          'aria-label',
          DemoSort.barAccessibilityLabel(i, String(v), null)
        );
      }

      stack.appendChild(label);
      stack.appendChild(bar);
      container.appendChild(stack);
    }
    DemoSort.clearRoles(container);
    if (options.allowHighlight !== false) {
      if (options.cursorSlot != null && options.cursorSlot >= 0) {
        DemoSort.assignRoles(container, [[options.cursorSlot, 'cursor']]);
      }
      if (options.writeSlot != null && options.writeSlot >= 0) {
        DemoSort.assignRoles(container, [[options.writeSlot, 'write']]);
      }
      if (options.highlightSlot != null && options.highlightSlot >= 0) {
        DemoSort.assignRoles(container, [
          [options.highlightSlot, options.highlightRole || 'swap'],
        ]);
      }
    }
  }

  function appendBucketBars(container, values, scale, opts) {
    const options = opts || {};
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }
    container.setAttribute('role', 'list');
    container.setAttribute('aria-label', options.ariaLabel || '棒グラフ');
    let i;
    for (i = 0; i < values.length; i++) {
      const v = values[i];
      const stack = document.createElement('div');
      stack.className = 'sort-demo__bar-stack';
      stack.setAttribute('role', 'listitem');

      const label = document.createElement('span');
      label.className = 'sort-demo__bar-value';

      const bar = document.createElement('div');
      bar.className = 'sort-demo__bar';

      stack.setAttribute('title', String(v));
      label.textContent = String(v);
      bar.style.height = scaledBarHeight(v, scale);
      stack.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(i, String(v), null)
      );

      stack.appendChild(label);
      stack.appendChild(bar);
      container.appendChild(stack);
    }
    DemoSort.clearRoles(container);
    if (options.allowHighlight !== false) {
      if (options.highlightIdx != null && options.highlightIdx >= 0) {
        DemoSort.assignRoles(container, [
          [options.highlightIdx, options.highlightRole || 'write'],
        ]);
      }
    }
  }

  function appendBars(container, values, scale, opts) {
    const options = opts || {};
    const compact = options.compact;
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }
    container.setAttribute('role', 'list');
    container.setAttribute('aria-label', options.ariaLabel || '棒グラフ');
    let i;
    for (i = 0; i < values.length; i++) {
      const v = values[i];
      const stack = document.createElement('div');
      stack.className = 'sort-demo__bar-stack';
      stack.setAttribute('role', 'listitem');
      stack.setAttribute('title', String(v));

      const label = document.createElement('span');
      label.className = 'sort-demo__bar-value';
      label.textContent = String(v);

      const bar = document.createElement('div');
      bar.className = 'sort-demo__bar';
      bar.style.height = scaledBarHeight(v, scale, compact);

      stack.appendChild(label);
      stack.appendChild(bar);
      container.appendChild(stack);
    }
    DemoSort.clearRoles(container);
    if (options.allowHighlight !== false) {
      if (options.cursorIdx != null && options.cursorIdx >= 0) {
        DemoSort.assignRoles(container, [[options.cursorIdx, 'cursor']]);
      }
      if (options.writeIdx != null && options.writeIdx >= 0) {
        DemoSort.assignRoles(container, [[options.writeIdx, 'write']]);
      }
      if (options.highlightIdx != null && options.highlightIdx >= 0) {
        DemoSort.assignRoles(container, [
          [options.highlightIdx, options.highlightRole || 'swap'],
        ]);
      }
    }
  }

  function matchBucketBarWidths(wrap, mainBars) {
    function setBucketBarWidth() {
      const sourceBar = mainBars.querySelector('.sort-demo__bar-stack');
      if (!sourceBar) {
        return;
      }
      wrap.style.setProperty(
        '--burst-bucket-bar-width',
        sourceBar.getBoundingClientRect().width + 'px'
      );
    }

    setBucketBarWidth();
    if (typeof ResizeObserver === 'undefined') {
      return;
    }
    if (bucketBarWidthObserver) {
      bucketBarWidthObserver.disconnect();
    }
    bucketBarWidthObserver = new ResizeObserver(setBucketBarWidth);
    bucketBarWidthObserver.observe(mainBars);
  }

  function createBucketCard(key, bucketState, scale, options) {
    const bucketRow = document.createElement('div');
    bucketRow.className = 'burst-demo__bucket burst-demo__bucket--dynamic';
    if (options.allowHighlight !== false) {
      if (options.highlightBucket === key) {
        bucketRow.classList.add('burst-demo__bucket--active');
      }
      if (options.burstSourceKey === key) {
        bucketRow.classList.add('burst-demo__bucket--source');
      }
      if (options.burstTargetKey === key) {
        bucketRow.classList.add('burst-demo__bucket--target');
      }
    }

    const bucketLabelEl = document.createElement('div');
    bucketLabelEl.className = 'burst-demo__bucket-label';
    bucketLabelEl.textContent = bucketShortLabel(key);
    bucketLabelEl.setAttribute('title', bucketLabel(key));

    const barRow = document.createElement('div');
    barRow.className = 'burst-demo__bars burst-demo__bars--bucket';
    const bucketViewport = document.createElement('div');
    bucketViewport.className = 'burst-demo__bucket-viewport';
    const barOpts = {
      allowHighlight: options.allowHighlight,
      ariaLabel: bucketLabel(key) + ' の棒グラフ',
    };
    if (
      options.allowHighlight !== false &&
      options.burstTargetKey === key
    ) {
      barOpts.highlightIdx = bucketState[key].length - 1;
      barOpts.highlightRole = 'write';
    }
    appendBucketBars(barRow, bucketState[key] || [], scale, barOpts);
    bucketRow.appendChild(bucketLabelEl);
    bucketViewport.appendChild(barRow);
    bucketRow.appendChild(bucketViewport);
    return bucketRow;
  }

  function mountBucketDemo(container, opts) {
    const options = opts || {};
    container.innerHTML = '';
    const wrap = document.createElement('div');
    wrap.className = 'burst-demo';

    const bucketState = options.bucketState || makeEmptyState();
    const fullArr = options.fullArr || demoValues();
    const slotCount = fullArr.length;
    const scale = valueScale(fullArr);
    const movedThroughIdx =
      options.movedThroughIdx != null ? options.movedThroughIdx : -1;
    const cursorSlot =
      options.cursorSlot != null
        ? options.cursorSlot
        : movedThroughIdx + 1 < slotCount
          ? movedThroughIdx + 1
          : null;
    const allowHighlight =
      options.allowHighlight !== false &&
      !options.noHighlight &&
      (options.outputMode
        ? (options.outputArr || []).length > 0
        : movedThroughIdx >= 0);
    const mountOpts = {
      allowHighlight: allowHighlight,
      highlightBucket: options.highlightBucket,
      burstSourceKey: options.burstSourceKey,
      burstTargetKey: options.burstTargetKey,
    };

    const mainSection = document.createElement('div');
    mainSection.className = 'burst-demo__section';
    const mainLabel = document.createElement('div');
    mainLabel.className = 'burst-demo__section-label';
    mainLabel.textContent = options.outputMode ? '出力' : '入力';
    const mainBars = document.createElement('div');
    mainBars.className = 'burst-demo__bars burst-demo__bars--slots';
    if (options.outputMode) {
      const outArr = options.outputArr || [];
      const outSlots = buildOutputSlots(outArr, slotCount);
      applySlotGrid(mainBars, outSlots.length);
      appendBarSlots(mainBars, outSlots, scale, {
        allowHighlight: allowHighlight,
        ariaLabel: 'バーストソートの出力配列。左から位置 0、1…の順です。',
        writeSlot: allowHighlight && outArr.length ? outArr.length - 1 : null,
      });
    } else {
      const inSlots = buildInputSlots(fullArr, movedThroughIdx);
      applySlotGrid(mainBars, inSlots.length);
      appendBarSlots(mainBars, inSlots, scale, {
        allowHighlight: allowHighlight,
        ariaLabel: 'バーストソートの入力配列。左から位置 0、1…の順です。',
        cursorSlot: allowHighlight ? cursorSlot : null,
      });
    }
    mainSection.appendChild(mainLabel);
    mainSection.appendChild(mainBars);

    const bucketsWrap = document.createElement('div');
    bucketsWrap.className = 'burst-demo__buckets';
    let hasBuckets = false;
    if (!options.hideBuckets) {
      const keys = orderedBucketKeys(bucketState);
      hasBuckets = keys.length > 0;
      const groups = { root: [], tens: [], ones: [] };
      let ki;
      for (ki = 0; ki < keys.length; ki++) {
        groups[bucketTier(keys[ki])].push(keys[ki]);
      }

      if (groups.root.length) {
        const tierEl = document.createElement('div');
        tierEl.className = 'burst-demo__tier burst-demo__tier--root';
        let ri;
        for (ri = 0; ri < groups.root.length; ri++) {
          tierEl.appendChild(
            createBucketCard(groups.root[ri], bucketState, scale, mountOpts)
          );
        }
        bucketsWrap.appendChild(tierEl);
      }

      if (groups.tens.length) {
        const tierEl = document.createElement('div');
        tierEl.className = 'burst-demo__tier burst-demo__tier--tens';
        const tierLabel = document.createElement('div');
        tierLabel.className = 'burst-demo__tier-label';
        tierLabel.textContent = '10の位';
        const grid = document.createElement('div');
        grid.className = 'burst-demo__tier-grid';
        let ti;
        for (ti = 0; ti < groups.tens.length; ti++) {
          grid.appendChild(
            createBucketCard(groups.tens[ti], bucketState, scale, mountOpts)
          );
        }
        tierEl.appendChild(tierLabel);
        tierEl.appendChild(grid);
        bucketsWrap.appendChild(tierEl);
      }

      if (groups.ones.length) {
        const tierEl = document.createElement('div');
        tierEl.className = 'burst-demo__tier burst-demo__tier--ones';
        const tierLabel = document.createElement('div');
        tierLabel.className = 'burst-demo__tier-label';
        tierLabel.textContent = '1の位';
        const grid = document.createElement('div');
        grid.className = 'burst-demo__tier-grid';
        let oi;
        for (oi = 0; oi < groups.ones.length; oi++) {
          grid.appendChild(
            createBucketCard(groups.ones[oi], bucketState, scale, mountOpts)
          );
        }
        tierEl.appendChild(tierLabel);
        tierEl.appendChild(grid);
        bucketsWrap.appendChild(tierEl);
      }
    }

    wrap.appendChild(mainSection);
    if (hasBuckets) {
      wrap.appendChild(bucketsWrap);
    }
    container.appendChild(wrap);
    matchBucketBarWidths(wrap, mainBars);
  }

  function burstNthLabel(count) {
    if (count > 0) {
      return '（' + count + '回目のバースト）';
    }
    return '';
  }

  function burstNode(node, exp, path, state, steps, meta) {
    const items = node.bucket.slice();
    const fromKey = pathToKey(path);
    meta.totalBurstCount += 1;
    const burstCount = meta.totalBurstCount;

    steps.push({
      kind: 'burst_ready',
      burstKey: fromKey,
      burstExp: exp,
      burstCount: burstCount,
      idx: meta.currentIdx,
      value: meta.currentValue,
      arr: meta.arr.slice(),
      bucketState: cloneState(state),
    });

    node.bucket.splice(0);
    let i;
    for (i = 0; i < items.length; i++) {
      const itemValue = items[i];
      const digit = Math.floor(itemValue / exp) % 10;
      const nextPath = path.concat([digit]);
      const toKey = pathToKey(nextPath);
      if (!node.children[digit]) {
        node.children[digit] = makeBurstNode();
      }
      node.children[digit].bucket.push(itemValue);
      state[fromKey] = items.slice(i + 1);
      state[toKey] = node.children[digit].bucket.slice();
      steps.push({
        kind: 'burst_move',
        burstKey: fromKey,
        burstExp: exp,
        burstCount: burstCount,
        moveValue: itemValue,
        moveDigit: digit,
        moveToKey: toKey,
        moveIndex: i,
        moveTotal: items.length,
        idx: meta.currentIdx,
        value: meta.currentValue,
        arr: meta.arr.slice(),
        bucketState: cloneState(state),
      });
    }
    state[fromKey] = [];

    steps.push({
      kind: 'burst_done',
      burstKey: fromKey,
      burstExp: exp,
      burstCount: burstCount,
      idx: meta.currentIdx,
      value: meta.currentValue,
      arr: meta.arr.slice(),
      bucketState: cloneState(state),
    });

    let d;
    for (d = 0; d < 10; d++) {
      if (!node.children[d]) {
        continue;
      }
      const child = node.children[d];
      const childPath = path.concat([d]);
      if (
        !isTrie(child) &&
        child.bucket.length > BURST_THRESHOLD &&
        Math.floor(exp / 10) > 0
      ) {
        burstNode(child, Math.floor(exp / 10), childPath, state, steps, meta);
      }
    }
  }

  function burstInsert(node, value, exp, path, state, steps, meta) {
    if (isTrie(node)) {
      if (exp === 0) {
        node.bucket.push(value);
        const key = pathToKey(path);
        state[key] = node.bucket.slice();
        steps.push({
          kind: 'insert',
          idx: meta.currentIdx,
          value: meta.currentValue,
          arr: meta.arr.slice(),
          bucketState: cloneState(state),
          bucketKey: key,
        });
        return;
      }
      const digit = Math.floor(value / exp) % 10;
      const nextPath = path.concat([digit]);
      if (!node.children[digit]) {
        node.children[digit] = makeBurstNode();
      }
      burstInsert(
        node.children[digit],
        value,
        Math.floor(exp / 10),
        nextPath,
        state,
        steps,
        meta
      );
      return;
    }

    node.bucket.push(value);
    const key = pathToKey(path);
    state[key] = node.bucket.slice();
    const overflow = node.bucket.length > BURST_THRESHOLD && exp > 0;
    steps.push({
      kind: 'insert',
      idx: meta.currentIdx,
      value: meta.currentValue,
      arr: meta.arr.slice(),
      bucketState: cloneState(state),
      overflow: overflow,
      bucketKey: key,
    });
    if (overflow) {
      burstNode(node, exp, path, state, steps, meta);
    }
  }

  function insertionSortSilent(bucket) {
    const a = bucket.slice();
    let i;
    let j;
    for (i = 1; i < a.length; i++) {
      const key = a[i];
      j = i - 1;
      while (j >= 0 && a[j] > key) {
        a[j + 1] = a[j];
        j--;
      }
      a[j + 1] = key;
    }
    return a;
  }

  function burstCollectSilent(node, path, out, state, steps, sourceArr) {
    let d;
    for (d = 0; d < 10; d++) {
      if (node.children[d]) {
        burstCollectSilent(
          node.children[d],
          path.concat([d]),
          out,
          state,
          steps,
          sourceArr
        );
      }
    }
    if (node.bucket.length > 1) {
      const before = node.bucket.slice();
      const sorted = insertionSortSilent(node.bucket);
      node.bucket = sorted;
      const key = pathToKey(path);
      state[key] = sorted.slice();
      steps.push({
        kind: 'leaf_sort',
        path: path.slice(),
        before: before,
        bucket: sorted.slice(),
        out: out.slice(),
        bucketState: cloneState(state),
        arr: sourceArr,
      });
    }
    let bi;
    const key = pathToKey(path);
    for (bi = 0; bi < node.bucket.length; bi++) {
      out.push(node.bucket[bi]);
      state[key] = node.bucket.slice(bi + 1);
      steps.push({
        kind: 'emit',
        value: node.bucket[bi],
        path: path.slice(),
        out: out.slice(),
        bucketState: cloneState(state),
        arr: sourceArr,
        emitBucketKey: key,
      });
    }
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const state = makeEmptyState();
    if (!a.length) {
      steps.push({ kind: 'done', arr: [], bucketState: makeEmptyState() });
      return steps;
    }

    const maxVal = Math.max.apply(null, a);
    const exp = maxExp(maxVal);
    const root = makeBurstNode();

    steps.push({
      kind: 'phase',
      phase: 'insert',
      arr: a.slice(),
      exp: exp,
      bucketState: cloneState(state),
    });

    const meta = { totalBurstCount: 0, arr: a };
    let i;
    for (i = 0; i < a.length; i++) {
      meta.currentIdx = i;
      meta.currentValue = a[i];
      burstInsert(root, a[i], exp, [], state, steps, meta);
    }

    const out = [];
    steps.push({
      kind: 'phase',
      phase: 'collect',
      arr: a.slice(),
      out: out.slice(),
      bucketState: cloneState(state),
    });
    burstCollectSilent(root, [], out, state, steps, a);

    steps.push({
      kind: 'done',
      arr: out.slice(),
      bucketState: cloneState(state),
    });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-burst',
    initialValues: demoValues(),
    initialCaption:
      '挿入フェーズ: 各値をバケットへ入れます（閾値 ' +
      BURST_THRESHOLD +
      '）。「1ステップ」で開始',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    rebuild: function (api) {
      const vals = demoValues();
      api.values = vals;
      api.steps = generateSteps(vals);
      api.idx = 0;
      mountBucketDemo(api.barsEl, {
        fullArr: vals,
        movedThroughIdx: -1,
        bucketState: makeEmptyState(),
      });
      api.setCaption(
        '挿入フェーズ: 各値をバケットへ入れます（閾値 ' +
          BURST_THRESHOLD +
          '）。「1ステップ」で開始'
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;

      if (s.kind === 'phase') {
        if (s.phase === 'collect') {
          mountBucketDemo(barsEl, {
            outputMode: true,
            fullArr: s.arr,
            outputArr: s.out || [],
            movedThroughIdx: s.arr.length - 1,
            bucketState: s.bucketState,
          });
          api.setCaption(
            '収集フェーズ: 子 0..9 の順に走査し、出力配列を作ります'
          );
        } else {
          mountBucketDemo(barsEl, {
            fullArr: s.arr,
            movedThroughIdx: -1,
            bucketState: s.bucketState,
          });
          api.setCaption(
            '挿入フェーズ: 最上位桁は ' +
              digitName(s.exp) +
              ' から処理します'
          );
        }
        return;
      }

      if (s.kind === 'insert') {
        mountBucketDemo(barsEl, {
          fullArr: s.arr,
          movedThroughIdx: s.idx,
          bucketState: s.bucketState,
          highlightBucket: s.overflow ? s.bucketKey : null,
        });
        if (s.overflow) {
          api.setCaption(
            '位置 ' +
              s.idx +
              ' の ' +
              s.value +
              ' を' +
              bucketLabel(s.bucketKey) +
              'へ挿入。閾値を超えました'
          );
        } else {
          api.setCaption(
            '位置 ' +
              s.idx +
              ' の ' +
              s.value +
              ' を' +
              bucketLabel(s.bucketKey) +
              'へ挿入しました'
          );
        }
        return;
      }

      if (s.kind === 'burst_ready') {
        mountBucketDemo(barsEl, {
          fullArr: s.arr,
          movedThroughIdx: s.idx,
          bucketState: s.bucketState,
          highlightBucket: s.burstKey,
          burstSourceKey: s.burstKey,
        });
        api.setCaption(
          bucketLabel(s.burstKey) +
            'を' +
            digitName(s.burstExp) +
            'で振り分けます' +
            burstNthLabel(s.burstCount)
        );
        return;
      }

      if (s.kind === 'burst_move') {
        mountBucketDemo(barsEl, {
          fullArr: s.arr,
          movedThroughIdx: s.idx,
          bucketState: s.bucketState,
          burstSourceKey: s.burstKey,
          burstTargetKey: s.moveToKey,
        });
        api.setCaption(
          s.moveValue +
            ' を' +
            bucketLabel(s.burstKey) +
            'から' +
            bucketLabel(s.moveToKey) +
            'へ移します（' +
            (s.moveIndex + 1) +
            '/' +
            s.moveTotal +
            '）' +
            burstNthLabel(s.burstCount)
        );
        return;
      }

      if (s.kind === 'burst_done') {
        mountBucketDemo(barsEl, {
          fullArr: s.arr,
          movedThroughIdx: s.idx,
          bucketState: s.bucketState,
        });
        api.setCaption(
          bucketLabel(s.burstKey) +
            'のバーストが完了しました' +
            burstNthLabel(s.burstCount)
        );
        return;
      }

      if (s.kind === 'leaf_sort') {
        mountBucketDemo(barsEl, {
          outputMode: true,
          fullArr: s.arr,
          outputArr: s.out,
          movedThroughIdx: s.arr.length - 1,
          bucketState: s.bucketState,
          highlightBucket: pathToKey(s.path),
        });
        api.setCaption(
          bucketLabel(pathToKey(s.path)) +
            ' を挿入ソートで整列しました（' +
            s.before.join(', ') +
            ' → ' +
            s.bucket.join(', ') +
            '）'
        );
        return;
      }

      if (s.kind === 'emit') {
        mountBucketDemo(barsEl, {
          outputMode: true,
          fullArr: s.arr,
          outputArr: s.out,
          movedThroughIdx: s.arr.length - 1,
          bucketState: s.bucketState,
          burstSourceKey: s.emitBucketKey,
        });
        api.setCaption(
          bucketLabel(pathToKey(s.path)) +
            ' から ' +
            s.value +
            ' を出力（位置 ' +
            (s.out.length - 1) +
            '）'
        );
        return;
      }

      if (s.kind === 'done') {
        mountBucketDemo(barsEl, {
          outputMode: true,
          fullArr: s.arr,
          outputArr: s.arr,
          noHighlight: true,
          hideBuckets: true,
        });
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: function (api) {
      const s = api.steps[api.idx - 1];
      if (
        s &&
        (s.kind === 'burst_ready' ||
          s.kind === 'burst_move' ||
          s.kind === 'burst_done')
      ) {
        return 550;
      }
      return 400;
    },
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="burst-sort-demo"
  data_prefix="burst"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[トライソート](/2026/07/11/sort-trie.html)は全キーを最初から桁ごとの木へ挿入する。[基数ソート](/2026/06/21/sort-radix.html)の MSD 版と区分は同型で、バーストソートはバケットが閾値を超えたときだけ下位桁へ展開する点が異なる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000010 |        0.000115 |              82 |              88 |
|        512 |        0.000019 |        0.000090 |              86 |              92 |
|       1024 |        0.000037 |        0.000090 |             113 |             120 |
|       2048 |        0.000073 |        0.000160 |             158 |             168 |
|       4096 |        0.000146 |        0.000273 |             245 |             252 |
|       8192 |        0.000311 |        0.001433 |             341 |             436 |
|      16384 |        0.000646 |        0.001280 |             636 |             672 |
|      32768 |        0.001312 |        0.002226 |            1276 |            1308 |
|      65536 |        0.002764 |        0.011497 |            2543 |            2576 |
|     131072 |        0.006005 |        0.039689 |            5124 |            5156 |
|     262144 |        0.012808 |        0.033667 |           10355 |           10388 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="burst" %}
