---
layout: post
title:  Debian版のwhichコマンドの実装を確認する
date:   2026-04-27 23:22:41 +0900
tags:   bash debian
---

## パブリックドメインで公開されている

Debian版の `which` コマンドは、`debianutils` パッケージに含まれるもので、[パブリックドメインで公開されている](https://salsa.debian.org/debian/debianutils/-/blob/debian/5.23.2/debian/copyright?ref_type=tags#L42)。

## シェルスクリプトで実装されている

Debian版の `which` コマンドは、[シェルスクリプトで実装されている](https://salsa.debian.org/debian/debianutils/-/blob/debian/5.23.2/which.debianutils?ref_type=tags)。

`PATH` 環境変数に列挙されたディレクトリを順に探し、引数に指定した名前の**実行ファイル**が見つかったとき、そのパスを標準出力へ書き出す。

特定のディレクトリを除外して検索するために `PATH` を一時的に変更することも想定されるため外部コマンドには依存しないように実装されている。

```sh
#! /bin/sh
set -ef

SILENT=0
if test -n "$KSH_VERSION"; then
    puts() {
        [ "$SILENT" -eq 1 ] && return
        print -r -- "$*"
    }
else
    puts() {
        [ "$SILENT" -eq 1 ] && return
        printf '%s\n' "$*"
    }
fi

ALLMATCHES=0

while getopts as whichopts
do
    case "$whichopts" in
        a) ALLMATCHES=1 ;;
        s) SILENT=1 ;;
        ?) puts "Usage: $0 [-as] args"; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ "$#" -eq 0 ]; then
    ALLRET=1
else
    ALLRET=0
fi
case $PATH in
    (*[!:]:) PATH="$PATH:" ;;
esac
for PROGRAM in "$@"; do
    RET=1
    IFS_SAVE="$IFS"
    IFS=:
    case $PROGRAM in
        */*)
            if [ -f "$PROGRAM" ] && [ -x "$PROGRAM" ]; then
                puts "$PROGRAM"
                RET=0
            fi
            ;;
        *)
            for ELEMENT in $PATH; do
                if [ -z "$ELEMENT" ]; then
                    ELEMENT=.
                fi
                if [ -f "$ELEMENT/$PROGRAM" ] && [ -x "$ELEMENT/$PROGRAM" ]; then
                    puts "$ELEMENT/$PROGRAM"
                    RET=0
                    [ "$ALLMATCHES" -eq 1 ] || break
                fi
            done
            ;;
    esac
    IFS="$IFS_SAVE"
    if [ "$RET" -ne 0 ]; then
        ALLRET=1
    fi
done

exit "$ALLRET"
```
