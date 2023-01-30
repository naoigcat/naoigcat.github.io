---
layout: post
title:  CocoaPodsでフレームワークとライブラリを混ぜる
date:   2023/01/30 12:14:32 +0900
tags:   swift
---

## フレームワークとしてビルドするかどうかを設定できる

`use_frameworks!`メソッドをPodfileから呼び出すことでCocoaPodsをフレームワークとしてビルドできる。

`:linkage`オプションで`:dynamic`か`:static`かを選択することもできる。

```rb
use_frameworks! :linkage => :static
```

## バイナリで配布されている場合は制限がある

ライブラリが下記のようなバイナリで配布されている場合、

-   `*.a` + `*.h`
-   `*.framework`
-   `*.xcframework`

リンクするときにスタティックフレームワークもしくはスタティックライブラリのどちらかでしかリンクできない場合がある。

## ライブラリ毎にフレームワークかどうかを選択できない

CocoaPodsでは上記のように`use_frameworks!`でライブラリ全てをフレームワークとするかどうかを選択できるが、個別には選択できない。

そのため特殊な実装が必要になる。

個別のライブラリがダイナミックかスタティックか、フレームワークかライブラリかは`build_type`プロパティで決められているためこれを上書きすることで挙動を変えられる。

```rb
Module.new do
  def static_libraries
    @static_libraries ||= []
  end

  def pod(name = nil, *requirements)
    static_libraries << name if requirements&.last&.is_a?(Hash) && requirements&.last&.delete(:static_library)
    super
  end
end.tap(&singleton_class.method(:prepend))

use_frameworks! :linkage => :static

pod "StaticFramework"
pod "StaticLibrary" :static_library => true

pre_install do |installer|
  installer.pod_targets.select do |pod|
    next unless static_libraries.include?(pod.name)

    def pod.build_type
      ::Pod::BuildType.static_library
    end
  end
end
```
