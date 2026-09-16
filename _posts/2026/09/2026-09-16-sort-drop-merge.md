---
title:     ドロップマージソートで配列を並び替える
date:      2026-09-16 23:33:31 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## ドロップマージソートを使用する

ドロップマージソート (`drop-merge sort`) は、ほぼ整列済みの入力向けに提案された適応的な不安定ソートである。

損失ソートとして知られるドロップソート（順序を崩す要素を捨てる）を「より多くの要素を残す」方向へ改良した近似的な最長非減少部分列（LNS）検出を土台にし、捨てた要素を別途ソートして戻しマージする。

整列済みリストへ少数の変更を加えたあと再ソートする、といった「大半がすでに昇順で、外れ値が散在する」場面で特に効く。`N` 個中 `K` 個が外れ値なら、比較回数の目安は $$O(N + K \log K)$$、追加メモリは $$O(K)$$ である。

1.  **最長非減少部分列の近似抽出**: 配列を左から走査し、直前に残した末尾以上ならその場へ詰めて残す。末尾より小さければいったん「ドロップ」（別リストへ退避）する。
2.  **誤採択の取り消し**: 連続ドロップが閾値（本稿では 8）に達したら、直前に残した要素が外れ値だったとみなし、その要素と必要ならさらに手前までをドロップへ戻して読み位置を巻き戻す。直前 1 件だけが跳ね上がっている典型例は、連続ドロップ前の「1 つ手前との二重比較」で即時に取り消す。
3.  **早期打ち切り**: 走査の早い段階でドロップ率が高すぎるときは、ほぼ乱順と判断して配列全体をクイックソートへ委ねる。
4.  **マージ**: 残した非減少列と、ソート済みのドロップ列を末尾側からマージして元配列へ書き戻す。

```pseudocode
procedure drop_merge_sort(A)
  n = length(A)
  if n < 2 then
    return
  dropped = empty list
  write = 0
  read = 0
  num_dropped_in_row = 0
  while read < n
    if write == 0 or A[read] >= A[write - 1] then
      A[write] = A[read]
      write = write + 1
      read = read + 1
      num_dropped_in_row = 0
    else if num_dropped_in_row == 0 and write >= 2
         and A[read] >= A[write - 2] then
      append A[write - 1] to dropped
      A[write - 1] = A[read]
      read = read + 1
    else if num_dropped_in_row < RECENCY then
      append A[read] to dropped
      read = read + 1
      num_dropped_in_row = num_dropped_in_row + 1
    else
      undo last num_dropped_in_row drops
      backtrack write until a recently seen value can stay
      append backtracked values to dropped
      num_dropped_in_row = 0
  sort(dropped)  // e.g. quicksort
  merge A[0 .. write) and dropped into A from the right
```

