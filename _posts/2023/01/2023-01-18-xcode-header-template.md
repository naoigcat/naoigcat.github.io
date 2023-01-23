---
layout: post
title:  Xcodeのファイルヘッダーをカスタマイズする
date:   2023/01/18 11:54:32 +0900
tags:   xcode
---

## 以前はヘッダーの一部しかカスタマイズできなかった

Xcodeでファイルを新規作成したときファイルヘッダーにはファイル名や日付、作成者名、組織名などが自動的に入力されていた。

作成者名はログインユーザーが使用され、組織名はXcodeプロジェクトのOrganizationに入力されたものが使われるためこれらはカスタマイズ可能だった。

Xcode 9から全体をカスタマイズできるようになっている。

## テンプレートファイルによってカスタマイズできる

下記のディレクトリに置かれた`IDETemplateMacros.plist`のうち最初に見つかったテンプレートを用いてファイルヘッダーが生成される。

|Name                 |Directory                                                     |
|:--------------------|:-------------------------------------------------------------|
|Project user data    |<ProjectName>.xcodeproj/xcuserdata/[username].xcuserdatad/    |
|Project shared data  |<ProjectName>.xcodeproj/xcshareddata/                         |
|Workspace user data  |<WorkspaceName>.xcworkspace/xcuserdata/[username].xcuserdatad/|
|Workspace shared data|<WorkspaceName>.xcworkspace/xcshareddata/                     |
|User Xcode data      |~/Library/Developer/Xcode/UserData/                           |

-   ref. [Customize text macros - Xcode Help](https://help.apple.com/xcode/mac/9.0/index.html?localePath=en.lproj#/dev91a7a31fc)

## テンプレートファイルを編集する

デフォルトのファイルヘッダーを再現する`IDETemplateMacros.plist`の内容は下記のようになる。

この内容を書き換えることで新規作成時のファイルヘッダーを変更できる。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>FILEHEADER</key>
<string>
//  ___FILENAME___
//  ___TARGETNAME___
//
//  Created by ___USERNAME___ on ___DATE___.
//  ___COPYRIGHT___
//</string>
</dict>
</plist>
```

上記のファイルのままの場合は下記のように生成される。

```swift
//
//  File.swift
//  Target
//
//  Created by User on 2023/01/18.
//  Copyright © 2023 Organization. All rights reserved.
//

import Foundation
```

-   マクロの使用方法や使用できるマクロについてはXcodeのヘルプサイトに記載されている
    -   ref. [Text macros reference - Xcode Help](https://help.apple.com/xcode/mac/9.0/index.html?localePath=en.lproj#/dev7fe737ce0)
    -   ref. [Text macro format reference - Xcode Help](https://help.apple.com/xcode/mac/9.0/index.html?localePath=en.lproj#/devc8a500cb9)
-   先頭行の`//`+改行1つと最終行の改行2つは自動的に挿入される
