---
title:     図書館ソートで配列を並べ替える
date:      2026-05-13 07:55:29 +0900
tags:      sort
sort_demo: true
---

## 図書館ソートを使用する

図書館ソート (`library sort`、**空隙付き挿入ソート**とも呼ばれる) は、整列済みデータを **隙間（空きスロット）を挟みながら** 棚に並べるイメージのソートである。新しい本（要素）を挿入するとき、適切な隙間に直接置ければ周りを大きく動かさずに済む。隙間が足りなければ、近くの空きへ本をずらしてから挿入する。

挿入位置の探索に二分探索を使えるため、ランダムな入力に対しては **比較回数が O(n log n)** になりやすい（詳細は隙間の取り方や再配置の戦略に依存する）。古典的な [挿入ソート](/2026/05/05/sort-insertion.html) と同じく **安定ソート** にできる。

1.  **棚（作業配列）**: 要素数より長いバッファを用意し、値が入っていないマスを **空き** とみなす。
2.  **まだ挿していない値** を1つずつ取り出す（入力順はデモではシャッフル後の並び）。
3.  **探索**: 棚上の値だけを対象に、挿入すべき **順序上の位置** を二分探索で求める。
4.  **挿入**: その区間に空きがあればそこへ値を書き込む。なければ **近い空きまで値を隣接交換でずらし**、空いたマスへ書き込む。
5.  **終了**: すべての値を置き終えたとき、左から右へ読めば昇順になっている（値同士の間に空きが残ってもよい）。

以下は手順を抽象的に示した疑似コードである。

```pseudocode
procedure library_sort_insert(keys, capacity)
  buf[0 .. capacity-1] = empty
  for each key in keys
    find sorted rank r of key among filled cells of buf
    choose a free cell at or near rank r (open with shifts if needed)
    buf[chosen] = key
```

