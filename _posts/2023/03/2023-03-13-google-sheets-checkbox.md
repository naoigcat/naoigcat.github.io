---
layout: post
title:  スプレッドシートのセル内にチェックボックスを追加する
date:   2023/03/13 12:05:17 +0900
tags:   google
---

## [チェックボックスを追加して使用する](https://support.google.com/docs/answer/7684717?hl=ja)

セルを選択して次のいずれかでチェックボックスが追加できる。

-   上部メニュー > `挿入` > `チェックボックス`
-   上部メニュー > `データ` > `データの入力規則` > `ルールを追加`
    -   `データの入力規則`パネルの`範囲に適用`にチェックボックスを表示する範囲を入力する
    -   `データの入力規則`パネルの`条件`で`チェックボックス`を選択する

## チェックボックスが追加されたセルの値は変更できる

チェックボックスを追加したセルの値は`チェックマーク付き`の時は`TRUE`、`チェックマークなし`の時は`FALSE`になる。

`データの入力規則`パネルで`カスタムのセル値を使用する`にチェックを入れると`チェックマーク付き`の時、`チェックマークなし`の時、それぞれ個別に値を変更できる。

セルの値は下記に反映される。

-   コピーして値のみ貼り付けしたとき
-   数式で参照したとき
-   上部メニュー > `ファイル` > `ダウンロード`からダウンロードしたとき
