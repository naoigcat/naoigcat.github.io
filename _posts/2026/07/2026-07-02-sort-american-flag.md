---
title:     アメリカ国旗ソートで配列を並び替える
date:      2026-07-02 08:38:35 +0900
tags:      sort
sort_demo: true
---

## アメリカ国旗ソートを使用する

アメリカ国旗ソート (`American flag sort`) は、キーを固定幅の記号列（典型例は 1 バイト単位）として見なし、現在位置の記号値ごとにカウンティングしてバケット境界を決め、インプレースの交換で各要素を対応バケットへ集める処理を再帰的に実行する。

名称は Dijkstra の「オランダ国旗問題」に由来する 3 区分のインプレース分割と、星条旗の複数色帯を連想させる MSD の多区分分割の対応から来ている。基数ソートや文字列向け MSD 整列の実装で、補助配列を増やさずに済ませたい場面に用いられる。

1.  **記号位置の選択**: 最上位バイト（または桁）から処理する。部分配列が十分小さければ挿入ソートなどで終える。
2.  **出現回数の集計**: 現在位置の記号 `0..σ-1`（バイトなら `σ = 256`）について各出現数を数える。
3.  **バケット境界の確定**: 累積和から各記号の区間 `[start, end)` を求める。
4.  **インプレース配置**: 記号 `r` の区間を左から走査し、属する記号が `r` でなければ先頭未確定要素と交換して前進させ、すべて `r` に揃えたら次の記号へ進む。
5.  **再帰**: 要素が 2 個以上残った各区間について、次の記号位置で手順 1〜4 を繰り返す。

```pseudocode
procedure american_flag_sort(A, byte)
  if length(A) <= THRESHOLD then
    insertion_sort(A)
    return
  if byte >= key_width then
    return
  count[0..σ-1] = 0
  for each x in A
    count[digit(x, byte)]++
  offset[0] = 0
  for r from 1 to σ - 1
    offset[r] = offset[r - 1] + count[r - 1]
  begin[r] = offset[r]
  end[r] = offset[r] + count[r]
  for r from 0 to σ - 1
    if count[r] = 0 then continue
    while begin[r] < end[r]
      b = digit(A[begin[r]], byte)
      if b ≠ r then
        end[b] = end[b] - 1
        swap(A[begin[r]], A[end[b]])
      else
        begin[r] = begin[r] + 1
    american_flag_sort(A[offset[r]..offset[r] + count[r]), byte + 1)
```

整数キーを `usize` として整列するときは、最上位バイトから下位バイトへと `digit(x, byte)` を取り、記号集合サイズ `σ = 256` として上記を適用するのが典型である（下の計測コードもこの方式）。

記号幅 w なら `O(w · (n + σ))` となり、カウンティング配列 `O(σ)` だけのインプレース志向の実装が多い。一般に不安定である。

