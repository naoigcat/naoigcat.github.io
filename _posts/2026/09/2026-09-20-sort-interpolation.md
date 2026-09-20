---
title:     補間ソートで配列を並び替える
date:      2026-09-20 07:00:26 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## 補間ソートを使用する

補間ソート (`interpolation sort`) は、キーの最小値・最大値を端点とする線形補間で各要素の配置先インデックスを推定し、推定先のバケットへ仕分けてからバケット内を再帰的に同じ手続きで整列する分布ソートである。

[バケットソート](/2026/06/23/sort-bucket.html)の特別な場合で、バケット数を要素数 `n` に取り、仕分け関数を補間式に固定した形とみなせる。

1.  **値域の決定**: 配列の最小値 `min` と最大値 `max` を求める。等しければ既に整列済みとして終了する。
2.  **補間インデックス**: 各要素 `x` について $$k = \left\lfloor \frac{x - min}{max - min} \times (n - 1) \right\rfloor$$ を計算し、バケット `k` へ追加する。`min` は常に `0`、`max` は常に `n - 1` へ写る。
3.  **再帰**: 要素が 2 個以上のバケットに対し、同じ補間ソートを再帰適用する（実装では小さなバケットを挿入ソートへ切り替えてよい）。
4.  **連結**: バケット `0, 1, …, n - 1` の順に要素を書き戻せば全体が昇順になる。

```pseudocode
procedure interpolation_sort(A)
  n = length(A)
  if n <= 1 then return
  minVal = minimum(A)
  maxVal = maximum(A)
  if minVal = maxVal then return
  buckets = empty list of n arrays
  for each x in A
    k = floor((x - minVal) / (maxVal - minVal) * (n - 1))
    append x to buckets[k]
  for k from 0 to n - 1
    if length(buckets[k]) > 1 then
      interpolation_sort(buckets[k])
  A = concatenate(buckets)
```

値が等差に近い一様分布なら各バケットはほぼ 1 要素になり、平均時間計算量は $$O(n)$$ に近づく。偏った分布では大きなバケットが残り、再帰や内部ソートが重なって $$O(n^2)$$ になりうる。追加メモリはバケット配列で $$O(n)$$ である。バケットへの追加順を保ち内部も安定にすれば全体も安定にできるが、循環交換や非安定な内部ソートを使う変種は不安定になる。

