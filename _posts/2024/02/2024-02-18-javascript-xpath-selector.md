---
title:     素のJavaScript (Vanilla JS) でXPathを使用する
date:      2024-02-18 11:30:34 +0900
tags:      javascript
---

## ライブラリを使わずにCSSセレクタで要素を選択する

W3C の Selectors API（DOM）で定義された`querySelector`により、jQuery等のライブラリを使用しなくてもセレクターによるDOM指定が行えるようになった。

```javascript
const node = document.querySelector('div > a');
```

## ライブラリを使わずにXPathで要素を選択する

`document.evaluate`の戻り値は要素そのものではなく`XPathResult`である。先頭の1件だけ欲しいときは`FIRST_ORDERED_NODE_TYPE`を指定し、`.singleNodeValue`で取り出す。

```javascript
const result = document.evaluate(
    '//a[text() = ">"]',
    document,
    null,
    XPathResult.FIRST_ORDERED_NODE_TYPE,
    null
);
const node = result.singleNodeValue;
```
