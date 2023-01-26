---
layout: post
title:  依存しているSwift Packageのコードを変更する
date:   2023/01/26 11:56:08 +0900
tags:   swift
---

## CocoaPodsではファイルのロックを解除できる

CocoaPodsでインストールしたライブラリのソースファイルは

```sh
${PROJECT_DIR}/Pods
```

にあり、ファイルを変更しようとすると確認メッセージが表示されてファイルのロックを解除でき、そのままソースコードを変更して動作確認ができる。

## Swift Package Managerではファイルは変更できない

Swift Package Managerでインストールしたライブラリのソースファイルは

```sh
${BUILD_DIR%/Build/Products}/SourcePackages/checkouts
```

にあり、ファイルを変更しようとするとエラーになる。

## ローカルパッケージとして追加する

1.  リポジトリをクローンする
1.  File > Add Packages... > Add Local...からリポジトリを追加する
1.  Targets > General > Frameworks, Libraries, and Embedded Contentからターゲットを追加する

リポジトリのファイルを直接変更してビルドすると反映されるようになる。
