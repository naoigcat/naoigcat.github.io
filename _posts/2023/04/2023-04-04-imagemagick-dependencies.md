---
layout: post
title:  ImageMagickが依存しているライブラリを調べる
date:   2023/04/04 12:19:55 +0900
tags:   imagemagick
---

## 依存ライブラリの一覧を出力する

Debian Bullseye上の`apt-cache depends`コマンドでImageMagickをインストールするの必要なライブラリを出力する。

```sh
$ docker run --rm debian:bullseye-slim bash -c 'apt-get update && apt-cache depends imagemagick'
Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
Get:2 http://deb.debian.org/debian-security bullseye-security InRelease [48.4 kB]
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [44.1 kB]
Get:4 http://deb.debian.org/debian bullseye/main arm64 Packages [8072 kB]
Get:5 http://deb.debian.org/debian-security bullseye-security/main arm64 Packages [232 kB]
Get:6 http://deb.debian.org/debian bullseye-updates/main arm64 Packages [12.0 kB]
Fetched 8524 kB in 2s (4155 kB/s)
Reading package lists...
imagemagick
  Depends: imagemagick-6.q16
```

```sh
$ docker run --rm debian:bullseye-slim bash -c 'apt-get update && apt-cache depends imagemagick-6.q16'
Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
Get:2 http://deb.debian.org/debian-security bullseye-security InRelease [48.4 kB]
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [44.1 kB]
Get:4 http://deb.debian.org/debian bullseye/main arm64 Packages [8072 kB]
Get:5 http://deb.debian.org/debian-security bullseye-security/main arm64 Packages [232 kB]
Get:6 http://deb.debian.org/debian bullseye-updates/main arm64 Packages [12.0 kB]
Fetched 8524 kB in 3s (2583 kB/s)
Reading package lists...
imagemagick-6.q16
  Depends: libc6
  Depends: libmagickcore-6.q16-6
  Depends: libmagickwand-6.q16-6
  Depends: hicolor-icon-theme
  Breaks: libmagickcore-dev
  Recommends: libmagickcore-6.q16-6-extra
  Recommends: ghostscript
  Recommends: netpbm
  Suggests: imagemagick-doc
    imagemagick-6-doc
  Suggests: <autotrace>
 |Suggests: cups-bsd
 |Suggests: lpr
    cups-bsd
    lprng
  Suggests: lprng
  Suggests: curl
  Suggests: enscript
  Suggests: ffmpeg
  Suggests: gimp
  Suggests: gnuplot
    gnuplot-nox
    gnuplot-qt
    gnuplot-x11
  Suggests: grads
  Suggests: graphviz
  Suggests: groff-base
  Suggests: hp2xx
  Suggests: html2ps
  Suggests: libwmf-bin
  Suggests: mplayer
  Suggests: povray
  Suggests: <radiance>
  Suggests: sane-utils
  Suggests: <texlive-base-bin>
    texlive-binaries
  Suggests: <transfig>
    fig2dev
  Suggests: <ufraw-batch>
  Suggests: xdg-utils
  Replaces: imagemagick
```

```sh
$ docker run --rm debian:bullseye-slim bash -c 'apt-get update && apt-cache depends libmagickcore-6.q16-6'
Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
Get:2 http://deb.debian.org/debian-security bullseye-security InRelease [48.4 kB]
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [44.1 kB]
Get:4 http://deb.debian.org/debian bullseye/main arm64 Packages [8072 kB]
Get:5 http://deb.debian.org/debian-security bullseye-security/main arm64 Packages [232 kB]
Get:6 http://deb.debian.org/debian bullseye-updates/main arm64 Packages [12.0 kB]
Fetched 8524 kB in 4s (2281 kB/s)
Reading package lists...
libmagickcore-6.q16-6
  PreDepends: dpkg
  Depends: libbz2-1.0
  Depends: libc6
  Depends: libfftw3-double3
  Depends: libfontconfig1
  Depends: libfreetype6
  Depends: libgcc-s1
  Depends: libgomp1
  Depends: libheif1
  Depends: libjbig0
  Depends: libjpeg62-turbo
  Depends: liblcms2-2
  Depends: liblqr-1-0
  Depends: libltdl7
  Depends: liblzma5
  Depends: libopenjp2-7
  Depends: libpng16-16
  Depends: libtiff5
  Depends: libwebp6
  Depends: libwebpdemux2
  Depends: libwebpmux3
  Depends: libx11-6
  Depends: libxext6
  Depends: libxml2
  Depends: zlib1g
  Depends: imagemagick-6-common
  Recommends: ghostscript
  Recommends: gsfonts
  Suggests: libmagickcore-6.q16-6-extra
```

