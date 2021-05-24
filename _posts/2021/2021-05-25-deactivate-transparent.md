---
layout: post
title:  透過画像を非透過画像に変換する
date:   2021/05/25 08:06:09 +0900
tags:   imagemagick
---

## 半透明を無視する場合

```sh
convert SOURCE.PNG -background white -alpha deactivate -flatten TARGET.PNG
```

## 半透明を考慮する場合

```sh
convert SOURCE.PNG \
    \( +clone -alpha opaque -fill white -colorize 100% \) \
    +swap -geometry +0+0 -compose Over -composite -alpha off \
    TARGET.PNG
```
