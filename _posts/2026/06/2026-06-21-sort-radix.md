---
title:     基数ソートで配列を並び替える
date:      2026-06-21 09:00:00 +0900
tags:      sort
sort_demo: true
---

## 基数ソートを使用する

基数ソート (`radix sort`) は、キーを桁（または固定幅のビット列）ごとに分割し、各桁についてカウンティングソートなどの安定な部分ソートを繰り返す。

最下位桁から順に処理する LSD（Least Significant Digit）方式がよく用いられる。

1.  **桁の決定**: 最大値から必要な桁数（または基数 `r` に対するパス数）を求める。
2.  **桁ごとの安定ソート**: 現在の桁 `exp`（1, 10, 100, …）について、各要素のその桁の値 `0..r-1` をキーに安定なカウンティングソートを行う。
3.  **桁の更新**: `exp` を基数倍し、最上位桁まで 2 を繰り返す。

```pseudocode
procedure radix_sort(A)
  if length(A) = 0 then return
  maxVal = maximum(A)
  exp = 1
  while maxVal / exp > 0 do
    stable_counting_sort_by_digit(A, exp)
    exp = exp * 10
```

各桁パスはカウンティングソートと同様に、出現回数の集計・累積和・後方からの配置で構成される。LSD かつ各パスが安定であれば、上位桁の整列結果を下位桁のソートが壊さないため、全体が昇順になる。

桁数 d・基数 r なら `O(d · (n + r))` となり、カウンティングソートより広い値域に適用しやすい。

