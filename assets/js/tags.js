/**
 * Tag index: /tags/ lists all tags; /tags/?tag={slug} filters posts client-side.
 * Major tags are embedded in #tags-data; others load /assets/tags/{slug}.json on demand.
 */
(function () {
  'use strict';

  const tagCache = new Map();

  function readData() {
    const el = document.getElementById('tags-data');
    if (!el) return null;
    try {
      return JSON.parse(el.textContent);
    } catch (_err) {
      return null;
    }
  }

  function renderPosts(container, posts) {
    container.replaceChildren();
    posts.forEach(function (post) {
      const li = document.createElement('li');
      const meta = document.createElement('span');
      meta.className = 'post-meta';
      meta.textContent = post.date;
      const heading = document.createElement('h3');
      const link = document.createElement('a');
      link.className = 'post-link';
      link.href = post.url;
      link.textContent = post.title;
      heading.appendChild(link);
      li.appendChild(meta);
      li.appendChild(heading);
      container.appendChild(li);
    });
  }

  function findEmbedded(data, slug) {
    if (!data.embeddedTags) return null;
    return data.embeddedTags.find(function (entry) {
      return entry.slug === slug;
    });
  }

  function findIndexEntry(data, slug) {
    if (!data.tagIndex) return null;
    return data.tagIndex.find(function (entry) {
      return entry.slug === slug;
    });
  }

  async function loadTag(data, slug) {
    const embedded = findEmbedded(data, slug);
    if (embedded) return embedded;

    if (tagCache.has(slug)) return tagCache.get(slug);

    const base = data.tagsBase || '/assets/tags/';
    const url = base + encodeURIComponent(slug) + '.json';
    const response = await fetch(url, { credentials: 'same-origin' });
    if (!response.ok) return null;

    const tag = await response.json();
    tagCache.set(slug, tag);
    return tag;
  }

  async function render() {
    const data = readData();
    if (!data) return;

    const slug = new URLSearchParams(window.location.search).get('tag');
    const pageHeader = document.getElementById('tags-page-header');
    const listView = document.getElementById('tags-list-view');
    const filterView = document.getElementById('tags-filter-view');
    const filterHeading = document.getElementById('tags-filter-heading');
    const loadingEl = document.getElementById('tags-filter-loading');
    const postsEl = document.getElementById('tags-filter-posts');
    const emptyEl = document.getElementById('tags-filter-empty');

    if (!listView || !filterView || !filterHeading || !postsEl || !emptyEl) {
      return;
    }

    if (!slug) {
      if (pageHeader) pageHeader.hidden = false;
      listView.hidden = false;
      filterView.hidden = true;
      if (loadingEl) loadingEl.hidden = true;
      document.title = 'Tags | ' + data.siteTitle;
      return;
    }

    if (pageHeader) pageHeader.hidden = true;
    listView.hidden = true;
    filterView.hidden = false;

    const indexEntry = findIndexEntry(data, slug);
    const embedded = findEmbedded(data, slug);

    if (!indexEntry) {
      if (pageHeader) pageHeader.hidden = true;
      listView.hidden = true;
      filterView.hidden = false;
      filterHeading.textContent = slug;
      postsEl.hidden = true;
      emptyEl.hidden = false;
      if (loadingEl) loadingEl.hidden = true;
      document.title = slug + ' | ' + data.siteTitle;
      return;
    }

    filterHeading.textContent = indexEntry.name;
    document.title = filterHeading.textContent + ' | ' + data.siteTitle;

    if (embedded) {
      if (loadingEl) loadingEl.hidden = true;
      postsEl.hidden = false;
      emptyEl.hidden = true;
      renderPosts(postsEl, embedded.posts);
      return;
    }

    postsEl.hidden = true;
    emptyEl.hidden = true;
    if (loadingEl) loadingEl.hidden = false;

    let tag;
    try {
      tag = await loadTag(data, slug);
    } catch (_err) {
      tag = null;
    }

    if (loadingEl) loadingEl.hidden = true;

    if (!tag) {
      postsEl.hidden = true;
      emptyEl.hidden = false;
      return;
    }

    filterHeading.textContent = tag.name;
    document.title = tag.name + ' | ' + data.siteTitle;
    postsEl.hidden = false;
    emptyEl.hidden = true;
    renderPosts(postsEl, tag.posts);
  }

  document.addEventListener('DOMContentLoaded', function () {
    render().catch(function () {
      const emptyEl = document.getElementById('tags-filter-empty');
      const loadingEl = document.getElementById('tags-filter-loading');
      if (loadingEl) loadingEl.hidden = true;
      if (emptyEl) emptyEl.hidden = false;
    });
  });
  window.addEventListener('popstate', function () {
    render().catch(function () {
      /* render handles empty state */
    });
  });
})();
