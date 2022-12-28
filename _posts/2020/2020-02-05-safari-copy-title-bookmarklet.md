---
layout: post
title:  SafariでタイトルをコピーするBookmarkletを作成する
date:   2020-02-05 14:45:11 +0900
tags:   macos safari bookmarklet
---

SafariではJavaScriptでクリップボードにテキストをコピーしようとすると一度`textarea`に貼り付けてからコピーコマンドを実行する必要がある。

`textarea`のテキストをコピーするため、リンク付きのテキストでコピーできず、プレーンテキストになる。

## Redmineでタイトルからチケットタイトルを取得するスクリプト

```js
javascript:
(function () {
    var body = document.getElementsByTagName("body")[0];
    var [, title=document.title] = document.title.match(/(.*#\d :.*) - .*? - Redmine for .*/) || [];
    var textarea = document.createElement("textarea");
    textarea.textContent = title;
    body.appendChild(textarea);
    textarea.contentEditable = true;
    textarea.readOnly = false;
    textarea.setSelectionRange(0, 999999);
    document.execCommand("copy");
    body.removeChild(textarea);
})();
```

## Chromeなどクリップボードを直接扱える場合

```javascript
(function () {
  function listener(e) {
    var [, title=document.title, text=""] = document.title.match(/.*(#\d+)(:.*) - .*? - Redmine for .*/) || [];
    e.clipboardData.setData("text/html", "<a href='" + document.URL + "'>" + title + "</a>" + text);
    e.clipboardData.setData("text/plain", title + text);
    e.preventDefault();
  }
  document.addEventListener("copy", listener);
  document.execCommand("copy");
  document.removeEventListener("copy", listener);
})();
```
