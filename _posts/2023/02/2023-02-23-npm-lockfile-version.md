---
layout: post
title:  npmのバージョンによってロックファイルのフォーマットが異なる
date:   2023/02/23 18:08:14 +0900
tags:   node
---

## ロックファイルのバージョンはnpmに対応する

`npm install`で作成される`package-lock.json`の`lockfile-version`は1〜3の値を取り、デフォルト値はnpmのバージョンによって異なる。

|NPM |Available|Default; Converting      |
|---:|:--------|:------------------------|
|   5|1        |1                        |
|   6|1        |1                        |
|   7|1,2,3    |2; 1 -> 2, 2 -> 2, 3 -> 3|
|   8|1,2,3    |2; 1 -> 2, 2 -> 2, 3 -> 3|
|   9|1,2,3    |3; 1 -> 3, 2 -> 2, 3 -> 3|

## NPM 6以下では1種類しかない

npm version 6以下では`lockfile-version`は`1`固定になる。

## [NPM 7,8では2以上に変換される](https://docs.npmjs.com/cli/v8/using-npm/config#lockfile-version)

npm version 7では`lockfile-version`に`3`が導入された。より高速にパッケージのインストールが行える形式になっている。

`2`は`1`から`3`への移行のために両方の情報を含んだ形式となっていてファイルサイズが大きくなっている。

`package-lock.json`がない、もしくは、`lockfile-version`が`2`以下の場合は`lockfile-version`を`2`のファイルが生成される。

## [NPM 9ではデフォルト値が3に変更された](https://docs.npmjs.com/cli/v9/using-npm/config#lockfile-version)

npm version 9ではデフォルト値と`lockfile-version`が`1`だったときの変換先が`3`に変更された。
