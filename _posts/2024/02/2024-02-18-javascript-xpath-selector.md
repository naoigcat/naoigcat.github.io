---
layout: post
title:  素のJavaScript (Vanilla JS) でXPathを使用する
date:   2024/02/18 11:30:34 +0900
tags:   javascript
---

## ライブラリを使わずにCSSセレクタで要素を選択する

ES5で登場した`querySelector`により、jQuery等のライブラリを使用しなくてもセレクターによるDOM指定が行えるようになった。

```js
let node = document.querySelector('div > a');
```

## ライブラリを使わずにXPathで要素を選択する

`evaluate`を使用すると第一引数がXPathのためXPathで要素を取得できる。

```js
let node = document.evaluate(
    '//a[text() = ">"]',
    document,
    null,
    XPathResult.ORDERED_NODE_ITERATOR_TYPE,
    null
);
```
