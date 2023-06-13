---
layout: post
title:  Gitのリモートから削除されたタグをローカルからも削除する
date:   2023/06/13 13:23:06 +0900
tags:   xcode
---

## リモートから削除されたブランチをローカルからも削除する

`git fetch`でリモートから取得したブランチはリモート側で削除しても`origin/xxx`ブランチとして残ったままになる。

`git fetch`に`--prune`オプションを付けることでリモートで削除されている`origin/xxx`ブランチも削除される。

```sh
git fetch --prune
```

## リモートから削除されたタグをローカルからも削除する

`--prune`オプションではタグは削除されないため、一度全て削除して再取得する。

```sh
git tag -l | xargs git tag -d
git fetch
```
