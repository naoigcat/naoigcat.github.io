/**
 * Tag index: /tags/ lists all tags; /tags/?tag={slug} filters posts client-side.
 * Data is embedded at build time in #tags-data (no Jekyll plugins required).
 */
(function () {
  'use strict';

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

  function render() {
    const data = readData();
    if (!data) return;

    const slug = new URLSearchParams(window.location.search).get('tag');
    const pageHeader = document.getElementById('tags-page-header');
    const listView = document.getElementById('tags-list-view');
    const filterView = document.getElementById('tags-filter-view');
    const filterHeading = document.getElementById('tags-filter-heading');
    const postsEl = document.getElementById('tags-filter-posts');
    const emptyEl = document.getElementById('tags-filter-empty');

    if (!listView || !filterView || !filterHeading || !postsEl || !emptyEl) {
      return;
    }

    if (!slug) {
      if (pageHeader) pageHeader.hidden = false;
      listView.hidden = false;
      filterView.hidden = true;
      document.title = 'Tags | ' + data.siteTitle;
      return;
    }

    const tag = data.tags.find(function (entry) {
      return entry.slug === slug;
    });

    if (pageHeader) pageHeader.hidden = true;
    listView.hidden = true;
    filterView.hidden = false;

    if (!tag) {
      filterHeading.textContent = slug;
      postsEl.hidden = true;
      emptyEl.hidden = false;
      document.title = slug + ' | ' + data.siteTitle;
      return;
    }

    filterHeading.textContent = tag.name;
    postsEl.hidden = false;
    emptyEl.hidden = true;
    renderPosts(postsEl, tag.posts);
    document.title = tag.name + ' | ' + data.siteTitle;
  }

  document.addEventListener('DOMContentLoaded', render);
  window.addEventListener('popstate', render);
})();
