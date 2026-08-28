---
title:     バイナリクイックソートで配列を並び替える
date:      2026-08-13 07:07:06 +0900
tags:      sort
sort_demo: true
---

## バイナリクイックソートを使用する

バイナリクイックソート (`binary quick sort`) は、キーをビット列と見なし、最上位ビットから 1 ビットずつ見て配列を「そのビットが 0 の側」と「1 の側」に分割し、両側へ同じ処理を再帰する整列法である。基数交換ソート (`radix-exchange sort`) とも呼ばれる。

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)が要素値そのものをピボットにするのに対し、こちらは「現在見ているビットが 0 か 1 か」が分割の基準になる。分割の形はクイックソートに近く、桁の扱い方は最上位桁優先の[基数ソート](/2026/06/21/sort-radix.html)や[アメリカ国旗ソート](/2026/07/02/sort-american-flag.html)に近い。

1.  **ビット位置の選択**: キー幅のうち最上位の有効ビットから始める。部分配列が十分短ければ挿入ソートなどで終える。
2.  **2 分割**: 左右の走査ポインタで、現在ビットが 0 の要素を左へ、1 の要素を右へ寄せる（Hoare 分割と同型）。
3.  **再帰**: 0 側・1 側それぞれについて、1 つ下のビット位置で手順 1〜2 を繰り返す。ビットが尽きるか要素が 1 個以下なら終了する。

```pseudocode
procedure binary_quick_sort(A, bit)
  if length(A) <= 1 or bit < 0 then
    return
  if length(A) <= INSERTION_THRESHOLD then
    insertion_sort(A)
    return
  i = 0
  j = length(A)
  while i < j
    while i < j and bit(A[i], bit) = 0
      i = i + 1
    while i < j and bit(A[j - 1], bit) = 1
      j = j - 1
    if i < j then
      swap(A[i], A[j - 1])
      i = i + 1
      j = j - 1
  mid = i
  binary_quick_sort(A[0 .. mid), bit - 1)
  binary_quick_sort(A[mid .. length(A)), bit - 1)
```

キー幅を w ビットとすると、各要素は高々 w 回のビット検査で行き先が決まるため、計算量は概ね `O(n · w)` である（下の計測では、入力の最大値から始めて無駄な上位ゼロビットを飛ばす）。補助配列は使わず、再帰の深さは高々 w なので作業領域は `O(w)` 程度に抑えられる。一般に不安定である。

