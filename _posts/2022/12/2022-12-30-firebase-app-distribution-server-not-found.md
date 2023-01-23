---
layout: post
title:  Firebase App Distributionによる配信時にエラーが発生する
date:   2022/12/30 12:10:20 +0900
tags:   fastlane firebase
---

## コマンド実行時にエラーになる場合がある

FastlaneのプラグインでFirebase App Distributionによる配信を行うため下記のコマンドを呼び出すと`the server responded with status 404`になる場合がある。

```sh
$ export FIREBASEAPPDISTRO_APP=...
$ export FIREBASEAPPDISTRO_GROUPS=...
$ export FIREBASEAPPDISTRO_RELEASE_NOTES=...
$ export FIREBASEAPPDISTRO_IPA_PATH=...
$ export GOOGLESERVICE_INFO_PLIST_PATH=...
$ export GOOGLE_APPLICATION_CREDENTIALS=...
$ fastlane add_plugin firebase_app_distribution
$ fastlane run firebase_app_distribution
[12:10:17]: ---------------------------------------
[12:10:17]: --- Step: firebase_app_distribution ---
[12:10:17]: ---------------------------------------
[12:10:17]: 🔐 Authenticating with GOOGLE_APPLICATION_CREDENTIALS environment variable: '${GOOGLE_APPLICATION_CREDENTIALS}'
[12:10:17]: ⌛ Uploading the IPA.
[12:10:20]: the server responded with status 404
```

## 初期化されていないために発生する

Firebase App Distributionが初期化されていないため発生している。

1.  Firebaseのコンソールにログインする
2.  プロジェクトを開く
3.  Release & Monitor > App Distributionを開く
4.  対象のアプリを選択してGet Startedをクリックする
