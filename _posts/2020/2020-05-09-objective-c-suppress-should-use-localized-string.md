---
layout: post
title:  User-facing text should use localized string macroの警告を抑制する
date:   2020/05/09 17:58:28 +0900
tags:   objective-c
---

ローカライズが不要な文字列に対してもXcode上で`User-facing text should use localized string macro`という警告が表示されてしまう。

以下のようなメソッドを定義することで警告を抑制することが可能になる。

```objc
__attribute__((annotate("returns_localized_nsstring")))
static inline NSString* NSNonLocalizedString(NSString* string, NSString* comment) {
  return string;
}

UITextField* textField = [[UITextField alloc] initWithFrame:CGRectZero];
textField.text = NSNonLocalizedString(@"Debug", nil);
```
