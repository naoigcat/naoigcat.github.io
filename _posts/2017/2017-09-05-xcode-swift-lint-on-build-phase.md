---
layout: post
title:  Xcodeでのビルド時にSwiftLintを実行する
date:   2017/09/05 19:30:00 +0900
tags:   xcode
---

## ビルド時にSwiftLintを実行する

1.  SwiftLintをHomebrewを使用してインストールする。

    ```sh
    brew install swiftlint
    ```

2.  実行したいTargetのBuild PhasesでRun Scriptを追加し、下記のスクリプトを実行させる。

    ```sh
    if which swiftlint >/dev/null; then
        swiftlint
    else
        echo "warning: swiftlint does not exist, do brew install swiftlint"
    fi
    ```

3.  末尾のスペースの削除など簡単なものは自動修正させたい場合は`swiftlint`の前に`swiftlint autocorrect`を入れる。
