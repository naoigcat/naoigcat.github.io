---
layout: post
title:  Globパターンにマッチするファイルがあるかテストする
date:   2023/02/03 12:04:39 +0900
tags:   sh
---

## ファイルが存在するかどうかテストする

`test`コマンドの`-e`オプションで引数に渡したファイル名のファイルが存在するかをテストできる。

```sh
test -e filename
```

このときGlobパターンを渡すことはできず、`test -e filename*`とすると、先にGlobパターンが展開されるため、

|マッチするファイルの数|結果                    |
|---------------------:|:-----------------------|
|                     0|失敗: no matches found  |
|                     1|成功                    |
|                   >=2|失敗: too many arguments|

となる。`test -e "filename*"`とすると、`filename*`という名前のファイルが存在するかをテストするためGlobパターンとして認識されない。

## Bashならcompgenコマンドが使用できる

Bashなら`compgen`コマンドが使用できる。コマンド補完しようとしたときに最初にヒットするものを返すコマンドで`-G`オプションとGlobパターンを渡すとGlobパターンに最初にマッチするファイルを返す。

```sh
compgen -G "filename*" > /dev/null
```

## シェルを問わないならfindコマンドが使用できる

`find`コマンドでも同様のことが行える。`-name`オプションはGlobパターンを渡すことができ、`-quit`オプションは1つでも見つかったときに終了するため無駄に探索しなくて済む。

```sh
test -n "$(find . -maxdepth 1 -name 'filename*' -print -quit)"
```
