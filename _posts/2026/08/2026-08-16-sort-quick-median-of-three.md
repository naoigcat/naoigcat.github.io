---
title:     三点中央値型クイックソートで配列を並び替える
date:      2026-08-16 14:31:17 +0900
tags:      sort
sort_demo: true
---

## 三点中央値型クイックソートを使用する

三点中央値型クイックソート (`quick sort with median-of-three pivot`) は、部分配列の左端・中央・右端の 3 要素から中央値となるものをピボットに選び、分割の偏りを抑える。

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)が右端固定だと昇順・降順に近い入力で最悪計算量 `O(n²)` になりやすいのに対し、三点中央値は整列済みやほぼ整列済みでも端の極端な値を避けやすい。分割そのものはロムート方式を使い、違いは「どの位置をピボットにするか」にある。

[ランダムピボット型クイックソート](/2026/08/15/sort-quick-random-pivot.html)が乱択で期待値を上げるのに対し、こちらは決定的な 3 点比較で同じ目的に近づける。

1.  **三点中央値**: 部分配列 `lo … hi` の `A[lo]`・`A[mid]`・`A[hi]`（`mid = lo + ⌊(hi - lo) / 2⌋`）を比べ、値の中央値にあたる添字を選ぶ。
2.  **ロムート分割**: 選んだ要素を右端へ移し、片方向走査で「未満」と「以上」に分ける。返り値 `p` がピボットの最終位置になる。
3.  **再帰**: `lo … p - 1` と `p + 1 … hi` に同じ処理を繰り返す。十分短い区間は挿入ソートで仕上げる。

```pseudocode
procedure median_of_three_quick_sort(A, lo, hi)
  if lo >= hi then
    return
  if hi - lo < INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  m = median_of_three_index(A, lo, hi)
  swap(A[m], A[hi])
  p = lomuto_partition(A, lo, hi)
  median_of_three_quick_sort(A, lo, p - 1)
  median_of_three_quick_sort(A, p + 1, hi)

procedure median_of_three_index(A, lo, hi)
  mid = lo + floor((hi - lo) / 2)
  // A[lo], A[mid], A[hi] のうち値の中央値の添字を返す
  ...

procedure lomuto_partition(A, lo, hi)
  pivot = A[hi]
  i = lo
  for j from lo to hi - 1
    if A[j] < pivot then
      swap(A[i], A[j])
      i = i + 1
  swap(A[i], A[hi])
  return i
```

整列済み配列では中央が中央値になりやすく、右端固定より分割がバランスしやすい。それでも巧妙に構成した入力では最悪計算量は `O(n²)` のままである。一般に不安定である。

