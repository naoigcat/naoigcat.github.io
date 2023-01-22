---
layout: post
title:  Gitでfast-forward可能かどうかを判定する
date:   2017-09-06 02:56:00 +0900
tags:   git
---

下記コマンドの終了コードで`feature`ブランチが`master`ブランチにfast-forwardでマージできるか判定できる。

```sh
git merge-base --is-ancestor master feature
```
