---
layout: post
title:  LaunchPadに表示されるアイコンの数を変更する
date:   2017-09-21 09:12:00 +0900
tags:   macos
---

LaunchPadに表示されているアイコンの数は7x5などがデフォルトになっているが下記のコマンドで変更できる。

```sh
defaults write com.apple.dock springboard-columns -int 10
defaults write com.apple.dock springboard-rows -int 7
defaults write com.apple.dock ResetLaunchPad -bool TRUE
```

変更を反映するためにDockの再起動が必要になる。

```sh
killall Dock
```

上記コマンドを実行するとアイコンの並び順がリセットされるため注意する。また、数を変更せずに並び順をリセットするには下記コマンドのみを実行する。

```sh
defaults write com.apple.dock ResetLaunchPad -bool TRUE
```

デフォルトに戻すコマンドは存在しないため、変更前の数を記録しておいて同じコマンドで戻す必要がある。
