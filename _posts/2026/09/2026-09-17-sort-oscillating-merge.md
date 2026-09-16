---
title:     振動ソートで配列を並び替える
date:      2026-09-17 01:56:29 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## 振動ソートを使用する

振動ソート (`oscillating merge sort` / `oscillating sort`) は、後退読み取り可能なテープ向けに提案された外部マージ整列である。入力の分配（ラン生成）とマージを交互に進め、バランスマージのように全ランを先に配り切ってからマージパスへ入るのではなく、途中でマージを挟みながら大きなランを組み立てる。

テープ本数を $$n$$（入力 1 本 + 作業 $$n - 1$$ 本）とすると、各マージはおおむね $$n - 2$$ 方向になる。本稿のデモとベンチマークでは $$n = 5$$、すなわち 3 方向マージ（`WAY = 3`）と、作業テープ 4 本分に相当するレベル管理を採用する。

物理テープの代わりに「マージ段（レベル）」ごとのラン列をベクタで持ち、同レベルに `WAY` 本たまったら次レベルへ 1 本まとめる。バッチ長は $$3^0, 3^1, 3^2, \ldots$$ のように累乗で伸びる。

1.  **初期ラン生成**: 配列を固定長（デモは 3、計測は 32）の区間に区切り、各区間を内部整列してレベル 0 のランとする。
2.  **分配と振動**: 入力ランを最大 `WAY` 本ずつレベル 0 へ置き、そのたびに「同レベルに `WAY` 本あるか」を見てマージする。分配とマージを交互に繰り返すのが振動の由来である。
3.  **k 方向マージ**: `WAY` 本の昇順ランの先頭を比較し、最小（同値ならより左のラン）を出力へ確定する。結果は 1 段上のレベルへ 1 ランとして積む。
4.  **仕上げ**: 入力が尽きたあと、残った各レベルのランを同じ k 方向マージで 1 本にまとめて配列へ書き戻す。

後退読み取りそのものはメモリ上のシミュレーションでは省略する。テープ実装では、直前に書き出した昇順ランを後ろから読むことで巻き戻しを避けつつ次のマージに渡す、という点が歴史的な利点だった。

```pseudocode
procedure merge_k_way(runs[0..k))
  heads[i] = 0 for each run i
  while some run still has unread elements
    pick run i with smallest heads[i] value
      (ties: smallest i, for stability)
    append runs[i][heads[i]] to output
    heads[i] = heads[i] + 1
  return output

procedure collapse(by_level, lv)
  while length(by_level[lv]) >= WAY
    batch = take WAY runs from by_level[lv]
    append merge_k_way(batch) to by_level[lv + 1]
    collapse(by_level, lv + 1)

procedure oscillating_merge_sort(A)
  pending = create_runs(A, run_size)
  by_level[0] = empty list
  while pending is not empty
    for up to WAY runs from pending
      append run to by_level[0]
      collapse(by_level, 0)
  leftover = concatenate all by_level[*]
  while length(leftover) > 1
    k = min(WAY, length(leftover))
    append merge_k_way(leftover[0 .. k)) to leftover; drop those k
  copy leftover[0] back into A
```

