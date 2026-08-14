---
title:     パターン撃退クイックソートで配列を並び替える
date:      2026-07-27 12:03:02 +0900
tags:      sort
sort_demo: true
---

## パターン撃退クイックソートを使用する

パターン撃退クイックソート (`pattern-defeating quicksort`) は、[イントロソート](/2026/05/07/sort-intro.html)を拡張したハイブリッドな比較ソートである。

Rust の標準ライブラリや Go 1.19 以降の `sort` パッケージなどでも採用されている。

基本は[ロムート分割型クイックソート](/2026/05/02/sort-quick-lumoto.html)だが、次の仕掛けで「悪い入力パターン」を撃退する。

1.  **ピボット選択**: 小区間は 3 要素の中央値、大きめの区間は Tukey の ninther（9 要素の疑似中央値）を使う。
2.  **等値の扱い**: 直前の分割でピボットと等しい値が左端に接しているときは、等値を左へ寄せる分割に切り替え、等値だらけの区間を再帰から外す。
3.  **不均衡の検知**: 左右の部分配列が元サイズの 1/8 未満に偏ったら、候補位置を入れ替えてパターンを崩す。偏りが `⌊log₂ n⌋` 回続くと[ヒープソート](/2026/05/04/sort-heap.html)へフォールバックする。
4.  **ほぼ整列の検知**: 分割がほとんど動かなかった区間には、移動回数に上限付きの部分挿入ソートを試し、成功すればその場で打ち切る。
5.  **小区間**: 要素数が閾値未満なら[挿入ソート](/2026/05/05/sort-insertion.html)で仕上げる。

```pseudocode
procedure pdqsort(A, lo, hi, bad_allowed, leftmost)
  while lo <= hi
    size = hi - lo + 1
    if size < INSERTION_THRESHOLD then
      insertion_sort(A, lo, hi)
      return
    choose_pivot_median3_or_ninther(A, lo, hi)
    if not leftmost and A[lo - 1] = A[lo] then
      lo = partition_left(A, lo, hi) + 1
      continue
    pivot_pos, already = partition_right(A, lo, hi)
    l = pivot_pos - lo
    r = hi - pivot_pos
    if l < size / 8 or r < size / 8 then
      if bad_allowed = 0 then
        heapsort(A, lo, hi)
        return
      bad_allowed = bad_allowed - 1
      shuffle_candidates(A, lo, pivot_pos, hi)
    else if already and partial_insertion(A, lo, pivot_pos - 1)
                    and partial_insertion(A, pivot_pos + 1, hi) then
      return
    pdqsort(A, lo, pivot_pos - 1, bad_allowed, leftmost)
    lo = pivot_pos + 1
    leftmost = false

procedure sort(A)
  if length(A) > 1 then
    pdqsort(A, 0, length(A) - 1, floor(log2(length(A))), true)
```

