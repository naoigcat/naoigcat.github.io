---
layout: post
title:  macOSでSSH接続時にDocumentsディレクトリやDesktopディレクトリにアクセスする
date:   2022/12/27 12:03:01 +0900
tags:   macos ssh
---

## 現象

macOS Catalina以降の端末にSSH接続してDocumentsディレクトリやDesktopディレクトリにアクセスしようとすると`Operation not permitted`というエラーになる場合がある。

## 解決策

SSH接続の場合は`sshd-keygen-wrapper`としてアクセスすることになるためシステム設定 > セキュリティとプライバシー > プライバシー > フルディスクアクセスに`sshd-keygen-wrapper`を追加することでアクセスできるようになる。

## 参考

-   <https://apple.stackexchange.com/questions/438586/macos-documents-folder-not-accessible-from-ssh>
