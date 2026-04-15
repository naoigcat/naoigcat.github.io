---
layout: post
title:  Gitで親ブランチを取得する
date:   2026-04-15 07:39:04 +0900
tags:   git
---

## ブランチとコミットの一覧を表示する

検証用のリポジトリを作成して `show-branch` コマンドでブランチとコミットの一覧を表示する。

```bash
$ git -c init.defaultBranch=main init test
Initialized empty Git repository in test/.git/
$ cd test
$ git config user.name "naoigcat"
$ git config user.email "naoigcat@example.com"
```

チェックアウトしているブランチのコミットは `*` が表示され、別ブランチのコミットは `+` が表示される。そのため、出力結果から `*` が付いているコミットのうち、現在のブランチに存在しないコミットを探すことで親ブランチを特定できる。

```bash
$ git commit --allow-empty --message "Initial commit"
[main (root-commit) 71395af] Initial commit
$ git commit --allow-empty --message "Second commit"
[main 10f8e9f] Second commit
$ git checkout -b feature1 main
Switched to a new branch 'feature1'
$ git commit --allow-empty --message "Third commit"
[feature1 a997372] Third commit
$ git commit --allow-empty --message "Fourth commit"
[feature1 deeab42] Fourth commit
$ git show-branch --all
* [feature1] Fourth commit
 ! [main] Second commit
--
*  [feature1] Fourth commit
*  [feature1^] Third commit
*+ [main] Second commit
$ git show-branch | grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
main
```

```bash
$ git checkout -b feature2 main
Switched to a new branch 'feature2'
$ git commit --allow-empty --message "Fifth commit"
[feature2 9427c21] Fifth commit
$ git show-branch --all
! [feature1] Fourth commit
 * [feature2] Fifth commit
  ! [main] Second commit
---
 *  [feature2] Fifth commit
+   [feature1] Fourth commit
+   [feature1^] Third commit
+*+ [main] Second commit
$ git show-branch | grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
main
```

```bash
$ git switch feature1
Switched to branch 'feature1'
$ git commit --allow-empty --message "Sixth commit"
[feature1 3346fab] Sixth commit
$ git show-branch --all
* [feature1] Sixth commit
 ! [feature2] Fifth commit
  ! [main] Second commit
---
*   [feature1] Sixth commit
*   [feature1^] Fourth commit
*   [feature1~2] Third commit
 +  [feature2] Fifth commit
*++ [main] Second commit
$ git show-branch | grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
main
```

```bash
$ git checkout -b feature3 feature2
Switched to a new branch 'feature3'
$ git commit --allow-empty --message "Seventh commit"
[feature3 721b86e] Seventh commit
$ git show-branch --all
! [feature1] Sixth commit
 ! [feature2] Fifth commit
  * [feature3] Seventh commit
   ! [main] Second commit
----
  *  [feature3] Seventh commit
 +*  [feature2] Fifth commit
+    [feature1] Sixth commit
+    [feature1^] Fourth commit
+    [feature1~2] Third commit
++*+ [main] Second commit
$ git show-branch | grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
feature2
```

```bash
$ git switch feature2
Switched to branch 'feature2'
$ git commit --allow-empty --message "Eighth commit"
[feature2 49403ac] Eighth commit
$ git switch main
Switched to branch 'main'
$ git merge --no-ff feature2 --message "Merge feature2 into main"
Merge made by the 'ort' strategy.
$ git show-branch --all
! [feature1] Sixth commit
 ! [feature2] Eighth commit
  ! [feature3] Seventh commit
   * [main] Merge feature2 into main
----
   - [main] Merge feature2 into main
 + * [feature2] Eighth commit
  +  [feature3] Seventh commit
 ++* [feature2^] Fifth commit
+    [feature1] Sixth commit
+    [feature1^] Fourth commit
+    [feature1~2] Third commit
+++* [main^] Second commit
$ git show-branch | grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
feature2
$ git show-branch $(git branch --no-merged | sed 's/^..//') $(git rev-parse --abbrev-ref HEAD)
! [feature1] Sixth commit
 ! [feature3] Seventh commit
  * [main] Merge feature2 into main
---
  - [main] Merge feature2 into main
  * [main^2] Eighth commit
 +  [feature3] Seventh commit
 +* [feature3^] Fifth commit
+   [feature1] Sixth commit
+   [feature1^] Fourth commit
+   [feature1~2] Third commit
++* [main^] Second commit
$ git show-branch $(git branch --no-merged | sed 's/^..//') $(git rev-parse --abbrev-ref HEAD) | \
  grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
feature3
```

## 親ブランチをコマンドで取得する

カレントブランチのコミットでほかのブランチにも存在する一番近いコミットが所属しているブランチ名を返す。

```bash
git show-branch --all | grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
```

マージコミットが混ざっている場合、マージ済みのブランチが選択されやすくなってしまうため除外する。

```bash
git show-branch $(git branch --no-merged | sed 's/^..//') $(git rev-parse --abbrev-ref HEAD) | \
grep '*' | grep -v "\[$(git rev-parse --abbrev-ref HEAD)[]~^]" | head -1 | awk -F'[]~^[]' '{print $2}'
main
```
