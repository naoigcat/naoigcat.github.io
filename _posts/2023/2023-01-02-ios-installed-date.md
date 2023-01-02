---
layout: post
title:  iOSアプリのインストール日時を取得する
date:   2023/01/02 12:33:04 +0900
tags:   ios
---

## 概要

iOS/iPadOSアプリをApp Storeからインストールした日時を取得するAPIがない。そのためインストールしたときに作成されるドキュメントディレクトリの作成日時を見なす必要がある。

ディレクトリの作成日時のため端末日時がずれているとその分ずれることになる。

## コード例

```swift
let date: Date? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first.flatMap({ document in
    let attributes = try? FileManager.default.attributesOfItem(atPath: document)
    return attributes.flatMap({ $0[FileAttributeKey.creationDate] as? Date })
})
```
