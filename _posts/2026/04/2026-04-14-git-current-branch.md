---
layout: post
title:  Gitでカレントブランチを取得する
date:   2026-04-14 04:37:49 +0900
tags:   git
---

## カレントブランチ名を取得する

`git rev-parse` コマンドはリビジョンや参照名を解決してコミットハッシュを表示する。

`--abbrev-ref` オプションを付けるとコミットに対応するブランチやタグがある場合にその名前を表示する。

```bash
$ git rev-parse --abbrev-ref HEAD
main
```