平均計算量は `O(n log n)`、最悪もヒープソートへの切り替えにより `O(n log n)` に抑えられる。一般に不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('pattern-defeating-quick-sort-demo', function (root) {
  /** デモ用に小区間閾値を小さめにし、クイック／撃退フェーズが見えやすくしている。 */
  const INSERTION_THRESHOLD = 4;
  const PARTIAL_LIMIT = 2;

  function floorLog2(n) {
    if (n <= 1) return 0;
    return Math.floor(Math.log2(n));
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function sort2(i, j) {
      steps.push({ kind: 'compare', lo: i, hi: j, arr: a.slice(), phase: 'pivot' });
      if (a[j] < a[i]) {
        const t = a[i];
        a[i] = a[j];
        a[j] = t;
        steps.push({ kind: 'swap', lo: i, hi: j, arr: a.slice(), phase: 'pivot' });
      }
    }

    function sort3(i, j, k) {
      sort2(i, j);
      sort2(j, k);
      sort2(i, j);
    }

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

    function partialInsertion(lo, hi) {
      if (hi < lo) return true;
      let limit = 0;
      for (let i = lo + 1; i <= hi; i++) {
        if (a[i] < a[i - 1]) {
          const tmp = a[i];
          let j = i;
          do {
            a[j] = a[j - 1];
            j--;
          } while (j > lo && tmp < a[j - 1]);
          a[j] = tmp;
          limit += i - j;
          steps.push({
            kind: 'phase',
            text:
              '部分挿入ソート: 位置 ' +
              lo +
              ' … ' +
              hi +
              '（移動累計 ' +
              limit +
              ' / 上限 ' +
              PARTIAL_LIMIT +
              '）',
            arr: a.slice(),
          });
          if (limit > PARTIAL_LIMIT) return false;
        }
      }
      return true;
    }

    function siftDown(lo0, heapLen, startRel) {
      let i = startRel;
      while (true) {
        const l = 2 * i + 1;
        const r = 2 * i + 2;
        let largest = i;
        if (l < heapLen) {
          steps.push({
            kind: 'compare',
            lo: lo0 + largest,
            hi: lo0 + l,
            arr: a.slice(),
            phase: 'heap',
          });
          if (a[lo0 + l] > a[lo0 + largest]) largest = l;
        }
        if (r < heapLen) {
          steps.push({
            kind: 'compare',
            lo: lo0 + largest,
            hi: lo0 + r,
            arr: a.slice(),
            phase: 'heap',
          });
          if (a[lo0 + r] > a[lo0 + largest]) largest = r;
        }
        if (largest === i) break;
        const tmp = a[lo0 + i];
        a[lo0 + i] = a[lo0 + largest];
        a[lo0 + largest] = tmp;
        steps.push({
          kind: 'swap',
          lo: lo0 + i,
          hi: lo0 + largest,
          arr: a.slice(),
          phase: 'heap',
        });
        i = largest;
      }
    }

    function heapsortRange(lo0, hi0) {
      steps.push({ kind: 'heap_start', lo: lo0, hi: hi0, arr: a.slice() });
      const n = hi0 - lo0 + 1;
      for (let i = Math.floor(n / 2) - 1; i >= 0; i--) {
        siftDown(lo0, n, i);
      }
      for (let i = n - 1; i > 0; i--) {
        const t = a[lo0];
        a[lo0] = a[lo0 + i];
        a[lo0 + i] = t;
        steps.push({ kind: 'swap', lo: lo0, hi: lo0 + i, arr: a.slice(), phase: 'heap' });
        siftDown(lo0, i, 0);
      }
      steps.push({ kind: 'heap_done', lo: lo0, hi: hi0, arr: a.slice() });
    }

    function partitionRight(lo, hi) {
      const pivot = a[lo];
      let first = lo;
      let last = hi + 1;
      do {
        first++;
      } while (a[first] < pivot);
      if (first - 1 === lo) {
        do {
          if (first >= last) break;
          last--;
        } while (!(a[last] < pivot));
      } else {
        do {
          last--;
        } while (!(a[last] < pivot));
      }
      const already = first >= last;
      while (first < last) {
        const t = a[first];
        a[first] = a[last];
        a[last] = t;
        steps.push({
          kind: 'swap',
          lo: first,
          hi: last,
          arr: a.slice(),
          phase: 'quick',
        });
        do {
          first++;
        } while (a[first] < pivot);
        do {
          last--;
        } while (!(a[last] < pivot));
      }
      const pivotPos = first - 1;
      a[lo] = a[pivotPos];
      a[pivotPos] = pivot;
      steps.push({
        kind: 'swap',
        lo: lo,
        hi: pivotPos,
        arr: a.slice(),
        phase: 'pivot_place',
      });
      return { pivotPos: pivotPos, already: already };
    }

    function partitionLeft(lo, hi) {
      const pivot = a[lo];
      let first = lo;
      let last = hi + 1;
      do {
        last--;
      } while (pivot < a[last]);
      if (last === hi) {
        do {
          if (first >= last) break;
          first++;
        } while (!(pivot < a[first]));
      } else {
        do {
          first++;
        } while (!(pivot < a[first]));
      }
      while (first < last) {
        const t = a[first];
        a[first] = a[last];
        a[last] = t;
        steps.push({
          kind: 'swap',
          lo: first,
          hi: last,
          arr: a.slice(),
          phase: 'equals',
        });
        do {
          last--;
        } while (pivot < a[last]);
        do {
          first++;
        } while (!(pivot < a[first]));
      }
      a[lo] = a[last];
      a[last] = pivot;
      steps.push({
        kind: 'swap',
        lo: lo,
        hi: last,
        arr: a.slice(),
        phase: 'pivot_place',
      });
      return last;
    }

    function pdq(lo, hi, badAllowed, leftmost) {
      while (lo <= hi) {
        const size = hi - lo + 1;
        if (size <= INSERTION_THRESHOLD) {
          steps.push({
            kind: 'phase',
            text:
              '要素が ' +
              size +
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
          bad: badAllowed,
          arr: a.slice(),
        });
        const mid = lo + Math.floor(size / 2);
        sort3(mid, lo, hi);
        steps.push({
          kind: 'phase',
          text: '3 要素の中央値をピボット候補として左端へ（位置 ' + lo + '）',
          arr: a.slice(),
        });

        if (!leftmost && !(a[lo - 1] < a[lo])) {
          steps.push({
            kind: 'phase',
            text:
              '左隣がピボットと等しいため、等値を左へ寄せる分割へ切替え',
            arr: a.slice(),
          });
          lo = partitionLeft(lo, hi) + 1;
          if (lo > hi) return;
          continue;
        }

        const part = partitionRight(lo, hi);
        const pivotPos = part.pivotPos;
        const lSize = pivotPos - lo;
        const rSize = hi - pivotPos;
        steps.push({
          kind: 'part_end',
          pivot: pivotPos,
          bad: badAllowed,
          arr: a.slice(),
        });

        const unbalanced = lSize < size / 8 || rSize < size / 8;
        if (unbalanced) {
          if (badAllowed === 0) {
            steps.push({
              kind: 'phase',
              text:
                '不均衡分割が上限に達したため、この範囲はヒープソートへ（最悪 `O(n log n)` を担保）',
              arr: a.slice(),
            });
            heapsortRange(lo, hi);
            return;
          }
          badAllowed -= 1;
          steps.push({
            kind: 'phase',
            text:
              '不均衡を検知（左 ' +
              lSize +
              ' / 右 ' +
              rSize +
              '）。候補を入れ替えてパターンを崩す（残り許容 ' +
              badAllowed +
              '）',
            arr: a.slice(),
          });
          if (lSize >= INSERTION_THRESHOLD) {
            const t1 = a[lo];
            a[lo] = a[lo + Math.floor(lSize / 4)];
            a[lo + Math.floor(lSize / 4)] = t1;
            steps.push({
              kind: 'swap',
              lo: lo,
              hi: lo + Math.floor(lSize / 4),
              arr: a.slice(),
              phase: 'shuffle',
            });
          }
          if (rSize >= INSERTION_THRESHOLD) {
            const t2 = a[hi];
            a[hi] = a[hi + 1 - Math.floor(rSize / 4)];
            a[hi + 1 - Math.floor(rSize / 4)] = t2;
            steps.push({
              kind: 'swap',
              lo: hi + 1 - Math.floor(rSize / 4),
              hi: hi,
              arr: a.slice(),
              phase: 'shuffle',
            });
          }
        } else if (
          part.already &&
          (pivotPos === lo || partialInsertion(lo, pivotPos - 1)) &&
          (pivotPos >= hi || partialInsertion(pivotPos + 1, hi))
        ) {
          steps.push({
            kind: 'phase',
            text: '既にほぼ分割済みのため、部分挿入ソートで打ち切り',
            arr: a.slice(),
          });
          return;
        }

        if (pivotPos > lo) {
          pdq(lo, pivotPos - 1, badAllowed, leftmost);
        }
        lo = pivotPos + 1;
        leftmost = false;
        if (lo > hi) return;
      }
    }

    if (a.length > 0) {
      pdq(0, a.length - 1, floorLog2(a.length), true);
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function rolePair(lo, hi, role) {
    if (lo == null || hi == null) return [];
    return [
      [lo, role],
      [hi, role],
    ];
  }

  function phaseRole(kind, phase) {
    if (phase === 'insert') return 'insert';
    if (phase === 'heap') return 'heap';
    return kind === 'swap' ? 'swap' : 'compare';
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-pattern-defeating-quick',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'パターン撃退クイックソートのデモ（不均衡検知・等値分割・ヒープ切替を可視化）',
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
      if (s.kind === 'heap_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ヒープソート開始: 位置 ' + s.lo + ' … ' + s.hi + ' の範囲を整列'
        );
        return;
      }
      if (s.kind === 'heap_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ヒープソート完了: 位置 ' + s.lo + ' … ' + s.hi + ' が整列しました'
        );
        return;
      }
      if (s.kind === 'part_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '分割開始: 位置 ' +
            s.lo +
            ' … ' +
            s.hi +
            '（不均衡の残り許容 ' +
            s.bad +
            '）'
        );
        return;
      }
      if (s.kind === 'part_end') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pivot, 'pivot']]);
        api.setCaption('ピボット確定: 位置 ' + s.pivot);
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          rolePair(s.lo, s.hi, phaseRole('compare', s.phase))
        );
        if (s.phase === 'insert') {
          api.setCaption('挿入ソート: 隣接要素を比較');
        } else if (s.phase === 'heap') {
          api.setCaption(
            'ヒープ: 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
          );
        } else {
          api.setCaption(
            'ピボット候補: 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
          );
        }
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(
          barsEl,
          rolePair(s.lo, s.hi, phaseRole('swap', s.phase))
        );
        const label =
          s.phase === 'shuffle'
            ? 'パターン崩し: 候補位置を入れ替え'
            : s.phase === 'equals'
              ? '等値を左側へ寄せる'
              : s.phase === 'pivot_place'
                ? 'ピボットを確定位置へ'
                : '交換しています…';
        api.setCaption(label);
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
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
  id="pattern-defeating-quick-sort-demo"
  data_prefix="pattern-defeating-quick"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[イントロソート](/2026/05/07/sort-intro.html)は再帰深度の上限でヒープソートへ切り替えるのに対し、
