---
title:     アンシャッフルソートで配列を並び替える
date:      2026-07-01 09:30:32 +0900
tags:      sort
sort_demo: true
---

## アンシャッフルソートを使用する

アンシャッフルソート (`unshuffle sort`) は、入力を両端キュー（パイル）へ載せ、載せられなければ新しいパイルを増やし、最後にパイルをマージして昇順にする。

整列済みの山札を切って混ぜ直した状態を「元に戻す」イメージから名付けられた。整列済みに近い入力や、すでに単調な部分列が多いデータで効率が出やすい。

1.  **分布フェーズ**: 入力を左から走査し、各値 `x` について既存のパイル（両端にだけ追加できる整列済み両端キュー）を左から試す。先頭要素 `h` に対し `x <= h` なら先頭へ、末尾要素 `t` に対し `x >= t` なら末尾へ載せる。どのパイルにも載せられなければ右端に新しいパイルを増やす。
2.  **マージフェーズ**: 分布でできた複数のパイルを理想マージと呼ばれる逐次マージで 1 本の昇順列へ統合する。各パイル内部は先頭から末尾へ非減少に保たれる。

```pseudocode
procedure unshuffle_distribute(elements)
  piles = sequence of piles, initially empty deques
  for each x in elements then
    placed = false
    for each pile p in piles left to right then
      if x <= front(p) then
        push_front x onto p
        placed = true
        break
      else if x >= back(p) then
        push_back x onto p
        placed = true
        break
    if not placed then
      piles.append(deque containing only x)

procedure unshuffle_merge(piles)
  result = contents of piles[0]
  for i from 1 to length(piles) - 1 then
    result = merge_sorted(result, contents of piles[i])
  return result
```

要素の交換や中間挿入を避け、リンクの付け替えで済むため、もともとは単方向連結リスト向けに設計された。配列上では各パイルを両端キューとして模倣する実装が一般的である。

