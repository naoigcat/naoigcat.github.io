---
title:     多段SSH切断時のエラーメッセージ `Killed by signal 1.` を抑制する
date:      2024-02-16 20:55:36 +0900
tags:      ssh
---

## サーバーを中継してSSHを接続する

`ProxyCommand`を利用すると目的のサーバーに接続するまでに別のサーバーを経由することができる。

```txt
Host target
  HostName hostname
  ProxyCommand ssh relay-host -W %h:%p
```

## 多段SSHを切断するとエラーメッセージが表示される

上記のように多段SSHを構成すると、切断時にエラーメッセージが表示される。

```txt
Killed by signal 1.
```

## コマンドを変更することでエラーメッセージを抑制する

### SSHコマンドのオプションを利用する

```txt
ProxyCommand ssh -q relay-host -W %h:%p
```

### 標準エラーを捨てる

```txt
ProxyCommand ssh relay-host -W %h:%p 2> /dev/null
```
