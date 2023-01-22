---
layout: post
title:  Xcodeで新規ファイルに挿入されるヘッダーのローカライズを英語にする
date:   2017/04/10 10:46:53 +0900
tags:   xcode
---

Xcodeでファイルを新規作成するとヘッダーが自動的に挿入される。日本語環境だと下記のようにCopyrightの年のところにだけ`2017年`と漢字が混じる。

```objc
//
//  Sample.m
//  Sample
//
//  Created by naoigcat on 2017/04/10.
//  Copyright © 2017年 naoigcat. All rights reserved.
//

#import <Foundation/Foundation.h>
```

これはアプリケーションのロケールを変更することで回避できる。

```bash
defaults write com.apple.dt.Xcode AppleLocale en_JP
```

```objc
//
//  Sample.m
//  Sample
//
//  Created by naoigcat on 2017/04/10.
//  Copyright © 2017 naoigcat. All rights reserved.
//

#import <Foundation/Foundation.h>
```

`en_JP`は日付の形式は日本式で英語表記というロケール。同じ英語表記でも`en_US`にすると`4/10/17`、`en_GB`にすると`10/4/17`のようになる。