```sh
$ docker run --rm debian:bullseye-slim bash -c 'apt-get update && apt-cache depends libmagickwand-6.q16-6'
Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
Get:2 http://deb.debian.org/debian-security bullseye-security InRelease [48.4 kB]
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [44.1 kB]
Get:4 http://deb.debian.org/debian bullseye/main arm64 Packages [8072 kB]
Get:5 http://deb.debian.org/debian-security bullseye-security/main arm64 Packages [232 kB]
Get:6 http://deb.debian.org/debian bullseye-updates/main arm64 Packages [12.0 kB]
Fetched 8524 kB in 2s (3458 kB/s)
Reading package lists...
libmagickwand-6.q16-6
  PreDepends: dpkg
  Depends: libc6
  Depends: libgcc-s1
  Depends: libgomp1
  Depends: libmagickcore-6.q16-6
  Depends: libx11-6
  Depends: imagemagick-6-common
```

```sh
$ docker run --rm debian:bullseye-slim bash -c 'apt-get update && apt-cache depends imagemagick-6-common'
Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
Get:2 http://deb.debian.org/debian-security bullseye-security InRelease [48.4 kB]
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [44.1 kB]
Get:4 http://deb.debian.org/debian bullseye/main arm64 Packages [8072 kB]
Get:5 http://deb.debian.org/debian-security bullseye-security/main arm64 Packages [232 kB]
Get:6 http://deb.debian.org/debian bullseye-updates/main arm64 Packages [12.0 kB]
Fetched 8524 kB in 2s (4610 kB/s)
Reading package lists...
imagemagick-6-common
  Breaks: imagemagick-common
  Breaks: <libmagickcore-6.q16-2>
  Breaks: <libmagickcore-6.q16-3>
  Breaks: <libmagickcore-6.q16-4>
  Breaks: <libmagickcore-6.q16hdri-4>
  Replaces: imagemagick-common
  Replaces: <libmagickcore-6.q16>
```

```sh
$ docker run --rm debian:bullseye-slim bash -c 'apt-get update && apt-cache depends libmagickcore-6.q16-6-extra'
Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
Get:2 http://deb.debian.org/debian-security bullseye-security InRelease [48.4 kB]
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [44.1 kB]
Get:4 http://deb.debian.org/debian bullseye/main arm64 Packages [8072 kB]
Get:5 http://deb.debian.org/debian-security bullseye-security/main arm64 Packages [232 kB]
Get:6 http://deb.debian.org/debian bullseye-updates/main arm64 Packages [12.0 kB]
Fetched 8524 kB in 3s (3252 kB/s)
Reading package lists...
libmagickcore-6.q16-6-extra
  Depends: libc6
  Depends: libcairo2
  Depends: libdjvulibre21
  Depends: libglib2.0-0
  Depends: libmagickcore-6.q16-6
  Depends: libmagickwand-6.q16-6
  Depends: libopenexr25
  Depends: libpango-1.0-0
  Depends: libpangocairo-1.0-0
  Depends: libwmf0.2-7
  Depends: libxml2
  Recommends: libjxr-tools
  Suggests: inkscape
  Enhances: libmagickcore-6.q16-6
```
