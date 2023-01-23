---
layout: post
title:  iOSアプリのインストール日時を取得する
date:   2023/01/02 12:33:04 +0900
tags:   ios
---

## ディレクトリ作成日時をインストール日時と見做す

iOS/iPadOSアプリをApp Storeからインストールした日時を取得するAPIがない。そのためインストールしたときに作成されるドキュメントディレクトリの作成日時を見做す必要がある。

ディレクトリの作成日時のため端末日時がずれているとその分ずれることになる。

```swift
let date: Date? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first.flatMap({ document in
    let attributes = try? FileManager.default.attributesOfItem(atPath: document)
    return attributes.flatMap({ $0[FileAttributeKey.creationDate] as? Date })
})
```
