---
layout: post
title:  Gitで過去のコミットの作成日時を修正する
date:   2020/03/03 09:48:04 +0900
tags:   git
---

## 作成日時と適用日時が異なるコミットを抽出する

Gitで過去のコミットを改変した場合、コミットの作成日時と適用日時がずれてしまう。

```bash
diff \
<(cat <(git log --oneline --pretty=format:'%cd' --date=format:'%Y-%m-%d %H:%M:%S') <(echo '')) \
<(cat <(git log --oneline --pretty=format:'%ad' --date=format:'%Y-%m-%d %H:%M:%S') <(echo ''))
```

## 適用日時を作成日時に書き換える

下記コマンドを実行することで適用日時を作成日時に書き換えることで修正の痕跡を消し去ることができる。

```bash
git rebase --committer-date-is-author-date HEAD^
```

## 最初のコミットを修正する

ただし、上記の方法はInitial Commitに対しては実行できない。Initial Commitの適用日時を修正したい場合は`--root`オプションを追加して対話的リベースを始める。

```bash
git rebase --interactive --root
```

ここでInitial Commitを`e`（もしくは`edit`）にするとInitial Commitに対して変更が行える。

## 直前のコミットの適用日時を修正する

```bash
export GIT_COMMITTER_DATE="2020/03/03 09:48:04 +0900" && git commit --amend --date "$GIT_COMMITTER_DATE" --reuse-message HEAD && unset GIT_COMMITTER_DATE
```

Initial Commitを変更するとほかのコミットの適用日時も更新されるため全てのコミットの適用日時を作成日時に変更する。

```bash
git rebase --committer-date-is-author-date $(git log --oneline --pretty=format:'%H' | tail -n 1)
```

## 作成日時が昇順になっているか確認する

コミットの作成日時が昇順になっているかどうかは下記コマンドで確認できる。

```bash
diff \
<(git log --oneline --pretty=format:'%ad' --date=format:'%Y-%m-%d %H:%M:%S' | sort -r) \
<(cat <(git log --oneline --pretty=format:'%ad' --date=format:'%Y-%m-%d %H:%M:%S') <(echo ''))
```
