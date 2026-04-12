---
layout: post
title:  npmで公開直後のバージョンを避ける
date:   2026-04-13 00:12:36 +0900
tags:   npm
---

## 公開直後のバージョンを避ける

npmの`min-release-age`を設定すると、公開から指定した日数が経過していないバージョンをインストール対象から除外できる。

たとえば`3`を設定すると、公開から3日以内のバージョンは選ばれず、3日より前に公開されたバージョンだけがインストールされる。

```sh
npm config set min-release-age 3 --location=project
```

プロジェクト単位で設定する場合は`.npmrc`に次のように書く。

```ini
min-release-age=3
```

## `before`とは併用できない

`min-release-age`は相対的な日数で制限する設定で、特定日時以前のバージョンだけを使う`before`とは併用できない。

指定した条件を満たすバージョンが存在しない場合、`npm install`はエラーになる。
