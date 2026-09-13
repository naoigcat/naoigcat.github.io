---
title:     基数ソートで配列を並び替える
date:      2026-06-21 09:00:00 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## 基数ソートを使用する

基数ソート (`radix sort`) は、キーを桁（または固定幅のビット列）ごとに分割し、各桁についてカウンティングソートなどの安定な部分ソートを繰り返す。

桁をどの向きから見るかで、最下位桁優先（LSD; Least Significant Digit）と最上位桁優先（MSD; Most Significant Digit）に分かれる。どちらも「いま見ている桁の値 `0..r-1` で安定に仕分ける」点は共通である。

違うのは、全配列を下位から同じ回数だけ通すか、上位からバケット単位で再帰するかである。

最下位桁優先（LSD）の手順は次のとおりである。

1.  **桁の決定**: 最大値から必要な桁数（または基数 `r` に対するパス数）を求める。
2.  **桁ごとの安定ソート**: 現在の桁 `exp`（1, 10, 100, …）について、各要素のその桁の値 `0..r-1` をキーに安定なカウンティングソートを行う。
3.  **桁の更新**: `exp` を基数倍し、最上位桁まで 2 を繰り返す。

```pseudocode
procedure lsd_radix_sort(A)
  if length(A) = 0 then return
  maxVal = maximum(A)
  exp = 1
  while maxVal / exp > 0 do
    stable_counting_sort_by_digit(A, exp)
    exp = exp * 10
```

各桁パスはカウンティングソートと同様に、出現回数の集計・累積和・後方からの配置で構成される。最下位桁優先かつ各パスが安定であれば、上位桁の整列結果を下位桁のソートが壊さないため、全体が昇順になる。再帰は不要で、固定幅の整数向けの定番形である。

最上位桁優先（MSD）の手順は次のとおりである。

1.  **最上位桁の決定**: 最大値から最上位の桁重み `exp` を求める。
2.  **区間の安定仕分け**: いま見ている部分配列について、桁 `exp` の値ごとに安定なカウンティングソートで並べ替える。
3.  **バケットごとの再帰**: 同じ桁値の連続区間それぞれについて、`exp` を 10 で割った下位桁へ同じ処理を繰り返す。区間長が 1 以下、または桁が尽きたら終了する。

```pseudocode
procedure msd_radix_sort(A)
  if length(A) = 0 then return
  exp = highest_digit_weight(maximum(A))
  msd(A, 0, length(A), exp)

procedure msd(A, lo, hi, exp)
  if hi - lo <= 1 or exp < 1 then
    return
  stable_counting_sort_by_digit(A[lo .. hi), exp)
  for each digit-bucket B = [bLo, bHi) in A[lo .. hi)
    msd(A, bLo, bHi, exp / 10)
```

先頭桁でキーが分かれれば下位桁を見なくてよい。可変長キーや文字列にも向きやすい一方、制御は区間ごとの再帰になり、素朴形では補助配列を使った安定配置が中心になる。

桁数 d・基数 r ならいずれも $$O(d \cdot (n + r))$$ 程度であり、カウンティングソートより広い値域に適用しやすい。MSD は入力によっては一部の下位桁を省略できる。

キーの表現と基数の選び方に依存する点は共通で、負の数や浮動小数点は符号・指数・仮数部への分解など前処理が必要になる。

