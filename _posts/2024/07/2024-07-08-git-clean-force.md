---
layout: post
title:  管理対象外のGitディレクトリを削除する
date:   2024/07/08 12:49:11 +0900
tags:   git
---

## Gitの管理対象外ファイルを削除する

Gitリポジトリ内でGitに登録されていないファイルを削除するには下記のコマンドを実行する。

```sh
git clean
```

.gitignoreで無視しているファイルも削除したい場合は`-x`オプションを追加する。

```sh
git clean -x
```

## Gitディレクトリも削除できる

デフォルトではGitに登録されていない、もしくは、.gitignoreで無視しているディレクトリに.gitディレクトリがあった場合、`git clean`コマンドはそのディレクトリを無視する。

```sh
$ mkdir -p Sources/Package
$ touch Package/Package.swift
$ echo $'.build\nPackage.resolved' > .gitignore
$ cat <<EOS > Package.swift
// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

public let package = Package(
    name: "Package",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", exact: "0.53.0"),
    ],
    targets: [
        .target(name: "Package"),
    ]
)
EOS
$ git add .
$ swift run swiftlint Sources
$ git clean -fdx .
Skipping repository .build/checkouts/swift-argument-parser
Skipping repository .build/checkouts/Yams
Skipping repository .build/checkouts/swift-syntax
Skipping repository .build/checkouts/CollectionConcurrencyKit
Skipping repository .build/checkouts/SwiftyTextTable
Skipping repository .build/checkouts/CryptoSwift
Skipping repository .build/checkouts/SWXMLHash
Skipping repository .build/checkouts/SourceKitten
Skipping repository .build/checkouts/SwiftLint
Removing .build/artifacts
Removing .build/workspace-state.json
Removing .build/debug.yaml
Removing .build/repositories
Removing .build/arm64-apple-macosx
Removing .build/debug
Removing Package.resolved
```

しかし、`-f`オプションを二重に付けることで.gitディレクトリのあるサブディレクトリも削除できる

```sh
$ git clean -ffdx .
Removing .build/
Removing Package.resolved
```
