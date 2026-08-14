---
title:     ランダムピボット型クイックソートで配列を並び替える
date:      2026-08-15 08:03:34 +0900
tags:      sort
sort_demo: true
---

## ランダムピボット型クイックソートを使用する

ランダムピボット型クイックソート (`quick sort with random pivot`) は、分割のたびに部分配列から一様に選んだ要素をピボットにし、偏った分割が続く確率を下げる。

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)が右端固定だと昇順・降順に近い入力で最悪計算量 `O(n²)` になりやすいのに対し、乱択ピボットは入力の並び方に依存しにくく、期待計算量を `O(n log n)` に近づけやすい。分割そのものはロムート方式を使い、違いは「どの位置をピボットにするか」にある。

1.  **乱択ピボット**: 部分配列 `lo … hi` から添字を一様に 1 つ選び、その要素を右端へ移す。
2.  **ロムート分割**: 右端をピボットとして片方向走査し、「未満」と「以上」に分ける。返り値 `p` がピボットの最終位置になる。
3.  **再帰**: `lo … p - 1` と `p + 1 … hi` に同じ処理を繰り返す。十分短い区間は挿入ソートで仕上げる。

```pseudocode
procedure random_pivot_quick_sort(A, lo, hi)
  if lo >= hi then
    return
  if hi - lo < INSERTION_THRESHOLD then
    insertion_sort(A, lo, hi)
    return
  r = random_integer(lo, hi)
  swap(A[r], A[hi])
  p = lomuto_partition(A, lo, hi)
  random_pivot_quick_sort(A, lo, p - 1)
  random_pivot_quick_sort(A, p + 1, hi)

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

乱数は擬似乱数で足りる。最悪計算量の上界は依然として `O(n²)` だが、固定ピボットと比べて「いつも最悪になる入力」を攻撃者が作りにくくなる。一般に不安定である。

平均（期待）計算量は `O(n log n)`、追加空間は再帰スタックの `O(log n)` 程度を見込む。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('random-pivot-quick-sort-demo', function (root) {
  const INSERTION_THRESHOLD = 4;

  function makeRng(seed) {
    let state = seed >>> 0;
    return function next() {
      state ^= state << 13;
      state ^= state >>> 17;
      state ^= state << 5;
      return state >>> 0;
    };
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const next = makeRng(0x9e3779b9 ^ a.length);

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

    function randomPivotQuick(lo, hi) {
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

      const pivotIdx = lo + (next() % (hi - lo + 1));
      steps.push({
        kind: 'pick',
        lo,
        hi,
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
      randomPivotQuick(lo, p - 1);
      randomPivotQuick(p + 1, hi);
    }

    if (a.length > 0) {
      randomPivotQuick(0, a.length - 1);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-random-pivot-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ランダムピボット型クイックソートのデモ（比較はオレンジ、交換は緑、ピボットは紫）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'pick') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption(
          '乱択: 位置 ' +
            s.pivot +
            ' をピボットに選ぶ（範囲 ' +
            s.lo +
            ' … ' +
            s.hi +
            '）'
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
  id="random-pivot-quick-sort-demo"
  data_prefix="random-pivot-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)は分割手順が同じだが、ピボットを右端固定にする。本アルゴリズムはその右端へ移す前に乱択する点が違う。

[ホーア分割型クイックソート](/2026/08/14/sort-quick-hoare.html)は両端ポインタの分割で、返り値の意味と再帰区間の切り方が異なる。乱択ピボットはホーア分割とも組み合わせられるが、ここではロムート分割との組み合わせを示す。

[三分割クイックソート](/2026/08/12/sort-three-way-quick.html)は等値帯をその場で確定する。[デュアルピボットクイックソート](/2026/07/26/sort-dual-pivot-quick.html)はピボットを 2 つ使い 3 区間に分ける。いずれもピボット選びの乱択とは直交する改良である。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000005 |        0.000071 |              58 |              64 |
|        512 |        0.000011 |        0.000098 |              69 |              76 |
|       1024 |        0.000024 |        0.000102 |              73 |              80 |
|       2048 |        0.000051 |        0.000101 |              62 |              68 |
|       4096 |        0.000110 |        0.000314 |              61 |              68 |
|       8192 |        0.000237 |        0.000373 |              62 |              68 |
|      16384 |        0.000514 |        0.003550 |              78 |              84 |
|      32768 |        0.001103 |        0.001896 |              74 |              80 |
|      65536 |        0.002338 |        0.003196 |              66 |              72 |
|     131072 |        0.005010 |        0.007096 |              62 |              68 |
|     262144 |        0.011068 |        0.015481 |              77 |              84 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="quick_random_pivot" %}
