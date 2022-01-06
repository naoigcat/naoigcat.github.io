---
layout: post
title:  Swiftで配列を一定数ずつ分割する
date:   2022/01/06 09:04:13 +0900
tags:   swift
---

一定数刻みで数値のコレクションを返してくれる`stride`関数を利用して配列を一定数毎に分割する`Extension`を作成できる。

```swift
import Foundation

extension Array {
    func slice(_ n: Int) -> [ArraySlice<Element>] {
        return stride(from: 0, through: count - 1, by: n).map({ self[($0..<$0+n).clamped(to: self.indices)] })
    }
}

print(Array(1..<10).slice(3).map({ $0.map({ String($0) }).joined(separator: " ") }).joined(separator: "\n"))
// 1 2 3
// 4 5 6
// 7 8 9
```
