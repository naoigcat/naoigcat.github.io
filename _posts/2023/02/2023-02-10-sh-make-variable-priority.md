---
layout: post
title:  makeコマンドは引数に指定した変数が優先される
date:   2023/02/10 12:37:41 +0900
tags:   sh
---

## 引数に指定した変数の優先順位が一番高い

`make`コマンドに変数を渡す場合の優先順位は下記のようになる。

1.  引数に指定した値
2.  ファイル内で定義した値 (`:=`)
3.  環境変数で渡した値
4.  ファイル内で定義した値 (`?=`)

|    |`make`      |`x=env make`|`make x=arg`|
|:--:|:----------:|:----------:|:----------:|
|`:=`|var         |var         |arg         |
|`?=`|var         |env         |arg         |

<!-- markdownlint-disable MD010 -->
```sh
$ <<MAKEFILE > Makefile
a := var
b ?= var
default:
	@echo a=\$(a) b=\$(b)
MAKEFILE
$ make ; a=env b=env make ; make a=arg b=arg
a=var b=var
a=var b=env
a=arg b=arg
```
<!-- markdownlint-enable MD010 -->

## サブコマンドに渡す場合はオプションの有無で優先順位が変わる

サブコマンドに環境変数として変数が渡される。`export`や`-e`オプションの有無で優先順位が変わる。

|      |    |    |`make`         |`make -e`      |`x=env make`   |`x=env make -e`|`make x=arg`   |`make x=arg -e`|
|:----:|:--:|:--:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
|      |`:=`|`:=`|sub            |sub            |sub            |var            |arg            |arg            |
|      |`?=`|`:=`|sub            |sub            |sub            |env            |arg            |arg            |
|      |`:=`|`?=`|sub            |sub            |var            |var            |arg            |arg            |
|      |`?=`|`?=`|sub            |sub            |env            |env            |arg            |arg            |
|export|`:=`|`:=`|sub            |var            |sub            |var            |arg            |arg            |
|export|`?=`|`:=`|sub            |var            |sub            |env            |arg            |arg            |
|export|`:=`|`?=`|var            |var            |var            |var            |arg            |arg            |
|export|`?=`|`?=`|var            |var            |env            |env            |arg            |arg            |

<!-- markdownlint-disable MD010 -->
```sh
$ <<MAKEFILE > ./Makefile
a := var
b ?= var
c := var
d ?= var
export e := var
export f ?= var
export g := var
export h ?= var
default:
	@\$(MAKE) -C sub
	@\$(MAKE) -e -C sub
MAKEFILE
$ mkdir -p sub && <<MAKEFILE > ./sub/Makefile
a := sub
b := sub
c ?= sub
d ?= sub
e := sub
f := sub
g ?= sub
h ?= sub
default:
	@echo a=\$(a) b=\$(b) c=\$(c) d=\$(d) e=\$(e) f=\$(f) g=\$(g) h=\$(h)
MAKEFILE
$ make ; a=env b=env c=env d=env e=env f=env g=env h=env make ; make a=arg b=arg c=arg d=arg e=arg f=arg g=arg h=arg
a=sub b=sub c=sub d=sub e=sub f=sub g=var h=var
a=sub b=sub c=sub d=sub e=var f=var g=var h=var
a=sub b=sub c=var d=env e=sub f=sub g=var h=env
a=var b=env c=var d=env e=var f=env g=var h=env
a=arg b=arg c=arg d=arg e=arg f=arg g=arg h=arg
a=arg b=arg c=arg d=arg e=arg f=arg g=arg h=arg
```
<!-- markdownlint-enable MD010 -->
