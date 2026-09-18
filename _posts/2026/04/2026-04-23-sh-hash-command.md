---
title:     シェルで実行ファイルのパスのキャッシュを扱う
date:      2026-04-23 02:51:30 +0900
tags:      bash
---

## 実行ファイルのパスのキャッシュを扱う

組み込みコマンドの `hash` は実行ファイルの場所を覚えておくためのハッシュテーブルを扱う。

何も登録されていない状態で実行ファイルを一度呼ぶと、そのパスが記録される。

```sh
$ bash --noprofile --norc -lc 'hash -r; hash; ls >/dev/null; hash'
hash: hash table empty
hits    command
   1    /bin/ls
```

明示的に登録したり、登録済みのパスを表示したり、キャッシュを消したりできる。 `-t` オプションで登録済みのパスを表示できる（macOS 同梱の Bash 3.2 でも利用できる）。

```sh
$ bash --noprofile --norc -lc 'hash -r; hash ls; hash -t ls'
/bin/ls
```

`PATH` を代入し直すと記憶は消える。コマンドを入れ直した直後などで古いパスが残っているときは `hash -r` で忘れる。

```sh
$ bash --noprofile --norc -lc 'hash -r; hash ls; PATH="$PATH"; hash'
hash: hash table empty
```

## 終了ステータスだけでは存在チェックに使いにくい

`hash name` の成否を存在確認に使う例はあるが、シェルによって意味が違う。終了ステータスだけを見ると誤判定しやすい。

Bash では外部コマンドのときだけハッシュ表に載る。組み込みコマンドや関数では終了ステータスは 0 になるが表には載らず、`hash -t` は失敗する。予約語とエイリアスは失敗する。

```sh
$ bash --noprofile --norc -c 'hash -r; hash ls; echo $?; hash -t ls'
0
/bin/ls
$ bash --noprofile --norc -c 'hash -r; hash cd; echo $?; hash -t cd; hash'
0
bash: line 0: hash: cd: not found
hash: hash table empty
$ bash --noprofile --norc -c 'fn(){ :; }; hash -r; hash fn; echo $?; hash -t fn; hash'
0
bash: line 0: hash: fn: not found
hash: hash table empty
$ bash --noprofile --norc -c 'hash -r; hash if; echo $?'
bash: line 0: hash: if: not found
1
$ bash --noprofile --norc -c 'alias ll="ls -l"; hash -r; hash ll; echo $?'
bash: line 0: hash: ll: not found
1
```

Zsh の `hash` は外部コマンドのパスを表に載せる。`cd` のように PATH 上に同名の実行ファイルがある組み込みも `/usr/bin/cd` として登録されるが、予約語・関数・エイリアスでは失敗する。

Ksh の `hash` は `alias -t` の別名であり、存在しない名前でも常に成功する。存在確認には使えない。

```sh
$ ksh -c 'type hash; hash nosuchXYZ999; echo $?'
hash is an alias for 'alias -t --'
0
```

tcsh / csh に `hash` 組み込みはなく、`/usr/bin/hash`（sh の組み込みを呼ぶラッパ）が使われる。これらのシェル自身のコマンド検索用テーブルは `rehash` / `unhash` で扱う。

```sh
$ for shell in zsh bash ksh; do printf "%-5s" $shell; $shell -c 'type hash'; done
zsh  hash is a shell builtin
bash hash is a shell builtin
ksh  hash is an alias for 'alias -t --'
$ printf "%-5s" tcsh; tcsh -c 'which hash'
tcsh /usr/bin/hash
$ printf "%-5s" csh; csh -c 'which hash'
csh  /usr/bin/hash
```
