---
layout: post
title:  macOSのターミナルからApple IDを取得する
date:   2023/02/28 12:03:57 +0900
tags:   macos
---

## iCloudへのログイン情報はユーザー設定から取得する

macOS端末でiCloudにログインしているときユーザー設定にログイン情報が保存されているため`defaults`コマンドで取得することができる。

```sh
$ defaults read MobileMeAccounts Accounts
(
    {
        AccountAlternateDSID = "";
        ...
    }
)
```

保存されている形式が辞書の配列のためApple ID単体で取得するには`plistbuddy`コマンドを使用する。

```sh
$ /usr/libexec/plistbuddy -c 'Print Accounts:0:AccountID' ~/Library/Preferences/MobileMeAccounts.plist
17925623+naoigcat@users.noreply.github.com
```

同様に表示名単体も取得できる。

```sh
$ /usr/libexec/plistbuddy -c 'Print Accounts:0:DisplayName' ~/Library/Preferences/MobileMeAccounts.plist
naoigcat
```

## App Storeへのログイン情報はmasコマンドで取得する

App StoreへはiCloudと別のApple IDでログインすることができる。

こちらは[`mas`](https://github.com/mas-cli/mas)コマンドで取得できる。

```sh
$ mas account
17925623+naoigcat@users.noreply.github.com
```

ただし、macOS 12.x以降では現在動作していない（[#417](https://github.com/mas-cli/mas/issues/417)）。
