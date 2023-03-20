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

macOS 10.12 Sierra以前はAppleの[サポートページ](https://support.apple.com/ja-jp/HT211683)からディスクイメージをダウンロードする。.dmgファイルをマウントして.pkgファイルを実行すると/Applicationsディレクトリにインストーラーがインストールされる。

インストーラーを実行することで古いmacOSを上書きインストールできる。

## [起動可能なインストーラの作成も行える](https://support.apple.com/ja-jp/HT201372)

古いバージョンではエラーになってインストールが実行できない場合がある。その場合は起動可能なインストーラを作成して`option`キーを押下したまま再起動することでインストーラを実行できる。

## High Sierraのインストーラを作成する

インストーラに付属している`createinstallmedia`コマンドで外部メディアを起動可能なインストーラにすることができる。

```sh
sudo /Applications/Install\ OS\ X\ El\ Capitan.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Sierraのインストーラを作成する

Sierra以前は`--applicationpath`オプションでインストーラーアプリのパスを指定する必要がある。

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

## El Capitanのインストーラを作成する

```sh
sudo /Applications/Install\ OS\ X\ El\ Capitan.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --applicationpath /Applications/Install\ OS\ X\ El\ Capitan.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Yosemiteのインストーラを作成する

```sh
sudo /Applications/Install\ OS\ X\ Yosemite.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --applicationpath /Applications/Install\ OS\ X\ Yosemite.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Mavericksのインストーラを作成する

Mavericksはディスクイメージ (.dmg) が[Appleのウェブサイト](https://support.apple.com/ja-jp/HT211683)上に存在しないが、過去にApp Storeからダウンロードしたことがあれば`mas`コマンドでダウンロードできる。

```sh
$ brew install mas
$ mas install 675248567
==> Downloading OS X Mavericks
==> Installed OS X Mavericks
$ sudo /Applications/Install\ OS\ X\ Mavericks.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --applicationpath /Applications/Install\ OS\ X\ Mavericks.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Mountain Lionのインストーラを作成する

Mountain Lionのインストーラを作成する場合は`createinstallmedia`のコマンドがないため、`asr`コマンドでディスクイメージを復元する。

```sh
$ sudo asr restore \
  --source /Applications/Install\ OS\ X\ Lion.app/Contents/SharedSupport/InstallESD.dmg \
  --target /Volumes/Media \
  --erase --noprompt
    Validating target...done
    Validating source...done
    Retrieving scan information...done
    Validating sizes...done
    Restoring  ....10....20....30....40....50....60....70....80....90....100
    Verifying  ....10....20....30....40....50....60....70....80....90....100
    Remounting target volume...done
```

## Lionのインストーラを作成する

Lionのインストーラを作成する場合はMountain Lionと同様に`asr`コマンドでディスクイメージを復元するが、チェックサムが一致しないエラーが発生するため`--noverify`オプションを付けて実行する。

```sh
$ sudo asr restore \
  --source /Applications/Install\ OS\ X\ Mountain\ Lion.app/Contents/SharedSupport/InstallESD.dmg \
  --target /Volumes/Media \
  --erase --noprompt
    Validating target...done
    Validating source...done
    Retrieving scan information...done
    Validating sizes...done
    Restoring  ....10....20....30....40....50....60....70....80....90....100
    Verifying  ....10....20....30....40....50....60....70....80....90....100
Checksum failed.
Expected 7425D663
but got 84E748B9
Could not restore - Invalid argument
$ sudo asr restore \
  --source /Applications/Install\ OS\ X\ Mountain\ Lion.app/Contents/SharedSupport/InstallESD.dmg \
  --target /Volumes/Media \
  --erase --noprompt --noverify
    Validating target...done
    Validating source...done
    Retrieving scan information...done
    Validating sizes...done
    Restoring  ....10....20....30....40....50....60....70....80....90....100
    Verifying  ....10....20....30....40....50....60....70....80....90....100
    Remounting target volume...done
```