パス数はおおよそ $$\log_{n-2}(N / r)$$（$$N$$ は要素数、$$r$$ は初期ラン長）なので、全体の時間は $$O(N \log N)$$ である。作業領域はランとマージバッファに依存し、テープ実装では追加メモリはほぼ定数、本稿のメモリ実装では $$O(N)$$ のバッファを使う。同値を左ラン優先で取れば安定ソートになる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('oscillating-merge-sort-demo', function (root) {
  const WAY = 3;
  const RUN_SIZE = 3;
  const barClass = 'sort-demo__bar';
  // 24 elements → 8 runs (WAY=3). Several merge→return cycles so oscillation is visible.
  const initialValues = [
    18, 5, 12, 2, 21, 9, 14, 1, 24, 7, 16, 4, 20, 11, 3, 23, 8, 15, 6, 19, 13, 22, 10, 17,
  ];
  const initialCaption =
    '振動ソート（24要素・ラン長3・WAY=3。上段=レベル0、下段=レベル1。マージは下へ、完了後は上へ1本ずつ）';

  function prefersReducedMotion() {
    try {
      return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    } catch (_e) {
      return false;
    }
  }

  function nextFrame() {
    return new Promise(function (resolve) {
      requestAnimationFrame(function () {
        requestAnimationFrame(resolve);
      });
    });
  }

  function cloneRuns(runs) {
    return runs.map(function (run) {
      return run.slice();
    });
  }

  function flattenRuns(runs) {
    const out = [];
    for (let i = 0; i < runs.length; i++) {
      out.push.apply(out, runs[i]);
    }
    return out;
  }

  function valueScale(values) {
    if (!values.length) {
      return { min: 0, span: 1 };
    }
    const max = Math.max.apply(null, values);
    const min = Math.min.apply(null, values);
    return { min: min, span: Math.max(max - min, 1) };
  }

  function mkBar(value, scale, role) {
    const bar = document.createElement('div');
    bar.className = barClass;
    const h = 28 + ((value - scale.min) / scale.span) * 92;
    bar.style.height = h + 'px';
    bar.setAttribute('title', String(value));
    if (role) {
      bar.setAttribute('data-role', role);
    }
    return bar;
  }

  function snapshot(level0Runs, level1, extras) {
    const s = Object.assign(
      {
        level0Runs: cloneRuns(level0Runs),
        level1: level1.slice(),
      },
      extras || {}
    );
    return s;
  }

  function mountOscillatingView(container, s) {
    const allValues = flattenRuns(s.level0Runs).concat(s.level1);
    const scale = valueScale(allValues.length ? allValues : initialValues);
    container.innerHTML = '';
    container.removeAttribute('role');
    container.removeAttribute('aria-label');

    const wrap = document.createElement('div');
    wrap.className = 'sort-demo-oscillating-wrap';

    function addRow(labelText, trackClass, runsOrFlat, flat) {
      const row = document.createElement('div');
      row.className = 'sort-demo-oscillating__row';
      const label = document.createElement('div');
      label.className = 'sort-demo-oscillating__label';
      label.textContent = labelText;
      const track = document.createElement('div');
      track.className = 'sort-demo-oscillating__track ' + trackClass;
      track.setAttribute('role', 'list');
      if (flat) {
        if (runsOrFlat.length === 0) {
          track.classList.add('sort-demo-oscillating__track--empty');
        }
        runsOrFlat.forEach(function (v, idx) {
          let role = null;
          if (s.kind === 'merge_write' && idx === runsOrFlat.length - 1) {
            role = 'write';
          }
          if (s.kind === 'return' && idx === 0) {
            role = 'cursor';
          }
          track.appendChild(mkBar(v, scale, role));
        });
      } else {
        const runs = runsOrFlat;
        if (runs.length === 0) {
          track.classList.add('sort-demo-oscillating__track--empty');
        }
        let offset = 0;
        runs.forEach(function (run, runIdx) {
          const group = document.createElement('div');
          group.className = 'sort-demo-oscillating__run';
          group.setAttribute('data-run', String(runIdx));
          run.forEach(function (v, i) {
            let role = null;
            if (s.kind === 'run_range') {
              const abs = offset + i;
              if (abs >= s.lo && abs <= s.hi) {
                role = s.kindRole || 'range';
              }
            }
            if (
              s.kind === 'merge_compare' &&
              s.headAbs &&
              s.headAbs.indexOf(offset + i) >= 0
            ) {
              role = offset + i === s.pickAbs ? 'cursor' : 'compare';
            }
            if (
              s.kind === 'merge_start' &&
              typeof s.mergeRunCount === 'number' &&
              runIdx < s.mergeRunCount
            ) {
              role = 'range';
            }
            if (s.kind === 'return' && runIdx === runs.length - 1 && i === run.length - 1) {
              role = 'write';
            }
            if (s.kind === 'done') {
              role = null;
            }
            group.appendChild(mkBar(v, scale, role));
          });
          track.appendChild(group);
          offset += run.length;
        });
      }
      row.appendChild(label);
      row.appendChild(track);
      wrap.appendChild(row);
      DemoSort.syncBarsAccessibility(track);
    }

    addRow('レベル0', 'sort-demo-oscillating__track--l0', s.level0Runs, false);
    addRow('レベル1', 'sort-demo-oscillating__track--l1', s.level1, true);
    container.appendChild(wrap);
  }

  function findL0Bar(container, absIndex) {
    const bars = container.querySelectorAll(
      '.sort-demo-oscillating__track--l0 .sort-demo__bar'
    );
    return bars[absIndex] || null;
  }

  function findL1Bar(container, index) {
    const bars = container.querySelectorAll(
      '.sort-demo-oscillating__track--l1 .sort-demo__bar'
    );
    return bars[index] || null;
  }

  async function flyBar(fromRect, toEl) {
    if (!fromRect || !toEl || prefersReducedMotion()) {
      return;
    }
    const toRect = toEl.getBoundingClientRect();
    const dx = fromRect.left - toRect.left;
    const dy = fromRect.top - toRect.top;
    if (dx === 0 && dy === 0) {
      return;
    }
    toEl.style.transition = 'none';
    toEl.style.transform = 'translate(' + dx + 'px,' + dy + 'px)';
    void toEl.offsetWidth;
    await nextFrame();
    toEl.style.transition = 'transform 220ms ease';
    toEl.style.transform = '';
    await DemoSort.transitionPromise(toEl);
    toEl.style.transition = '';
    toEl.style.transform = '';
  }

  function headAbsIndices(runs, headsMeta) {
    const abs = [];
    let offset = 0;
    const headOfRun = {};
    headsMeta.forEach(function (h) {
      headOfRun[h.run] = true;
    });
    for (let r = 0; r < runs.length; r++) {
      if (headOfRun[r] && runs[r].length > 0) {
        abs.push(offset);
      }
      offset += runs[r].length;
    }
    return abs;
  }

  function pickAbsIndex(runs, pickRun) {
    let offset = 0;
    for (let r = 0; r < runs.length; r++) {
      if (r === pickRun) {
        return offset;
      }
      offset += runs[r].length;
    }
    return 0;
  }

  function generateSteps(initial) {
    const steps = [];
    const values = initial.slice();
    let level0Runs = [values.slice()];
    let level1 = [];

    steps.push(
      snapshot(level0Runs, level1, {
        kind: 'start',
      })
    );

    const pending = [];
    const flat = values.slice();
    for (let i = 0; i < flat.length; i += RUN_SIZE) {
      const lo = i;
      const hi = Math.min(i + RUN_SIZE, flat.length) - 1;
      steps.push(
        snapshot(level0Runs, level1, {
          kind: 'run_range',
          kindRole: 'range',
          lo: lo,
          hi: hi,
        })
      );
      const run = flat.slice(lo, hi + 1);
      run.sort(function (x, y) {
        return x - y;
      });
      for (let j = 0; j < run.length; j++) {
        flat[lo + j] = run[j];
      }
      level0Runs = [flat.slice()];
      pending.push(run.slice());
      steps.push(
        snapshot(level0Runs, level1, {
          kind: 'run_range',
          kindRole: 'write',
          lo: lo,
          hi: hi,
          run: run.slice(),
        })
      );
    }

    if (pending.length <= 1) {
      level0Runs = pending.length === 1 ? [pending[0].slice()] : [];
      steps.push(snapshot(level0Runs, level1, { kind: 'done' }));
      return steps;
    }

    level0Runs = cloneRuns(pending);
    steps.push(
      snapshot(level0Runs, level1, {
        kind: 'runs_ready',
      })
    );

    // Oscillating: take up to WAY runs, merge onto level1 one bar at a time,
    // then return the merged run to level0 one bar at a time.
    while (level0Runs.length > 1) {
      const take = Math.min(WAY, level0Runs.length);
      const batch = level0Runs.splice(0, take);
      const kept = cloneRuns(level0Runs);

      level0Runs = cloneRuns(batch).concat(cloneRuns(kept));
      steps.push(
        snapshot(level0Runs, level1, {
          kind: 'merge_start',
          mergeRunCount: take,
        })
      );

      const heads = batch.map(function () {
        return 0;
      });
      const working = cloneRuns(batch);
      level1 = [];

      for (;;) {
        const displayBatch = working.filter(function (run) {
          return run.length > 0;
        });
        if (displayBatch.length === 0) {
          break;
        }

        let best = -1;
        let bestVal = 0;
        const live = [];
        for (let i = 0; i < displayBatch.length; i++) {
          live.push({ run: i, value: displayBatch[i][0] });
          const v = displayBatch[i][0];
          if (best < 0 || v < bestVal || (v === bestVal && i < best)) {
            best = i;
            bestVal = v;
          }
        }

        level0Runs = cloneRuns(displayBatch).concat(cloneRuns(kept));
        const headAbs = headAbsIndices(
          displayBatch,
          live.map(function (h) {
            return { run: h.run };
          })
        );
        const pickAbs = pickAbsIndex(displayBatch, best);
        steps.push(
          snapshot(level0Runs, level1, {
            kind: 'merge_compare',
            heads: live,
            pick: best,
            value: bestVal,
            headAbs: headAbs,
            pickAbs: pickAbs,
            pickRun: best,
          })
        );

        // Remove the chosen head from the matching non-empty working run.
        let seen = 0;
        for (let i = 0; i < working.length; i++) {
          if (working[i].length === 0) {
            continue;
          }
          if (seen === best) {
            working[i].shift();
            break;
          }
          seen += 1;
        }

        level1 = level1.concat([bestVal]);
        const visible = working.filter(function (run) {
          return run.length > 0;
        });
        level0Runs = cloneRuns(visible).concat(cloneRuns(kept));
        steps.push(
          snapshot(level0Runs, level1, {
            kind: 'merge_write',
            value: bestVal,
            pickRun: best,
            fromAbs: pickAbs,
            toIndex: level1.length - 1,
          })
        );
      }

      // Return merged level1 back to level0 one bar at a time.
      const merged = level1.slice();
      let returned = [];
      for (let i = 0; i < merged.length; i++) {
        const v = merged[i];
        level1 = merged.slice(i + 1);
        returned.push(v);
        level0Runs = [returned.slice()].concat(cloneRuns(kept));
        steps.push(
          snapshot(level0Runs, level1, {
            kind: 'return',
            value: v,
            fromIndex: 0,
            toAbs: returned.length - 1,
          })
        );
      }
      level1 = [];
      level0Runs = [merged.slice()].concat(cloneRuns(kept));
      steps.push(
        snapshot(level0Runs, level1, {
          kind: 'merge_done',
          merged: merged.slice(),
        })
      );
    }

    steps.push(snapshot(level0Runs, level1, { kind: 'done' }));
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-oscillating-merge',
    initialValues: initialValues,
    initialCaption: initialCaption,
    barClass: barClass,
    generateSteps: generateSteps,
    rebuild: function (api, v) {
      api.values = v;
      api.steps = generateSteps(v.slice());
      api.idx = 0;
      mountOscillatingView(api.barsEl, api.steps[0]);
      api.setCaption(initialCaption);
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      const stepIdx = api.idx - 1;
      const prev = stepIdx > 0 ? api.steps[stepIdx - 1] : null;

      if (
        s.kind === 'merge_write' &&
        prev &&
        !prefersReducedMotion() &&
        typeof s.fromAbs === 'number'
      ) {
        mountOscillatingView(barsEl, prev);
        await nextFrame();
        const fromEl = findL0Bar(barsEl, s.fromAbs);
        const fromRect = fromEl ? fromEl.getBoundingClientRect() : null;
        mountOscillatingView(barsEl, s);
        await nextFrame();
        const toEl = findL1Bar(barsEl, s.toIndex);
        await flyBar(fromRect, toEl);
      } else if (
        s.kind === 'return' &&
        prev &&
        !prefersReducedMotion()
      ) {
        mountOscillatingView(barsEl, prev);
        await nextFrame();
        const fromEl = findL1Bar(barsEl, 0);
        const fromRect = fromEl ? fromEl.getBoundingClientRect() : null;
        mountOscillatingView(barsEl, s);
        await nextFrame();
        const toEl = findL0Bar(barsEl, s.toAbs);
        await flyBar(fromRect, toEl);
      } else {
        mountOscillatingView(barsEl, s);
      }

      if (s.kind === 'start') {
        api.setCaption(
          'ソート前。下段のレベル1は空の作業列として用意しておく'
        );
      } else if (s.kind === 'run_range' && s.kindRole === 'range') {
        api.setCaption(
          '区間 [' + s.lo + '..' + s.hi + '] を内部整列してレベル0ランにします'
        );
      } else if (s.kind === 'run_range' && s.kindRole === 'write') {
        api.setCaption('ラン完成: [' + s.run.join(', ') + ']');
      } else if (s.kind === 'runs_ready') {
        api.setCaption(
          'レベル0に ' +
            s.level0Runs.length +
            ' 本のランが並んだ。同レベルが' +
            WAY +
            '本そろったらレベル1へマージする'
        );
      } else if (s.kind === 'merge_start') {
        api.setCaption(
          'レベル0先頭の ' +
            s.mergeRunCount +
            ' ランをマージし、結果を下段のレベル1へ1本ずつ書き込む'
        );
      } else if (s.kind === 'merge_compare') {
        const headText = s.heads
          .map(function (h) {
            return h.value;
          })
          .join(', ');
        api.setCaption(
          '各ラン先頭を比較（' + headText + '）→ ' + s.value + ' を選ぶ'
        );
      } else if (s.kind === 'merge_write') {
        api.setCaption(
          '選んだ ' + s.value + ' をレベル1（下段）へ1本移す'
        );
      } else if (s.kind === 'return') {
        api.setCaption(
          'マージ結果の ' + s.value + ' をレベル0（上段）へ1本戻す'
        );
      } else if (s.kind === 'merge_done') {
        api.setCaption(
          'レベル1が空に戻り、レベル0にマージ済みラン [' +
            s.merged.join(', ') +
            '] が残る'
        );
      } else if (s.kind === 'done') {
        api.setCaption('ソート完了（すべてレベル0）');
      }
    },
    stepPauseMs: 220,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="oscillating-merge-sort-demo"
  data_prefix="oscillating-merge"
  script=sort_demo_js
%}

デモでは上段をレベル0、下段を常設のレベル1作業列とする。マージで選んだ値は下段へ1本ずつ移し、マージが終わったらその結果を上段へ1本ずつ戻す。後退読み取り可能なテープでは、分配とマージを交互に進めることでドライブの空き時間と巻き戻しを抑えられる、というのが振動ソートの歴史的な狙いである。

## 類似アルゴリズムとの相違点

[マージソート](/2026/05/03/sort-merge.html)や[多方向マージソート](/2026/09/12/sort-multiway-merge.html)は、通常すべての分割（または初期ラン）を用意してから段階的にマージする。振動ソートは「少し分配してはマージする」点で位相が違う。

[ポリフェーズマージソート](/2026/06/26/sort-polyphase-merge.html)もテープ本数が少ない外部整列向けだが、フィボナッチ分布で全ランを先に配置してからパスを回す。振動ソートは分布を完了させず、$$n - 2$$ 方向のバッチを累乗で積み上げる。

本稿のレベル管理は、テープ上の「後ろから読む」詳細を省略した教育用モデルである。実テープでは読み書き方向の反転そのものが巻き戻し削減の本体になる。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size | Average time (s) | Maximum time (s) | Average memory (KiB) | Maximum memory (KiB) |
|-----------:|-----------------:|-----------------:|---------------------:|---------------------:|
|        256 |         0.000052 |         0.000473 |                    7 |                    7 |
|        512 |         0.000072 |         0.012272 |                   15 |                   15 |
|       1024 |         0.000114 |         0.000665 |                   27 |                   27 |
|       2048 |         0.000221 |         0.001313 |                   61 |                   61 |
|       4096 |         0.000421 |         0.007946 |                  135 |                  135 |
|       8192 |         0.000852 |         0.029075 |                  209 |                  209 |
|      16384 |         0.001841 |         0.015629 |                  544 |                  544 |
|      32768 |         0.003724 |         0.017902 |                 1089 |                 1089 |
|      65536 |         0.006871 |         0.029669 |                 2172 |                 2172 |
|     131072 |         0.014895 |         0.125831 |                 4330 |                 4330 |
|     262144 |         0.023055 |         0.332180 |                 8655 |                 8655 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="oscillating_merge" %}
