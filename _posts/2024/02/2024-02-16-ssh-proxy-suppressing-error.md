---
layout: post
title:  多段SSHをエラーメッセージ `Killed by signal 1.` を抑制する
date:   2024/02/16 20:55:36 +0900
tags:   ssh
---

## サーバーを中継してSSHを接続する

`ProxyCommand`を利用すると目的のサーバーに接続するまでに別のサーバーを経由することができる。

```config
Host target
  HostName hostname
  ProxyCommand ssh relay-host -W %h:%p
```

## 多段SSHを切断するとエラーメッセージが表示される

上記のようにして多段SSHにしていると切断時にエラーメッセージが表示される。

```output
Killed by signal 1.
```

## コマンドを変更することでエラーメッセージを抑制する

### SSHコマンドのオプションを利用する

```config
ProxyCommand ssh -q relay-host -W %h:%p
```

### 標準エラーを捨てる

```config
ProxyCommand ssh relay-host -W %h:%p 2> /dev/null
```
