---
layout: post
title:  設定ファイル名に付くrcはRun Commandsの略である
date:   2024/02/25 10:14:42 +0900
tags:   sh
---

## 設定ファイル名に共通する接尾辞がある

UNIX系の設定ファイルには.bashrcや.zshrc、.vimrcのように接尾辞に`rc`が付くものが多くある。

これは[Run Commands](https://en.wikipedia.org/wiki/Run_Commands)の略であるとされている。

## 互換タイムシェアリングシステムのコマンドに由来する

MIT計算センターで開発された世界初のタイムシェアリングシステムである[CTSS](https://ja.wikipedia.org/wiki/CTSS) (Compatible Time-Sharing System、互換タイムシェアリングシステム) で使用できたRUNCOMに由来しているとされている。

RUNCOMはファイルに書かれているコマンド群を実行するものでUNIXのシェルスクリプトの原型である。
