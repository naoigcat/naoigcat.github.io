---
layout: post
title:  ImageMagicで角丸の文字スタンプを作成する
date:   2024/04/19 15:30:17 +0900
tags:   imagemagick
---

## 文字列を画像にする

ImageMagickのコマンドで指定したフォント、サイズの文字列を画像にすることができる。

```sh
convert \
    -fill white \
    -background srgb\(132,162,212\) \
    -pointsize 100 \
    -gravity center \
    -extent 128x128 \
    -font "SF-Pro-Text-Bold" label\:01 out.png
```

-   `-fill`: 文字色
-   `-background`: 背景色
-   `-pointsize`: 文字サイズ (px)
-   `-gravity center`: 中央揃え
-   `-extent`: 画像サイズ
-   `-font`: フォント (利用可能なフォントは`convert -list font`で確認可能)
-   `label:xx`: 画像化する文字列

## 画像を角丸にする

ImageMagickのコマンドで画像を角丸にすることができる。

```sh
convert \
    -size 128x128 xc:none \
    -draw "roundrectangle 0,0 128,128 16,16" in.png \
    -resize 128x128 \
    -compose src-in \
    -composite out.png
```

-   `-size`, `-resize`: 画像サイズ
-   `-draw "roundrectangle 0,0 128,128 16,16"`: 角丸への変更 (1組目が描画を開始する位置、2組目が画像のサイズ、3組目が角丸のサイズ)
