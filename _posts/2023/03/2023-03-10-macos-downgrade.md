---
layout: post
title:  macOSの古いバージョンをインストールする
date:   2023/03/10 12:01:10 +0900
tags:   macos
---

## [初期搭載されていたバージョンを再インストールする](https://support.apple.com/ja-jp/HT204904)

Intel搭載のMacでは、起動時に`shift + option + command + R`キーを押下しているとmacOS復旧画面が起動し、Macに当初搭載されいたmacOSか、それに一番近い現在も提供されているバージョンが再インストールできる。

上記を`option + command + R`キーで行うとそのMacと互換性のある最新のmacOSがインストールされる。

## [古いバージョンをダウンロードする](https://support.apple.com/ja-jp/HT211683)

macOS 10.13 High Sierra以降はAppleの[サポートページ](https://support.apple.com/ja-jp/HT211683)のリンクからApp Storeを開き、インストールすることができる。

macOS 10.12 Sierra以前はAppleの[サポートページ](https://support.apple.com/ja-jp/HT211683)からイメージをダウンロードする。.dmgファイルをマウントして.pkgファイルを実行すると/Applicationsディレクトリにインストーラーがインストールされる。

インストーラーを実行することで古いmacOSを上書きインストールできる。

## [起動可能なインストーラの作成も行える](https://support.apple.com/ja-jp/HT201372)

古いバージョンではエラーになってインストールが実行できない場合がある。その場合は起動可能なインストーラを作成して`option`キーを押下したまま再起動することでインストーラを実行できる。

```sh
sudo /Applications/Install\ OS\ X\ El\ Capitan.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --applicationpath /Applications/Install\ OS\ X\ El\ Capitan.app \
  --nointeraction
```

Sierraのインストーラを作成しようとして同様に`createinstallmedia`を実行するとエラーになる。

```sh
$ sudo /Applications/Install\ macOS\ Sierra.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/Media \
  --applicationpath /Applications/Install\ macOS\ Sierra.app
/Volume/Media is not a valid volume mount point.
```

Info.plistのバージョンが違っているの原因のためバージョンを書き換えることで実行できるようになる。

```sh
$ sudo plutil \
  -replace CFBundleShortVersionString \
  -string "12.6.03" /Applications/Install\ macOS\ Sierra.app/Contents/Info.plist
$ sudo /Applications/Install\ macOS\ Sierra.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/Media \
  --applicationpath /Applications/Install\ macOS\ Sierra.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```
