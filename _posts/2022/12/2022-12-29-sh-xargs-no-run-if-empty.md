---
layout: post
title:  xargsで入力が空のときに処理を実行しない
date:   2022/12/29 12:11:20 +0900
tags:   sh
---

## GNU版とBSD版で挙動を揃える

下記コマンドでGNU版とBSD版のxargsの違いを無視して`command1`の結果が空のときに`command2`を実行しないようにできる。

```sh
command1 | xargs $(: | xargs echo '--no-run-if-empty') command2
```

## xargsは引数をまとめてコマンドを実行する

`xargs`は標準入力から読み取った項目を引数にして指定したコマンドを実行する。デフォルトでは引数はシステム的に許容される限界まで長くなるように渡され、一度で全ての項目を処理できない場合は複数回コマンドが実行される。

コマンドを指定しなかった場合は`echo`が実行される。

## : (colon) は何も実行しない

bashにおけるコロンコマンドは組み込みコマンドで何も実行しない。当然標準出力にも出力されるものはない。

## xargs (GNU) は入力が空でも実行される

1.  入力があるときは処理が実行される。

    ```sh
    echo a | xargs | wc -l
    # => 1
    ```

2.  入力が空のときは**処理が実行される**。

    ```sh
    : | xargs | wc -l
    # => 1
    ```

3.  入力が空で`--no-run-if-empty`オプションが指定されているときは**処理が実行されない**。

    ```sh
    : | xargs --no-run-if-empty | wc -l
    # => 0
    ```

## xargs (BSD) は入力が空なら実行されない

1.  入力があるときは処理が実行される。

    ```sh
    echo a | xargs | wc -l
    # => 1
    ```

2.  入力が空のときは**処理が実行されない**。

    ```sh
    : | xargs | wc -l
    # => 0
    ```

3.  入力が空で`--no-run-if-empty`オプションが指定されているときは**エラーになる**。

    ```sh
    : | xargs --no-run-if-empty | wc -l
    # => xargs: illegal option -- -
    ```
