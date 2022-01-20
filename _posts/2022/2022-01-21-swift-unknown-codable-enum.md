---
layout: post
title:  Swiftで想定外のレスポンスを変換可能なEnumを作る
date:   2022/01/21 08:58:59 +0900
tags:   swift, ios
---

Enumを持つオブジェクトをCodableにすると、未定義の値が渡されたときに`nil`になったりエラーになって全体の変換が失敗したりする。

APIのレスポンスなどでバージョンアップにより未定義の値が渡される可能性がある場合、値を受け取れるようにしたいケースがある。

```swift
protocol UnknownCodable: Codable, CaseIterable {
    var rawValue: String { get }
    static func unknown(_ value: String) -> Self
}

extension UnknownCodable {
    var rawValue: String {
        Mirror(reflecting: self).children.first?.value as? String ?? String(describing: self)
    }

    init?(rawValue: String) {
        self = Self.allCases.filter({ $0.rawValue == rawValue }).first ?? Self.unknown(rawValue)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self.allCases.filter({ $0.rawValue == rawValue }).first ?? Self.unknown(rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
```

上記のプロトコルに適合させ、`case unknown(String)`の追加と`allCases`の定義を行うことで未定義の値を受け取れるようになる。

ただ、`case`の名称と実際の値が異なる場合`=`で値を定義できないため`rawValue`のオーバーライドが必要になる。

```swift
enum EnumWithUnknown: UnknownCodable {

    case a
    case b
    case c
    case unknown(String)

    static var allCases: [EnumWithUnknown] = [
        .a,
        .b,
        .c,
    ]

    var rawValue: String {
        switch self {
        case .a:
            return "0"
        case .b:
            return "1"
        case .c:
            return "2"
        case .unknown(let value):
            return value
        }
    }

}

struct Object: Codable, CustomStringConvertible {
    var value: EnumWithUnknown

    var description: String {
        "value=\(self.value)"
    }
}

print((try? JSONEncoder().encode(Object(value: .a))).flatMap({ String(data: $0, encoding: .utf8) }) ?? "")
// => {"value":"0"}
print((try? JSONEncoder().encode(Object(value: .unknown("3")))).flatMap({ String(data: $0, encoding: .utf8) }) ?? "")
// => {"value":"3"}
print((try? JSONDecoder().decode(Object.self, from: Data("{\"value\": \"0\"}".utf8)))?.description ?? "")
// => value=a
print((try? JSONDecoder().decode(Object.self, from: Data("{\"value\": \"3\"}".utf8)))?.description ?? "")
// => value=unknown("3")
```
