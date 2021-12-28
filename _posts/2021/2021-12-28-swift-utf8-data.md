---
layout: post
title:  SwiftのStringをutf8でエンコーディングするときオプショナルにしない
date:   2021/12/28 12:08:37 +0900
tags:   swift
---

`StringProtocol`に

```swift
func data(using encoding: String.Encoding, allowLossyConversion: Bool = false) -> Data?
```

というメソッドが定義されており、`String`から`Data`に変換できるようになっている。この変換は第一引数で指定したエンコーディングで行われ、変換できない文字が含まれている場合に`nil`が返される。

Swift 5 以降では、[Stringは内部データをUTF8で保持](https://swift.org/blog/utf8-string/)していて、`var utf8: Self.UTF8View { get }`で参照できる。

そのため、UTF8でエンコーディングするときは下記のコードでオプショナルにせずに`Data`に変換できる。

```swift
let string: String = "string"
let data: Data = Data(string.utf8)
```

[内部の実装](https://github.com/apple/swift/blob/a353176e1eb570a56809cf4202f5f30aa8905840/stdlib/public/Darwin/Foundation/NSStringAPI.swift#L791-L811)でも`String.data(using:)`に`.utf8`を渡したときは`Data(self.utf8)`が呼ばれている。
