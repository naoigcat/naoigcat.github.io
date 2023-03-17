---
layout: post
title:  仮想端末なしでsudoを実行する
date:   2023/03/17 12:03:33 +0900
tags:   sh sudo
---

## 仮想端末と繋がっていないsudoの実行は無効化されている

macOSではデフォルトで仮想端末と繋がっていない状態での`sudo`の実行が無効化されている。

```sh
$ sudo visudo
# Disable "ssh hostname sudo <cmd>", because it will show the password in clear.
#         You have to run "ssh -t hostname sudo <cmd>".
#
Defaults    requiretty
```

これはクラッキング目的での侵入者に`sudo`を実行されないためにある。

Linuxディストリビューションはデフォルトでこの設定がなく`sudo`が実行可能になっている。

## SSH経由の場合はオプションを追加する

SSH経由でログインした状態であれば仮想端末があるため`sudo`は実行できる。

```sh
$ ssh hostname
> sudo uname
Password:
Darwin
```

`ssh`コマンドに直接`sudo`コマンドを渡す場合仮想端末が割り当てられないためエラーになる。

```sh
$ ssh hostname sudo uname
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
```

メッセージの通り`sudo`に`-S`オプションを付けるとパスワードの入力を受け付けるが、入力した文字が画面上に表示される状態になってしまう。

```sh
$ ssh hostname sudo -S uname
Password:password
Darwin
```

`ssh`に`-t`オプションを付けると強制的に仮想端末が割り当てられる。

```sh
$ ssh -t hostname sudo uname
Password:
Darwin
Connection to hostname closed.
```

## 特定のユーザーのみ有効にする

設定をコメントアウトすることで全てのユーザーで仮想端末なしの`sudo`を許可することができるがリスクが高いため特定のユーザーのみ有効にする。

```diff
 # Disable "ssh hostname sudo <cmd>", because it will show the password in clear.
 #         You have to run "ssh -t hostname sudo <cmd>".
 #
 Defaults    requiretty
+Defaults:root    !requiretty
```

## 特定のコマンドのみ有効にする

コマンド別に有効にすることもできる。

```diff
 Defaults    requiretty
+Defaults!/path/to/command    !requiretty
```