以下のデモでは、重複のない偏った 15 要素を、要素数と同じ `n` 個の推定順位バケットへ補間で仕分ける。バケットラベルはその順位に写る値（補間アンカー）で、棒がそこに飛ぶ。偏りで衝突したバケットは挿入ソートをアニメーションし、連結する。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('interpolation-sort-demo', function (root) {
  const barClass = 'sort-demo__bar';
  const DEMO_N = 15;
  const MAX_EMPTY_BUCKETS = 5;
  // 空バケット ≤ MAX_EMPTY_BUCKETS になるよう選んだ重複なし 15 要素
  const DEMO_INITIAL = [
    40, 3, 98, 13, 1, 28, 8, 65, 21, 2, 34, 18, 9, 54, 45,
  ];
  const CAPTION =
    '補間ソートのデモ（重複なし・偏った 15 要素を推定順位バケットへ）';

  function prefersReducedMotion() {
    if (!window.matchMedia) {
      return false;
    }
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

  function interpolationIndex(value, minVal, maxVal, n) {
    if (maxVal === minVal) {
      return 0;
    }
    const idx = Math.floor(
      ((value - minVal) / (maxVal - minVal)) * (n - 1)
    );
    return Math.min(idx, n - 1);
  }

  function emptyBuckets(n) {
    const buckets = [];
    for (let b = 0; b < n; b++) {
      buckets.push([]);
    }
    return buckets;
  }

  function cloneBuckets(buckets) {
    return buckets.map(function (bk) {
      return bk.slice();
    });
  }

  function formatAnchor(minVal, maxVal, n, b) {
    if (n <= 1 || maxVal === minVal) {
      return String(minVal);
    }
    const x = minVal + (b * (maxVal - minVal)) / (n - 1);
    if (Math.abs(x - Math.round(x)) < 1e-9) {
      return String(Math.round(x));
    }
    return String(Math.round(x * 10) / 10);
  }

  function valueScale(values) {
    const src =
      values && values.length ? values : DEMO_INITIAL;
    const min = Math.min.apply(null, src);
    const max = Math.max.apply(null, src);
    return { min: min, max: max, span: Math.max(max - min, 1) };
  }

  function emptyBucketCount(values) {
    const n = values.length;
    if (!n) {
      return 0;
    }
    const minVal = Math.min.apply(null, values);
    const maxVal = Math.max.apply(null, values);
    const seen = {};
    for (let i = 0; i < n; i++) {
      seen[interpolationIndex(values[i], minVal, maxVal, n)] = 1;
    }
    let empty = 0;
    for (let b = 0; b < n; b++) {
      if (!seen[b]) {
        empty++;
      }
    }
    return empty;
  }

  function hasBucketCollision(values) {
    const n = values.length;
    if (!n) {
      return false;
    }
    const minVal = Math.min.apply(null, values);
    const maxVal = Math.max.apply(null, values);
    const counts = [];
    for (let b = 0; b < n; b++) {
      counts.push(0);
    }
    for (let i = 0; i < n; i++) {
      counts[interpolationIndex(values[i], minVal, maxVal, n)]++;
    }
    for (let b = 0; b < n; b++) {
      if (counts[b] > 1) {
        return true;
      }
    }
    return false;
  }

  function isGoodDemoValues(values) {
    return (
      values &&
      values.length === DEMO_N &&
      emptyBucketCount(values) <= MAX_EMPTY_BUCKETS &&
      hasBucketCollision(values)
    );
  }

  function randomGoodDemoValues() {
    for (let attempt = 0; attempt < 400; attempt++) {
      const seen = {};
      const vals = [];
      while (vals.length < DEMO_N) {
        const v = 1 + Math.floor(Math.random() * 100);
        if (!seen[v]) {
          seen[v] = 1;
          vals.push(v);
        }
      }
      if (isGoodDemoValues(vals)) {
        return DemoSort.shuffleCopy(vals);
      }
    }
    return DEMO_INITIAL.slice();
  }

  function scaledBarHeight(value, scale) {
    return 28 + ((value - scale.min) / scale.span) * 92 + 'px';
  }

  function elementRect(el) {
    if (!el) {
      return null;
    }
    const box = el.getBoundingClientRect();
    return {
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
    };
  }

  function mkBar(value, scale, role) {
    const bar = document.createElement('div');
    bar.className = barClass;
    bar.style.height = scaledBarHeight(value, scale);
    bar.setAttribute('title', String(value));
    if (role) {
      bar.setAttribute('data-role', role);
    }
    return bar;
  }

  function mkBucketBar(value, scale) {
    const bar = document.createElement('div');
    bar.className = barClass;
    bar.style.height = scaledBarHeight(value, scale);
    bar.setAttribute('aria-hidden', 'true');
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
    bar.className = barClass;
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
    stack.setAttribute(
      'aria-label',
      DemoSort.barAccessibilityLabel(
        inputIdx != null ? inputIdx : 0,
        value == null ? '' : String(value),
        role || (value == null ? 'gap' : null)
      )
    );
    return stack;
  }

  function ensureLayout(barsEl) {
    let wrap = barsEl.querySelector('.interp-demo');
    if (wrap) {
      return wrap;
    }
    barsEl.innerHTML = '';
    wrap = document.createElement('div');
    wrap.className = 'interp-demo';

    const arraySection = document.createElement('section');
    arraySection.className = 'interp-demo__section';
    const arrayLabel = document.createElement('p');
    arrayLabel.className = 'interp-demo__section-label';
    arrayLabel.dataset.interpSection = 'array';
    arrayLabel.textContent = '入力';
    const arrayTrack = document.createElement('div');
    arrayTrack.className = 'interp-demo__track';
    arrayTrack.dataset.interpTrack = 'array';
    arraySection.appendChild(arrayLabel);
    arraySection.appendChild(arrayTrack);

    const bucketsSection = document.createElement('section');
    bucketsSection.className = 'interp-demo__section';
    const bucketsLabel = document.createElement('p');
    bucketsLabel.className = 'interp-demo__section-label';
    bucketsLabel.dataset.interpSection = 'buckets';
    bucketsLabel.textContent =
      '推定順位バケット（ラベルは補間アンカー。個数 = n）';
    const bucketsTrack = document.createElement('div');
    bucketsTrack.className = 'interp-demo__buckets';
    bucketsTrack.dataset.interpTrack = 'buckets';
    bucketsSection.appendChild(bucketsLabel);
    bucketsSection.appendChild(bucketsTrack);

    wrap.appendChild(arraySection);
    wrap.appendChild(bucketsSection);
    barsEl.appendChild(wrap);
    return wrap;
  }

  function slotValue(view, i) {
    const arr = view.arr || [];
    if (view.outputMode) {
      const out = view.outputArr || [];
      return i < out.length ? out[i] : null;
    }
    const movedThrough =
      view.movedThroughIdx == null ? -1 : view.movedThroughIdx;
    if (i <= movedThrough) {
      return null;
    }
    return arr[i];
  }

  function mountDemo(barsEl, view) {
    const wrap = ensureLayout(barsEl);
    const arr = view.arr || [];
    const scale = valueScale(arr.length ? arr : DEMO_INITIAL);
    const arrayTrack = wrap.querySelector('[data-interp-track="array"]');
    const bucketsTrack = wrap.querySelector('[data-interp-track="buckets"]');
    const arrayLabel = wrap.querySelector('[data-interp-section="array"]');
    const bucketsLabel = wrap.querySelector('[data-interp-section="buckets"]');
    const buckets = view.buckets || emptyBuckets(arr.length || 1);
    const n = Math.max(arr.length, buckets.length, 1);
    const minVal = view.minVal != null ? view.minVal : scale.min;
    const maxVal = view.maxVal != null ? view.maxVal : scale.max;

    arrayLabel.textContent = view.outputMode
      ? view.resultDone
        ? '結果'
        : '結果（回収中）'
      : '入力';
    bucketsLabel.textContent =
      '推定順位バケット（ラベルは補間アンカー。個数 = n = ' + n + '）';

    arrayTrack.innerHTML = '';
    bucketsTrack.innerHTML = '';

    arrayTrack.setAttribute('role', 'list');
    arrayTrack.setAttribute(
      'aria-label',
      '補間ソートの入力配列。棒の高さは値の大小です。'
    );

    for (let i = 0; i < n; i++) {
      const value = slotValue(view, i);
      let role = null;
      if (view.highlightIdx === i) {
        role = view.highlightRole || 'cursor';
      }
      if (view.hideOutputIdx === i && value != null) {
        const stack = mkBarStack(value, scale, role, i);
        const bar = stack.querySelector(
          '.sort-demo__bar:not([data-role="gap"])'
        );
        if (bar) {
          bar.style.visibility = 'hidden';
        }
        arrayTrack.appendChild(stack);
      } else {
        arrayTrack.appendChild(mkBarStack(value, scale, role, i));
      }
    }

    syncBarWidth(wrap, n);

    for (let b = 0; b < n; b++) {
      const items = buckets[b] || [];
      const bucketEl = document.createElement('div');
      bucketEl.className = 'interp-demo__bucket';
      if (!items.length) {
        bucketEl.classList.add('interp-demo__bucket--empty');
      }
      if (view.activeBucket === b) {
        bucketEl.classList.add('interp-demo__bucket--active');
      }
      bucketEl.dataset.bucket = String(b);

      const stackEl = document.createElement('div');
      stackEl.className = 'interp-demo__bucket-stack';
      stackEl.dataset.bucketStack = String(b);
      const anchor = formatAnchor(minVal, maxVal, n, b);
      stackEl.setAttribute('role', 'list');
      stackEl.setAttribute(
        'aria-label',
        '推定順位 ' + b + '（アンカー ' + anchor + '）のバケット'
      );

      for (let j = 0; j < items.length; j++) {
        const bar = mkBucketBar(items[j], scale);
        if (
          view.hideBucketBar &&
          view.hideBucketBar.bucket === b &&
          view.hideBucketBar.stackPos === j
        ) {
          bar.style.visibility = 'hidden';
        }
        stackEl.appendChild(bar);
      }

      const digitLabel = document.createElement('span');
      digitLabel.className = 'interp-demo__bucket-label';
      digitLabel.textContent = anchor;
      digitLabel.title = '推定順位 ' + b + ' ← アンカー値 ' + anchor;

      bucketEl.appendChild(stackEl);
      bucketEl.appendChild(digitLabel);
      bucketsTrack.appendChild(bucketEl);
    }
  }

  function syncBarWidth(wrap, n) {
    // 再生中は幅を変えない。空バケット上限を前提に一度だけ決める。
    if (wrap.dataset.interpBarWidthLocked === '1') {
      return;
    }
    const track =
      wrap.querySelector('[data-interp-track="buckets"]') ||
      wrap.querySelector('[data-interp-track="array"]');
    if (!track) {
      return;
    }
    const W = track.getBoundingClientRect().width;
    if (!(W > 0) || !(n > 0)) {
      return;
    }
    const styles = window.getComputedStyle(wrap);
    const gap = parseFloat(styles.getPropertyValue('--interp-gap')) || 3;
    const bucketGap =
      parseFloat(styles.getPropertyValue('--interp-bucket-gap')) || 4;
    const preferred =
      parseFloat(styles.getPropertyValue('--interp-bar-width')) || 26;
    // 空 ≤ MAX_EMPTY なら W >= (n+E)*bw + E*gap + (n-1)*bucketGap
    const E = MAX_EMPTY_BUCKETS;
    const fit = Math.floor(
      (W - E * gap - (n - 1) * bucketGap) / (n + E)
    );
    const finalBw = Math.max(12, Math.min(preferred, fit));
    wrap.style.setProperty('--interp-bar-width', finalBw + 'px');
    wrap.dataset.interpBarWidthLocked = '1';
  }

  function findInputBar(wrap, idx) {
    return wrap.querySelector(
      '[data-input-idx="' + idx + '"] .sort-demo__bar:not([data-role="gap"])'
    );
  }

  function findBucketStack(wrap, bucket) {
    return wrap.querySelector('[data-bucket-stack="' + bucket + '"]');
  }

  function findBucketBar(wrap, bucket, stackPos) {
    const stack = findBucketStack(wrap, bucket);
    if (!stack) {
      return null;
    }
    const bars = stack.querySelectorAll('.sort-demo__bar');
    return bars[stackPos] || null;
  }

  function findArrayBar(wrap, idx) {
    const track = wrap.querySelector('[data-interp-track="array"]');
    if (!track || !track.children[idx]) {
      return null;
    }
    return track.children[idx].querySelector(
      '.sort-demo__bar:not([data-role="gap"])'
    );
  }

  async function flyBarRects(fromRect, toRect, value, scale, role) {
    if (!fromRect || !toRect || prefersReducedMotion()) {
      return;
    }
    const ghost = mkBar(value, scale, role || 'write');
    ghost.style.position = 'fixed';
    ghost.style.left = fromRect.left + 'px';
    ghost.style.top = fromRect.top + 'px';
    ghost.style.width = fromRect.width + 'px';
    ghost.style.height = fromRect.height + 'px';
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
        if (e.propertyName !== 'left' && e.propertyName !== 'top') {
          return;
        }
        ghost.removeEventListener('transitionend', done);
        ghost.remove();
        resolve();
      }
      ghost.addEventListener('transitionend', done);
      setTimeout(function () {
        ghost.removeEventListener('transitionend', done);
        if (ghost.parentNode) {
          ghost.remove();
        }
        resolve();
      }, 450);
    });
  }

  function pushInsertionSortSteps(steps, buckets, bucketIdx, arr, minVal, maxVal) {
    const bucket = buckets[bucketIdx];
    steps.push({
      kind: 'bucket_start',
      bucket: bucketIdx,
      arr: arr.slice(),
      minVal: minVal,
      maxVal: maxVal,
      buckets: cloneBuckets(buckets),
      movedThroughIdx: arr.length - 1,
    });
    for (let j = 1; j < bucket.length; j++) {
      let cur = j;
      while (cur > 0 && bucket[cur - 1] > bucket[cur]) {
        steps.push({
          kind: 'bucket_compare',
          bucket: bucketIdx,
          lo: cur - 1,
          hi: cur,
          arr: arr.slice(),
          minVal: minVal,
          maxVal: maxVal,
          buckets: cloneBuckets(buckets),
          movedThroughIdx: arr.length - 1,
        });
        const t = bucket[cur - 1];
        bucket[cur - 1] = bucket[cur];
        bucket[cur] = t;
        steps.push({
          kind: 'bucket_swap',
          bucket: bucketIdx,
          lo: cur - 1,
          hi: cur,
          arr: arr.slice(),
          minVal: minVal,
          maxVal: maxVal,
          buckets: cloneBuckets(buckets),
          movedThroughIdx: arr.length - 1,
        });
        cur--;
      }
    }
    steps.push({
      kind: 'bucket_done',
      bucket: bucketIdx,
      arr: arr.slice(),
      minVal: minVal,
      maxVal: maxVal,
      buckets: cloneBuckets(buckets),
      movedThroughIdx: arr.length - 1,
    });
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const n = a.length;
    const steps = [];
    if (!n) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    const minVal = Math.min.apply(null, a);
    const maxVal = Math.max.apply(null, a);
    const buckets = emptyBuckets(n);

    steps.push({
      kind: 'phase',
      phase: 'distribute',
      arr: a.slice(),
      minVal: minVal,
      maxVal: maxVal,
      buckets: cloneBuckets(buckets),
      movedThroughIdx: -1,
    });

    for (let i = 0; i < n; i++) {
      const value = a[i];
      const bucket = interpolationIndex(value, minVal, maxVal, n);
      steps.push({
        kind: 'assign_scan',
        idx: i,
        value: value,
        bucket: bucket,
        arr: a.slice(),
        minVal: minVal,
        maxVal: maxVal,
        buckets: cloneBuckets(buckets),
        movedThroughIdx: i - 1,
      });
      buckets[bucket].push(value);
      steps.push({
        kind: 'assign_move',
        idx: i,
        value: value,
        bucket: bucket,
        arr: a.slice(),
        minVal: minVal,
        maxVal: maxVal,
        buckets: cloneBuckets(buckets),
        movedThroughIdx: i,
        bucketStackPos: buckets[bucket].length - 1,
      });
    }

    let needsSort = false;
    for (let b = 0; b < n; b++) {
      if (buckets[b].length > 1) {
        needsSort = true;
        break;
      }
    }
    if (needsSort) {
      steps.push({
        kind: 'phase',
        phase: 'sort_buckets',
        arr: a.slice(),
        minVal: minVal,
        maxVal: maxVal,
        buckets: cloneBuckets(buckets),
        movedThroughIdx: n - 1,
      });
      for (let b = 0; b < n; b++) {
        if (buckets[b].length < 2) {
          continue;
        }
        pushInsertionSortSteps(steps, buckets, b, a, minVal, maxVal);
      }
    }

    steps.push({
      kind: 'phase',
      phase: 'collect',
      arr: a.slice(),
      minVal: minVal,
      maxVal: maxVal,
      buckets: cloneBuckets(buckets),
      movedThroughIdx: n - 1,
      outputArr: [],
    });

    const working = cloneBuckets(buckets);
    const output = [];
    for (let b = 0; b < n; b++) {
      while (working[b].length > 0) {
        const value = working[b][0];
        steps.push({
          kind: 'collect_scan',
          bucket: b,
          value: value,
          arr: a.slice(),
          minVal: minVal,
          maxVal: maxVal,
          buckets: cloneBuckets(working),
          outputArr: output.slice(),
        });
        working[b].shift();
        output.push(value);
        steps.push({
          kind: 'collect_move',
          bucket: b,
          value: value,
          arr: a.slice(),
          minVal: minVal,
          maxVal: maxVal,
          buckets: cloneBuckets(working),
          outputArr: output.slice(),
          outputIdx: output.length - 1,
        });
      }
    }

    steps.push({
      kind: 'done',
      arr: output.slice(),
      minVal: minVal,
      maxVal: maxVal,
      buckets: cloneBuckets(working),
      outputArr: output.slice(),
    });
    return steps;
  }

  function baseView(s, extra) {
    const view = {
      arr: s.arr,
      minVal: s.minVal,
      maxVal: s.maxVal,
      buckets: s.buckets,
      movedThroughIdx: s.movedThroughIdx,
    };
    if (extra) {
      Object.keys(extra).forEach(function (k) {
        view[k] = extra[k];
      });
    }
    return view;
  }

  let demoBooted = false;

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-interpolation',
    initialValues: DEMO_INITIAL.slice(),
    initialCaption: CAPTION,
    barClass: barClass,
    generateSteps: generateSteps,
    rebuild: function (api, v) {
      let next;
      if (!demoBooted) {
        next =
          v && isGoodDemoValues(v) ? v.slice() : randomGoodDemoValues();
        demoBooted = true;
      } else {
        // 補間の振り分けは順序非依存なので、シャッフルでは値集合を引き直す
        next = randomGoodDemoValues();
      }
      api.values = next;
      api.steps = generateSteps(next);
      api.idx = 0;
      const first = api.steps[0];
      mountDemo(
        api.barsEl,
        baseView(first, {
          buckets: first.buckets || emptyBuckets(next.length),
        })
      );
      api.setCaption(CAPTION);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      const wrap = ensureLayout(barsEl);
      const scale = valueScale(s.arr && s.arr.length ? s.arr : DEMO_INITIAL);

      if (s.kind === 'phase') {
        if (s.phase === 'distribute') {
          mountDemo(barsEl, baseView(s));
          api.setCaption(
            '値域 [' +
              s.minVal +
              ', ' +
              s.maxVal +
              '] を線形補間し、推定順位バケット（n = ' +
              s.arr.length +
              '）へ写す'
          );
          return;
        }
        if (s.phase === 'sort_buckets') {
          mountDemo(barsEl, baseView(s));
          api.setCaption(
            '偏りで衝突したバケットだけ挿入ソートする'
          );
          return;
        }
        if (s.phase === 'collect') {
          mountDemo(
            barsEl,
            baseView(s, {
              outputMode: true,
              outputArr: s.outputArr,
            })
          );
          api.setCaption('バケット順に連結して結果配列へ戻す');
          return;
        }
      }

      if (s.kind === 'assign_scan') {
        mountDemo(
          barsEl,
          baseView(s, {
            highlightIdx: s.idx,
            highlightRole: 'cursor',
            activeBucket: s.bucket,
          })
        );
        api.setCaption(
          '値 ' +
            s.value +
            ' → 順位 ' +
            s.bucket +
            '（アンカー ' +
            formatAnchor(s.minVal, s.maxVal, s.arr.length, s.bucket) +
            '）'
        );
        return;
      }

      if (s.kind === 'assign_move') {
        const bucketsBefore = cloneBuckets(s.buckets);
        bucketsBefore[s.bucket].pop();

        mountDemo(
          barsEl,
          baseView(s, {
            buckets: bucketsBefore,
            movedThroughIdx: s.movedThroughIdx - 1,
            highlightIdx: s.idx,
            highlightRole: 'cursor',
            activeBucket: s.bucket,
          })
        );
        await nextFrame();
        const fromRect = elementRect(findInputBar(wrap, s.idx));

        mountDemo(
          barsEl,
          baseView(s, {
            activeBucket: s.bucket,
            hideBucketBar: {
              bucket: s.bucket,
              stackPos: s.bucketStackPos,
            },
          })
        );
        await nextFrame();
        const toRect = elementRect(
          findBucketBar(wrap, s.bucket, s.bucketStackPos)
        );

        if (fromRect && toRect) {
          await flyBarRects(fromRect, toRect, s.value, scale, 'write');
        }

        mountDemo(
          barsEl,
          baseView(s, { activeBucket: s.bucket })
        );
        api.setCaption(
          '値 ' +
            s.value +
            ' をアンカー ' +
            formatAnchor(s.minVal, s.maxVal, s.arr.length, s.bucket) +
            ' のバケットへ移しました'
        );
        return;
      }

      if (s.kind === 'bucket_start') {
        mountDemo(
          barsEl,
          baseView(s, { activeBucket: s.bucket })
        );
        api.setCaption(
          'バケット ' +
            s.bucket +
            '（[' +
            s.buckets[s.bucket].join(', ') +
            ']）を挿入ソート'
        );
        return;
      }

      if (s.kind === 'bucket_compare') {
        mountDemo(
          barsEl,
          baseView(s, { activeBucket: s.bucket })
        );
        const stack = findBucketStack(wrap, s.bucket);
        if (stack) {
          DemoSort.clearRoles(stack);
          if (stack.children[s.lo]) {
            stack.children[s.lo].setAttribute('data-role', 'compare');
          }
          if (stack.children[s.hi]) {
            stack.children[s.hi].setAttribute('data-role', 'compare');
          }
        }
        api.setCaption(
          'バケット ' +
            s.bucket +
            ': 位置 ' +
            s.lo +
            ' と ' +
            s.hi +
            ' を比較'
        );
        return;
      }

      if (s.kind === 'bucket_swap') {
        const stack = findBucketStack(wrap, s.bucket);
        if (stack) {
          DemoSort.clearRoles(stack);
          if (stack.children[s.lo]) {
            stack.children[s.lo].setAttribute('data-role', 'swap');
          }
          if (stack.children[s.lo + 1]) {
            stack.children[s.lo + 1].setAttribute('data-role', 'swap');
          }
          api.setCaption('交換しています…');
          await DemoSort.flipAdjacentSwap(stack, s.lo);
          DemoSort.clearRoles(stack);
        }
        api.setCaption(
          'バケット ' +
            s.bucket +
            ': 位置 ' +
            s.lo +
            ' と ' +
            (s.lo + 1) +
            ' を交換'
        );
        return;
      }

      if (s.kind === 'bucket_done') {
        mountDemo(
          barsEl,
          baseView(s, { activeBucket: s.bucket })
        );
        api.setCaption(
          'バケット ' +
            s.bucket +
            ' の整列が完了（[' +
            s.buckets[s.bucket].join(', ') +
            ']）'
        );
        return;
      }

      if (s.kind === 'collect_scan') {
        mountDemo(
          barsEl,
          baseView(s, {
            outputMode: true,
            outputArr: s.outputArr,
            activeBucket: s.bucket,
          })
        );
        api.setCaption(
          'バケット ' + s.bucket + ' から値 ' + s.value + ' を回収'
        );
        return;
      }

      if (s.kind === 'collect_move') {
        const bucketsBefore = cloneBuckets(s.buckets);
        bucketsBefore[s.bucket].unshift(s.value);
        const outputBefore = s.outputArr.slice(0, -1);

        mountDemo(
          barsEl,
          baseView(s, {
            buckets: bucketsBefore,
            outputMode: true,
            outputArr: outputBefore,
            activeBucket: s.bucket,
          })
        );
        await nextFrame();
        const fromRect = elementRect(findBucketBar(wrap, s.bucket, 0));

        mountDemo(
          barsEl,
          baseView(s, {
            outputMode: true,
            outputArr: s.outputArr,
            hideOutputIdx: s.outputIdx,
            activeBucket: s.bucket,
          })
        );
        await nextFrame();
        const toRect = elementRect(findArrayBar(wrap, s.outputIdx));

        if (fromRect && toRect) {
          await flyBarRects(fromRect, toRect, s.value, scale, 'write');
        }

        mountDemo(
          barsEl,
          baseView(s, {
            outputMode: true,
            outputArr: s.outputArr,
            highlightIdx: s.outputIdx,
            highlightRole: 'write',
            activeBucket: s.bucket,
          })
        );
        api.setCaption('結果[' + s.outputIdx + '] ← ' + s.value);
        return;
      }

      if (s.kind === 'done') {
        mountDemo(
          barsEl,
          baseView(s, {
            buckets: s.buckets || emptyBuckets(s.arr.length),
            outputMode: true,
            outputArr: s.outputArr || s.arr,
            resultDone: true,
          })
        );
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="interpolation-sort-demo"
  data_prefix="interpolation"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[バケットソート](/2026/06/23/sort-bucket.html)も値域を等分して仕分けるが、バケット数は任意で、内部は一度の比較ソートで終えることが多い。

補間ソートはバケット数を `n` に固定し、補間式でインデックスを決め、大きいバケットへ同じ手続きを再帰する点が特徴である。

[フラッシュソート](/2026/07/09/sort-flash.html)はクラス数を $$O(\sqrt{n \log n})$$ 程度に抑え、インプレースの循環交換で集める。[プロックスマップソート](/2026/06/30/sort-proxmap.html)は近接写像で開始位置を決め、配置と挿入を同時に行う。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size | Average time (s) | Maximum time (s) | Average memory (KiB) | Maximum memory (KiB) |
|-----------:|-----------------:|-----------------:|---------------------:|---------------------:|
|        256 |         0.000011 |         0.000263 |                    8 |                    8 |
|        512 |         0.000013 |         0.000125 |                   16 |                   16 |
|       1024 |         0.000020 |         0.000208 |                   32 |                   32 |
|       2048 |         0.000045 |         0.001191 |                   64 |                   64 |
|       4096 |         0.000069 |         0.001253 |                  128 |                  128 |
|       8192 |         0.000132 |         0.001268 |                  256 |                  256 |
|      16384 |         0.000277 |         0.002273 |                  527 |                  527 |
|      32768 |         0.000525 |         0.005769 |                 1039 |                 1039 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="interpolation" %}