以下のデモでは値を 1〜15（4 ビット）に抑え、最上位ビットから分割が進む様子を示す。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('binary-quick-sort-demo', function (root) {
  const INSERTION_THRESHOLD = 3;

  function bitLabel(bit) {
    return '2^' + bit + ' の位（ビット ' + bit + '）';
  }

  function msbOf(values) {
    let max = 0;
    for (let i = 0; i < values.length; i++) {
      if (values[i] > max) {
        max = values[i];
      }
    }
    if (max === 0) {
      return 0;
    }
    return 31 - Math.clz32(max);
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

    function binaryQuick(lo, hi, bit) {
      if (lo >= hi || bit < 0) {
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

      steps.push({
        kind: 'part_start',
        lo: lo,
        hi: hi,
        bit: bit,
        arr: a.slice(),
      });

      let i = lo;
      let j = hi + 1;
      while (i < j) {
        while (i < j && ((a[i] >> bit) & 1) === 0) {
          steps.push({
            kind: 'scan',
            i: i,
            j: j - 1,
            lo: lo,
            hi: hi,
            bit: bit,
            side: 'zero',
            arr: a.slice(),
          });
          i++;
        }
        while (i < j && ((a[j - 1] >> bit) & 1) === 1) {
          steps.push({
            kind: 'scan',
            i: i,
            j: j - 1,
            lo: lo,
            hi: hi,
            bit: bit,
            side: 'one',
            arr: a.slice(),
          });
          j--;
        }
        if (i < j) {
          const t = a[i];
          a[i] = a[j - 1];
          a[j - 1] = t;
          steps.push({
            kind: 'swap',
            lo: i,
            hi: j - 1,
            bit: bit,
            arr: a.slice(),
            phase: 'bit',
          });
          i++;
          j--;
        }
      }

      const mid = i;
      steps.push({
        kind: 'part_end',
        lo: lo,
        hi: hi,
        mid: mid,
        bit: bit,
        arr: a.slice(),
      });

      if (mid > lo) {
        binaryQuick(lo, mid - 1, bit - 1);
      }
      if (mid <= hi) {
        binaryQuick(mid, hi, bit - 1);
      }
    }

    if (a.length > 0) {
      binaryQuick(0, a.length - 1, msbOf(a));
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-binary-quick',
    initialValues: [11, 5, 14, 2, 9, 7, 13, 1, 8, 4, 15, 3, 10, 6, 12],
    initialCaption:
      'バイナリクイックソートのデモ（ビット 0 側は左、1 側は右へ分割）',
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
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ビット分割開始: 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            ' を ' +
            bitLabel(s.bit) +
            ' で 0 / 1 に分ける'
        );
        return;
      }
      if (s.kind === 'scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.i, 'compare'],
          [s.j, 'compare'],
        ]);
        const expect = s.side === 'zero' ? '0' : '1';
        api.setCaption(
          '走査: ' +
            bitLabel(s.bit) +
            ' が ' +
            expect +
            ' の側を進める（左 ' +
            s.i +
            ' / 右 ' +
            s.j +
            '）'
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
            : 'ビットが違う要素を交換（0 側 ↔ 1 側）';
        api.setCaption(label);
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        const roles = [];
        for (let p = s.lo; p < s.mid; p++) {
          roles.push([p, 'swap']);
        }
        for (let q = s.mid; q <= s.hi; q++) {
          roles.push([q, 'pivot']);
        }
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          bitLabel(s.bit) +
            ' の分割完了: 位置 ' +
            s.lo +
            ' … ' +
            (s.mid - 1) +
            ' が 0、' +
            s.mid +
            ' … ' +
            s.hi +
            ' が 1（次は下位ビットへ）'
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
  id="binary-quick-sort-demo"
  data_prefix="binary-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)は値の大小比較でピボット周辺へ分ける。バイナリクイックソートは比較の代わりにビット検査で 2 分割するため、ピボット選択の偏りというよりキーのビット分布が深さと走査量を決める。

[基数ソート](/2026/06/21/sort-radix.html)は最下位桁優先（LSD; Least Significant Digit）かつ十進カウンティングで桁ごとに安定なバケット集計を行い、補助配列を使うのが典型である。バイナリクイックソートは最上位桁優先（MSD; Most Significant Digit）かつ二進、インプレース交換が中心で安定性も補助領域も異なる。

[アメリカ国旗ソート](/2026/07/02/sort-american-flag.html)は記号集合が大きい（例: 1 バイトで 256 通り）最上位桁優先のインプレース分割である。バイナリクイックソートはその記号幅を 2 に固定した極端な場合とみなせる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000007 |        0.000049 |               0 |               0 |
|        512 |        0.000017 |        0.000083 |               0 |               0 |
|       1024 |        0.000036 |        0.000087 |               0 |               0 |
|       2048 |        0.000079 |        0.000141 |               0 |               0 |
|       4096 |        0.000171 |        0.000290 |               0 |               0 |
|       8192 |        0.000376 |        0.000598 |               0 |               0 |
|      16384 |        0.000850 |        0.003165 |               0 |               0 |
|      32768 |        0.001743 |        0.002693 |               0 |               0 |
|      65536 |        0.003782 |        0.008057 |               0 |               0 |
|     131072 |        0.008157 |        0.254469 |               0 |               0 |
|     262144 |        0.017062 |        0.241280 |               0 |               0 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="binary_quick" %}
