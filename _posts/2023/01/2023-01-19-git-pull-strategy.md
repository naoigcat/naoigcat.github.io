---
layout: post
title:  Gitのpullコマンドの挙動を変更する
date:   2023/01/19 14:47:07 +0900
tags:   git
---

## 特定のバージョンから警告が出るようになっている

Git 2.27.0以降で`git pull`コマンドを実行すると警告が表示される。

```sh
warning: Pulling without specifying how to reconcile divergent branches is
discouraged. You can squelch this message by running one of the following
commands sometime before your next pull:

  git config pull.rebase false  # merge (the default strategy)
  git config pull.rebase true   # rebase
  git config pull.ff only       # fast-forward only

You can replace "git config" with "git config --global" to set a default
preference for all repositories. You can also pass --rebase, --no-rebase,
or --ff-only on the command line to override the configured default per
invocation.
```

メッセージにあるように3つのオプションのうち1つを選択しないと警告が表示され続ける。

## リベースせずマージする

```sh
git config pull.rebase false
```

デフォルトの挙動で、リベースを行わず、分岐がある場合はマージコミットを作成する。

```mermaid
gitGraph
    commit id: "initial"
    branch origin/develop
    checkout origin/develop
    commit id: "commit-1"
    commit id: "commit-2"
    commit id: "commit-3"
    checkout main
    branch develop
    commit id: "commit-4"
    commit id: "commit-5"
    commit id: "commit-6"
```

このコミット状況で`git pull`を実行すると、

```mermaid
gitGraph
    commit id: "initial"
    branch origin/develop
    checkout origin/develop
    commit id: "commit-1"
    commit id: "commit-2"
    commit id: "commit-3"
    checkout main
    branch develop
    commit id: "commit-4"
    commit id: "commit-5"
    commit id: "commit-6"
    merge origin/develop
```

になる。

## リベースしてマージする

```sh
git config pull.rebase true
```

ローカルの変更をリベースをしてマージコミットを作成しない。

```mermaid
gitGraph
    commit id: "initial"
    branch origin/develop
    checkout origin/develop
    commit id: "commit-1"
    commit id: "commit-2"
    commit id: "commit-3"
    checkout main
    branch develop
    commit id: "commit-4"
    commit id: "commit-5"
    commit id: "commit-6"
```

このコミット状況で`git pull`を実行すると、

```mermaid
gitGraph
    commit id: "initial"
    branch origin/develop
    checkout origin/develop
    commit id: "commit-1"
    commit id: "commit-2"
    commit id: "commit-3"
    branch develop
    commit id: "commit-4"
    commit id: "commit-5"
    commit id: "commit-6"
```

になる。

## ファストフォワードのみ許可する

```sh
git config pull.ff only
```

ローカルで変更されておらずファストフォワードのみでリモートの変更を取り込める場合のみプルできる。

```mermaid
gitGraph
    commit id: "initial"
    branch develop
    commit id: "commit-1"
    commit id: "commit-2"
    commit id: "commit-3"
    branch origin/develop
    commit id: "commit-4"
    commit id: "commit-5"
    commit id: "commit-6"
```

このコミット状況で`git pull`を実行すると、

```mermaid
gitGraph
    commit id: "initial"
    branch develop
    commit id: "commit-1"
    commit id: "commit-2"
    commit id: "commit-3"
    commit id: "commit-4"
    commit id: "commit-5"
    commit id: "commit-6"
    branch origin/develop
```

になる。`develop`ブランチは`origin/develop`と完全に同じ位置を指す。
