---
title:     マルチキークイックソートで配列を並び替える
date:      2026-09-07 06:50:10 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## マルチキークイックソートを使用する

マルチキークイックソート (`multi-key quicksort`) は、キーを文字・桁・バイトなどの記号列と見なし、現在見ている記号位置だけで[三分割クイックソート](/2026/08/12/sort-three-way-quick.html) と同じ 3 色分割を行い、等値帯だけ次の記号位置へ進めて再帰する整列法である。

要素全体を 1 回の比較で片付ける通常のクイックソートと違い、「いま見ている桁が小さい／等しい／大きい」だけで仕分ける。等しい側は次の桁へ進むので、共通接頭辞の長いキーでも、すでに揃った桁を何度も見なくてよい。

1.  **記号位置の選択**: 最上位の記号（文字列なら先頭文字、整数なら最上位バイトや桁）から始める。部分配列が十分短ければ挿入ソートなどで終える。
2.  **3 分割**: 現在位置の記号をピボットに、`<`・`=`・`>` の 3 領域へインプレース分割する。
3.  **再帰**: 未満側と超過側は同じ記号位置のまま再帰する。等値帯だけ記号位置を 1 つ進めて再帰する。記号が尽きるか要素が 1 個以下なら終了する。

```pseudocode
procedure multi_key_quick_sort(A, lo, hi, d)
  if hi <= lo then
    return
  if hi - lo < THRESHOLD then
    insertion_sort(A[lo .. hi])
    return
  if d >= key_width then
    return
  pivot = digit(A[lo], d)
  lt = lo
  i = lo + 1
  gt = hi
  while i <= gt
    t = digit(A[i], d)
    if t < pivot then
      swap(A[lt], A[i])
      lt = lt + 1
      i = i + 1
    else if t > pivot then
      swap(A[i], A[gt])
      gt = gt - 1
    else
      i = i + 1
  multi_key_quick_sort(A, lo, lt - 1, d)
  multi_key_quick_sort(A, lt, gt, d + 1)
  multi_key_quick_sort(A, gt + 1, hi, d)
```

整数キーを `usize` として整列するときは、最上位バイトから下位バイトへと `digit(x, d)` を取り、記号集合サイズ $$\sigma = 256$$ として上記を適用するのが典型である。

キー幅を `w`、平均の分岐の深さを考えると時間はおおよそ $$O(n \cdot w)$$ 程度に収まりやすく、補助配列は使わず再帰の深さ分の作業領域で済む。一般に不安定である。

記号ごとに全バケットを数える [アメリカ国旗ソート](/2026/07/02/sort-american-flag.html) より、ピボット周りの 3 分割だけで進む点が比較ベースの特徴である。