平均計算量は `O(n log n)`、追加空間は再帰スタックの `O(log n)` 程度を見込む。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('median-of-three-quick-sort-demo', function (root) {
  const INSERTION_THRESHOLD = 4;

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
            j -= 1;
          } else {
            break;
          }
        }
      }
    }

    function medianOfThreeIndex(lo, hi) {
      const mid = lo + Math.floor((hi - lo) / 2);
      const x = a[lo];
      const y = a[mid];
      const z = a[hi];
      if ((x <= y && y <= z) || (z <= y && y <= x)) {
        return mid;
      }
      if ((y <= x && x <= z) || (z <= x && x <= y)) {
        return lo;
      }
      return hi;
    }

    function lomutoPartition(lo, hi) {
      const pivotVal = a[hi];
      let i = lo;
      for (let j = lo; j <= hi - 1; j++) {
        steps.push({
          kind: 'compare',
          lo: j,
          hi: hi,
          arr: a.slice(),
          phase: 'partition',
        });
        if (a[j] < pivotVal) {
          if (i !== j) {
            const t = a[i];
            a[i] = a[j];
            a[j] = t;
            steps.push({
              kind: 'swap',
              lo: i,
              hi: j,
              arr: a.slice(),
              phase: 'partition',
            });
          }
          i += 1;
        }
      }
      if (i !== hi) {
        const t2 = a[i];
        a[i] = a[hi];
        a[hi] = t2;
        steps.push({
          kind: 'swap',
          lo: i,
          hi: hi,
          arr: a.slice(),
          phase: 'partition',
        });
      }
      return i;
    }

    function medianOfThreeQuick(lo, hi) {
      if (lo >= hi) {
        return;
      }
      if (hi - lo < INSERTION_THRESHOLD) {
        steps.push({
          kind: 'part_start',
          lo,
          hi,
          phase: 'insert',
          arr: a.slice(),
        });
        insertionSort(lo, hi);
        steps.push({
          kind: 'part_end',
          lo,
          hi,
          phase: 'insert',
          arr: a.slice(),
        });
        return;
      }

      const mid = lo + Math.floor((hi - lo) / 2);
      const pivotIdx = medianOfThreeIndex(lo, hi);
      steps.push({
        kind: 'pick',
        lo,
        hi,
        mid,
        pivot: pivotIdx,
        arr: a.slice(),
      });
      if (pivotIdx !== hi) {
        const t = a[pivotIdx];
        a[pivotIdx] = a[hi];
        a[hi] = t;
        steps.push({
          kind: 'swap',
          lo: pivotIdx,
          hi: hi,
          arr: a.slice(),
          phase: 'pivot',
        });
      }
      steps.push({
        kind: 'part_start',
        lo,
        hi,
        phase: 'partition',
        arr: a.slice(),
      });
      const p = lomutoPartition(lo, hi);
      steps.push({
        kind: 'part_end',
        pivot: p,
        phase: 'partition',
        arr: a.slice(),
      });
      medianOfThreeQuick(lo, p - 1);
      medianOfThreeQuick(p + 1, hi);
    }

    if (a.length > 0) {
      medianOfThreeQuick(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-median-of-three-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '三点中央値型クイックソートのデモ（比較はオレンジ、交換は緑、ピボットは紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'pick') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.mid, 'compare'],
          [s.hi, 'compare'],
          [s.pivot, 'pivot'],
        ]);
        api.setCaption(
          '三点中央値: 位置 ' +
            s.lo +
            '・' +
            s.mid +
            '・' +
            s.hi +
            ' から位置 ' +
            s.pivot +
            ' をピボットに選ぶ'
        );
        return;
      }
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        if (s.phase === 'insert') {
          DemoSort.clearRoles(barsEl);
          api.setCaption(
            '短い区間: 位置 ' + s.lo + ' … ' + s.hi + ' を挿入ソート'
          );
        } else {
          DemoSort.assignRoles(barsEl, [[s.hi, 'pivot']]);
          api.setCaption(
            'ロムート分割: 右端へ移したピボットで位置 ' +
              s.lo +
              ' … ' +
              s.hi +
              ' を分割'
          );
        }
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption(
          s.phase === 'insert'
            ? '挿入ソート: 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
            : '比較: 位置 ' + s.lo + ' の値とピボット（位置 ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'swap'],
          [s.hi, 'swap'],
        ]);
        api.setCaption(
          s.phase === 'pivot'
            ? '選んだピボットを右端へ移しています…'
            : '交換しています…'
        );
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        if (s.phase === 'insert') {
          DemoSort.clearRoles(barsEl);
          api.setCaption(
            '挿入ソート完了: 位置 ' + s.lo + ' … ' + s.hi
          );
        } else {
          DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
          api.setCaption(
            'ピボット確定: 位置 ' +
              s.pivot +
              ' に小さい値群と大きい値群が分かれました'
          );
        }
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="median-of-three-quick-sort-demo"
  data_prefix="median-of-three-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)は分割手順が同じだが、ピボットを右端固定にする。本アルゴリズムはその右端へ移す前に三点中央値を選ぶ点が違う。

[ランダムピボット型クイックソート](/2026/08/15/sort-quick-random-pivot.html)は一様乱択で期待計算量を上げる。三点中央値は乱数を使わず、左端・中央・右端の比較だけで偏りを抑える。

[ホーア分割型クイックソート](/2026/08/14/sort-quick-hoare.html)は両端ポインタの分割で、返り値の意味と再帰区間の切り方が異なる。三点中央値はホーア分割とも組み合わせられるが、ここではロムート分割との組み合わせを示す。

[三分割クイックソート](/2026/08/12/sort-three-way-quick.html)は等値帯をその場で確定する。[デュアルピボットクイックソート](/2026/07/26/sort-dual-pivot-quick.html)はピボットを 2 つ使い 3 区間に分ける。いずれもピボット選びの三点中央値とは直交する改良である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000005 |        0.000032 |              57 |              64 |
|        512 |        0.000011 |        0.000054 |              62 |              68 |
|       1024 |        0.000024 |        0.000122 |              58 |              64 |
|       2048 |        0.000052 |        0.000271 |              58 |              64 |
|       4096 |        0.000112 |        0.000543 |              62 |              68 |
|       8192 |        0.000241 |        0.000898 |              65 |              72 |
|      16384 |        0.000520 |        0.000878 |              62 |              68 |
|      32768 |        0.001119 |        0.001794 |              58 |              64 |
|      65536 |        0.002382 |        0.003276 |              58 |              64 |
|     131072 |        0.005057 |        0.006681 |              73 |              80 |
|     262144 |        0.010675 |        0.013158 |              62 |              68 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="quick_median_of_three" %}
