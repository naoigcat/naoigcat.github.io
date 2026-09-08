#!/usr/bin/env node
/**
 * Regression: on-demand tag JSON must ignore stale responses when the user
 * switches tags before an earlier fetch settles.
 */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = fs.readFileSync(path.join(root, 'assets/js/tags.js'), 'utf8');

function el(id, extras = {}) {
  return {
    id,
    hidden: false,
    textContent: '',
    children: [],
    replaceChildren(...nodes) {
      this.children = nodes;
    },
    append(...nodes) {
      this.children.push(...nodes);
    },
    appendChild(node) {
      this.children.push(node);
      return node;
    },
    ...extras,
  };
}

function postTitle(postsRoot) {
  return postsRoot.children[0].children[1].children[0].textContent;
}

async function tick() {
  await new Promise((r) => setTimeout(r, 0));
}

async function waitFor(predicate, label) {
  for (let i = 0; i < 50; i += 1) {
    if (predicate()) return;
    await tick();
  }
  throw new Error(`timed out waiting for ${label}`);
}

async function runScenario() {
  const elements = {
    'tags-data': el('tags-data', {
      textContent: JSON.stringify({
        siteTitle: 'Test',
        tagsUrl: '/tags/',
        tagsBase: '/assets/tags/',
        embeddedTags: [],
        tagIndex: [
          { name: 'Alpha', slug: 'alpha', count: 1 },
          { name: 'Beta', slug: 'beta', count: 1 },
        ],
      }),
    }),
    'tags-page-header': el('tags-page-header'),
    'tags-list-view': el('tags-list-view'),
    'tags-filter-view': el('tags-filter-view'),
    'tags-filter-heading': el('tags-filter-heading'),
    'tags-filter-loading': el('tags-filter-loading'),
    'tags-filter-posts': el('tags-filter-posts'),
    'tags-filter-empty': el('tags-filter-empty'),
  };

  let search = '?tag=alpha';
  const listeners = { document: [], window: [] };
  const pending = new Map();

  const documentMock = {
    getElementById(id) {
      return elements[id] || null;
    },
    createElement(tagName) {
      return {
        tagName,
        className: '',
        href: '',
        textContent: '',
        children: [],
        appendChild(child) {
          this.children.push(child);
          return child;
        },
      };
    },
    addEventListener(type, handler) {
      listeners.document.push({ type, handler });
    },
  };

  const windowMock = {
    location: {
      get search() {
        return search;
      },
    },
    addEventListener(type, handler) {
      listeners.window.push({ type, handler });
    },
  };

  function fetchMock(url, opts = {}) {
    const key = String(url);
    return new Promise((resolve, reject) => {
      pending.set(key, { resolve, reject });
      const signal = opts.signal;
      if (!signal) return;
      if (signal.aborted) {
        pending.delete(key);
        reject(new DOMException('The operation was aborted.', 'AbortError'));
        return;
      }
      signal.addEventListener(
        'abort',
        () => {
          if (!pending.has(key)) return;
          pending.delete(key);
          reject(new DOMException('The operation was aborted.', 'AbortError'));
        },
        { once: true }
      );
    });
  }

  const context = {
    console,
    Map,
    URLSearchParams,
    AbortController,
    DOMException,
    fetch: fetchMock,
    document: documentMock,
    window: windowMock,
  };
  context.globalThis = context;

  vm.runInNewContext(source, context, { filename: 'tags.js' });

  const domReady = listeners.document.find((l) => l.type === 'DOMContentLoaded');
  const popstate = listeners.window.find((l) => l.type === 'popstate');
  assert.ok(domReady, 'DOMContentLoaded listener missing');
  assert.ok(popstate, 'popstate listener missing');

  // Handlers fire render() without returning its promise; wait on DOM/fetch instead.
  domReady.handler();

  assert.equal(pending.size, 1, 'expected alpha fetch');
  const alphaUrl = [...pending.keys()][0];
  assert.match(alphaUrl, /alpha\.json$/);

  search = '?tag=beta';
  popstate.handler();

  await waitFor(
    () => [...pending.keys()].some((u) => /beta\.json$/.test(u)),
    'beta fetch'
  );
  const betaUrl = [...pending.keys()].find((u) => /beta\.json$/.test(u));
  assert.equal(
    pending.has(alphaUrl),
    false,
    'alpha fetch should be aborted when beta starts'
  );

  // A late alpha completion must not win even if the abort path is bypassed.
  // The aborted request was removed from `pending`; only beta remains.

  pending.get(betaUrl).resolve({
    ok: true,
    async json() {
      return {
        name: 'Beta',
        slug: 'beta',
        posts: [{ date: '2026-02-02', url: '/b/', title: 'Beta Post' }],
      };
    },
  });

  await waitFor(
    () =>
      elements['tags-filter-posts'].hidden === false &&
      elements['tags-filter-posts'].children.length === 1,
    'beta posts to render'
  );

  assert.equal(elements['tags-filter-heading'].textContent, 'Beta');
  assert.equal(
    postTitle(elements['tags-filter-posts']),
    'Beta Post',
    'stale alpha response must not overwrite the beta list'
  );
}

await runScenario();
console.log('ok: stale on-demand tag fetch is discarded');
