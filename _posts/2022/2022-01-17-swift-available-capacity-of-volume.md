---
layout: post
title:  iOSで使用可能なストレージサイズを取得する
date:   2022/01/17 10:41:39 +0900
tags:   swift, ios
---

設定アプリの情報>使用可能に表示されているストレージサイズを取得したい場合がある。

Swift 3.0の時代には下記のようなコードが紹介されていたが、設定アプリの表示されている値よりも小さい値が返却される。

```swift
var systemFreeSize: NSNumber? {
    guard let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
        return nil
    }
    guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: documents) else {
        return nil
    }
    guard let systemFreeSize = attributes[.systemFreeSize] as? NSNumber else {
        return nil
    }
    return NSNumber(value: round(systemFreeSize.doubleValue / Double(1000 * 1000 * 1000) * 100) / 100)
}
```

iOS 11以降で`URLResourceKey`に追加された`volumeAvailableCapacityForImportantUsageKey`を使用すると設定アプリと一致する値が取得できる。

```swift
var systemFreeSize: NSNumber? {
    guard let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
        return nil
    }
    do {
        let values = try URL(fileURLWithPath: documents).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        guard let capacity = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }
        return NSNumber(value: round(Double(capacity) / Double(1000 * 1000 * 1000) * 100) / 100)
    } catch {
        return nil
    }
}
```