以下のデモでは視認性のため十進の各桁（`σ = 10`）を**上位桁から**同じ手順で示す。バイト列版と違いは記号の取り方だけで、バケット形成と再帰の流れは同じである。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('american-flag-sort-demo', function (root) {
  const THRESHOLD = 4;
  const RADIX = 10;

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

  function maxDigitExp(lo, hi, arr) {
    let maxVal = 0;
    let i;
    for (i = lo; i <= hi; i++) {
      if (arr[i] > maxVal) {
        maxVal = arr[i];
      }
    }
    let exp = 1;
    while (exp * RADIX <= maxVal) {
      exp *= RADIX;
    }
    return exp;
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
    const min = Math.min.apply(null, defined);
    const max = Math.max.apply(null, defined);
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
      tone++;
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

  function updateAmericanFlagStack(stack, index, value, scale, role) {
    const label = stack.querySelector('.sort-demo__bar-value');
    const bar = stack.querySelector('.sort-demo__bar');
    if (!label || !bar) {
      return;
    }

    stack.removeAttribute('data-role');
    label.textContent = String(value);
    const h = 28 + ((value - scale.min) / scale.span) * 92;
    bar.style.height = h + 'px';
    bar.setAttribute('title', String(value));
    stack.setAttribute(
      'aria-label',
      DemoSort.barAccessibilityLabel(index, String(value), role)
    );
    if (role) {
      stack.setAttribute('data-role', role);
    }
  }

  function mountAmericanFlagBars(container, values, bucketRanges) {
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }

    const scale = valueSpan(values);
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      'アメリカ国旗ソートの棒。値は棒の上に表示、左から位置0、1…の順です。'
    );

    let i;
    for (i = 0; i < values.length; i++) {
      const stack = document.createElement('div');
      stack.className = 'sort-demo__bar-stack';
      stack.setAttribute('role', 'listitem');

      const label = document.createElement('span');
      label.className = 'sort-demo__bar-value';

      const bar = document.createElement('div');
      bar.className = 'sort-demo__bar';

      stack.appendChild(label);
      stack.appendChild(bar);
      container.appendChild(stack);

      updateAmericanFlagStack(stack, i, values[i], scale, null);
    }

    applyBucketTones(container, bucketRanges);
  }

  function clearAmericanFlagRoles(container) {
    const stacks = container.children;
    let si;
    for (si = 0; si < stacks.length; si++) {
      stacks[si].removeAttribute('data-role');
      const label = stacks[si].querySelector('.sort-demo__bar-value');
      const valueText =
        label && label.textContent.trim() ? label.textContent.trim() : '';
      stacks[si].setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(si, valueText, null)
      );
    }
  }

  function assignAmericanFlagRoles(container, pairs, opts) {
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
      let si;
      for (si = 0; si < stacks.length; si++) {
        const label = stacks[si].querySelector('.sort-demo__bar-value');
        const valueText =
          label && label.textContent.trim() ? label.textContent.trim() : '';
        stacks[si].setAttribute(
          'aria-label',
          DemoSort.barAccessibilityLabel(si, valueText, null)
        );
      }
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
      const valueText =
        label && label.textContent.trim() ? label.textContent.trim() : '';
      stack.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(idx, valueText, pairs[i][1])
      );
    }
  }

  function renderBars(barsEl, s) {
    mountAmericanFlagBars(barsEl, s.arr, s.bucketRanges || null);
  }

  function generateSteps(initial) {
    const steps = [];
    const a = initial.slice();

    function insertionSort(lo, hi) {
      let i;
      for (i = lo + 1; i <= hi; i++) {
        let j = i;
        while (j > lo) {
          steps.push({
            kind: 'insert_compare',
            lo: j - 1,
            hi: j,
            arr: a.slice(),
          });
          if (a[j - 1] > a[j]) {
            const t = a[j - 1];
            a[j - 1] = a[j];
            a[j] = t;
            steps.push({
              kind: 'insert_swap',
              lo: j - 1,
              hi: j,
              arr: a.slice(),
            });
            j--;
          } else {
            break;
          }
        }
      }
    }

    function americanFlag(lo, hi, exp) {
      const len = hi - lo + 1;
      if (len <= 0) {
        return;
      }
      if (len <= THRESHOLD) {
        steps.push({
          kind: 'phase',
          text:
            '要素 ' +
            len +
            ' 個の区間は挿入ソート（閾値 ' +
            THRESHOLD +
            ' 以下）',
          lo: lo,
          hi: hi,
          exp: exp,
          arr: a.slice(),
        });
        insertionSort(lo, hi);
        return;
      }
      if (exp < 1) {
        return;
      }
      if (Math.floor(Math.max.apply(null, a.slice(lo, hi + 1)) / exp) <= 0) {
        return;
      }

      const count = new Array(RADIX);
      let r;
      for (r = 0; r < RADIX; r++) {
        count[r] = 0;
      }

      steps.push({
        kind: 'count_start',
        lo: lo,
        hi: hi,
        exp: exp,
        arr: a.slice(),
      });

      let i;
      for (i = lo; i <= hi; i++) {
        const digit = Math.floor(a[i] / exp) % RADIX;
        steps.push({
          kind: 'count_scan',
          idx: i,
          digit: digit,
          exp: exp,
          arr: a.slice(),
          count: count.slice(),
        });
        count[digit]++;
        steps.push({
          kind: 'count_bump',
          idx: i,
          digit: digit,
          exp: exp,
          arr: a.slice(),
          count: count.slice(),
        });
      }

      const offset = new Array(RADIX);
      offset[0] = lo;
      for (r = 1; r < RADIX; r++) {
        offset[r] = offset[r - 1] + count[r - 1];
      }

      const begin = offset.slice();
      const endIdx = offset.map(function (startPos, r) {
        return startPos + count[r];
      });
      const bucketRanges = buildBucketRanges(offset, count);

      steps.push({
        kind: 'count_done',
        lo: lo,
        hi: hi,
        exp: exp,
        arr: a.slice(),
        count: count.slice(),
        offset: offset.slice(),
        bucketRanges: bucketRanges,
      });

      for (r = 0; r < RADIX; r++) {
        if (count[r] === 0) {
          continue;
        }
        steps.push({
          kind: 'bucket_start',
          bucket: r,
          start: begin[r],
          end: endIdx[r],
          exp: exp,
          arr: a.slice(),
          bucketRanges: bucketRanges,
        });

        while (begin[r] < endIdx[r]) {
          const digit = Math.floor(a[begin[r]] / exp) % RADIX;
          if (digit !== r) {
            steps.push({
              kind: 'place_compare',
              idx: begin[r],
              bucket: r,
              digit: digit,
              target: endIdx[digit] - 1,
              exp: exp,
              arr: a.slice(),
              bucketRanges: bucketRanges,
            });
            const t = a[begin[r]];
            a[begin[r]] = a[endIdx[digit] - 1];
            a[endIdx[digit] - 1] = t;
            endIdx[digit] -= 1;
            steps.push({
              kind: 'place_swap',
              idx: begin[r],
              other: endIdx[digit],
              bucket: r,
              digit: digit,
              exp: exp,
              arr: a.slice(),
              bucketRanges: bucketRanges,
            });
          } else {
            begin[r]++;
          }
        }

        steps.push({
          kind: 'bucket_done',
          bucket: r,
          start: offset[r],
          end: offset[r] + count[r],
          exp: exp,
          arr: a.slice(),
          bucketRanges: bucketRanges,
        });

        const bucketStart = offset[r];
        const bucketEnd = bucketStart + count[r];
        if (bucketEnd - bucketStart > 1) {
          americanFlag(bucketStart, bucketEnd - 1, exp / RADIX);
        }
      }
    }

    if (a.length > 0) {
      americanFlag(0, a.length - 1, maxDigitExp(0, a.length - 1, a));
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-american-flag',
    initialValues: [54, 12, 38, 91, 27, 63, 45, 18, 72, 36, 84, 29, 57, 41, 66],
    initialCaption:
      'アメリカ国旗ソートのデモ（十進 MSD・棒上に値、バケット境界は背景色）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    afterRebuild: function (api) {
      renderBars(
        api.barsEl,
        api.steps[0] ? api.steps[0] : { arr: api.values }
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        renderBars(barsEl, s);
        clearAmericanFlagRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'count_start') {
        renderBars(barsEl, s);
        assignAmericanFlagRoles(barsEl, [[s.lo, 'range'], [s.hi, 'range']]);
        api.setCaption(
          digitName(s.exp) +
            ' で出現回数を集計（部分配列 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '）'
        );
        return;
      }
      if (s.kind === 'count_scan') {
        renderBars(barsEl, s);
        assignAmericanFlagRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          '走査: 位置 ' +
            s.idx +
            ' の値 ' +
            s.arr[s.idx] +
            '（' +
            digitName(s.exp) +
            ' = ' +
            s.digit +
            '）'
        );
        return;
      }
      if (s.kind === 'count_bump') {
        renderBars(barsEl, s);
        assignAmericanFlagRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          digitName(s.exp) +
            ' の桁 ' +
            s.digit +
            ' を更新（' +
            formatCounts(s.count) +
            '）'
        );
        return;
      }
      if (s.kind === 'count_done') {
        renderBars(barsEl, s);
        clearAmericanFlagRoles(barsEl);
        api.setCaption(
          'バケット境界を確定: ' + formatCounts(s.count)
        );
        return;
      }
      if (s.kind === 'bucket_start') {
        renderBars(barsEl, s);
        assignAmericanFlagRoles(barsEl, [[s.start, 'range'], [s.end - 1, 'range']]);
        api.setCaption(
          '記号 ' +
            s.bucket +
            ' の区間（位置 ' +
            s.start +
            ' … ' +
            (s.end - 1) +
            '）をインプレース配置'
        );
        return;
      }
      if (s.kind === 'place_compare') {
        renderBars(barsEl, s);
        assignAmericanFlagRoles(barsEl, [
          [s.idx, 'compare'],
          [s.target, 'compare'],
        ]);
        api.setCaption(
          '位置 ' +
            s.idx +
            ' は記号 ' +
            s.digit +
            '（現在のバケット ' +
            s.bucket +
            ' ではない）→ 位置 ' +
            s.target +
            ' と交換'
        );
        return;
      }
      if (s.kind === 'place_swap') {
        assignAmericanFlagRoles(barsEl, [[s.idx, 'swap'], [s.other, 'swap']]);
        api.setCaption('インプレース配置の交換…');
        await DemoSort.flipSwap(barsEl, s.idx, s.other);
        renderBars(barsEl, s);
        clearAmericanFlagRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.idx + ' と ' + s.other + '）'
        );
        return;
      }
      if (s.kind === 'bucket_done') {
        renderBars(barsEl, s);
        assignAmericanFlagRoles(barsEl, [[s.start, 'sorted'], [s.end - 1, 'sorted']]);
        api.setCaption(
          '記号 ' +
            s.bucket +
            ' の区間が揃いました（' +
            digitName(s.exp) +
            '）'
        );
        return;
      }
      if (s.kind === 'insert_compare') {
        renderBars(barsEl, s);
        assignAmericanFlagRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '挿入ソート: 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
        );
        return;
      }
      if (s.kind === 'insert_swap') {
        assignAmericanFlagRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('挿入ソートの交換…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        renderBars(barsEl, s);
        clearAmericanFlagRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'done') {
        renderBars(barsEl, s);
        clearAmericanFlagRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="american-flag-sort-demo"
  data_prefix="american-flag"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[基数ソート](/2026/06/21/sort-radix.html)の MSD 版に近いが、各桁（記号）ごとにインプレースでバケット境界へ集める。カウンティング配列 `O(σ)` だけで済ませやすい。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000012 |        0.000061 |            1739 |            1744 |
|        512 |        0.000017 |        0.000051 |            1743 |            1748 |
|       1024 |        0.000026 |        0.000079 |            1751 |            1756 |
|       2048 |        0.000043 |        0.000116 |            1767 |            1772 |
|       4096 |        0.000078 |        0.000152 |            1799 |            1804 |
|       8192 |        0.000150 |        0.000373 |            1863 |            1868 |
|      16384 |        0.000296 |        0.000522 |            1995 |            2000 |
|      32768 |        0.000599 |        0.001146 |            2255 |            2260 |
|      65536 |        0.001247 |        0.003208 |            2767 |            2772 |
|     131072 |        0.003073 |        0.009491 |            3791 |            3796 |
|     262144 |        0.006327 |        0.010087 |            5839 |            5844 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="american_flag" %}
