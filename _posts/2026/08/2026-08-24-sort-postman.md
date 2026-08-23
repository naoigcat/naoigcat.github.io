---
title:     ポストマンソートで配列を並び替える
date:      2026-08-24 05:51:22 +0900
tags:      sort
sort_demo: true
---

## ポストマンソートを使用する

ポストマンソート (`postman's sort`) は、キーを階層的な属性（文字・桁・地域コードなど）として扱い、最上位の属性から順にバケットへ配り、各バケットを次の属性で再帰的に仕分ける分布型の整列である。郵便区分機が郵便番号の上位桁／集配局／町域／配達順と段階的に手紙を振り分ける様子に例えられる。

トップダウン（最上位桁優先）の基数ソートの工学的変種とされ、要素同士を比較せずバケットへ配るため、キー幅とバケット数に依存する係数 `c` に対し時間は `O(c · n)` と説明される。

1.  **属性（桁）の選択**: 最上位の記号から処理する。部分列が十分小さければ挿入ソートなどで終える。
2.  **バケットへの配布**: 現在位置の記号 `0..σ-1` ごとに補助リストへ要素を追加する（デモでは十進桁で `σ = 10`）。
3.  **再帰**: 要素が 2 個以上ある各バケットについて、次の記号位置で手順 1〜2 を繰り返す。
4.  **連結**: 記号 `0, 1, …` の順にバケットを並べれば、全体が昇順になる。

```pseudocode
procedure postman_sort(A, exp)
  if length(A) <= THRESHOLD then
    insertion_sort(A)
    return
  if exp = 0 then
    return
  buckets = empty list of σ arrays
  for each x in A
    append x to buckets[digit(x, exp)]
  out = empty list
  for d from 0 to σ - 1
    if length(buckets[d]) > 1 then
      postman_sort(buckets[d], next_exp(exp))
    append buckets[d] to out
  A = out
```

整数キーを `usize` として整列するときは、最上位バイトから下位バイトへと記号を取り、`σ = 256` として上記を適用するのが典型である（下の計測コードもこの方式）。デモは視認性のため十進の各桁を上位から同じ手順で示す。

記号幅を `w`、記号集合サイズを `σ` とすると時間はおおよそ `O(w · (n + σ))`、補助空間はバケット分 `O(n + σ)` である。配布を入力順に行い同記号の相対順を保てば安定ソートになる。

郵便の住所のように属性が階層になっているデータや、可変長キーを上位から切りたい場面向きである。固定幅整数なら [アメリカ国旗ソート](/2026/07/02/sort-american-flag.html) のようなインプレース MSD も選択肢になる。

