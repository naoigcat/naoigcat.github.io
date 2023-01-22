---
layout: post
title:  Objective-Cのテキストフィールドの自動補正を無効にする
date:   2017/09/02 12:26:00 +0900
tags:   objective-c
---

## テキストフィールドに入力すると補正される

`UITextField`は入力中に先頭が大文字に補正されたり、スペルが修正されたりするが、ユーザーIDやメールアドレスの入力中はこの補正が邪魔になる場合がある。

## 補正機能を無効にする

補正機能はプロパティを変更することで無効にする事ができる。

```objc
@interface UITextField (Autocorrection)

+ (instancetype)textFieldWithoutAutocorrection:(CGRect)frame;

@end

@implementation UITextField (Autocorrection)

+ (instancetype)textFieldWithoutAutocorrection:(CGRect)frame {
    UITextField *textField = [[self alloc] initWithFrame:frame];
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    return textField;
}

@end
```
