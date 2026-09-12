---
title:     npmで公開直後のバージョンを避ける
date:      2026-04-13 00:12:36 +0900
tags:      npm
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

## `before`との併用

`min-release-age`は相対的な日数で制限する設定で、特定日時以前のバージョンだけを使う`before`と併用できる。同じ設定源で両方を指定した場合は`before`が優先される。

パッケージ名や glob を`min-release-age-exclude`に列挙すると、そのパッケージだけ公開直後のバージョンも選ばれる。

`min-release-age`（や`before`）の窓のせいで`npm audit fix`がパッチ版を入れられないときは、脆弱な版のまま警告して非ゼロ終了する。直すには対象を`min-release-age-exclude`に入れるか、窓を緩める。

指定した条件を満たすバージョンが存在しない場合、`npm install`はエラーになる。
