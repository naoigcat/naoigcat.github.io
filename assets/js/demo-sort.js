/**
 * Shared helpers for in-post sort-algorithm bar demos (GitHub Pages / Jekyll).
 * Depends on nothing; attaches DemoSort to window.
 */
(function (global) {
  'use strict';

  function transitionPromise(el) {
    return new Promise(function (resolve) {
      function done(e) {
        if (e.propertyName !== 'transform') return;
        el.removeEventListener('transitionend', done);
        resolve();
      }
      el.addEventListener('transitionend', done);
      setTimeout(function () {
        el.removeEventListener('transitionend', done);
        resolve();
      }, 600);
    });
  }

  var DemoSort = {};

  DemoSort.wait = function (ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  };

  DemoSort.transitionPromise = transitionPromise;

  DemoSort.swapDomIndices = function (parent, i, j) {
    if (i === j) return;
    var el1 = parent.children[i];
    var el2 = parent.children[j];
    var marker = document.createTextNode('');
    parent.insertBefore(marker, el1);
    parent.insertBefore(el1, el2.nextSibling);
    parent.insertBefore(el2, marker);
    parent.removeChild(marker);
  };

  DemoSort.mountBars = function (container, values, barClass) {
    container.innerHTML = '';
    if (!values.length) return;
    var max = Math.max.apply(null, values);
    var min = Math.min.apply(null, values);
    var span = Math.max(max - min, 1);
    values.forEach(function (v) {
      var bar = document.createElement('div');
      bar.className = barClass;
      var h = 28 + ((v - min) / span) * 92;
      bar.style.height = h + 'px';
      bar.setAttribute('title', String(v));
      container.appendChild(bar);
    });
  };

  DemoSort.shuffleCopy = function (arr) {
    var copy = arr.slice();
    var i;
    for (i = copy.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var t = copy[i];
      copy[i] = copy[j];
      copy[j] = t;
    }
    return copy;
  };

  DemoSort.flipAdjacentSwap = async function (container, lo) {
    var children = container.children;
    var first = children[lo];
    var second = children[lo + 1];
    if (!first || !second) return;

    var b1 = first.getBoundingClientRect();
    var b2 = second.getBoundingClientRect();

    container.insertBefore(second, first);

    var a1 = first.getBoundingClientRect();
    var a2 = second.getBoundingClientRect();

    var dx1 = b1.left - a1.left;
    var dx2 = b2.left - a2.left;
    first.style.transition = 'none';
    second.style.transition = 'none';
    first.style.transform = 'translateX(' + dx1 + 'px)';
    second.style.transform = 'translateX(' + dx2 + 'px)';

    await new Promise(function (r) {
      requestAnimationFrame(function () {
        requestAnimationFrame(r);
      });
    });

    var dur = '0.32s';
    first.style.transition = 'transform ' + dur + ' ease';
    second.style.transition = 'transform ' + dur + ' ease';
    first.style.transform = '';
    second.style.transform = '';

    await Promise.all([
      transitionPromise(first),
      transitionPromise(second),
    ]);

    first.style.transition = '';
    second.style.transition = '';
    first.style.transform = '';
    second.style.transform = '';
  };

  DemoSort.flipSwap = async function (container, i, j) {
    if (i === j) return;
    if (i > j) {
      var tmp = i;
      i = j;
      j = tmp;
    }
    var elI = container.children[i];
    var elJ = container.children[j];
    if (!elI || !elJ) return;

    var bI = elI.getBoundingClientRect();
    var bJ = elJ.getBoundingClientRect();

    DemoSort.swapDomIndices(container, i, j);

    var aI = elI.getBoundingClientRect();
    var aJ = elJ.getBoundingClientRect();

    var dxI = bI.left - aI.left;
    var dxJ = bJ.left - aJ.left;
    elI.style.transition = 'none';
    elJ.style.transition = 'none';
    elI.style.transform = 'translateX(' + dxI + 'px)';
    elJ.style.transform = 'translateX(' + dxJ + 'px)';

    await new Promise(function (r) {
      requestAnimationFrame(function () {
        requestAnimationFrame(r);
      });
    });

    var dur = '0.32s';
    elI.style.transition = 'transform ' + dur + ' ease';
    elJ.style.transition = 'transform ' + dur + ' ease';
    elI.style.transform = '';
    elJ.style.transform = '';

    await Promise.all([
      transitionPromise(elI),
      transitionPromise(elJ),
    ]);

    elI.style.transition = '';
    elJ.style.transition = '';
    elI.style.transform = '';
    elJ.style.transform = '';
  };

  global.DemoSort = DemoSort;
})(typeof window !== 'undefined' ? window : this);
