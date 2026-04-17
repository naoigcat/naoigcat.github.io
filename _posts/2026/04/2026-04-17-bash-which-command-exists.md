---
layout: post
title:  Bashでコマンドの存在を確認する
date:   2026-04-17 22:33:45 +0900
tags:   bash
---

## シェルにも種類がある

Bashは多くのUnix系システムでデフォルトのシェルとして採用されているが、他にもZshやKsh、Csh、Tcshなど様々なシェルが存在する。

-   1990 [Zsh](https://www.zsh.org/) - Bourne Shellベースに拡張したシェル
-   1989 [Bash](https://www.gnu.org/software/bash/) - GNUプロジェクトによって開発されたシェル
-   1983 [Ksh](https://www.kornshell.com/) - Korn Shellとも呼ばれ、Bashの前身となったシェル
-   1983 [Tcsh](https://www.tcsh.org/) - Cshをベースに拡張したシェル
-   1977 [Csh](https://www.cse.yorku.ca/~oz/csh.html) - C言語の構文に似たシェル

## 実行ファイルの場所を調べる

多くのシェルで `which` コマンドを使用して、コマンドが存在するかどうかを確認することができる。

`which` は、環境変数 `PATH` に列挙されたディレクトリを順に探し、引数に指定した名前の**実行ファイル**が見つかったとき、そのパスを標準出力へ書き出す。

見つからない場合は標準エラーへメッセージを出し、終了ステータスは 0 以外になる。

```sh
$ zsh -c 'which mv'
/bin/mv
$ bash -c 'which mv'
/bin/mv
$ ksh -c 'which mv'
/bin/mv
$ tcsh -c 'which mv'
/bin/mv
$ csh -c 'which mv'
/bin/mv
```

スクリプトで「このコマンドが使えるか」だけを判定したい場合は出力を捨てて終了ステータスだけを見る。

```sh
if which jq >/dev/null 2>&1; then
  echo 'jq is available'
else
  echo 'jq is not available'
fi
```

## 組み込みコマンドに対して実行する

組み込みコマンドに対して実行するとパスを返す場合と組み込みコマンドであることを返す場合がある。

```sh
$ zsh -c 'which cd'
cd: shell built-in command
$ bash -c 'which cd' || echo 'not found'
/usr/bin/cd
$ ksh -c 'which cd' || echo 'not found'
/usr/bin/cd
$ tcsh -c 'which cd'
cd: shell built-in command.
$ csh -c 'which cd'
cd: shell built-in command.
```

コマンドによってはエラーになるシェルもある。

```bash
$ zsh -c 'which let'
let: shell built-in command
$ bash -c 'which let' || echo 'not found'
not found
$ ksh -c 'which let' || echo 'not found'
not found
$ tcsh -c 'which let'
let: Command not found.
$ csh -c 'which let'
let: Command not found.
```

## エイリアスに対して実行する

エイリアスに対して実行すると`zsh`でのみエイリアスの定義を返す。

```sh
$ zsh -c 'alias ll="ls -l"; which ll'
ll: aliased to ls -l
$ bash -c 'alias ll="ls -l"; which ll' || echo 'not found'
not found
$ ksh -c 'alias ll="ls -l"; which ll' || echo 'not found'
not found
$ tcsh -c 'alias ll="ls -l"; which ll'
ll: Command not found.
$ csh -c 'alias ll="ls -l"; which ll'
ll: Command not found.
```

## 関数に対して実行する

関数に対して実行すると`zsh`でのみ関数の定義を返す。`tcsh`と`csh`は関数に対応していないため定義のタイミングでエラーになる。

```sh
$ zsh -c 'f() { echo foo; }; which f'
f () {
        echo foo
}
$ bash -c 'f() { echo foo; }; which f' || echo 'not found'
not found
$ ksh -c 'f() { echo foo; }; which f' || echo 'not found'
not found
$ tcsh -c 'f() { echo foo; }; which f'
Badly placed ()\'s.
$ csh -c 'f() { echo foo; }; which f'
Badly placed ()\'s.
```

## 予約語に対して実行する

予約語に対して実行すると`zsh`と`tcsh`、`csh`で組み込みコマンドであることを返す。`bash`と`ksh`は予約語に対応していないためエラーになる。

```sh
$ zsh -c 'which if'
if: shell reserved word
$ bash -c 'which if' || echo 'not found'
not found
$ ksh -c 'which if' || echo 'not found'
not found
$ tcsh -c 'which if'
if: shell built-in command.
$ csh -c 'which if'
if: shell built-in command.
```
