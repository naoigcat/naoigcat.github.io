---
layout: post
title:  SSHのパスワード認証を無効化する
date:   2023/03/16 22:16:57 +0900
tags:   ssh
---

## パスワード認証を無効化する

SSH接続時にデフォルトではパスワード認証や公開鍵認証が使用できる。

パスワード認証はブルートフォースアタックにより突破されるリスクがあるため公開鍵認証ができる状態になったら無効化しておきたい。

## 複数の設定を変更する必要がある

パスワード認証を有効にしている設定は複数ある。

### `PasswordAuthentication`

IDとパスワードを同時に送信する認証方式。

### `ChallengeResponseAuthentication`

SSH1でのS/Keyを使った認証方式。

先にIDを送り、サーバーからパスワードを要求されるためパスワードによる認証が行える。[OpenSSH 8.7](https://www.openssh.com/txt/release-8.7)以降は`KbdInteractiveAuthentication`のエイリアスになっている。

### `KbdInteractiveAuthentication`

SSH2でのキーボードからの認証方式。

キーボードからのパスワード入力による認証が行える。

## 設定を書き換える

`/etc/ssh/sshd_config`を

```sh
$ sudo systemsetup -setremotelogin on
$ sudo sed -i '' -e '/^#*PasswordAuthentication/{s/#//;s/yes/no/;}' /etc/ssh/sshd_config
$ sudo sed -i '' -e '/^#*ChallengeResponseAuthentication/{s/#//;s/yes/no/;}' /etc/ssh/sshd_config
$ sudo sed -i '' -e '/^#*KbdInteractiveAuthentication/{s/#//;s/yes/no/;}' /etc/ssh/sshd_config
$ sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
$ sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
$ sudo sshd -T | grep authentication
hostbasedauthentication no
pubkeyauthentication yes
kerberosauthentication no
gssapiauthentication no
passwordauthentication no
kbdinteractiveauthentication no
authenticationmethods any
```
