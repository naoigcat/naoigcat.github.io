---
layout:    post
title:     シェルでコマンドの存在や種類を確認する
date:      2026-04-20 22:37:37 +0900
tags:      bash
---

## 名前を解決できるか簡単に調べる

組み込みコマンドの `command` はエイリアスや関数以外の指定したコマンドを実行するコマンドである。

```bash
$ for shell in zsh bash ksh tcsh csh; do
    printf "%-5s" $shell
    $shell -c 'command date -j -f "%Y-%m-%d" "2026-04-20" +"%Y/%m/%d"'
done
zsh  2026/04/20
bash 2026/04/20
ksh  2026/04/20
tcsh 2026/04/20
csh  2026/04/20
```

`-v` オプションを付けると、指定したコマンドが組み込みコマンド、実行ファイルのどれで解決されるかを表示する。

```bash
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'command -v cd' ; done
zsh  cd
bash cd
ksh  cd
tcsh cd
csh  cd
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'command -v if' ; done
zsh  if
bash if
ksh  if
tcsh if
csh  if
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'command -v ls' ; done
zsh  /bin/ls
bash /bin/ls
ksh  /bin/ls
tcsh /bin/ls
csh  /bin/ls
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'fn(){ :; } ; command -v fn' ; done
zsh  fn
bash fn
ksh  fn
tcsh Badly placed ()\'s.
csh  Badly placed ()\'s.
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'alias ll="ls -l" ; command -v ll' || echo not found ; done
zsh  alias ll='ls -l'
bash not found
ksh  'ls -l'
tcsh not found
csh  not found
```

Bashでエイリアスも見えるようにするには、 `shopt -s expand_aliases` でエイリアス展開を有効にしてから実行する必要がある。このオプションはほかのシェルにはない。

```bash
$ printf "%-5s" bash ; bash -c 'shopt -s expand_aliases ; alias ll="ls -l" ; command -v ll'
bash alias ll='ls -l'
```

## 名前を解決できるか詳細に調べる

`-V` オプションを付けると、指定したコマンドがどのように解決されるかを詳しく表示する。

```bash
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'command -V cd' ; done
zsh  cd is a shell builtin
bash cd is a shell builtin
ksh  cd is a shell builtin
tcsh cd is a shell builtin
csh  cd is a shell builtin
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'command -V if' ; done
zsh  if is a reserved word
bash if is a shell keyword
ksh  if is a keyword
tcsh if is a shell keyword
csh  if is a shell keyword
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'command -V ls' ; done
zsh  ls is /bin/ls
bash ls is /bin/ls
ksh  ls is a tracked alias for /bin/ls
tcsh ls is /bin/ls
csh  ls is /bin/ls
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'fn(){ :; } ; command -V fn' ; done
zsh  fn is a shell function from zsh
bash fn is a function
fn ()
{
    :
}
ksh  fn is a function
tcsh Badly placed ()\'s.
csh  Badly placed ()\'s.
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'alias ll="ls -l" ; command -V ll' ; done
zsh  ll is an alias for ls -l
bash bash: line 0: command: ll: not found
ksh  ll is an alias for 'ls -l'
tcsh /usr/bin/command: line 4: command: ll: not found
csh  /usr/bin/command: line 4: command: ll: not found
$ printf "%-5s" bash ; bash -c 'shopt -s expand_aliases ; alias ll="ls -l" ; command -V ll'
bash ll is aliased to `ls -l'
```

組み込みコマンドの `type` は指定した名前が組み込みコマンド、実行ファイルのどれで解決されるかを詳しく表示する。 `command -V` と同じ内容を出力する。

```bash
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'type cd' ; done
zsh  cd is a shell builtin
bash cd is a shell builtin
ksh  cd is a shell builtin
tcsh cd is a shell builtin
csh  cd is a shell builtin
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'type if' ; done
zsh  if is a reserved word
bash if is a shell keyword
ksh  if is a keyword
tcsh if is a shell keyword
csh  if is a shell keyword
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'type ls' ; done
zsh  ls is /bin/ls
bash ls is /bin/ls
ksh  ls is a tracked alias for /bin/ls
tcsh ls is /bin/ls
csh  ls is /bin/ls
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'fn(){ :; } ; type fn' ; done
zsh  fn is a shell function from zsh
bash fn is a function
fn ()
{
    :
}
ksh  fn is a function
tcsh Badly placed ()\'s.
csh  Badly placed ()\'s.
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'alias ll="ls -l" ; type ll' ; done
zsh  ll is an alias for ls -l
bash bash: line 0: type: ll: not found
ksh  ll is an alias for 'ls -l'
tcsh /usr/bin/type: line 4: type: ll: not found
csh  /usr/bin/type: line 4: type: ll: not found
$ printf "%-5s" bash ; bash -c 'shopt -s expand_aliases ; alias ll="ls -l" ; type ll'
bash ll is aliased to `ls -l'
```
