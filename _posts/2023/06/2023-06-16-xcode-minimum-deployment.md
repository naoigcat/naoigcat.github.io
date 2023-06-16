---
layout: post
title:  Xcode 14.3でCocoaPodsライブラリのビルドが失敗する
date:   2023/06/16 17:03:27 +0900
tags:   xcode
---

## CocoaPodsライブラリのビルドが失敗する

Xcode 14.3以降でビルドすると、`libarclite`がなくなっているためCocoaPods経由でインストールしたライブラリのビルドが失敗するようになる場合がある。

```stderr
File not found: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/libarclite_iphoneos.a
```

## デプロイ対象バージョンを上げることで解消する

Minimum Deploymentを11.0以降にすることで解消する。

CocoaPodsが生成するプロジェクトのMinimum Deploymentを変更するには`post_install`フックを使用する。

```ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        end
    end
end
```

## 削除されたライブラリを復元することでも解消する

GitHub上でXcodeから削除されたライブラリを公開しているリポジトリがあるためそこからダウンロードすることでも解消できる。

```sh
mkdir -p /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc
cd /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc
sudo git clone https://github.com/kamyarelyasi/Libarclite-Files.git .
sudo chmod +x *
```
