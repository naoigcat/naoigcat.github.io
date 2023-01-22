---
layout: post
title:  Gitで履歴を完全に削除する
date:   2020/02/24 01:07:41 +0900
tags:   git
---

## 全てのブランチに対してコマンドを実行する

```sh
git filter-branch --prune-empty --index-filter \
'git rm --cached --ignore-unmatch password.txt' HEAD --all
```

## 参照ログを削除する

```sh
git reflog expire --expire=now --all
```

## ガベージコレクションを実行する

```sh
git gc --aggressive --prune=now
```

## 強制プッシュする

```sh
git push --force origin master
```

----

この操作を行ってもリモートリポジトリにはログが残ったままになるため、コミットにはアクセスできてしまう。
