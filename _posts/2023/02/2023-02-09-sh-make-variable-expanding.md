---
layout: post
title:  makeコマンドで変数を割り当てる
date:   2023/02/09 12:00:29 +0900
tags:   sh
---

## 変数割り当ての方法が3種類存在する

Makefileで変数に値を割り当てるとき最終的な結果が決まる方法が3種類存在する。

> [6.2 The Two Flavors of Variables](https://ftp.gnu.org/old-gnu/Manuals/make-3.80/html_chapter/make_6.html#SEC67)

[GNU Make 4.4](https://lists.gnu.org/archive/html/info-gnu/2022-10/msg00008.html)で `:::-` (Immediate Assignment) が導入されているがmacOSに付属しているバージョンが3.81で固定されているためここでは触れない。

### Recursive Assignment

`=`を使って割り当てると変数は実行時に展開される。

```sh
$ <<MAKEFILE > Makefile && make
a = \$(b)
b = \$(c)
c = 1
d = \$(c)
c = 2
all:; echo \$(a) \$(d) > /dev/null
MAKEFILE

echo 2 2 > /dev/null
```

変数に何かを追加しようとして自身を参照すると無限ループになるためエラーになる。

```sh
$ <<MAKEFILE > Makefile && make
r = 1
r = \$(r) 2
all:; echo \$(r) > /dev/null
MAKEFILE

Makefile:2: *** Recursive variable `r' references itself (eventually).  Stop.
```

また、実行時に都度展開されるためコマンド結果を使用していると参照するたびにコマンドが実行される。

<!-- markdownlint-disable MD010 -->
```sh
$ <<MAKEFILE > Makefile && make
x = \$(shell date)
.PHONY: all
all:
	@echo \$(x)
	@\$(shell sleep 3)
	@echo \$(x)
MAKEFILE

Wed Feb 9 12:06:19 JST 2023
Wed Feb 9 12:06:22 JST 2023
```
<!-- markdownlint-enable MD010 -->

### Simple Assignment

`:=`を使って割り当てると変数は割当時に展開される。

```sh
$ <<MAKEFILE > Makefile && make
a := \$(b)
b := \$(c)
c := 1
d := \$(c)
c := 2
all:; echo \$(a) \$(d) > /dev/null
MAKEFILE

echo  1 > /dev/null
```

自身を参照した場合でも割当時に展開されるためエラーにならない。

```sh
$ <<MAKEFILE > Makefile && make
r := 1
r := \$(r) 2
all:; echo \$(r) > /dev/null
MAKEFILE

echo 1 2 > /dev/null
```

### Conditional Assignment

`?=`を使って割り当てると既に割り当て済みの値を上書きしない。

```sh
$ <<MAKEFILE > Makefile && make
a ?= \$(b)
b ?= \$(c)
c ?= 1
d ?= \$(c)
c ?= 2
d ?= \$(c)
all:; echo \$(a) \$(d) > /dev/null
MAKEFILE

echo 1 1 > /dev/null
```
