---
title:     macOSでSSH接続時にフルディスクアクセス権限を付与する
date:      2022-12-27 12:03:01 +0900
tags:      macos ssh
---

## SSH経由でのディレクトリアクセス時にエラーになる

macOS Catalina以降の端末にSSH接続してDocumentsディレクトリやDesktopディレクトリにアクセスしようとすると`Operation not permitted`というエラーになる場合がある。

## 設定からアクセス許可を与える

SSH接続の場合は`/usr/libexec/sshd-keygen-wrapper`（Finder では非表示の `/usr/libexec` 配下）としてアクセスすることになる。

システム設定 > プライバシーとセキュリティ > フルディスクアクセス（macOS Ventura 以前は「セキュリティとプライバシー > プライバシー > フルディスクアクセス」）に`sshd-keygen-wrapper` を追加することでアクセスできるようになる。