ほぼ整列済みなら $$K$$ が小さく高速になる一方、乱順では早期打ち切り後のクイックソート相当になる。マージは同値の扱いを固定しないため不安定である。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('drop-merge-sort-demo', function (root) {
  const RECENCY = 8;
  const barClass = 'sort-demo__bar';

  function rangePairs(lo, hiExclusive, role) {
    const pairs = [];
    for (let k = lo; k < hiExclusive; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function displayState(kept, dropped, unread) {
    return kept.concat(dropped).concat(unread);
  }

  function generateSteps(initial) {
    const steps = [];
    const a = initial.slice();
    const n = a.length;
    if (n < 2) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    const dropped = [];
    let write = 0;
    let read = 0;
    let numDroppedInRow = 0;

    function pushScan(kind, extra) {
      const kept = a.slice(0, write);
      const unread = a.slice(read);
      const step = Object.assign(
        {
          kind: kind,
          arr: displayState(kept, dropped.slice(), unread),
          keptLen: kept.length,
          droppedLen: dropped.length,
        },
        extra || {}
      );
      steps.push(step);
    }

    pushScan('start');

    while (read < n) {
      if (write === 0 || a[read] >= a[write - 1]) {
        if (read !== write) {
          a[write] = a[read];
        }
        write += 1;
        read += 1;
        numDroppedInRow = 0;
        pushScan('keep', { index: write - 1 });
      } else if (
        numDroppedInRow === 0 &&
        write >= 2 &&
        a[read] >= a[write - 2]
      ) {
        dropped.push(a[write - 1]);
        a[write - 1] = a[read];
        read += 1;
        pushScan('quick_undo', {
          keptIndex: write - 1,
          droppedIndex: write + dropped.length - 1,
        });
      } else if (numDroppedInRow < RECENCY) {
        dropped.push(a[read]);
        read += 1;
        numDroppedInRow += 1;
        pushScan('drop', {
          droppedIndex: write + dropped.length - 1,
        });
      } else {
        dropped.splice(dropped.length - numDroppedInRow, numDroppedInRow);
        read -= numDroppedInRow;
        let numBacktracked = 1;
        write -= 1;
        let maxOfDropped = a[read];
        for (let i = 1; i <= numDroppedInRow; i++) {
          if (a[read + i] > maxOfDropped) {
            maxOfDropped = a[read + i];
          }
        }
        while (write >= 1 && maxOfDropped < a[write - 1]) {
          numBacktracked += 1;
          write -= 1;
        }
        for (let i = 0; i < numBacktracked; i++) {
          dropped.push(a[write + i]);
        }
        numDroppedInRow = 0;
        pushScan('backtrack', {
          backtracked: numBacktracked,
        });
      }
    }

    const keptFinal = a.slice(0, write);
    let droppedSorted = dropped.slice();
    droppedSorted.sort((x, y) => x - y);
    steps.push({
      kind: 'sort_dropped',
      arr: displayState(keptFinal, droppedSorted, []),
      keptLen: keptFinal.length,
      droppedLen: droppedSorted.length,
    });

    const merged = [];
    let i = 0;
    let j = 0;
    while (i < keptFinal.length && j < droppedSorted.length) {
      steps.push({
        kind: 'merge_compare',
        i: i,
        j: keptFinal.length + j,
        arr: displayState(
          merged.concat(keptFinal.slice(i)),
          droppedSorted.slice(j),
          []
        ),
        keptLen: merged.length + (keptFinal.length - i),
        droppedLen: droppedSorted.length - j,
        writePos: merged.length,
      });
      if (keptFinal[i] <= droppedSorted[j]) {
        merged.push(keptFinal[i]);
        i += 1;
      } else {
        merged.push(droppedSorted[j]);
        j += 1;
      }
      steps.push({
        kind: 'merge_write',
        writePos: merged.length - 1,
        arr: displayState(
          merged.concat(keptFinal.slice(i)),
          droppedSorted.slice(j),
          []
        ),
        keptLen: merged.length + (keptFinal.length - i),
        droppedLen: droppedSorted.length - j,
      });
    }
    while (i < keptFinal.length) {
      merged.push(keptFinal[i]);
      i += 1;
      steps.push({
        kind: 'merge_write',
        writePos: merged.length - 1,
        arr: displayState(merged.concat(keptFinal.slice(i)), [], []),
        keptLen: merged.length + (keptFinal.length - i),
        droppedLen: 0,
      });
    }
    while (j < droppedSorted.length) {
      merged.push(droppedSorted[j]);
      j += 1;
      steps.push({
        kind: 'merge_write',
        writePos: merged.length - 1,
        arr: displayState(merged, droppedSorted.slice(j), []),
        keptLen: merged.length,
        droppedLen: droppedSorted.length - j,
      });
    }

    steps.push({ kind: 'done', arr: merged });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-drop-merge',
    initialValues: [1, 2, 3, 14, 5, 6, 7, 8, 9, 10, 11, 12, 4, 13, 15],
    initialCaption:
      'ドロップマージソートのデモ（青＝残した LNS、比較はオレンジ、ドロップ／書き込みは緑）',
    barClass: barClass,
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      api.mountBars(barsEl, s.arr);
      if (s.kind === 'start') {
        DemoSort.clearRoles(barsEl);
        api.setCaption('走査開始: 非減少なら残し、崩れる要素はドロップへ');
        return;
      }
      if (s.kind === 'keep') {
        DemoSort.assignRoles(barsEl, rangePairs(0, s.keptLen, 'range'));
        api.setCaption('残す: 位置 ' + s.index + ' を LNS 末尾へ');
        return;
      }
      if (s.kind === 'drop') {
        const pairs = rangePairs(0, s.keptLen, 'range');
        pairs.push([s.droppedIndex, 'write']);
        DemoSort.assignRoles(barsEl, pairs);
        api.setCaption(
          'ドロップ: 表示位置 ' + s.droppedIndex + ' を退避リストへ'
        );
        return;
      }
      if (s.kind === 'quick_undo') {
        DemoSort.assignRoles(barsEl, [
          [s.keptIndex, 'compare'],
          [s.droppedIndex, 'write'],
        ]);
        api.setCaption(
          '二重比較で誤採択を取消: 跳ね上がりをドロップし、新しい値を残す'
        );
        return;
      }
      if (s.kind === 'backtrack') {
        DemoSort.assignRoles(
          barsEl,
          rangePairs(s.keptLen, s.keptLen + s.droppedLen, 'write')
        );
        api.setCaption(
          '連続ドロップが閾値に達したため ' +
            s.backtracked +
            ' 要素をバックトラック'
        );
        return;
      }
      if (s.kind === 'sort_dropped') {
        DemoSort.assignRoles(
          barsEl,
          rangePairs(0, s.keptLen, 'sorted').concat(
            rangePairs(s.keptLen, s.keptLen + s.droppedLen, 'range')
          )
        );
        api.setCaption('ドロップ列をソート（左が LNS、右がドロップ）');
        return;
      }
      if (s.kind === 'merge_compare') {
        DemoSort.assignRoles(barsEl, [
          [s.i, 'compare'],
          [s.j, 'compare'],
        ]);
        api.setCaption('マージ比較: 位置 ' + s.i + ' と ' + s.j);
        return;
      }
      if (s.kind === 'merge_write') {
        DemoSort.assignRoles(barsEl, [[s.writePos, 'write']]);
        api.setCaption('マージ確定: 位置 ' + s.writePos);
        return;
      }
      if (s.kind === 'done') {
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 220,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="drop-merge-sort-demo"
  data_prefix="drop-merge"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ナチュラルマージソート](/2026/07/28/sort-natural-merge.html)は隣接する自然ランをそのままマージするのに対し、ドロップマージは「1 本の長い非減少列をできるだけ残し、外れ値だけを別処理する」点が違う。ラン境界で切らず、飛び飛びの最長非減少部分列近似を取る。

[ストランドソート](/2026/05/16/sort-strand.html)も非減少部分列を抜き出してマージするが、毎回先頭からストランドを取り、残りは次ラウンドへ回す。ドロップマージは 1 回の走査で最長非減少部分列近似を固め、ドロップ側をまとめてソートしてから 1 度マージする。

[ティムソート](/2026/05/23/sort-tim.html)や[パワーソート](/2026/05/24/sort-power.html)は自然ランの検出に加え、短いランの拡張やスタック制約など実用向けの制御が多い。ドロップマージは「ほぼ整列＋散在する外れ値」に特化した単純なハイブリッドである。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size | Average time (s) | Maximum time (s) | Average memory (KiB) | Maximum memory (KiB) |
|-----------:|-----------------:|-----------------:|---------------------:|---------------------:|
|        256 |         0.000014 |         0.000181 |                    0 |                    0 |
|        512 |         0.000025 |         0.001978 |                    1 |                    1 |
|       1024 |         0.000048 |         0.000462 |                    2 |                    3 |
|       2048 |         0.000095 |         0.000649 |                    5 |                    6 |
|       4096 |         0.000197 |         0.000959 |                   11 |                   12 |
|       8192 |         0.000414 |         0.003557 |                   24 |                   24 |
|      16384 |         0.000796 |         0.009861 |                   48 |                   48 |
|      32768 |         0.001192 |         0.009827 |                   96 |                   96 |
|      65536 |         0.003016 |         0.019173 |                  196 |                  196 |
|     131072 |         0.007691 |         0.014485 |                  395 |                  395 |
|     262144 |         0.014065 |         0.030691 |                  791 |                  791 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="drop_merge" %}
