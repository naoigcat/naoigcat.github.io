---
layout: post
title:  Gitで巨大なリポジトリの一部だけを利用する
date:   2026/04/01 08:32:16 +0900
tags:   git
---

## 履歴の多いリポジトリはクローンに時間がかかる

Gitでリポジトリをクローンする際、履歴が多いと取得に時間がかかる。

必要なコミット数だけ取得する場合は`--depth`を指定する。

```sh
git clone --depth 1 https://github.com/owner/repo.git
```

`--depth`付きでクローンしたリポジトリでも、あとから取得する履歴を増やせる。

```sh
git fetch --depth 200 origin main
```

既存の深さに対して追加で履歴を取得する場合は`--deepen`を使う。

```sh
git fetch --deepen 100 origin main
```

履歴制限を解除して通常の状態に戻す場合は`--unshallow`を使う。

```sh
git fetch --unshallow
```

## ファイルを絞ってチェックアウトする

作業対象のディレクトリやファイルが限定されている場合は`sparse-checkout`を使う。

`--no-checkout`でクローンして、必要なパスだけ作業ツリーに展開する。

```sh
git clone --no-checkout https://github.com/owner/repo.git
cd repo
git sparse-checkout init --cone
git sparse-checkout set docs scripts
git checkout main
```

単一ファイルを対象にする場合は`--no-cone`を使う。

```sh
git sparse-checkout init --no-cone
git sparse-checkout set README.md config/app.yml
git checkout main
```

設定したパスを確認するには下記を実行する。

```sh
git sparse-checkout list
```

制限を解除して全ファイルを展開する場合は下記を実行する。

```sh
git sparse-checkout disable
```
