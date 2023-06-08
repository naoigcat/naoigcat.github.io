---
layout: post
title:  Xcode 12でシミュレーター向けにビルドする
date:   2023/06/08 14:08:39 +0900
tags:   xcode
---

## ライブラリのビルドがエラーになる場合がある

外部ライブラリを含むプロジェクトをシミュレーター向けにビルドする時、下記のエラーが発生する場合がある。

```log
Building for iOS Simulator, but linking in object file built for iOS
```

XcodeでのビルドではCPUアーキテクチャ毎にシミュレーター向けと実機向けで異なるビルドを作成するが、外部ライブラリがarm64アーキテクチャは実機向けにしか対応していないために発生する。

## ライブラリ側で対応する

根本的な対応方法はライブラリを.xcframeworkに対応させてarm64アーキテクチャのシミュレーター向けビルドを含めることである。

以前のライブラリの形式ではCPUアーキテクチャ毎に1種類のビルドしか含められないためarm64アーキテクチャの実機向けビルドとシミュレーター向けビルドを共存させることができない。

CocoaPodsでインストールしている場合は`.podspec`ファイルにビルド設定を追加することでも対応できる。

```ruby
Pod::Spec.new do |s|
  # ...
  s.pod_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" }
  s.user_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" }
end
```

ただし、この場合はM1 mac端末でRosettaを使わずにシミュレーターで動作させることはできない。

## プロジェクト側で対応する

まず、Xcode 11以前でビルド対象のアーキテクチャを選択する際に使用されていた`VALID_ARCHS`が非推奨になっているため

Xcode > Project > Build settings > User-Defined > VALID_ARCHS

を削除する。

Xcode 12以降はExcluded architecturesを使用して

Xcode > Project > Build settings > Architectures > Exclude architectures

のAny iOS Simulator SDKにarm64を追加する。

CocoaPods経由でインストールするライブラリにも同様の設定を追加するため`Podfile`に下記を追加する。

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end
```