以下のデモでは 2 桁の整数を十進の十の位・一の位の順に下のバケットへ配り、連結してから下位桁で再帰する。「シャッフル」で別の並びに差し替えられます。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('postman-sort-demo', function (root) {
  const THRESHOLD = 2;
  const RADIX = 10;
  const ARRAY_LEN = 12;
  const DEMO_INITIAL = [52, 17, 83, 41, 29, 65, 38, 74, 16, 91, 47, 23];
  const CAPTION =
    'ポストマンソートのデモ（上の配列から下の桁バケットへ移動し、連結して再帰）';

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
    return '桁の重み ' + exp;
  }

  function maxDigitExp(values) {
    let maxVal = 0;
    for (let i = 0; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
      }
    }
    let exp = 1;
    while (exp * 10 <= maxVal) {
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

  function randomTwoDigitArray(len) {
    const a = [];
    for (let i = 0; i < len; i++) {
      a.push(Math.floor(Math.random() * 90) + 10);
    }
    return a;
  }

  function valueScale(values) {
    if (!values.length) {
      return { min: 10, max: 99, span: 89 };
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
    arrayLabel.dataset.postmanSection = 'array';
    arrayLabel.textContent = '配列';
    const arrayTrack = document.createElement('div');
    arrayTrack.className = 'postman-demo__track postman-demo__array';
    arrayTrack.dataset.postmanTrack = 'array';
    arraySection.appendChild(arrayLabel);
    arraySection.appendChild(arrayTrack);

    const bucketsSection = document.createElement('section');
    bucketsSection.className = 'postman-demo__section';
    const bucketsLabel = document.createElement('p');
    bucketsLabel.className = 'postman-demo__section-label';
    bucketsLabel.dataset.postmanSection = 'buckets';
    bucketsLabel.textContent = '桁バケット';
    const bucketsTrack = document.createElement('div');
    bucketsTrack.className = 'postman-demo__buckets';
    bucketsTrack.dataset.postmanTrack = 'buckets';
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

  function mountPostmanDemo(barsEl, view) {
    const wrap = ensureLayout(barsEl);
    const arr = view.arr || [];
    const scale = valueScale(arr.length ? arr : DEMO_INITIAL);
    const arrayTrack = wrap.querySelector('[data-postman-track="array"]');
    const bucketsTrack = wrap.querySelector('[data-postman-track="buckets"]');
    const arrayLabel = wrap.querySelector('[data-postman-section="array"]');
    const bucketsLabel = wrap.querySelector('[data-postman-section="buckets"]');
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
    bucketsTrack.style.display = '';
    bucketsLabel.style.display = '';

    arrayTrack.setAttribute('role', 'list');
    arrayTrack.setAttribute(
      'aria-label',
      'ポストマンソートの配列。棒の高さは値の大小、左から右へ位置0、1の順です。'
    );

    for (let i = 0; i < slotCount; i++) {
      const value = slotValue(view, i);
      let role = null;
      if (view.highlightIdx === i) {
        role = view.highlightRole || 'cursor';
      } else if (
        view.rangeLo != null &&
        view.rangeHi != null &&
        (i === view.rangeLo || i === view.rangeHi) &&
        value != null
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
    const track = wrap.querySelector('[data-postman-track="array"]');
    if (!track || !track.children[idx]) {
      return null;
    }
    return track.children[idx].querySelector(
      '.sort-demo__bar:not([data-role="gap"])'
    );
  }

  function findArrayTrack(wrap) {
    return wrap.querySelector('[data-postman-track="array"]');
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

  function insertionSortRange(arr, lo, hi, steps, exp) {
    for (let j = lo + 1; j <= hi; j++) {
      let k = j;
      while (k > lo && arr[k - 1] > arr[k]) {
        steps.push({
          kind: 'compare',
          lo: k - 1,
          hi: k,
          arr: arr.slice(),
          exp: exp,
          rangeLo: lo,
          rangeHi: hi,
        });
        const t = arr[k - 1];
        arr[k - 1] = arr[k];
        arr[k] = t;
        steps.push({
          kind: 'swap',
          lo: k - 1,
          hi: k,
          arr: arr.slice(),
          exp: exp,
          rangeLo: lo,
          rangeHi: hi,
        });
        k--;
      }
    }
  }

  function postmanRecurse(arr, lo, hi, exp, steps) {
    const len = hi - lo + 1;
    if (len <= 1) {
      return;
    }
    if (len <= THRESHOLD || exp < 1) {
      steps.push({
        kind: 'leaf',
        lo: lo,
        hi: hi,
        arr: arr.slice(),
        exp: exp,
        rangeLo: lo,
        rangeHi: hi,
      });
      insertionSortRange(arr, lo, hi, steps, exp);
      steps.push({
        kind: 'leaf_done',
        lo: lo,
        hi: hi,
        arr: arr.slice(),
        exp: exp,
        rangeLo: lo,
        rangeHi: hi,
      });
      return;
    }

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
        });
        postmanRecurse(arr, bucketLo, bucketHi, Math.floor(exp / 10), steps);
      }
      offset += bucketLen;
    }
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }
    const exp = maxDigitExp(a);
    postmanRecurse(a, 0, a.length - 1, exp, steps);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-postman',
    initialValues: DEMO_INITIAL.slice(),
    initialCaption: CAPTION,
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    rebuild: function (api) {
      const vals = randomTwoDigitArray(ARRAY_LEN);
      api.values = vals;
      api.steps = generateSteps(vals);
      api.idx = 0;
      const first = api.steps[0];
      if (first && first.kind === 'phase') {
        mountPostmanDemo(api.barsEl, first);
      } else {
        mountPostmanDemo(api.barsEl, {
          arr: vals,
          buckets: emptyBuckets(),
          movedThroughIdx: -1,
          lo: 0,
          hi: vals.length - 1,
          hideBuckets: true,
        });
      }
      api.setCaption(CAPTION);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      const wrap = ensureLayout(barsEl);
      const scale = valueScale(s.arr || DEMO_INITIAL);

      if (s.kind === 'phase' && s.phase === 'distribute') {
        mountPostmanDemo(barsEl, s);
        api.setCaption(
          digitName(s.exp) +
            ' で位置 ' +
            s.lo +
            '…' +
            s.hi +
            ' を下の ' +
            RADIX +
            ' 個のバケットへ配ります'
        );
        return;
      }

      if (s.kind === 'phase' && s.phase === 'gather') {
        mountPostmanDemo(barsEl, {
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
        mountPostmanDemo(barsEl, {
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

        mountPostmanDemo(barsEl, {
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

        mountPostmanDemo(barsEl, {
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

        mountPostmanDemo(barsEl, {
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
        mountPostmanDemo(barsEl, {
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

        mountPostmanDemo(barsEl, {
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

        mountPostmanDemo(barsEl, {
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

        mountPostmanDemo(barsEl, {
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

      if (s.kind === 'recurse') {
        mountPostmanDemo(barsEl, {
          arr: s.arr,
          lo: s.lo,
          hi: s.hi,
          exp: s.exp,
          buckets: emptyBuckets(),
          movedThroughIdx: s.lo - 1,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          '桁 ' +
            s.digit +
            ' の区間（位置 ' +
            s.lo +
            '…' +
            s.hi +
            '）を下位桁で再帰'
        );
        return;
      }

      if (s.kind === 'leaf') {
        mountPostmanDemo(barsEl, {
          arr: s.arr,
          hideBuckets: true,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
          highlightIdx: s.lo,
          highlightRole: 'range',
        });
        api.setCaption(
          '小さな区間（位置 ' + s.lo + '…' + s.hi + '）を挿入ソート'
        );
        return;
      }

      if (s.kind === 'compare') {
        mountPostmanDemo(barsEl, {
          arr: s.arr,
          hideBuckets: true,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        const track = findArrayTrack(wrap);
        if (track) {
          DemoSort.assignRoles(track, [
            [s.lo, 'compare'],
            [s.hi, 'compare'],
          ]);
        }
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }

      if (s.kind === 'swap') {
        const track = findArrayTrack(wrap);
        if (track) {
          DemoSort.assignRoles(track, [
            [s.lo, 'swap'],
            [s.hi, 'swap'],
          ]);
          api.setCaption('交換しています…');
          await DemoSort.flipAdjacentSwap(track, s.lo);
          DemoSort.clearRoles(track);
        }
        mountPostmanDemo(barsEl, {
          arr: s.arr,
          hideBuckets: true,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }

      if (s.kind === 'leaf_done') {
        mountPostmanDemo(barsEl, {
          arr: s.arr,
          hideBuckets: true,
          rangeLo: s.rangeLo,
          rangeHi: s.rangeHi,
        });
        api.setCaption(
          '葉区間（位置 ' + s.lo + '…' + s.hi + '）の整列が完了'
        );
        return;
      }

      if (s.kind === 'done') {
        mountPostmanDemo(barsEl, {
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
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="postman-sort-demo"
  data_prefix="postman"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[バケットソート](/2026/06/23/sort-bucket.html)は値域を一度だけ等分してから各バケットを別ソートする。

[バーストソート](/2026/07/12/sort-burst.html)は閾値を超えたときだけ下位桁へトライを伸ばす。

[アメリカ国旗ソート](/2026/07/02/sort-american-flag.html)は同じ MSD の多区分だが、補助リストではなくインプレースでバケット境界へ集める。

[基数ソート](/2026/06/21/sort-radix.html)の記事は LSD 中心で、ポストマンはトップダウン（MSD）の配布である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000028 |        0.003066 |              22 |              22 |
|        512 |        0.000038 |        0.002309 |              36 |              36 |
|       1024 |        0.000054 |        0.000117 |              64 |              64 |
|       2048 |        0.000115 |        0.000258 |             120 |             120 |
|       4096 |        0.000207 |        0.000337 |             232 |             232 |
|       8192 |        0.000405 |        0.001489 |             456 |             456 |
|      16384 |        0.000761 |        0.002211 |             904 |             904 |
|      32768 |        0.001540 |        0.007308 |            1800 |            1800 |
|      65536 |        0.003467 |        0.013471 |            3592 |            3592 |
|     131072 |        0.006973 |        0.020928 |            6664 |            6664 |
|     262144 |        0.014685 |        0.068146 |           12808 |           12808 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="postman" %}
