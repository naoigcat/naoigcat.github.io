---
layout: post
title:  Bashで実行ファイルのパスのキャッシュを扱う
date:   2026-04-23 02:51:30 +0900
tags:   bash
---

## 実行ファイルのパスのキャッシュを扱う

組み込みコマンドの `hash` は実行ファイルの場所を覚えておくためのハッシュテーブルを扱う。

何も登録されていない状態で実行ファイルを一度呼ぶと、そのパスが記録される。

```bash
$ bash --noprofile --norc -lc 'hash -r; hash; ls >/dev/null; hash'
hash: hash table empty
hits    command
   1    /bin/ls
```

明示的に登録したり、登録済みのパスを表示したり、キャッシュを消したりできる。 `-t` オプションによるパスの表示はBash 5.1以降で利用できる。

```sh
$ bash --noprofile --norc -lc 'hash -r; hash git; hash -t git'
/usr/bin/git
```

## 実行ファイルの存在チェックも行える

ハッシュテーブルへの登録が成功するかどうか実行ファイルの存在チェックも行えるが、エイリアスや関数の存在確認が行えるかはシェルによって異なる。

```bash
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'hash cd && echo found' ; done
zsh  found
bash found
ksh  found
tcsh found
csh  found
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'hash if && echo found' ; done
zsh  zsh:hash:1: no such command: if
bash bash: line 0: hash: if: not found
ksh  found
tcsh /usr/bin/hash: line 4: hash: if: not found
csh  /usr/bin/hash: line 4: hash: if: not found
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'hash ls && echo found' ; done
zsh  found
bash found
ksh  found
tcsh found
csh  found
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'fn(){ :; } ; hash fn && echo found' ; done
zsh  zsh:hash:1: no such command: fn
bash found
ksh  found
tcsh Badly placed ()\'s.
csh  Badly placed ()\'s.
$ for shell in zsh bash ksh tcsh csh ; do printf "%-5s" $shell ; $shell -c 'alias ll="ls -l" ; hash ll && echo found' ; done
zsh  zsh:hash:1: no such command: ll
bash bash: line 0: hash: ll: not found
ksh  found
tcsh /usr/bin/hash: line 4: hash: ll: not found
csh  /usr/bin/hash: line 4: hash: ll: not found
$ printf "%-5s" bash ; bash -c 'shopt -s expand_aliases ; alias ll="ls -l" ; hash ll && echo found'
bash bash: line 0: hash: ll: not found
```
