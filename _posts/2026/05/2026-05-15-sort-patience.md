---
title:     ペイシェンスソートで配列を並び替える
date:      2026-05-15 05:56:22 +0900
tags:      sort
sort_demo: true
---

## ペイシェンスソートを使用する

ペイシェンスソート (`patience sort`) は、左から並ぶ複数の山（パイル）に入力を順に載せ、その後山の一番上の値だけを読みながら昇順へ取り出していく。

[ソリティア](https://ja.wikipedia.org/wiki/%E3%82%BD%E3%83%AA%E3%83%86%E3%82%A3%E3%82%A2)でトランプを並べていく規則に似せたアルゴリズムである。

1.  **積載**: 入力配列を先頭から左へ見ていき、現在の値 `x` について、一番上の値が `x` より大きいなかで先頭にあるパイルを探し、その山の上へ `x` を載せる。

    該当する山がひとつもなければ、一番右に新しい山を増やしてそこに `x` だけ載せた状態から始める。

2.  **取出**: すべての山が空になるまで、一番上の値のうち現在の最小値を持っている山ひとつを選び、その値を取り除いて結果列の末尾へ付ける。

    一番上の値だけを対象とするのでマージソートと同種のマージ処理の特殊形だと見なせる。

```pseudocode
procedure patience_deal(elements)
  piles = sequence of piles, initially empty lists
  for each x in elements then
    i = smallest index where piles[i] is non-empty AND top(piles[i]) > x
           (otherwise i = undefined)
    if i is undefined then
      piles.append([x])
    else then
      push x onto piles[i]

procedure patience_collect(piles)
  result = []
  until all piles empty then
    p = pile index minimizing top(piles[p]), breaking ties arbitrarily
    y = pop top from piles[p]
    append y to result
  return result
```

山の総数によらず、一番上の値の参照にはヒープなどを使える。また積載のルールだけを切り離してみると、山の個数が増加部分列についてのモデルとも対応することが知られている。

安定ソートではなく、山と出力用の追加領域が要る。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('patience-sort-demo', function (root) {
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

      steps.push(
        stamp({
          kind: 'deal_look',
          piles: clonePiles(piles),
          merged: [],
          incoming: x,
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
            mergePhase: false,
            highlightPile: 0,
          })
        );
        continue;
      }

      let placed = false;
      for (let j = 0; j < piles.length; j++) {
        const pile = piles[j];
        const topVal = pile[pile.length - 1];
        steps.push(
          stamp({
            kind: 'deal_compare',
            piles: clonePiles(piles),
            merged: [],
            incoming: x,
            pileIdx: j,
            mergePhase: false,
            highlightPile: j,
          })
        );

        if (topVal > x) {
          pile.push(x);
          placed = true;
          steps.push(
            stamp({
              kind: 'deal_place',
              piles: clonePiles(piles),
              merged: [],
              incoming: null,
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
        const v = piles[p][piles[p].length - 1];
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

      piles[best].pop();
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

  function barHeight(val, mn, mx) {
    const span = Math.max(mx - mn, 1);
    return 28 + ((val - mn) / span) * 92;
  }

  function mountPatienceBars(container, s) {
    container.innerHTML = '';
    container.setAttribute('role', 'group');
    container.setAttribute(
      'aria-label',
      'ペイシェンスソートの現在の状態（山・取り出し結果）。'
    );
    const wrap = document.createElement('div');
    wrap.className = 'sort-demo-patience-wrap';
    const mn = s.rangeMin;
    const mx = s.rangeMax;

    function mkBar(val, role) {
      const bar = document.createElement('div');
      bar.className = barClass;
      bar.style.height = barHeight(val, mn, mx) + 'px';
      bar.setAttribute('title', String(val));
      if (role) bar.setAttribute('data-role', role);
      bar.setAttribute(
        'aria-label',
        DemoSort.barAccessibilityLabelSimple(String(val), role)
      );
      return bar;
    }

    const dealRow = document.createElement('div');
    dealRow.className = 'sort-demo-patience__row';

    const incomingCol = document.createElement('div');
    incomingCol.className = 'sort-demo-patience__incoming';
    if (
      !s.mergePhase &&
      typeof s.incoming === 'number' &&
      !Number.isNaN(s.incoming)
    ) {
      let incRole = null;
      if (s.kind === 'deal_look' || s.kind === 'deal_compare')
        incRole = 'compare';
      incomingCol.appendChild(mkBar(s.incoming, incRole));
    }
    dealRow.appendChild(incomingCol);

    const pilesRow = document.createElement('div');
    pilesRow.className = 'sort-demo-patience__piles-row';

    s.piles.forEach(function (pile, idx) {
      const col = document.createElement('div');
      col.className = 'sort-demo-patience__pile-col';
      pile.forEach(function (cardVal, ki) {
        const isTop = ki === pile.length - 1;
        let hitRole = null;
        if (s.highlightPile === idx && isTop && s.kind === 'deal_compare') {
          hitRole = 'compare';
        }
        if (s.highlightPile === idx && isTop && s.kind === 'merge_pick') {
          hitRole = 'compare';
        }
        if (
          s.highlightPile === idx &&
          isTop &&
          (s.kind === 'deal_place' || s.kind === 'deal_new')
        ) {
          hitRole = 'swap';
        }
        col.appendChild(mkBar(cardVal, hitRole));
      });
      pilesRow.appendChild(col);
    });

    dealRow.appendChild(pilesRow);
    wrap.appendChild(dealRow);

    if (s.mergePhase || (s.merged && s.merged.length > 0)) {
      const mb = document.createElement('div');
      mb.className = 'sort-demo-patience__merged-block';

      const lab = document.createElement('span');
      lab.className = 'sort-demo-patience__merged-label';
      lab.textContent = '取り出し結果';

      const mergedBars = document.createElement('div');
      mergedBars.className = 'sort-demo-patience__merged-row';
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
        mergedBars.appendChild(mkBar(val, r));
      });

      mb.appendChild(lab);
      mb.appendChild(mergedBars);
      wrap.appendChild(mb);
    }

    container.appendChild(wrap);
  }

  const initialCaption =
    'ペイシェンスソート（左へ積み、一番上の値の最小を順に結果へ。比較＝オレンジ、積んだ山＝緑の枠）';

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-patience',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption: initialCaption,
    barClass: barClass,
    generateSteps: generateSteps,
    rebuild: function (api, v) {
      api.values = v;
      api.steps = generateSteps(v.slice());
      api.idx = 0;
      const first = api.steps[0];
      mountPatienceBars(api.barsEl, first || { piles: [], merged: [], rangeMin: 0, rangeMax: 1, mergePhase: false });
      api.setCaption(initialCaption);
    },
    applyStep: async function (api, s) {
      mountPatienceBars(api.barsEl, s);
      if (s.kind === 'deal_look') {
        api.setCaption(
          '積載: 次の値「' + s.incoming + '」を載せます（左から山の一番上の値と比べます）'
        );
      } else if (s.kind === 'deal_compare') {
        api.setCaption(
          '比較: 値「' +
            s.incoming +
            '」と「山' +
            (s.pileIdx + 1) +
            '」の一番上の値。より大きい値が見つかったら載せられます'
        );
      } else if (s.kind === 'deal_place') {
        api.setCaption(
          '山「' +
            (s.pileIdx + 1) +
            '」の一番上の値より小さいので、その上に載せました'
        );
      } else if (s.kind === 'deal_new') {
        api.setCaption('該当の山がなかったので右端に新しい山を増やしました');
      } else if (s.kind === 'merge_start') {
        api.setCaption('すべての入力を載せ終えました。一番上の値の最小を順に収集します');
      } else if (s.kind === 'merge_pick') {
        api.setCaption(
          '各山の一番上の値の最小は「山' +
            (s.pickPile + 1) +
            '」（オレンジ）です。この値を結果へ動かします'
        );
      } else if (s.kind === 'merge_took') {
        api.setCaption('一番上の値から「' + s.took + '」を取り出しました（緑）');
      } else if (s.kind === 'done') {
        api.setCaption('ソート完了（取り出し結果の左から昇順）');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="patience-sort-demo"
  data_prefix="patience"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[アンシャッフルソート](/2026/07/01/sort-unshuffle.html)もパイルへ載せてから整列する点は似ている。ペイシェンスソートは山の一番上の値が新要素より厳密に大きい山にだけ載せ、積載が終わったあと各山の一番上に見えている値のうち最小を繰り返し取り出して昇順列を組み立てる。山の個数は最長増加部分列の長さに対応することが知られている。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000021 |        0.000376 |            1670 |            1676 |
|        512 |        0.000050 |        0.000661 |            1678 |            1688 |
|       1024 |        0.000111 |        0.000467 |            1694 |            1704 |
|       2048 |        0.000264 |        0.001003 |            1726 |            1736 |
|       4096 |        0.000628 |        0.001742 |            1783 |            1800 |
|       8192 |        0.001561 |        0.001793 |            1907 |            1924 |
|      16384 |        0.003949 |        0.007335 |            2137 |            2164 |
|      32768 |        0.010260 |        0.040460 |            2481 |            2616 |
|      65536 |        0.027393 |        0.044625 |            3327 |            3328 |
|     131072 |        0.076682 |        0.154541 |            5134 |            5248 |
|     262144 |        0.222812 |        0.341926 |            8702 |            8832 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="patience" %}
