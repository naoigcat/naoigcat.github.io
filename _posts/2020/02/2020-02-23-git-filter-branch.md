---
layout: post
title:  Gitで履歴を書き換える
date:   2020/02/23 00:37:18 +0900
tags:   git
---

## コミットを対話的に書き換える

```sh
git rebase --interactive HEAD
```

## コミットの適用日時を作成日時に合わせる

```sh
git rebase --committer-date-is-author-date HEAD
```

## 名前とメールアドレスを変更する

```sh
git filter-branch --force --env-filter \
"GIT_AUTHOR_NAME='$(git config --get user.name)';"\
"GIT_AUTHOR_EMAIL='$(git config --get user.email)';"\
"GIT_COMMITTER_NAME='$(git config --get user.name)';"\
"GIT_COMMITTER_EMAIL='$(git config --get user.email)';" HEAD
```

## コミットを機械的に書き換える

```sh
git filter-branch --tree-filter \
"find . -name *.txt -print0 | xargs -0 perl -pi -e 's/as-is/to-be/g'" HEAD
```

`--tree-filter`は各コミットをチェックアウトしてからコマンドを実行し、コミットし直す。

```sh
git filter-branch --index-filter \
"git rm --cached --ignore-unmatch password.txt" HEAD
```

`--index-filter`はコミットをチェックアウトせずにインデックスを書き換える。

## 書き換える範囲を指定する

`filter-branch`で書き換える範囲は`HEAD`やハッシュでの指定ができず、ブランチで指定する。

変更を適用したい直前のコミットに対してブランチを作成し、ブランチ間のコミットを指定する。

以下は`origin/master`以降で`master`の最新まで、すなわち、プッシュされていないコミットに対して書き換えを実施する。

```sh
git filter-branch --index-filter \
"git rm --cached --ignore-unmatch password.txt" origin/master..master
```