パターン撃退クイックソートは「分割の偏り」を数え、加えて等値の片寄せや部分挿入による早期終了、
不均衡時の候補シャッフルで悪パターン自体を崩す。

[デュアルピボットクイックソート](/2026/07/26/sort-dual-pivot-quick.html)は 1 回の走査で 3 分割する単一アルゴリズムの改良だが、
パターン撃退版は単一ピボットのままハイブリッド戦略で最悪ケースと現実的な入力パターンの両方に備える。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000011 |        0.000215 |              58 |              64 |
|        512 |        0.000022 |        0.000283 |              61 |              68 |
|       1024 |        0.000048 |        0.000355 |              57 |              64 |
|       2048 |        0.000105 |        0.001239 |              66 |              72 |
|       4096 |        0.000223 |        0.001628 |              61 |              68 |
|       8192 |        0.000470 |        0.001941 |              74 |              80 |
|      16384 |        0.000958 |        0.003703 |              58 |              64 |
|      32768 |        0.002042 |        0.006398 |              61 |              68 |
|      65536 |        0.004189 |        0.011259 |              57 |              64 |
|     131072 |        0.008602 |        0.016500 |              61 |              68 |
|     262144 |        0.018110 |        0.047239 |              62 |              68 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="pattern_defeating_quick" %}
