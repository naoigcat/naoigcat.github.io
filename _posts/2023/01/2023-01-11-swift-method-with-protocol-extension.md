---
layout: post
title:  Swiftのプロトコルにメソッド宣言があるかどうかで挙動が異なる
date:   2023/01/11 12:48:56 +0900
tags:   swift
---

## メソッド宣言があるとクラス側の実装が使用される

```swift
protocol Customizable {
    func customMessage() -> String
}

extension Customizable {
    func customMessage() -> String {
        return "Default Message"
    }
}

class Example: Customizable {
    func customMessage() -> String {
        return "Example Message"
    }
}

let example = Example()
example.customMessage()                   // "Example Message"
(example as Customizable).customMessage() // "Example Message"
```

プロトコルに宣言されたメソッドをエクステンションで実装した場合はデフォルト実装となり、プロトコルを適用したクラスにメソッドが実装されていない場合のみ呼び出される。

キャストしたとしても**動的ディスパッチ**となり、クラス側の実装が適用される。

## メソッド宣言がないとプロトコル側の実装が使用される

```swift
protocol Customizable {
    // func customMessage() -> String
}

extension Customizable {
    func customMessage() -> String {
        return "Default Message"
    }
}

class Example: Customizable {
    func customMessage() -> String {
        return "Example Message"
    }
}

let example = Example()
example.customMessage()                   // "Example Message"
(example as Customizable).customMessage() // "Default Message"
```

プロトコルに宣言されていないメソッドをエクステンションで実装した場合はプロトコルが持つメソッドでクラス側の実装とは独立している。

キャストすると**静的ディスパッチ**となり、プロトコル側の実装が適用される。