以下のデモは、上の配列から下の桁バケットへ移し、バケットを順に回収してから次の桁で同じことを繰り返す。ツールバーの LSD / MSD で走査の向きを切り替えられる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('radix-sort-demo', function (root) {
  const RADIX = 10;
  const DEMO_INITIAL = [54, 12, 38, 91, 27, 63, 45, 18, 72, 36, 84, 29];
  const CAPTION_LSD =
    '基数ソート（LSD）のデモ（下の桁バケットへ配り、回収してから次の桁へ）';
  const CAPTION_MSD =
    '基数ソート（MSD）のデモ（下の桁バケットへ配り、回収してから区間ごとに下位桁へ）';

  let mode = 'lsd';
  let demoScale = null;

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

  function digitName(exp) {
    if (exp === 1) {
      return '1の位';
    }
    if (exp === 10) {
      return '10の位';
    }
    if (exp === 100) {
      return '100の位';
    }
    return '桁の重み ' + exp;
  }

  function highestDigitWeight(maxVal) {
    let exp = 1;
    while (Math.floor(maxVal / (exp * 10)) > 0) {
      exp *= 10;
    }
    return exp;
  }

  function emptyBuckets() {
    const buckets = [];
    for (let d = 0; d < RADIX; d++) {
      buckets.push([]);
    }
    return buckets;
  }

  function cloneBuckets(buckets) {
    return buckets.map(function (bk) {
      return bk.slice();
    });
  }

  function valueScale(values) {
    const defined = [];
    for (let i = 0; i < values.length; i++) {
      if (values[i] != null && !Number.isNaN(values[i])) {
        defined.push(values[i]);
      }
    }
    if (!defined.length) {
      return { min: 10, max: 99, span: 89 };
    }
    const min = Math.min.apply(null, defined);
    const max = Math.max.apply(null, defined);
    return { min: min, max: max, span: Math.max(max - min, 1) };
  }

  function refreshDemoScale(values) {
    demoScale = valueScale(values && values.length ? values : DEMO_INITIAL);
  }

  refreshDemoScale(DEMO_INITIAL);

  function barHeightPx(value, scale) {
    return 28 + ((value - scale.min) / scale.span) * 92;
  }

  function scaledBarHeight(value, scale) {
    return barHeightPx(value, scale) + 'px';
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
    bar.className = 'sort-demo__bar';
    bar.style.height = scaledBarHeight(value, scale);
    bar.setAttribute('title', String(value));
    if (role) {
      bar.setAttribute('data-role', role);
    }
    return bar;
  }

  function mkBucketBar(value, scale) {
    const bar = document.createElement('div');
    bar.className = 'sort-demo__bar';
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
    let wrap = barsEl.querySelector('.postman-demo');
    if (wrap) {
      return wrap;
    }
    barsEl.innerHTML = '';
    wrap = document.createElement('div');
    wrap.className = 'postman-demo';

    const arraySection = document.createElement('section');
    arraySection.className = 'postman-demo__section';
    const arrayLabel = document.createElement('p');
    arrayLabel.className = 'postman-demo__section-label';
    arrayLabel.dataset.radixSection = 'array';
    arrayLabel.textContent = '配列';
    const arrayTrack = document.createElement('div');
    arrayTrack.className = 'postman-demo__track';
    arrayTrack.dataset.radixTrack = 'array';
    arraySection.appendChild(arrayLabel);
    arraySection.appendChild(arrayTrack);

    const bucketsSection = document.createElement('section');
    bucketsSection.className = 'postman-demo__section';
    const bucketsLabel = document.createElement('p');
    bucketsLabel.className = 'postman-demo__section-label';
    bucketsLabel.dataset.radixSection = 'buckets';
    bucketsLabel.textContent = '桁バケット';
    const bucketsTrack = document.createElement('div');
    bucketsTrack.className = 'postman-demo__buckets';
    bucketsTrack.dataset.radixTrack = 'buckets';
    bucketsSection.appendChild(bucketsLabel);
    bucketsSection.appendChild(bucketsTrack);

    wrap.appendChild(arraySection);
    wrap.appendChild(bucketsSection);
    barsEl.appendChild(wrap);
    return wrap;
  }

  function slotValue(view, i) {
    const arr = view.arr || [];
    if (view.hideBuckets) {
      return arr[i];
    }
    if (view.outputMode) {
      const out = view.outputArr || [];
      const lo = view.lo == null ? 0 : view.lo;
      const hi = view.hi == null ? arr.length - 1 : view.hi;
      if (i < lo || i > hi) {
        return arr[i];
      }
      const pos = i - lo;
      return pos < out.length ? out[pos] : null;
    }
    const lo = view.lo == null ? 0 : view.lo;
    const hi = view.hi == null ? arr.length - 1 : view.hi;
    const movedThrough =
      view.movedThroughIdx == null ? lo - 1 : view.movedThroughIdx;
    if (i >= lo && i <= hi && i <= movedThrough) {
      return null;
    }
    return arr[i];
  }

  function mountRadixDemo(barsEl, view) {
    const wrap = ensureLayout(barsEl);
    const arr = view.arr || [];
    const scale = demoScale;
    const arrayTrack = wrap.querySelector('[data-radix-track="array"]');
    const bucketsTrack = wrap.querySelector('[data-radix-track="buckets"]');
    const arrayLabel = wrap.querySelector('[data-radix-section="array"]');
    const bucketsLabel = wrap.querySelector('[data-radix-section="buckets"]');
    const idleBuckets = !!view.hideBuckets;
    const buckets = idleBuckets ? emptyBuckets() : view.buckets || emptyBuckets();
    const slotCount = Math.max(arr.length, 1);

    arrayLabel.textContent = view.outputMode ? '配列（回収中）' : '配列';
    if (view.exp != null && !idleBuckets) {
      bucketsLabel.textContent = '桁バケット（' + digitName(view.exp) + '）';
    } else {
      bucketsLabel.textContent = '桁バケット';
    }

    arrayTrack.innerHTML = '';
    bucketsTrack.innerHTML = '';

    arrayTrack.setAttribute('role', 'list');
    arrayTrack.setAttribute(
      'aria-label',
      '基数ソートの配列。棒の高さは値の大小、左から右へ位置0、1の順です。'
    );

    for (let i = 0; i < slotCount; i++) {
      const value = slotValue(view, i);
      let role = null;
      if (view.highlightIdx === i) {
        role = view.highlightRole || 'cursor';
      } else if (
        view.rangeLo != null &&
        view.rangeHi != null &&
        i >= view.rangeLo &&
        i <= view.rangeHi &&
        value != null &&
        view.highlightRange
      ) {
        role = 'range';
      }
      if (view.hideOutputIdx === i && value != null) {
        const stack = mkBarStack(value, scale, role, i);
        const bar = stack.querySelector('.sort-demo__bar:not([data-role="gap"])');
        if (bar) {
          bar.style.visibility = 'hidden';
        }
        arrayTrack.appendChild(stack);
      } else {
        arrayTrack.appendChild(mkBarStack(value, scale, role, i));
      }
    }

    for (let d = 0; d < RADIX; d++) {
      const bucketEl = document.createElement('div');
      bucketEl.className = 'postman-demo__bucket';
      if (!idleBuckets && view.activeDigit === d) {
        bucketEl.classList.add('postman-demo__bucket--active');
      }
      bucketEl.dataset.digit = String(d);

      const digitLabel = document.createElement('span');
      digitLabel.className = 'postman-demo__bucket-label';
      digitLabel.textContent = String(d);

      const stackEl = document.createElement('div');
      stackEl.className = 'postman-demo__bucket-stack';
      stackEl.dataset.bucketStack = String(d);
      stackEl.setAttribute('role', 'list');
      stackEl.setAttribute('aria-label', '桁 ' + d + ' のバケット');

      const items = buckets[d] || [];
      for (let j = 0; j < items.length; j++) {
        const bar = mkBucketBar(items[j], scale);
        if (
          !idleBuckets &&
          view.hideBucketBar &&
          view.hideBucketBar.digit === d &&
          view.hideBucketBar.stackPos === j
        ) {
          bar.style.visibility = 'hidden';
        }
        stackEl.appendChild(bar);
      }

      bucketEl.appendChild(stackEl);
      bucketEl.appendChild(digitLabel);
      bucketsTrack.appendChild(bucketEl);
    }
  }

  function findInputBar(wrap, idx) {
    return wrap.querySelector(
      '[data-input-idx="' + idx + '"] .sort-demo__bar:not([data-role="gap"])'
    );
  }

  function findBucketBar(wrap, digit, stackPos) {
    const stack = wrap.querySelector('[data-bucket-stack="' + digit + '"]');
    if (!stack) {
      return null;
    }
    const bars = stack.querySelectorAll('.sort-demo__bar');
    return bars[stackPos] || null;
  }

  function findArrayBar(wrap, idx) {
    const track = wrap.querySelector('[data-radix-track="array"]');
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
    ghost.style.height = scaledBarHeight(value, scale);
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

  function appendDistributeGather(arr, lo, hi, exp, steps) {
    const buckets = emptyBuckets();
    steps.push({
      kind: 'phase',
      phase: 'distribute',
      lo: lo,
      hi: hi,
      arr: arr.slice(),
      exp: exp,
      buckets: cloneBuckets(buckets),
      movedThroughIdx: lo - 1,
      rangeLo: lo,
      rangeHi: hi,
    });

    for (let i = lo; i <= hi; i++) {
      const value = arr[i];
      const digit = Math.floor(value / exp) % RADIX;
      steps.push({
        kind: 'assign_scan',
        idx: i,
        value: value,
        digit: digit,
        lo: lo,
        hi: hi,
        arr: arr.slice(),
        exp: exp,
        buckets: cloneBuckets(buckets),
        movedThroughIdx: i - 1,
        rangeLo: lo,
        rangeHi: hi,
      });
      buckets[digit].push(value);
      steps.push({
        kind: 'assign_move',
        idx: i,
        value: value,
        digit: digit,
        lo: lo,
        hi: hi,
        arr: arr.slice(),
        exp: exp,
        buckets: cloneBuckets(buckets),
        movedThroughIdx: i,
        bucketStackPos: buckets[digit].length - 1,
        rangeLo: lo,
        rangeHi: hi,
      });
    }

    steps.push({
      kind: 'phase',
      phase: 'gather',
      lo: lo,
      hi: hi,
      arr: arr.slice(),
      exp: exp,
      buckets: cloneBuckets(buckets),
      movedThroughIdx: hi,
      outputArr: [],
      rangeLo: lo,
      rangeHi: hi,
    });

    const working = cloneBuckets(buckets);
    const output = [];
    for (let d = 0; d < RADIX; d++) {
      while (working[d].length > 0) {
        const value = working[d][0];
        steps.push({
          kind: 'collect_scan',
          digit: d,
          value: value,
          lo: lo,
          hi: hi,
          arr: arr.slice(),
          exp: exp,
          buckets: cloneBuckets(working),
          outputArr: output.slice(),
          movedThroughIdx: hi,
          rangeLo: lo,
          rangeHi: hi,
        });
        working[d].shift();
        output.push(value);
        const writeIdx = lo + output.length - 1;
        arr[writeIdx] = value;
        steps.push({
          kind: 'collect_move',
          digit: d,
          value: value,
          lo: lo,
          hi: hi,
          arr: arr.slice(),
          exp: exp,
          buckets: cloneBuckets(working),
          outputArr: output.slice(),
          outputIdx: writeIdx,
          movedThroughIdx: hi,
          rangeLo: lo,
          rangeHi: hi,
        });
      }
    }

    return buckets;
  }

  function generateLsdSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }
    const maxVal = Math.max.apply(null, a);
    let exp = 1;
    while (Math.floor(maxVal / exp) > 0) {
      appendDistributeGather(a, 0, a.length - 1, exp, steps);
      steps.push({
        kind: 'pass_done',
        arr: a.slice(),
        exp: exp,
        lo: 0,
        hi: a.length - 1,
      });
      exp *= 10;
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function msdRecurse(arr, lo, hi, exp, steps) {
    if (hi - lo < 1 || exp < 1) {
      return;
    }
    const buckets = appendDistributeGather(arr, lo, hi, exp, steps);
    steps.push({
      kind: 'pass_done',
      arr: arr.slice(),
      exp: exp,
      lo: lo,
      hi: hi,
    });

    let offset = lo;
    for (let d = 0; d < RADIX; d++) {
      const bucketLen = buckets[d].length;
      if (bucketLen === 0) {
        continue;
      }
      const bucketLo = offset;
      const bucketHi = offset + bucketLen - 1;
      if (bucketLen > 1) {
        steps.push({
          kind: 'recurse',
          digit: d,
          lo: bucketLo,
          hi: bucketHi,
          arr: arr.slice(),
          exp: exp,
          buckets: emptyBuckets(),
          rangeLo: bucketLo,
          rangeHi: bucketHi,
          highlightRange: true,
        });
        msdRecurse(arr, bucketLo, bucketHi, Math.floor(exp / 10), steps);
      }
      offset += bucketLen;
    }
  }

  function generateMsdSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }
    const exp = highestDigitWeight(Math.max.apply(null, a));
    msdRecurse(a, 0, a.length - 1, exp, steps);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function generateSteps(initial) {
    return mode === 'msd' ? generateMsdSteps(initial) : generateLsdSteps(initial);
  }

  function modeCaption() {
    return mode === 'msd' ? CAPTION_MSD : CAPTION_LSD;
  }

  function idleView(vals) {
    return {
      arr: vals,
      buckets: emptyBuckets(),
      movedThroughIdx: -1,
      lo: 0,
      hi: vals.length - 1,
      hideBuckets: true,
    };
  }

  const toolbar = root.querySelector('.sort-demo__toolbar');
  const lsdBtn = document.createElement('button');
  lsdBtn.type = 'button';
  lsdBtn.textContent = 'LSD';
  lsdBtn.setAttribute('aria-pressed', 'true');
  lsdBtn.title = '最下位桁優先';

  const msdBtn = document.createElement('button');
  msdBtn.type = 'button';
  msdBtn.textContent = 'MSD';
  msdBtn.setAttribute('aria-pressed', 'false');
  msdBtn.title = '最上位桁優先';

  if (toolbar) {
    toolbar.insertBefore(msdBtn, toolbar.firstChild);
    toolbar.insertBefore(lsdBtn, toolbar.firstChild);
  }

  function syncModeButtons() {
    lsdBtn.setAttribute('aria-pressed', mode === 'lsd' ? 'true' : 'false');
    msdBtn.setAttribute('aria-pressed', mode === 'msd' ? 'true' : 'false');
  }

  const playback = DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-radix',
    initialValues: DEMO_INITIAL.slice(),
    initialCaption: CAPTION_LSD,
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    rebuild: function (api, v) {
      refreshDemoScale(v);
      api.values = v;
      api.steps = generateSteps(v);
      api.idx = 0;
      const first = api.steps[0];
      if (first && first.kind === 'phase') {
        mountRadixDemo(api.barsEl, first);
      } else {
        mountRadixDemo(api.barsEl, idleView(v));
      }
      api.setCaption(modeCaption());
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      const wrap = ensureLayout(barsEl);
      const scale = demoScale;

      if (s.kind === 'phase' && s.phase === 'distribute') {
        mountRadixDemo(barsEl, s);
        api.setCaption(
          digitName(s.exp) +
            ' で位置 ' +
            s.lo +
            '…' +
            s.hi +
            ' を下のバケットへ配ります'
        );
        return;
      }

      if (s.kind === 'phase' && s.phase === 'gather') {
        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: s.buckets,
          movedThroughIdx: s.movedThroughIdx,
          outputMode: true,
          outputArr: s.outputArr || [],
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          digitName(s.exp) +
            ' のバケットを 0…' +
            (RADIX - 1) +
            ' の順に配列へ回収します'
        );
        return;
      }

      if (s.kind === 'assign_scan') {
        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: s.buckets,
          movedThroughIdx: s.movedThroughIdx,
          highlightIdx: s.idx,
          highlightRole: 'cursor',
          activeDigit: s.digit,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          '位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' → ' +
            digitName(s.exp) +
            ' は ' +
            s.digit
        );
        return;
      }

      if (s.kind === 'assign_move') {
        const bucketsBefore = cloneBuckets(s.buckets);
        bucketsBefore[s.digit].pop();

        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: bucketsBefore,
          movedThroughIdx: s.movedThroughIdx - 1,
          highlightIdx: s.idx,
          highlightRole: 'cursor',
          activeDigit: s.digit,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        await nextFrame();
        const fromRect = elementRect(findInputBar(wrap, s.idx));

        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: s.buckets,
          movedThroughIdx: s.movedThroughIdx,
          activeDigit: s.digit,
          hideBucketBar: {
            digit: s.digit,
            stackPos: s.bucketStackPos,
          },
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        await nextFrame();
        const toRect = elementRect(
          findBucketBar(wrap, s.digit, s.bucketStackPos)
        );

        if (fromRect && toRect) {
          await flyBarRects(fromRect, toRect, s.value, scale, 'write');
        }

        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: s.buckets,
          movedThroughIdx: s.movedThroughIdx,
          activeDigit: s.digit,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          '値 ' + s.value + ' を桁 ' + s.digit + ' のバケットへ移しました'
        );
        return;
      }

      if (s.kind === 'collect_scan') {
        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: s.buckets,
          movedThroughIdx: s.movedThroughIdx,
          outputMode: true,
          outputArr: s.outputArr,
          activeDigit: s.digit,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          '桁 ' + s.digit + ' のバケットから値 ' + s.value + ' を回収'
        );
        return;
      }

      if (s.kind === 'collect_move') {
        const bucketsBefore = cloneBuckets(s.buckets);
        bucketsBefore[s.digit].unshift(s.value);
        const outputBefore = s.outputArr.slice(0, -1);

        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: bucketsBefore,
          movedThroughIdx: s.movedThroughIdx,
          outputMode: true,
          outputArr: outputBefore,
          activeDigit: s.digit,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        await nextFrame();
        const fromRect = elementRect(findBucketBar(wrap, s.digit, 0));

        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: s.buckets,
          movedThroughIdx: s.movedThroughIdx,
          outputMode: true,
          outputArr: s.outputArr,
          hideOutputIdx: s.outputIdx,
          activeDigit: s.digit,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        await nextFrame();
        const toRect = elementRect(findArrayBar(wrap, s.outputIdx));

        if (fromRect && toRect) {
          await flyBarRects(fromRect, toRect, s.value, scale, 'write');
        }

        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: s.buckets,
          movedThroughIdx: s.movedThroughIdx,
          outputMode: true,
          outputArr: s.outputArr,
          highlightIdx: s.outputIdx,
          highlightRole: 'write',
          activeDigit: s.digit,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          '値 ' + s.value + ' を位置 ' + s.outputIdx + ' へ書き戻しました'
        );
        return;
      }

      if (s.kind === 'pass_done') {
        mountRadixDemo(barsEl, {
          arr: s.arr,
          hideBuckets: true,
          rangeLo: s.lo,
          rangeHi: s.hi,
          highlightRange: true,
        });
        api.setCaption(digitName(s.exp) + ' のパスが完了しました');
        return;
      }

      if (s.kind === 'recurse') {
        mountRadixDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: emptyBuckets(),
          movedThroughIdx: s.lo - 1,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
          highlightRange: true,
        });
        api.setCaption(
          '桁 ' +
            s.digit +
            ' の区間（位置 ' +
            s.lo +
            '…' +
            s.hi +
            '）を下位桁で続けます'
        );
        return;
      }

      if (s.kind === 'done') {
        mountRadixDemo(barsEl, {
          arr: s.arr,
          hideBuckets: true,
        });
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: function (api) {
      const s = api.steps[api.idx - 1];
      if (s && (s.kind === 'assign_move' || s.kind === 'collect_move')) {
        return 420;
      }
      return 280;
    },
  });

  function modeSwitchAllowed() {
    const pause = root.querySelector('[data-radix="pause"]');
    const shuffle = root.querySelector('[data-radix="shuffle"]');
    if (pause && !pause.disabled) {
      return false;
    }
    if (shuffle && shuffle.disabled) {
      return false;
    }
    return true;
  }

  function setMode(next) {
    if (mode === next || !playback) {
      return;
    }
    if (!modeSwitchAllowed()) {
      return;
    }
    mode = next;
    syncModeButtons();
    playback.rebuild();
  }

  lsdBtn.addEventListener('click', function () {
    setMode('lsd');
  });
  msdBtn.addEventListener('click', function () {
    setMode('msd');
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="radix-sort-demo"
  data_prefix="radix"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[カウンティングソート](/2026/06/20/sort-counting.html)は値そのものをインデックスにする。基数ソートは桁ごとに同じ集計を繰り返し、値域が広くても桁数分のパスで済ませる。

本稿の LSD は全配列を下位桁から同じ回数だけ安定ソートする。MSD は上位桁から区間を分けて再帰する。どちらもカウンティングによる安定配置が中心である。

[ポストマンソート](/2026/08/24/sort-postman.html)は最上位桁優先の配布を郵便の仕分けに例える。本稿の MSD と同じトップダウンだが、比喩と補助リストへの配布が前面に出る。

[アメリカ国旗ソート](/2026/07/02/sort-american-flag.html)も最上位桁優先だが、補助配列ではなくインプレースでバケット境界へ集める。

[バイナリクイックソート](/2026/08/13/sort-binary-quick.html)は最上位ビットからの 2 分割である。本稿の MSD は十進の多区分カウンティングが中心で、安定性も補助領域も異なる。

[トライソート](/2026/07/11/sort-trie.html)は桁による区分は同型だが、木を組み立ててから走査する。

[キャッシュ効率型基数ソート](/2026/08/04/sort-cradix.html)は MSD 側でキーバッファによりキャッシュミスを抑える。本稿の素朴形はキー本体を都度読む。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000002 |        0.000048 |               2 |               2 |
|        512 |        0.000004 |        0.000049 |               4 |               4 |
|       1024 |        0.000012 |        0.000058 |               8 |               8 |
|       2048 |        0.000020 |        0.000067 |              16 |              16 |
|       4096 |        0.000036 |        0.000223 |              32 |              32 |
|       8192 |        0.000076 |        0.000256 |              64 |              64 |
|      16384 |        0.000239 |        0.000393 |             128 |             128 |
|      32768 |        0.000385 |        0.001273 |             256 |             256 |
|      65536 |        0.000726 |        0.001283 |             512 |             512 |
|     131072 |        0.001900 |        0.003144 |            1024 |            1024 |
|     262144 |        0.003535 |        0.009127 |            2048 |            2048 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="radix" %}
