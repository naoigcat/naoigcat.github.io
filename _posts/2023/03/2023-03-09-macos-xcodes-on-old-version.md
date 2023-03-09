---
layout: post
title:  古いmacOSでxcodesコマンドは実行できない
date:   2023/03/09 12:23:18 +0900
tags:   macos xcode
---

## Xcodeのバージョンを管理をコマンドで行う

[xcodes](https://github.com/RobotsAndPencils/xcodes)コマンドでXcodeのバージョン管理を行うことができる。

通常はHomebrew経由でインストールする。

```sh
brew install robotsandpencils/made/xcodes
```

## macOS Catalina以降ならソースからビルドできる

ソースからのビルドにはXcode 12以降が必要なためXcode 12がインストール可能なmacOS Catalina 10.15.4以降であればソースからビルドできる。

## macOS Mojave以降ならバイナリが使用できる

macOS Mojave以降ならビルドされたバイナリをダウンロードすることでそのまま実行できる。

```sh
$ curl -fsSLO https://github.com/RobotsAndPencils/xcodes/releases/download/0.6.0/xcodes-0.6.0.mojave.bottle.tar.gz
$ tar zxf xcodes-0.6.0.mojave.bottle.tar.gz --strip-component 3
$ ./xcodes list
1.0
1.5
2.2.1
...
```

## macOS High Sierra以前では使用できない

macOS High Sierra以前ではビルドされたバイナリをダウンロードしてもビルドした時のライブラリと互換性がないため実行できない。

```sh
$ curl -fsSLO https://github.com/RobotsAndPencils/xcodes/releases/download/0.6.0/xcodes-0.6.0.mojave.bottle.tar.gz
$ tar zxf xcodes-0.6.0.mojave.bottle.tar.gz --strip-component 3
$ install_name_tool -add_rpath /Library/Developer/CommandLineTools/usr/lib/swift/macosx/ xcodes
$ install_name_tool -change /usr/lib/swift/libswiftCompression.dylib @rpath/libswiftCompression.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftCore.dylib @rpath/libswiftCore.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftCoreFoundation.dylib @rpath/libswiftCoreFoundation.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftDarwin.dylib @rpath/libswiftDarwin.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftDispatch.dylib @rpath/libswiftDispatch.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftIOKit.dylib @rpath/libswiftIOKit.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftObjectiveC.dylib @rpath/libswiftObjectiveC.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftXPC.dylib @rpath/libswiftXPC.dylib xcodes
$ install_name_tool -change /usr/lib/swift/libswiftFoundation.dylib @rpath/libswiftFoundation.dylib xcodes
$ ./xcodes list
dyld: Symbol not found: _$s11SubSequenceSlTl
  Referenced from: /Users/smaregi/Downloads/./xcodes (which was built for Mac OS X 10.14)
  Expected in: /Library/Developer/CommandLineTools/usr/lib/swift/macosx/libswiftCore.dylib
 in /Users/smaregi/Downloads/./xcodes
Abort trap: 6
```

0.5.0以前であれば実行可能だが、ログイン先の情報が変わっているためエラーになる。

```sh
curl -fsSLO https://github.com/RobotsAndPencils/xcodes/releases/download/0.5.0/xcodes-0.5.0.mojave.bottle.tar.gz
tar zxf xcodes-0.5.0.mojave.bottle.tar.gz --strip-component 3
install_name_tool -add_rpath /Library/Developer/CommandLineTools/usr/lib/swift/macosx/ xcodes
install_name_tool -change /usr/lib/swift/libswiftCompression.dylib @rpath/libswiftCompression.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftCore.dylib @rpath/libswiftCore.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftCoreFoundation.dylib @rpath/libswiftCoreFoundation.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftDarwin.dylib @rpath/libswiftDarwin.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftDispatch.dylib @rpath/libswiftDispatch.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftIOKit.dylib @rpath/libswiftIOKit.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftObjectiveC.dylib @rpath/libswiftObjectiveC.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftXPC.dylib @rpath/libswiftXPC.dylib xcodes
install_name_tool -change /usr/lib/swift/libswiftFoundation.dylib @rpath/libswiftFoundation.dylib xcodes
./xcodes list
Apple ID:
Apple ID Password:
A server with the specified hostname could not be found.
```
