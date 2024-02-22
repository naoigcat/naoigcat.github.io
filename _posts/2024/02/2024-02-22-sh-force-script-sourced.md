---
layout: post
title:  シェルスクリプトを直接実行させない
date:   2024/02/22 16:25:46 +0900
tags:   sh
---

## 環境変数を定義するスクリプトを実行する

`export`を使用して環境変数を定義するスクリプトを呼び出すときにスクリプト自体を実行するとサブシェルで実行されるため呼び出し元には環境変数が定義されない。

```sh
$ unset TEST
$ cat << EOS > script.sh
#!/bin/sh
export TEST=1
env | grep TEST || echo NOT FOUND
EOS
$ chmod 755 script.sh
$ ./script.sh
TEST=1
$ env | grep TEST || echo NOT FOUND
NOT FOUND
```

`source`や`.`で読み込むと呼び出し元のシェルで実行されるため呼び出し元に環境変数が定義される。

```sh
$ . ./script.sh
TEST=1
$ env | grep TEST || echo NOT FOUND
TEST=1
```

## コマンドで読み込まれたかどうかを判定するのは難しい

[How to detect if a script is being sourced](https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced) で議論されているがシェルの種類によって判定方法が異なり、汎用的な方法は存在しない。

## スクリプトを実行したときはメッセージを表示する

Shebangに`sed`を指定することで直接実行した場合はメッセージを表示することができる。ただし、`bash script.sh`のように新しいシェルを実行した場合はそのまま実行される。

```sh
$ unset TEST
$ cat << EOS > script.sh
#!/usr/bin/sed 2,5!d;s/^\x23//;s/^\x20//
# This script must be sourced from within a shell
#
# Usage:
#   . script.sh
export TEST=1
env | grep TEST || echo NOT FOUND
EOS
$ chmod 755 script.sh
$ ./script.sh
This script must be sourced from within a shell

Usage:
  . script.sh
$ . ./script.sh
TEST=1
$ env | grep TEST || echo NOT FOUND
TEST=1
```

また、引数を渡すと`sed`に全て渡されてしまうため正しく処理されない。

```sh
./script.sh argument1 argument2
This script must be sourced from within a shell

Usage:
  . script.sh
sed: argument1: No such file or directory
sed: argument2: No such file or directory
```

## BashとZshで実行されたときのみチェックする

macOSで使われるシェルは主にBashとZshのためこの2つだけチェックを行う。

```sh
$ unset TEST
$ cat << EOS > script.sh
#!/bin/bash
if [[ "\$BASH_SOURCE" = "\$0" || ! "\$ZSH_EVAL_CONTEXT" =~ :file\$ ]] ; then
  echo "This script must be sourced from within a shell"
  echo ""
  echo "Usage:"
  echo "  . script.sh"
  exit 1
fi
export TEST=1
env | grep TEST || echo NOT FOUND
EOS
$ chmod 755 script.sh
$ ./script.sh
This script must be sourced from within a shell

Usage:
  . script.sh
$ bash ./script.sh
This script must be sourced from within a shell

Usage:
  . script.sh
$ zsh ./script.sh
This script must be sourced from within a shell

Usage:
  . script.sh
$ . ./script.sh
TEST=1
$ env | grep TEST || echo NOT FOUND
TEST=1
```