整列済みや逆順に近い入力では `O(n)` に近づく。大小が交互の並びでは最悪計算量 `O(n²)` となる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('unshuffle-sort-demo', function (root) {
  const barClass = 'sort-demo__bar';

  function clonePiles(piles) {
    return piles.map(function (pile) {
      return pile.slice();
    });
  }

  function generateSteps(initial) {
    const rangeMin = Math.min.apply(null, initial);
    const rangeMax = Math.max.apply(null, initial);
    function stamp(base) {
      const o =
        typeof base === 'object' && base !== null ? base : {};
      o.rangeMin = rangeMin;
      o.rangeMax = rangeMax;
      return o;
    }

    const a = initial.slice();
    const steps = [];
    const piles = [];
    const n = a.length;

    for (let i = 0; i < n; i++) {
      const x = a[i];
      const queueBefore = a.slice(i);
      const queueAfter = a.slice(i + 1);

      steps.push(
        stamp({
          kind: 'deal_look',
          piles: clonePiles(piles),
          merged: [],
          incoming: x,
          queue: queueBefore,
          mergePhase: false,
          highlightPile: null,
        })
      );

      if (piles.length === 0) {
        piles.push([x]);
        steps.push(
          stamp({
            kind: 'deal_new',
            piles: clonePiles(piles),
            merged: [],
            incoming: null,
            queue: queueAfter,
            mergePhase: false,
            highlightPile: 0,
          })
        );
        continue;
      }

      let placed = false;
      for (let j = 0; j < piles.length; j++) {
        const pile = piles[j];
        const head = pile[0];
        const tail = pile[pile.length - 1];

        steps.push(
          stamp({
            kind: 'deal_compare_head',
            piles: clonePiles(piles),
            merged: [],
            incoming: x,
            queue: queueBefore,
            pileIdx: j,
            mergePhase: false,
            highlightPile: j,
          })
        );

        if (x <= head) {
          pile.unshift(x);
          placed = true;
          steps.push(
            stamp({
              kind: 'deal_head',
              piles: clonePiles(piles),
              merged: [],
              incoming: null,
              queue: queueAfter,
              pileIdx: j,
              mergePhase: false,
              highlightPile: j,
            })
          );
          break;
        }

        steps.push(
          stamp({
            kind: 'deal_compare_tail',
            piles: clonePiles(piles),
            merged: [],
            incoming: x,
            queue: queueBefore,
            pileIdx: j,
            mergePhase: false,
            highlightPile: j,
          })
        );

        if (x >= tail) {
          pile.push(x);
          placed = true;
          steps.push(
            stamp({
              kind: 'deal_tail',
              piles: clonePiles(piles),
              merged: [],
              incoming: null,
              queue: queueAfter,
              pileIdx: j,
              mergePhase: false,
              highlightPile: j,
            })
          );
          break;
        }
      }

      if (!placed) {
        piles.push([x]);
        steps.push(
          stamp({
            kind: 'deal_new',
            piles: clonePiles(piles),
            merged: [],
            incoming: null,
            queue: queueAfter,
            mergePhase: false,
            highlightPile: piles.length - 1,
          })
        );
      }
    }

    steps.push(
      stamp({
        kind: 'merge_start',
        piles: clonePiles(piles),
        merged: [],
        incoming: null,
        mergePhase: true,
      })
    );

    const sortedOut = [];

    while (true) {
      let best = -1;
      let bestV = Infinity;
      for (let p = 0; p < piles.length; p++) {
        if (piles[p].length === 0) continue;
        const v = piles[p][0];
        if (v < bestV) {
          bestV = v;
          best = p;
        }
      }
      if (best === -1) break;

      steps.push(
        stamp({
          kind: 'merge_pick',
          piles: clonePiles(piles),
          merged: sortedOut.slice(),
          mergePhase: true,
          pickPile: best,
          highlightPile: best,
        })
      );

      piles[best].shift();
      sortedOut.push(bestV);

      steps.push(
        stamp({
          kind: 'merge_took',
          piles: clonePiles(piles),
          merged: sortedOut.slice(),
          took: bestV,
          mergePhase: true,
          highlightMergedIdx: sortedOut.length - 1,
        })
      );
    }

    steps.push(
      stamp({
        kind: 'done',
        piles: clonePiles(piles),
        merged: sortedOut.slice(),
        incoming: null,
        mergePhase: true,
      })
    );
    return steps;
  }

  function mountUnshuffleBars(container, s) {
    container.innerHTML = '';
    container.setAttribute('role', 'group');
    container.setAttribute(
      'aria-label',
      'アンシャッフルソートの現在の状態（パイル・マージ結果）。'
    );
    const wrap = document.createElement('div');
    wrap.className = 'sort-demo-unshuffle-wrap';

    function mkChip(val, role) {
      const chip = document.createElement('div');
      chip.className = 'sort-demo-unshuffle__chip sort-demo__bar';
      chip.textContent = String(val);
      chip.setAttribute('title', String(val));
      if (role) chip.setAttribute('data-role', role);
      chip.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabelSimple(String(val), role)
      );
      return chip;
    }

    if (s.mergePhase || (s.merged && s.merged.length > 0)) {
      const mergedBlock = document.createElement('div');
      mergedBlock.className = 'sort-demo-unshuffle__merged-block';

      const mergedLab = document.createElement('span');
      mergedLab.className = 'sort-demo-unshuffle__section-label';
      mergedLab.textContent = 'マージ結果';

      const mergedTrack = document.createElement('div');
      mergedTrack.className = 'sort-demo-unshuffle__merged-track';
      mergedTrack.setAttribute('role', 'list');
      const merged = s.merged || [];

      merged.forEach(function (val, wi) {
        let r = null;
        if (
          s.kind === 'merge_took' &&
          typeof s.highlightMergedIdx === 'number' &&
          wi === s.highlightMergedIdx
        ) {
          r = 'swap';
        }
        mergedTrack.appendChild(mkChip(val, r));
      });

      mergedBlock.appendChild(mergedLab);
      mergedBlock.appendChild(mergedTrack);
      wrap.appendChild(mergedBlock);
    }

    if (!s.mergePhase) {
      const incomingBlock = document.createElement('div');
      incomingBlock.className = 'sort-demo-unshuffle__incoming-block';

      const incomingLab = document.createElement('span');
      incomingLab.className = 'sort-demo-unshuffle__section-label';
      incomingLab.textContent = '次の値';

      const incomingTrack = document.createElement('div');
      incomingTrack.className = 'sort-demo-unshuffle__incoming-track';
      incomingTrack.setAttribute('role', 'list');
      const queue =
        Array.isArray(s.queue) && s.queue.length
          ? s.queue
          : typeof s.incoming === 'number' && !Number.isNaN(s.incoming)
            ? [s.incoming]
            : [];
      const comparing =
        s.kind === 'deal_look' ||
        s.kind === 'deal_compare_head' ||
        s.kind === 'deal_compare_tail';
      queue.forEach(function (val, qi) {
        let incRole = null;
        if (qi === 0 && comparing) {
          incRole = 'compare';
        }
        incomingTrack.appendChild(mkChip(val, incRole));
      });

      incomingBlock.appendChild(incomingLab);
      incomingBlock.appendChild(incomingTrack);
      wrap.appendChild(incomingBlock);
    }

    const hasPiles = (s.piles || []).some(function (pile) {
      return pile.length > 0;
    });
    if (hasPiles) {
      const pilesBlock = document.createElement('div');
      pilesBlock.className = 'sort-demo-unshuffle__piles-block';

      const pilesLab = document.createElement('span');
      pilesLab.className = 'sort-demo-unshuffle__section-label';
      pilesLab.textContent = s.mergePhase
        ? '残りパイル（左が先頭）'
        : 'パイル（左が先頭・右が末尾）';

      const pilesList = document.createElement('div');
      pilesList.className = 'sort-demo-unshuffle__piles-list';

      s.piles.forEach(function (pile, idx) {
        if (pile.length === 0) return;

        const pileRow = document.createElement('div');
        pileRow.className = 'sort-demo-unshuffle__pile-row';
        if (s.highlightPile === idx) {
          pileRow.classList.add('sort-demo-unshuffle__pile-row--active');
        }

        const pileLabel = document.createElement('span');
        pileLabel.className = 'sort-demo-unshuffle__pile-label';
        pileLabel.textContent = String(idx + 1);

        const track = document.createElement('div');
        track.className = 'sort-demo-unshuffle__pile-track';
        track.setAttribute('role', 'list');

        pile.forEach(function (cardVal, ki) {
          const isHead = ki === 0;
          const isTail = ki === pile.length - 1;
          let hitRole = null;
          if (s.highlightPile === idx && isHead && s.kind === 'deal_compare_head') {
            hitRole = 'compare';
          }
          if (s.highlightPile === idx && isTail && s.kind === 'deal_compare_tail') {
            hitRole = 'compare';
          }
          if (s.highlightPile === idx && isHead && s.kind === 'merge_pick') {
            hitRole = 'compare';
          }
          if (s.highlightPile === idx && s.kind === 'deal_head' && isHead) {
            hitRole = 'swap';
          }
          if (s.highlightPile === idx && s.kind === 'deal_tail' && isTail) {
            hitRole = 'swap';
          }
          if (
            s.highlightPile === idx &&
            s.kind === 'deal_new' &&
            pile.length === 1
          ) {
            hitRole = 'swap';
          }
          track.appendChild(mkChip(cardVal, hitRole));
        });

        pileRow.appendChild(pileLabel);
        pileRow.appendChild(track);
        pilesList.appendChild(pileRow);
      });

      pilesBlock.appendChild(pilesLab);
      pilesBlock.appendChild(pilesList);
      wrap.appendChild(pilesBlock);
    }

    container.appendChild(wrap);
  }

  const initialCaption =
    'アンシャッフルソート（各パイルは左が先頭・右が末尾。比較＝オレンジ、載せた位置＝緑）';

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-unshuffle',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption: initialCaption,
    barClass: barClass,
    generateSteps: generateSteps,
    rebuild: function (api, v) {
      api.values = v;
      api.steps = generateSteps(v.slice());
      api.idx = 0;
      const first = api.steps[0];
      mountUnshuffleBars(api.barsEl, first || {
        piles: [],
        merged: [],
        rangeMin: 0,
        rangeMax: 1,
        mergePhase: false,
      });
      api.setCaption(initialCaption);
    },
    applyStep: async function (api, s) {
      mountUnshuffleBars(api.barsEl, s);
      if (s.kind === 'deal_look') {
        api.setCaption(
          '分布: 左端の値「' + s.incoming + '」をパイルへ載せます'
        );
      } else if (s.kind === 'deal_compare_head') {
        api.setCaption(
          '先頭比較: 値「' +
            s.incoming +
            '」とパイル ' +
            (s.pileIdx + 1) +
            ' の先頭。小さければ先頭へ載せます'
        );
      } else if (s.kind === 'deal_compare_tail') {
        api.setCaption(
          '末尾比較: 値「' +
            s.incoming +
            '」とパイル ' +
            (s.pileIdx + 1) +
            ' の末尾。大きければ末尾へ載せます'
        );
      } else if (s.kind === 'deal_head') {
        api.setCaption(
          'パイル ' + (s.pileIdx + 1) + ' の先頭へ載せました（緑）'
        );
      } else if (s.kind === 'deal_tail') {
        api.setCaption(
          'パイル ' + (s.pileIdx + 1) + ' の末尾へ載せました（緑）'
        );
      } else if (s.kind === 'deal_new') {
        api.setCaption('載せ先がなかったので右端に新しいパイルを増やしました');
      } else if (s.kind === 'merge_start') {
        api.setCaption('分布完了。各パイル先頭の最小を順にマージします');
      } else if (s.kind === 'merge_pick') {
        api.setCaption(
          '各パイル先頭の最小はパイル ' +
            (s.pickPile + 1) +
            '（オレンジ）です。この値を結果へ移します'
        );
      } else if (s.kind === 'merge_took') {
        api.setCaption('先頭から「' + s.took + '」を取り出しました（緑）');
      } else if (s.kind === 'done') {
        api.setCaption('ソート完了（マージ結果の左から昇順）');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="unshuffle-sort-demo"
  data_prefix="unshuffle"
  script=sort_demo_js
%}

理想マージにより逐次 2 列マージを最適化するが、各パイルが内部で昇順であるため、デモでは各パイル先頭の最小を繰り返し取る k 路マージでも同じ結果が得られる。

## 類似アルゴリズムとの相違点

[ペイシェンスソート](/2026/05/15/sort-patience.html)もパイルへ載せるが、両端キューに先頭・末尾へ載せられる点と、理想マージによる統合が異なる。載せる条件も山の一番上だけに厳密に大きい値、というルールが違う。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000011 |        0.000046 |            1694 |            1704 |
|        512 |        0.000021 |        0.000079 |            1707 |            1716 |
|       1024 |        0.000045 |        0.000132 |            1737 |            1748 |
|       2048 |        0.000100 |        0.000235 |            1789 |            1800 |
|       4096 |        0.000252 |        0.000671 |            1901 |            1916 |
|       8192 |        0.000740 |        0.001788 |            2043 |            2060 |
|      16384 |        0.002407 |        0.003718 |            2276 |            2404 |
|      32768 |        0.007125 |        0.024242 |            3090 |            3328 |
|      65536 |        0.021105 |        0.092899 |            4602 |            4808 |
|     131072 |        0.062542 |        0.137245 |            7260 |            8328 |
|     262144 |        0.192843 |        0.524597 |           13557 |           14044 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="unshuffle" %}
