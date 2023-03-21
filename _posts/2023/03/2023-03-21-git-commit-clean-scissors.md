---
layout: post
title:  コミットメッセージをハッシュ記号から始める
date:   2023/03/21 12:51:34 +0900
tags:   git
---

## コミットメッセージ中のコメントは記録されない

`git commit`で`--message`でメッセージを指定するときは`#`から始まっていてもそのまま記録されるが、メッセージを指定せずエディタで指定する場合、デフォルトでは`#`から始まる行は無視されて記録されない。

```sh
$ git commit --allow-empty --message "# Message"
[master (root-commit) d364dc3] # Message
$ git commit --allow-empty
# Message

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch master
#
# Initial commit
#
Aborting commit due to empty commit message.
```

## 設定でコメント文字を変更できる

`git 1.8.2`以降であれば、`git config core.commentChar`でコメントの先頭文字を変更できる。

```sh
$ git --version
git version 2.39.2
$ git config core.commentChar %
$ git commit --allow-empty
# Message

% Please enter the commit message for your changes. Lines starting
% with '%' will be ignored, and an empty message aborts the commit.
%
% On branch master
%
% Initial commit
%
[master (root-commit) d364dc3] # Message
```

## オプションで無視される部分を変更できる

`git 2.0.0`以降であれば、`--cleanup`オプションで無視される部分を変更できる。

```sh
$ git --version
git version 2.39.2
$ git commit --allow-empty --cleanup=scissors
# Message

# ------------------------ >8 ------------------------
# Do not modify or remove the line above.
# Everything below it will be ignored.
#
# On branch master
#
# Initial commit
[master (root-commit) d364dc3] # Message
```

`--cleanup=scissors`を指定すると`# --- >8 ---`の行以降がメッセージに含まれなくなる。