デモでは **30マスの棚** に **15個の値** を順に挿入する。空きマスは灰色の短いバーで示す。実装の論文レベルの工夫（一定割合の隙間の維持や全体の再配置など）は省略し、**二分探索で順序位置を決め、必要なら右または左の空きへ向かって隣接スワップでずらす** ところまでを追えるようにしている。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('library-sort-demo', function (root) {
  const barClass = 'sort-demo__bar';

  function mountLibraryBars(container, buf) {
    container.innerHTML = '';
    const numbers = buf.filter(function (v) {
      return v > 0;
    });
    const max = numbers.length ? Math.max.apply(null, numbers) : 1;
    const min = numbers.length ? Math.min.apply(null, numbers) : 0;
    const span = Math.max(max - min, 1);
    buf.forEach(function (v) {
      const bar = document.createElement('div');
      bar.className = barClass;
      if (v === 0) {
        bar.setAttribute('data-role', 'gap');
        bar.style.height = '14px';
        bar.setAttribute('title', '空き');
      } else {
        const h = 28 + ((v - min) / span) * 92;
        bar.style.height = h + 'px';
        bar.setAttribute('title', String(v));
      }
      container.appendChild(bar);
    });
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      '図書館ソートの棚。左から位置0の順。短い棒は空きマスです。'
    );
    DemoSort.syncBarsAccessibility(container);
  }

  function generateSteps(initial) {
    const buf = new Array(30).fill(0);
    const steps = [];

    function openGapRight(t) {
      if (buf[t] === 0) return;
      let g = t;
      while (g < buf.length && buf[g] !== 0) g++;
      if (g >= buf.length) {
        openGapLeft(t - 1);
        return;
      }
      for (let j = g - 1; j >= t; j--) {
        const tmp = buf[j];
        buf[j] = buf[j + 1];
        buf[j + 1] = tmp;
        steps.push({ kind: 'shift', lo: j, hi: j + 1, arr: buf.slice() });
      }
    }

    function openGapLeft(t) {
      if (buf[t] === 0) return;
      let g = t;
      while (g >= 0 && buf[g] !== 0) g--;
      if (g < 0) {
        openGapRight(t + 1);
        return;
      }
      for (let j = g; j < t; j++) {
        const tmp = buf[j];
        buf[j] = buf[j + 1];
        buf[j + 1] = tmp;
        steps.push({ kind: 'shift', lo: j, hi: j + 1, arr: buf.slice() });
      }
    }

    for (let k = 0; k < initial.length; k++) {
      const key = initial[k];
      const occ = [];
      for (let i = 0; i < buf.length; i++) {
        if (buf[i] > 0) occ.push(i);
      }

      if (occ.length === 0) {
        steps.push({ kind: 'next_key', key: key, arr: buf.slice() });
        const t = Math.floor(buf.length / 2);
        steps.push({ kind: 'insert', p: t, key: key, arr: buf.slice() });
        buf[t] = key;
        steps.push({ kind: 'after_insert', arr: buf.slice() });
        continue;
      }

      let lo = 0;
      let hi = occ.length;
      while (lo < hi) {
        const mid = (lo + hi) >> 1;
        const idx = occ[mid];
        steps.push({
          kind: 'search_compare',
          shelfIdx: idx,
          key: key,
          arr: buf.slice(),
        });
        if (buf[idx] < key) lo = mid + 1;
        else hi = mid;
      }
      const rank = lo;
      const leftBound = rank === 0 ? -1 : occ[rank - 1];
      const rightBound = rank === occ.length ? buf.length : occ[rank];

      steps.push({ kind: 'next_key', key: key, arr: buf.slice() });

      let t = -1;
      for (let p = leftBound + 1; p < rightBound; p++) {
        if (buf[p] === 0) {
          t = p;
          break;
        }
      }
      if (t < 0) {
        if (rightBound < buf.length) {
          t = rightBound;
        } else {
          t = leftBound + 1;
          if (t >= buf.length) t = buf.length - 1;
        }
        if (buf[t] !== 0) {
          let g = t;
          while (g < buf.length && buf[g] !== 0) g++;
          if (g < buf.length) openGapRight(t);
          else openGapLeft(t - 1);
        }
      }

      steps.push({ kind: 'insert', p: t, key: key, arr: buf.slice() });
      buf[t] = key;
      steps.push({ kind: 'after_insert', arr: buf.slice() });
    }

    steps.push({ kind: 'done', arr: buf.slice() });
    return steps;
  }

  const initialCaption =
    '図書館ソートのデモ（空き＝灰色の短いバー。比較はオレンジ、ずらしは緑、挿入先は紫）';

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-library',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption: initialCaption,
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    rebuild: function (api, v) {
      api.values = v;
      api.steps = generateSteps(v.slice());
      api.idx = 0;
      const st = api.steps[0];
      mountLibraryBars(api.barsEl, st ? st.arr : new Array(30).fill(0));
      api.setCaption(initialCaption);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'search_compare') {
        mountLibraryBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.shelfIdx, 'compare']]);
        api.setCaption(
          '二分探索: キー ' +
            s.key +
            ' と棚・位置 ' +
            s.shelfIdx +
            ' の値を比較'
        );
        return;
      }
      if (s.kind === 'next_key') {
        mountLibraryBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('次のキー ' + s.key + ' を挿入します');
        return;
      }
      if (s.kind === 'insert') {
        mountLibraryBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.p, 'insert']]);
        api.setCaption(
          'キー ' + s.key + ' を位置 ' + s.p + ' の空きへ置きます'
        );
        return;
      }
      if (s.kind === 'after_insert') {
        mountLibraryBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('挿入しました');
        return;
      }
      if (s.kind === 'shift') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('空きを作るため隣接要素をずらしています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        mountLibraryBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ずらしました（位置 ' + s.lo + ' と ' + s.hi + '）');
        return;
      }
      if (s.kind === 'done') {
        mountLibraryBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了（棚上の値は左から右へ昇順）');
      }
    },
    stepPauseMs: 220,
  });
});
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="library-sort-demo"
  preset="library"
  data_prefix="library"
  script=sort_demo_js
%}

概念的には「棚に空きを残しておく」ことで [挿入ソート](/2026/05/05/sort-insertion.html) で毎回長いシフトが続く状況を緩和しようとする発想である。実装や定数の取り方次第では再配置のコストが支配的になる場合もあるため、用途に合わせてマージソートやヒープソートなどとも比較したい。
