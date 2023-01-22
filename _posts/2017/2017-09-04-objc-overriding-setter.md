---
layout: post
title:  Objective-Cでプロパティのセッターをオーバーライドする
date:   2017/09/04 16:15:00 +0900
tags:   objective-c
---

## プロパティのセッターとゲッターは自動生成される

Objective-Cで`@property`ディレクティブを用いるとセッターとゲッターが自動生成されるため、
セッターをオーバーライドする場合は自動生成されている処理を実装する必要がある。

自動生成されるセッターは以下のようになる。

### MRC

#### retain (MRC)

```objc
- (void)setObject:(Object *)object {
    if (_object != object) {
        [_object release];
        _object = [object retain];
    }
}
```

#### copy (MRC)

```objc
- (void)setObject:(Object *)object {
    [_object release];
    _object = [object copy];
}
```

#### assign (MRC)

```objc
- (void)setInteger:(NSInteger)integer {
    _integer = integer;
}
```

### ARC

#### strong/weak/assign (ARC)

```objc
- (void)setObject:(Object *)object {
    _object = object;
}
```

#### copy (ARC)

```objc
- (void)setObject:(Object *)object {
    _object = [object copy];
}
```
