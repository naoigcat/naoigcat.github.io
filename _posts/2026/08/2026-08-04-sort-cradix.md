---
title:     キャッシュ効率型基数ソートで配列を並び替える
date:      2026-08-04 23:25:15 +0900
tags:      sort
sort_demo: true
---

## キャッシュ効率型基数ソートを使用する

キャッシュ効率型基数ソート (`CRadix sort`) は、MSD（最上位桁優先）基数ソートをキャッシュミスが少なくなるよう改めた文字列整列向けのアルゴリズムである。

通常の MSD 基数ソートでは、文字列そのものではなく「各文字列へのポインタ」の配列を並べ替えることが多い。ポインタ配列は連続に読めても、各ポインタの先にある文字列はメモリ上の別々の場所にある。桁を調べるたびにその先へ辿ると、アクセス先が飛び飛びになりキャッシュミスが増えやすい。

キャッシュ効率型基数ソートは、各キーに短いキーバッファを割り当て、先に使う数桁をそこへコピーしてから区分する。並べ替えではポインタ（本記事では整数キーそのもの）と対応するバッファを同じ順番で動かす。次の桁はばらばらの文字列を追い直さず、並んだバッファを順に読めばよいので、キャッシュに載りやすい。

手順は次のとおりである。

1.  **キーバッファの確保**: キーごとに長さ `bs` のバッファを用意する。理論上の目安はアルファベットサイズ `m`・件数 `n` に対しおよそ `log n / log m` だが、実装では小さな定数（本記事では `bs = 2`）で足りることが多い。
2.  **バッファへの読込み**: まだ見ていない桁のうち先頭 `bs` 個を各バッファへコピーする。キー本体へのアクセスはこのタイミングに寄せる。
3.  **バッファ先頭桁での区分**: MSD と同様、バッファの先頭文字（桁）`0..r-1` で安定にバケット分けする。キーポインタ（本記事では整数キーそのもの）とバッファブロックを同じ順で入れ替える。
4.  **使用済み桁の廃棄**: 調べた桁をバッファ先頭から捨て、残りを前へ詰める。次のパスでも常に先頭だけ見ればよい。
5.  **再充填と再帰**: バッファが空になったら次の `bs` 桁を読み直す。要素が 2 個以上残る各バケットについて、下位桁で 3〜5 を繰り返す。

```pseudocode
procedure cradix_sort(A)
  if length(A) = 0 then return
  width = digit_width(maximum(A))
  B[i] = fill_buffer(A[i], start=0, width) for each i
  cradix(A, B, digit_pos=0, width)

procedure cradix(A, B, digit_pos, width)
  if length(A) <= 1 or digit_pos >= width then return
  stable_partition A and B by B[i][0]
  for each non-empty bucket S
    discard_front_digit(B in S)
    next = digit_pos + 1
    if next >= width then continue
    if next mod bs = 0 then
      refill B[i] from A[i] at digit next
    cradix(S, B in S, next, width)
```

桁数を `w`、基数を `r` とすると時間計算量は通常の MSD と同様に `O(w · (n + r))` 程度である。追加でキーバッファ `O(bs · n)` と区分用の作業領域を要する。各パスが安定なら全体も安定になる。

本記事と計測コードでは、サイト共通の整数配列向けに十進桁へ写した簡略版を用いる。文字列ポインタ版と同じく「キーとバッファを同じ順で動かす」点が中心で、素朴な LSD 基数ソートとは設計目標が異なる。

