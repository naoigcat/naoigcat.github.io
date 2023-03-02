---
layout: post
title:  JavaScriptでオブジェクトとクラスを相互変換する
date:   2023-03-02 12:06:27 +0900
tags:   javascript
---

## ライブラリを導入する

オープンソースのライブラリ<https://github.com/typestack/class-transformer>を使用してオブジェクトとクラスの相互変換を簡単に行う。

Node.jsで使用する場合は`npm`経由でインストールする。

```sh
npm install class-transformer --save
```

## プレインオブジェクトをクラスに変換する

```typescript
import { plainToInstance } from 'class-transformer';
class Customer {
    constructor(private name: string, private age: number) {
        this.name = name;
        this.age = age;
    }
}
const customer = plainToInstance(Customer, {
    name: 'alice',
    age: 13,
});
console.log(customer); // Customer {name: "alice", age: 13}
console.log(customer instanceof Customer); // true
```

配列を渡すと変換されたインスタンスの配列が返される。

## クラスをプレインオブジェクトに変換する

```typescript
import { instanceToPlain } from 'class-transformer';
class Customer {
    constructor(private name: string, private age: number) {
        this.name = name;
        this.age = age;
    }
}
const customer = instanceToPlain(new Customer('alice', 13));
console.log(customer); // {name: "alice", age: 13}
console.log(customer instanceof Customer); // false
```

## ネストされたオブジェクトも変換できる

クラス定義に`@Type`属性を付けることでネストされたオブジェクトも変換できる。

```typescript
import { Type, plainToInstance } from 'class-transformer';
class Album {
    id: number;
    name: string;
    @Type(() => Photo)
    photos: Photo[];
}
class Photo {
    id: number;
    filename: string;
}
const album = plainToInstance(Album, {
    id: 1,
    name: 'Photograph',
    photos: [{id: 1, filename: 'IMG_0001.PNG'}, {id: 2, filename: 'IMG_0002.PNG'}]
});
```
