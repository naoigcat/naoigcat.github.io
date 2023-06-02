---
layout: post
title:  Laravel MixのビルドでPolyfillのエラーが起きる
date:   2023/06/02 10:30:52 +0900
tags:   xcode
---

## ライブラリのビルドに失敗することがある

Laravel MixでビルドするときにライブラリのPolyfillでエラーが発生することがある。

```sh
$ mix
BREAKING CHANGE: webpack < 5 used to include polyfills for node.js core modules by default.
This is no longer the case. Verify if you need this module and configure a polyfill for it.

If you want to include a polyfill, you need to:
        - add a fallback 'resolve.fallback: { "buffer": require.resolve("buffer/") }'
        - install 'buffer'
If you don't want to include a polyfill, you can use an empty module like this:
        resolve.fallback: { "buffer": false }
```

## メッセージ通りに対応することでエラーは解消できる

メッセージ通り、`webpack.mix.js`で

```js
const mix = require('laravel-mix');
mix.webpackConfig({
    resolve: {
        fallback: {
            "buffer": require.resolve("buffer/")
        }
    }
});
```

として、Polyfillに必要なライブラリをインストールする (`npm install --save-dev buffer`) か、

```js
const mix = require('laravel-mix');
mix.webpackConfig({
    resolve: {
        fallback: {
            "buffer": false
        }
    }
});
```

とすることでエラーは解消される。

## 根本的にはライブラリ側の依存関係に追加する必要がある

根本的にはライブラリのコードをビルドする時に参照できないことが原因のためライブラリ側の依存関係に追加することでもエラーは解消される。