以下のデモでは 3 桁の整数を `bs = 2` で扱う。棒の上の括弧内がキーバッファの中身である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('cradix-sort-demo', function (root) {
  const RADIX = 10;
  const BS = 2;

  function digitWidth(maxVal) {
    if (maxVal <= 0) {
      return 1;
    }
    let w = 0;
    let v = maxVal;
    while (v > 0) {
      w += 1;
      v = Math.floor(v / RADIX);
    }
    return w;
  }

  function digitAt(value, pos, width) {
    let div = 1;
    let p;
    for (p = 0; p < width - 1 - pos; p++) {
      div *= RADIX;
    }
    return Math.floor(value / div) % RADIX;
  }

  function fillBuffer(value, start, width) {
    const buf = [];
    let i;
    for (i = 0; i < BS; i++) {
      if (start + i < width) {
        buf.push(digitAt(value, start + i, width));
      } else {
        buf.push(0);
      }
    }
    return buf;
  }

  function formatBuffer(buf) {
    return buf.join('');
  }

  function formatCounts(count) {
    const parts = [];
    let d;
    for (d = 0; d < count.length; d++) {
      if (count[d] > 0) {
        parts.push('桁 ' + d + ' → ' + count[d] + ' 個');
      }
    }
    return parts.length ? parts.join('、') : '（まだなし）';
  }

  function valueSpan(values) {
    const defined = [];
    let vi;
    for (vi = 0; vi < values.length; vi++) {
      if (values[vi] != null && !Number.isNaN(values[vi])) {
        defined.push(values[vi]);
      }
    }
    if (!defined.length) {
      return null;
    }
    const min = Math.min(...defined);
    const max = Math.max(...defined);
    return {
      min: min,
      max: max,
      span: Math.max(max - min, 1),
    };
  }

  function buildBucketRanges(offset, count) {
    const ranges = [];
    let tone = 0;
    let r;
    for (r = 0; r < count.length; r++) {
      if (count[r] === 0) {
        continue;
      }
      ranges.push({
        start: offset[r],
        end: offset[r] + count[r],
        tone: tone % 6,
      });
      tone += 1;
    }
    return ranges;
  }

  function applyBucketTones(container, bucketRanges) {
    const stacks = container.children;
    let i;
    for (i = 0; i < stacks.length; i++) {
      stacks[i].removeAttribute('data-bucket-tone');
    }
    if (!bucketRanges) {
      return;
    }
    let ri;
    for (ri = 0; ri < bucketRanges.length; ri++) {
      const range = bucketRanges[ri];
      const tone = String(range.tone);
      for (i = range.start; i < range.end; i++) {
        if (stacks[i]) {
          stacks[i].setAttribute('data-bucket-tone', tone);
        }
      }
    }
  }

  function updateCradixStack(stack, index, value, buffer, scale, role) {
    const label = stack.querySelector('.sort-demo__bar-value');
    const bufLabel = stack.querySelector('.sort-demo__bar-buffer');
    const bar = stack.querySelector('.sort-demo__bar');
    if (!label || !bufLabel || !bar) {
      return;
    }

    stack.removeAttribute('data-role');
    if (value != null && !Number.isNaN(value)) {
      label.textContent = String(value);
      bufLabel.textContent = '〔' + formatBuffer(buffer || [0, 0]) + '〕';
      stack.classList.remove('sort-demo__bar-stack--empty');
      bar.style.visibility = '';
      bar.style.height = 28 + ((value - scale.min) / scale.span) * 92 + 'px';
      bar.style.opacity = '';
      bar.setAttribute('title', String(value));
      const valueText = String(value) + ' バッファ ' + formatBuffer(buffer || [0, 0]);
      stack.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(index, valueText, role)
      );
      if (role) {
        stack.setAttribute('data-role', role);
      }
      return;
    }

    label.textContent = '\u00a0';
    bufLabel.textContent = '\u00a0';
    stack.classList.add('sort-demo__bar-stack--empty');
    bar.style.visibility = 'hidden';
    bar.style.height = '0px';
    bar.style.opacity = '';
    bar.removeAttribute('title');
    stack.setAttribute(
      'aria-label',
      DemoSort.barAccessibilityLabel(index, '未配置', role)
    );
    if (role) {
      stack.setAttribute('data-role', role);
    }
  }

  function mountCradixBars(container, values, buffers, bucketRanges, scale) {
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }

    const resolvedScale =
      scale || valueSpan(values) || { min: 0, max: 0, span: 1 };
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      'キャッシュ効率型基数ソートの棒。値とキーバッファを表示し、左から位置0、1…の順です。'
    );

    let i;
    for (i = 0; i < values.length; i++) {
      const stack = document.createElement('div');
      stack.className = 'sort-demo__bar-stack';
      stack.setAttribute('role', 'listitem');

      const label = document.createElement('span');
      label.className = 'sort-demo__bar-value';

      const bufLabel = document.createElement('span');
      bufLabel.className = 'sort-demo__bar-buffer';

      const bar = document.createElement('div');
      bar.className = 'sort-demo__bar';

      stack.appendChild(label);
      stack.appendChild(bufLabel);
      stack.appendChild(bar);
      container.appendChild(stack);

      updateCradixStack(
        stack,
        i,
        values[i],
        buffers[i],
        resolvedScale,
        null
      );
    }

    applyBucketTones(container, bucketRanges);
  }

  function clearCradixRoles(container) {
    const stacks = container.children;
    let si;
    for (si = 0; si < stacks.length; si++) {
      stacks[si].removeAttribute('data-role');
      const label = stacks[si].querySelector('.sort-demo__bar-value');
      const bufLabel = stacks[si].querySelector('.sort-demo__bar-buffer');
      const valueText =
        (label && label.textContent.trim() ? label.textContent.trim() : '') +
        (bufLabel && bufLabel.textContent.trim()
          ? ' バッファ ' + bufLabel.textContent.replace(/[〔〕]/g, '')
          : '');
      stacks[si].setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(si, valueText, null)
      );
    }
  }

  function assignCradixRoles(container, pairs, opts) {
    if (!container) {
      return;
    }
    const options = opts || {};
    const preserve = options.preserve;
    const stacks = container.children;
    let i;
    for (i = 0; i < stacks.length; i++) {
      const current = stacks[i].getAttribute('data-role');
      if (current == null) {
        continue;
      }
      if (!preserve || preserve.indexOf(current) === -1) {
        stacks[i].removeAttribute('data-role');
      }
    }
    if (!pairs) {
      clearCradixRoles(container);
      return;
    }
    for (i = 0; i < pairs.length; i++) {
      const idx = pairs[i][0];
      if (idx == null) {
        continue;
      }
      const stack = stacks[idx];
      if (!stack) {
        continue;
      }
      stack.setAttribute('data-role', pairs[i][1]);
      const label = stack.querySelector('.sort-demo__bar-value');
      const bufLabel = stack.querySelector('.sort-demo__bar-buffer');
      const valueText =
        (label && label.textContent.trim() ? label.textContent.trim() : '') +
        (bufLabel && bufLabel.textContent.trim()
          ? ' バッファ ' + bufLabel.textContent.replace(/[〔〕]/g, '')
          : '');
      stack.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(idx, valueText, pairs[i][1])
      );
    }
  }

  function cloneBuffers(buffers) {
    return buffers.map(function (b) {
      return b ? b.slice() : null;
    });
  }

  let barScale = { min: 0, max: 0, span: 1 };

  function renderBars(barsEl, s) {
    mountCradixBars(
      barsEl,
      s.arr,
      s.buffers ||
        s.arr.map(function () {
          return null;
        }),
      s.bucketRanges || null,
      barScale
    );
  }

  function generateSteps(initial) {
    const steps = [];
    const a = initial.slice();
    barScale = valueSpan(a) || { min: 0, max: 0, span: 1 };
    const width = digitWidth(Math.max(...a));
    const buffers = a.map(function (v) {
      return fillBuffer(v, 0, width);
    });

    steps.push({
      kind: 'fill',
      text: 'キーバッファへ先頭 ' + BS + ' 桁を読み込む（幅 ' + width + '）',
      arr: a.slice(),
      buffers: cloneBuffers(buffers),
    });

    function cradix(lo, hi, digitPos) {
      const len = hi - lo + 1;
      if (len <= 1 || digitPos >= width) {
        return;
      }

      steps.push({
        kind: 'phase',
        text:
          '位置 ' +
          lo +
          '…' +
          hi +
          ' をバッファ先頭桁（全体の桁位置 ' +
          digitPos +
          '）で区分',
        lo: lo,
        hi: hi,
        digitPos: digitPos,
        arr: a.slice(),
        buffers: cloneBuffers(buffers),
      });

      const count = new Array(RADIX).fill(0);
      let i;
      for (i = lo; i <= hi; i++) {
        const digit = buffers[i][0];
        steps.push({
          kind: 'count_scan',
          idx: i,
          digit: digit,
          digitPos: digitPos,
          arr: a.slice(),
          buffers: cloneBuffers(buffers),
          count: count.slice(),
        });
        count[digit] += 1;
        steps.push({
          kind: 'count_bump',
          idx: i,
          digit: digit,
          digitPos: digitPos,
          arr: a.slice(),
          buffers: cloneBuffers(buffers),
          count: count.slice(),
        });
      }

      const offset = new Array(RADIX);
      offset[0] = lo;
      let r;
      for (r = 1; r < RADIX; r++) {
        offset[r] = offset[r - 1] + count[r - 1];
      }

      steps.push({
        kind: 'count_done',
        lo: lo,
        hi: hi,
        digitPos: digitPos,
        arr: a.slice(),
        buffers: cloneBuffers(buffers),
        count: count.slice(),
        offset: offset.slice(),
      });

      const srcA = a.slice(lo, hi + 1);
      const srcB = cloneBuffers(buffers.slice(lo, hi + 1));
      const outA = a.slice();
      const outB = cloneBuffers(buffers);
      for (i = lo; i <= hi; i++) {
        outA[i] = null;
        outB[i] = null;
      }

      const bucketRanges = buildBucketRanges(offset, count);
      steps.push({
        kind: 'place_start',
        text:
          'バッファ先頭桁で安定に配置する（' + formatCounts(count) + '）',
        lo: lo,
        hi: hi,
        digitPos: digitPos,
        arr: outA.slice(),
        buffers: cloneBuffers(outB),
        count: count.slice(),
        bucketRanges: bucketRanges,
      });

      const cursor = offset.slice();
      for (i = 0; i < srcA.length; i++) {
        const digit = srcB[i][0];
        const pos = cursor[digit];
        outA[pos] = srcA[i];
        outB[pos] = srcB[i].slice();
        cursor[digit] += 1;
        steps.push({
          kind: 'place',
          from: lo + i,
          pos: pos,
          value: srcA[i],
          digit: digit,
          digitPos: digitPos,
          arr: outA.slice(),
          buffers: cloneBuffers(outB),
          count: count.slice(),
          bucketRanges: bucketRanges,
        });
      }

      for (i = lo; i <= hi; i++) {
        a[i] = outA[i];
        buffers[i] = outB[i];
      }

      steps.push({
        kind: 'partition_done',
        text: 'バッファ先頭桁での区分が完了: ' + formatCounts(count),
        lo: lo,
        hi: hi,
        digitPos: digitPos,
        arr: a.slice(),
        buffers: cloneBuffers(buffers),
        count: count.slice(),
        bucketRanges: bucketRanges,
      });

      for (r = 0; r < RADIX; r++) {
        if (count[r] <= 1) {
          continue;
        }
        const start = offset[r];
        const end = start + count[r] - 1;
        const nextPos = digitPos + 1;
        if (nextPos >= width) {
          continue;
        }

        for (i = start; i <= end; i++) {
          buffers[i] = buffers[i].slice(1).concat([0]);
        }
        steps.push({
          kind: 'discard',
          text:
            'バケット ' +
            r +
            ' で使用済み桁を廃棄（次の桁位置 ' +
            nextPos +
            '）',
          lo: start,
          hi: end,
          digitPos: nextPos,
          arr: a.slice(),
          buffers: cloneBuffers(buffers),
          bucketRanges: bucketRanges,
        });

        if (nextPos % BS === 0) {
          for (i = start; i <= end; i++) {
            buffers[i] = fillBuffer(a[i], nextPos, width);
          }
          steps.push({
            kind: 'refill',
            text:
              'キーバッファを桁位置 ' +
              nextPos +
              ' から再充填（バケット ' +
              r +
              '）',
            lo: start,
            hi: end,
            digitPos: nextPos,
            arr: a.slice(),
            buffers: cloneBuffers(buffers),
            bucketRanges: bucketRanges,
          });
        }

        cradix(start, end, nextPos);
      }
    }

    if (a.length > 0) {
      cradix(0, a.length - 1, 0);
    }
    steps.push({
      kind: 'done',
      arr: a.slice(),
      buffers: cloneBuffers(buffers),
    });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-cradix',
    initialValues: [540, 123, 381, 917, 275, 634, 458, 182, 726, 364, 509, 241],
    getBarsEl: function (r) {
      return r.querySelector('[data-cradix="bars"]');
    },
    generateSteps: generateSteps,
    afterRebuild: function (api) {
      renderBars(
        api.barsEl,
        api.steps[0] ? api.steps[0] : { arr: api.values }
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'fill' || s.kind === 'phase') {
        renderBars(barsEl, s);
        clearCradixRoles(barsEl);
        if (s.lo != null) {
          const pairs = [];
          let i;
          for (i = s.lo; i <= s.hi; i++) {
            pairs.push([i, 'range']);
          }
          assignCradixRoles(barsEl, pairs);
        }
        api.setCaption(s.text || '');
        return;
      }
      if (s.kind === 'count_scan' || s.kind === 'count_bump') {
        renderBars(barsEl, s);
        assignCradixRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          'バッファ先頭桁 ' +
            s.digit +
            ' を集計（' +
            formatCounts(s.count) +
            '）'
        );
        return;
      }
      if (s.kind === 'count_done') {
        renderBars(barsEl, s);
        clearCradixRoles(barsEl);
        api.setCaption(
          '集計完了。配置位置を確定（' + formatCounts(s.count) + '）'
        );
        return;
      }
      if (s.kind === 'place_start') {
        renderBars(barsEl, s);
        clearCradixRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'place') {
        renderBars(barsEl, s);
        assignCradixRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption(
          '配置: 元位置 ' +
            s.from +
            ' の値 ' +
            s.value +
            '（バッファ先頭桁 ' +
            s.digit +
            '）を位置 ' +
            s.pos +
            ' へ'
        );
        return;
      }
      if (s.kind === 'partition_done') {
        renderBars(barsEl, s);
        clearCradixRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'discard' || s.kind === 'refill') {
        renderBars(barsEl, s);
        const pairs = [];
        let i;
        for (i = s.lo; i <= s.hi; i++) {
          pairs.push([i, 'range']);
        }
        assignCradixRoles(barsEl, pairs);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'done') {
        renderBars(barsEl, s);
        clearCradixRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="cradix-sort-demo"
  data_prefix="cradix"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[基数ソート](/2026/06/21/sort-radix.html)の記事は LSD（下位桁から）の素朴なカウンティング繰り返しが中心である。

キャッシュ効率型基数ソートは MSD 側に立ち、キーバッファでキャッシュ線上の参照をまとめる点が異なる。

[アメリカ国旗ソート](/2026/07/02/sort-american-flag.html)も MSD だが、インプレース交換でバケットを作ることに主眼があり、キーバッファは用いない。

[バーストソート](/2026/07/12/sort-burst.html)はキャッシュ効率をトライの遅延展開で稼ぐ別系統である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000003 |        0.000062 |              66 |              72 |
|        512 |        0.000006 |        0.000059 |              86 |              92 |
|       1024 |        0.000018 |        0.000052 |             106 |             112 |
|       2048 |        0.000034 |        0.000144 |             122 |             128 |
|       4096 |        0.000063 |        0.000148 |             122 |             128 |
|       8192 |        0.000124 |        0.000256 |             181 |             188 |
|      16384 |        0.000354 |        0.000685 |             382 |             388 |
|      32768 |        0.000667 |        0.001810 |             372 |             412 |
|      65536 |        0.001359 |        0.006057 |             744 |             784 |
|     131072 |        0.003513 |        0.010571 |            2556 |            2596 |
|     262144 |        0.006693 |        0.014070 |            4076 |            4144 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="cradix" %}