以下のデモでは視認性のため十進の各桁（$$\sigma = 10$$）を**上位桁から**同じ手順で示す。バイト列版と違いは記号の取り方だけで、3 分割と「等値帯だけ次桁へ」の流れは同じである。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('multi-key-quick-sort-demo', function (root) {
  const INSERTION_THRESHOLD = 3;
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

  function digitAt(value, exp) {
    return Math.floor(value / exp) % RADIX;
  }

  function maxDigitExp(values) {
    let maxVal = 0;
    for (let i = 0; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
      }
    }
    let exp = 1;
    while (exp * RADIX <= maxVal) {
      exp *= RADIX;
    }
    return exp;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function insertionSort(lo, hi) {
      for (let i = lo + 1; i <= hi; i++) {
        let j = i;
        while (j > lo) {
          steps.push({
            kind: 'compare',
            lo: j - 1,
            hi: j,
            arr: a.slice(),
            phase: 'insert',
          });
          if (a[j - 1] > a[j]) {
            const t = a[j - 1];
            a[j - 1] = a[j];
            a[j] = t;
            steps.push({
              kind: 'swap',
              lo: j - 1,
              hi: j,
              arr: a.slice(),
              phase: 'insert',
            });
            j--;
          } else {
            break;
          }
        }
      }
    }

    function multiKey(lo, hi, exp) {
      if (lo >= hi) {
        return;
      }
      if (hi - lo + 1 <= INSERTION_THRESHOLD) {
        steps.push({
          kind: 'phase',
          text:
            '要素が ' +
            (hi - lo + 1) +
            ' 個以下のため、この範囲は挿入ソート（閾値 ' +
            INSERTION_THRESHOLD +
            ' 以下）',
          arr: a.slice(),
        });
        insertionSort(lo, hi);
        return;
      }
      if (exp < 1) {
        return;
      }

      steps.push({
        kind: 'part_start',
        lo: lo,
        hi: hi,
        exp: exp,
        arr: a.slice(),
      });

      const pivotDigit = digitAt(a[lo], exp);
      let pivotIdx = lo;
      let lt = lo;
      let i = lo + 1;
      let gt = hi;

      while (i <= gt) {
        steps.push({
          kind: 'scan',
          i: i,
          lt: lt,
          gt: gt,
          lo: lo,
          hi: hi,
          pivot: pivotIdx,
          exp: exp,
          pivotDigit: pivotDigit,
          arr: a.slice(),
        });
        const d = digitAt(a[i], exp);
        if (d < pivotDigit) {
          if (lt !== i) {
            const t1 = a[lt];
            a[lt] = a[i];
            a[i] = t1;
            if (pivotIdx === lt) {
              pivotIdx = i;
            } else if (pivotIdx === i) {
              pivotIdx = lt;
            }
            steps.push({
              kind: 'swap',
              lo: lt,
              hi: i,
              arr: a.slice(),
              phase: 'less',
              exp: exp,
            });
          }
          lt++;
          i++;
        } else if (d > pivotDigit) {
          if (i !== gt) {
            const t2 = a[i];
            a[i] = a[gt];
            a[gt] = t2;
            if (pivotIdx === i) {
              pivotIdx = gt;
            } else if (pivotIdx === gt) {
              pivotIdx = i;
            }
            steps.push({
              kind: 'swap',
              lo: i,
              hi: gt,
              arr: a.slice(),
              phase: 'great',
              exp: exp,
            });
          }
          gt--;
        } else {
          i++;
        }
      }

      steps.push({
        kind: 'part_end',
        lo: lo,
        hi: hi,
        lt: lt,
        gt: gt,
        exp: exp,
        pivotDigit: pivotDigit,
        arr: a.slice(),
      });

      if (lt > lo) {
        multiKey(lo, lt - 1, exp);
      }
      if (gt >= lt) {
        multiKey(lt, gt, Math.floor(exp / RADIX));
      }
      if (gt < hi) {
        multiKey(gt + 1, hi, exp);
      }
    }

    if (a.length > 0) {
      multiKey(0, a.length - 1, maxDigitExp(a));
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-multi-key-quick',
    initialValues: [52, 17, 58, 41, 29, 55, 38, 51, 16, 57, 47, 23],
    initialCaption:
      'マルチキークイックソートのデモ（棒の数字が値。上位桁で 3 分割し、等値帯だけ下位桁へ）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'pivot']]);
        api.setCaption(
          digitName(s.exp) +
            ' で 3 分割: 部分配列 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（左端の桁をピボットに、< / = / > へ仕分け）'
        );
        return;
      }
      if (s.kind === 'scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.i, 'compare'],
          [s.lt, 'swap'],
          [s.gt, 'swap'],
          [s.pivot, 'pivot'],
        ]);
        api.setCaption(
          digitName(s.exp) +
            ': 位置 ' +
            s.i +
            ' の桁をピボット桁 ' +
            s.pivotDigit +
            ' と比較（<' +
            s.lt +
            ' … = … ' +
            s.gt +
            '>）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        const label =
          s.phase === 'insert'
            ? '挿入ソート: 交換しています…'
            : s.phase === 'less'
              ? digitName(s.exp) + ': ピボット桁未満の領域へ移動'
              : s.phase === 'great'
                ? digitName(s.exp) + ': ピボット桁超の領域へ移動'
                : '交換しています…';
        api.setCaption(label);
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        const roles = [];
        for (let p = s.lt; p <= s.gt; p++) {
          roles.push([p, 'pivot']);
        }
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          digitName(s.exp) +
            ' の等値帯確定: 位置 ' +
            s.lt +
            ' … ' +
            s.gt +
            ' は桁 ' +
            s.pivotDigit +
            '（この帯だけ次の下位桁へ）'
        );
        return;
      }
      if (s.kind === 'compare' && s.phase === 'insert') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption(
          '挿入ソート: 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="multi-key-quick-sort-demo"
  data_prefix="multi-key-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[三分割クイックソート](/2026/08/12/sort-three-way-quick.html)はキー全体を 1 回比較して等値帯を確定する。マルチキー版は記号位置ごとの比較に落とし、等値帯では次の記号へ進む。

[アメリカ国旗ソート](/2026/07/02/sort-american-flag.html)や[ポストマンソート](/2026/08/24/sort-postman.html)も最上位桁優先だが、記号値ごとのバケットを数えて配る。こちらはピボット 1 値まわりの 3 分割だけで進む。

[バイナリクイックソート](/2026/08/13/sort-binary-quick.html)は 1 ビットずつの 2 分割である。マルチキー版は記号（バイトや桁）単位の 3 分割で、等値帯の扱いが明示的である。

[トライソート](/2026/07/11/sort-trie.html)や[バーストソート](/2026/07/12/sort-burst.html)も桁で分岐する点は近いが、木やバケット構造を育てる。マルチキークイックソートは配列上の交換中心である。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size | Average time (s) | Maximum time (s) | Average memory (KiB) | Maximum memory (KiB) |
|-----------:|-----------------:|-----------------:|---------------------:|---------------------:|
|        256 |         0.000006 |         0.000049 |                    0 |                    0 |
|        512 |         0.000014 |         0.000059 |                    0 |                    0 |
|       1024 |         0.000030 |         0.000076 |                    0 |                    0 |
|       2048 |         0.000064 |         0.000116 |                    0 |                    0 |
|       4096 |         0.000135 |         0.000382 |                    0 |                    0 |
|       8192 |         0.000287 |         0.000487 |                    0 |                    0 |
|      16384 |         0.000616 |         0.000890 |                    0 |                    0 |
|      32768 |         0.001316 |         0.001871 |                    0 |                    0 |
|      65536 |         0.002811 |         0.003822 |                    0 |                    0 |
|     131072 |         0.005986 |         0.007770 |                    0 |                    0 |
|     262144 |         0.012567 |         0.044685 |                    0 |                    0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="multi_key_quick" %}
