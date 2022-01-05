---
layout: post
title:  未知の値を受け取れるEnumを実装する
date:   2022/01/05 19:33:49 +0900
tags:   swift
---

APIのレスポンスをEnumに入れる場合、未知の値が返ってくるとデコードに失敗してErrorが投げられてしまう。

`nil`を入れるようにすることも可能だがレスポンスが`null`だったのかデコードに失敗したのか区別が付かない上に実際のレスポンスの内容が確認できない。

そのため、下記のように実装することで未知の値を`unknown`で受け取るようにすることができる。

`CaseIterable`や`RawRepresentable`に適合させる場合はそれぞれ自前での実装が必要になる。

```swift
enum EnumWithUnknown: Codable {

    case a
    case b
    case c
    case unknown(String)

    private enum RawValue: String, Codable {
        case a
        case b
        case c
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedString = try container.decode(String.self)
        if let value = RawValue(rawValue: decodedString) {
            switch value {
            case .a:
                self = .a
            case .b:
                self = .b
            case .c:
                self = .c
            }
        } else {
            self = .unknown(decodedString)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .a:
            try container.encode(RawValue.a)
        case .b:
            try container.encode(RawValue.b)
        case .c:
            try container.encode(RawValue.c)
        case .unknown(let value):
            try container.encode(value)
        }
    }

}
```
