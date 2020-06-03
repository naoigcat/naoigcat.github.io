---
layout: post
title:  Gitで過去のコミットの作成日時を任意の時刻に変更する
date:   2020/06/03 17:11:38 +0900
tags:   git
---

下記コマンドで任意のコミットの作成日時を変更することができる。

```sh
git commit --amend --date "2020/06/03 17:11:38 +0900" --reuse-message HEAD
```

さらにログから時刻を取り出すことで一つ前のコミットの作成日時と同じ時刻に変更することができる。

```sh
git commit --amend --date "$(git log --pretty=format:"%ad" | head -n2 | tail -n1)" --reuse-message HEAD
```