カウンティングソートと同様、キーの表現と基数の選び方に依存する。負の数や浮動小数点は符号・指数・仮数部への分解など前処理が必要になる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('radix-sort-demo', function (root) {
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

  function formatDigitCounts(count) {
    const parts = [];
    let d;
    for (d = 0; d < count.length; d++) {
      if (count[d] > 0) {
        parts.push('桁 ' + d + ' → ' + count[d] + ' 個');
      }
    }
    return parts.length ? parts.join('、') : '（まだなし）';
  }

  function radixValueSpan(values) {
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

  function updateRadixStack(stack, index, value, scale, role) {
    const label = stack.querySelector('.sort-demo__bar-value');
    const bar = stack.querySelector('.sort-demo__bar');
    if (!label || !bar) {
      return;
    }

    stack.removeAttribute('data-role');
    if (value != null && !Number.isNaN(value)) {
      label.textContent = String(value);
      stack.classList.remove('sort-demo__bar-stack--empty');
      bar.style.visibility = '';
      bar.style.height = 28 + ((value - scale.min) / scale.span) * 92 + 'px';
      bar.style.opacity = '';
      bar.setAttribute('title', String(value));
      stack.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(index, String(value), role)
      );
      if (role) {
        stack.setAttribute('data-role', role);
      }
      return;
    }

    label.textContent = '\u00a0';
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

  function mountRadixBars(container, values) {
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }

    const scale = radixValueSpan(values);
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      '基数ソートの棒。値は棒の上に表示、左から位置0、1…の順です。'
    );

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

      stack.appendChild(label);
      stack.appendChild(bar);
      container.appendChild(stack);

      if (scale) {
        updateRadixStack(stack, i, v, scale, null);
      } else {
        updateRadixStack(stack, i, null, { min: 0, max: 0, span: 1 }, null);
      }
    }
  }

  function clearRadixRoles(container) {
    const stacks = container.children;
    let si;
    for (si = 0; si < stacks.length; si++) {
      stacks[si].removeAttribute('data-role');
      const label = stacks[si].querySelector('.sort-demo__bar-value');
      const valueText =
        label && label.textContent.trim() ? label.textContent.trim() : '未配置';
      stacks[si].setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(si, valueText, null)
      );
    }
  }

  function assignRadixRoles(container, pairs) {
    clearRadixRoles(container);
    if (!pairs) {
      return;
    }
    let pi;
    for (pi = 0; pi < pairs.length; pi++) {
      const idx = pairs[pi][0];
      if (idx == null) {
        continue;
      }
      const stack = container.children[idx];
      if (!stack) {
        continue;
      }
      stack.setAttribute('data-role', pairs[pi][1]);
      const label = stack.querySelector('.sort-demo__bar-value');
      const valueText =
        label && label.textContent.trim()
          ? label.textContent.trim()
          : '未配置';
      stack.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabel(idx, valueText, pairs[pi][1])
      );
    }
  }

  function generateSteps(initial) {
    const steps = [];
    let a = initial.slice();
    const n = a.length;
    if (n === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    const maxVal = Math.max.apply(null, a);
    let exp = 1;

    while (Math.floor(maxVal / exp) > 0) {
      const count = new Array(10);
      let i;
      let digit;

      for (i = 0; i < 10; i++) {
        count[i] = 0;
      }

      steps.push({
        kind: 'phase',
        phase: 'count',
        exp: exp,
        arr: a.slice(),
      });

      for (i = 0; i < n; i++) {
        digit = Math.floor(a[i] / exp) % 10;
        steps.push({
          kind: 'count_scan',
          i: i,
          value: a[i],
          digit: digit,
          exp: exp,
          arr: a.slice(),
          count: count.slice(),
        });
        count[digit]++;
        steps.push({
          kind: 'count_bump',
          i: i,
          value: a[i],
          digit: digit,
          exp: exp,
          arr: a.slice(),
          count: count.slice(),
        });
      }

      for (i = 1; i < 10; i++) {
        count[i] += count[i - 1];
      }

      steps.push({
        kind: 'count_done',
        exp: exp,
        arr: a.slice(),
        count: count.slice(),
      });

      const output = new Array(n);
      const slots = count.slice();

      steps.push({
        kind: 'phase',
        phase: 'place',
        exp: exp,
        arr: a.slice(),
      });

      for (i = n - 1; i >= 0; i--) {
        digit = Math.floor(a[i] / exp) % 10;
        slots[digit]--;
        output[slots[digit]] = a[i];
        steps.push({
          kind: 'place',
          i: i,
          pos: slots[digit],
          value: a[i],
          digit: digit,
          exp: exp,
          output: output.slice(),
        });
      }

      a = output.slice();
      steps.push({
        kind: 'pass_done',
        exp: exp,
        arr: a.slice(),
      });

      exp *= 10;
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-radix',
    initialValues: [54, 12, 38, 91, 27, 63, 45, 18, 72, 36, 84, 29, 57, 41, 66],
    initialCaption:
      '基数ソートのデモ（桁ごとのカウンティングは水色、配置は確定の書き込み）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    afterRebuild: function (api) {
      mountRadixBars(
        api.barsEl,
        api.steps[0] ? api.steps[0].arr : []
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        if (s.phase === 'place') {
          mountRadixBars(barsEl, new Array(s.arr.length));
        } else {
          mountRadixBars(barsEl, s.arr);
        }
        clearRadixRoles(barsEl);
        if (s.phase === 'count') {
          api.setCaption(
            'フェーズ1: ' +
              digitName(s.exp) +
              ' でカウンティングソート（出現回数を数えます）'
          );
        } else {
          api.setCaption(
            'フェーズ2: ' +
              digitName(s.exp) +
              ' の結果を安定に配置します'
          );
        }
        return;
      }
      if (s.kind === 'count_scan') {
        assignRadixRoles(barsEl, [[s.i, 'cursor']]);
        api.setCaption(
          '走査: 位置 ' +
            s.i +
            ' の値 ' +
            s.value +
            '（' +
            digitName(s.exp) +
            ' = ' +
            s.digit +
            '）'
        );
        return;
      }
      if (s.kind === 'count_bump') {
        assignRadixRoles(barsEl, [[s.i, 'cursor']]);
        api.setCaption(
          digitName(s.exp) +
            ' の桁 ' +
            s.digit +
            ' を更新しました（' +
            formatDigitCounts(s.count) +
            '）'
        );
        return;
      }
      if (s.kind === 'count_done') {
        clearRadixRoles(barsEl);
        api.setCaption(
          '集計完了: ' + formatDigitCounts(s.count)
        );
        return;
      }
      if (s.kind === 'place') {
        mountRadixBars(barsEl, s.output);
        assignRadixRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption(
          '配置: 値 ' +
            s.value +
            '（' +
            digitName(s.exp) +
            ' = ' +
            s.digit +
            '）を位置 ' +
            s.pos +
            ' に書き込み'
        );
        return;
      }
      if (s.kind === 'pass_done') {
        mountRadixBars(barsEl, s.arr);
        clearRadixRoles(barsEl);
        api.setCaption(
          digitName(s.exp) + ' のパスが完了しました'
        );
        return;
      }
      if (s.kind === 'done') {
        mountRadixBars(barsEl, s.arr);
        clearRadixRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="radix-sort-demo"
  data_prefix="radix"
  script=sort_demo_js
%}

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000002 |        0.000027 |            1666 |            1672 |
|        512 |        0.000003 |        0.000528 |            1670 |            1676 |
|       1024 |        0.000011 |        0.000583 |            1682 |            1688 |
|       2048 |        0.000019 |        0.000594 |            1706 |            1712 |
|       4096 |        0.000034 |        0.000585 |            1754 |            1760 |
|       8192 |        0.000073 |        0.001300 |            1849 |            1856 |
|      16384 |        0.000216 |        0.000508 |            2046 |            2052 |
|      32768 |        0.000388 |        0.001164 |            2434 |            2440 |
|      65536 |        0.000742 |        0.001181 |            3201 |            3208 |
|     131072 |        0.001972 |        0.005915 |            4738 |            4744 |
|     262144 |        0.004096 |        0.012222 |            7814 |            7944 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="radix" %}
