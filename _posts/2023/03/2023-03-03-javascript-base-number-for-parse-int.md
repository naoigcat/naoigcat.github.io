---
layout: post
title:  JavaScriptで文字列を整数値に変換する
date:   2023/03/03 12:44:27 +0900
tags:   javascript
---

## [`parseInt`](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/parseInt)関数は引数を整数値に変換する

```javascript
parseInt(string);
parseInt(string, radix);
```

## 第1引数`string`には整数値に変換する文字列を渡す

-   文字列でなかった場合は[`ToString`](https://tc39.es/ecma262/#sec-tostring)で文字列に変換される。
-   先頭の[ホワイトスペース](https://developer.mozilla.org/ja/docs/Glossary/Whitespace)は無視される。
-   先頭のホワイトスペース以外の文字が数値に変換できない場合、関数は`NaN`を返す。
-   ホワイトスペースを取り除いた後先頭に来る正負の符号を認識できる。

第1引数`string`に数値を渡した場合、一度文字列に変換されてから整数に変換されるため、小数などを指定して指数表記になると正しく変換されない。

```javascript
parseInt(0.000005);  // 0 [ToString(0.000005)  === '0.000005']
parseInt(0.0000005); // 5 [ToString(0.0000005) === '5e-7']
```

## 第2引数`radix`には整数値に変換するときの基数を渡す

-   `Number`型以外の場合は`Number`に型変換される。
-   `2`から`36`までの整数以外を渡した場合、関数は`NaN`を返す。
-   `10`以上の基数を指定した場合は、`9`より大きい数字はアルファベットで示される。
-   先頭から解析して解析可能な英数字以外の文字が現れた時点でそれ以降の文字は無視される。

第2引数`radix`が省略された場合、または、`Number`に変換した結果`0`、`NaN` (`undefined`), `Infinity`のいずれかになる場合、`string`が`0x`または`0X`から始まる場合は16進数、それ以外は10進数として変換する。

```javascript
parseInt('0xF'); //  15
parseInt('111'); // 111
```

## 数値の整数部を取り出すには`Math.trunc`を使用する

`parseInt`は文字列を引数にすることを前提にしているため変換元が数値の場合は`Math.trunc`で整数部を取得する。

```javascript
Math.trunc(0.000005);  // 0
Math.trunc(0.0000005); // 0
```

## `Number`関数は文字列全体が数値でない場合`NaN`を返す

`Number`関数に文字列を渡すと全体が数値の場合は数値に変換し、そうでない場合は`NaN`を返す。2進数、8進数、16進数も扱える。

```javascript
Number('123a'); // NaN
Number('0xFF'); // 256
```
