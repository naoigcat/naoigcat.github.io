---
layout: post
title:  psをgrepした結果から自身を除外する
date:   2023/01/04 12:02:48 +0900
tags:   sh
---

## psコマンドでプロセスの一覧を取得できる

psコマンドを実行すると実行中のプロセスの一覧を取得でき、そのときの結果には実行されたコマンドが含まれる。

```sh
$ ps
  PID TTY           TIME CMD
18323 ttys003    0:00.07 /bin/zsh -il
46828 ttys004    0:00.18 /bin/zsh -il
```

xオプションを指定すると端末を持たないすべてのプロセスが表示される。

```sh
$ ps x
  PID   TT  STAT      TIME CMD
  462   ??  S      8:37.37 /usr/sbin/distnoted agent
                           ...
18323 s003  Ss+    0:00.07 /bin/zsh -il
46828 s004  Ss     0:00.23 /bin/zsh -il
48128 s004  R+     0:00.00 ps x
```

## grepによる絞り込みでは自身も残る

特定のコマンドのプロセスを探したい場合はgrepによる絞り込みをよく利用する。

```sh
$ ps x | grep pboard
  527   ??  S      2:10.15 /usr/libexec/pboard
48473 s004  S+     0:00.00 grep pboard
```

このとき、grepコマンド自身にも検索対象の文字列が含まれるため結果に残ってしまう。

## 絞り込み結果からさらにgrepコマンドを除外する

さらにパイプでgrepコマンドを繋いでvオプションでgrepコマンド自身を除外することができる。

```sh
$ ps x | grep pboard | grep -v grep
  527   ??  S      2:10.53 /usr/libexec/pboard
```

-   ただし、検索したいコマンドに`grep`という文字列が含まれているとこの方法は使用できない。

## grepコマンドでの絞り込みを正規表現で行う

grepコマンドの絞り込みは正規表現のため正規表現として意味のある文字列を含むことでgrepコマンド自身を除外することができる。

```sh
$ ps x | grep '[p]board'
527   ??  S      2:10.53 /usr/libexec/pboard
```

-   `[p]board`をgrepコマンドに渡したとき検索するのは`pboard`を含むものだが、psコマンドの結果はコマンドそのままのため角括弧`[]`が含まれるためヒットしない。
-   zshでは角括弧`[]`はエスケープする必要があるためクォーテーションで括る。
