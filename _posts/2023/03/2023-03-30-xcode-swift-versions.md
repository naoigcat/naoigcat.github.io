---
layout: post
title:  Xcodeが対応しているSwiftのバージョンを調べる
date:   2023/03/30 12:13:10 +0900
tags:   sh
---

## SwiftのバージョンはXcodeに対応している

SwiftのバージョンはXcodeに対応しているため利用しているXcodeのバージョンで利用可能なSwiftのバージョンが決まる。

さらにXcodeはmacOSのバージョンによって利用可能なバージョンが決まっているためmacOSのバージョンによって利用可能なSwiftのバージョンも決まる。

|Swift|Xcode|Release   |Minimum macOS|
|----:|----:|:--------:|------------:|
|  5.7| 14.0|2022-09-12|         12.5|
|  5.6| 13.3|2022-03-14|         12.0|
|  5.5| 13.0|2021-09-20|         11.3|
|  5.4| 12.5|2021-04-25|         11.0|
|  5.3| 12.0|2020-09-17|      10.15.4|
|  5.2| 11.4|2020-03-24|      10.15.2|
|  5.1| 11.0|2019-09-20|      10.14.4|
|  5.0| 10.2|2019-03-25|      10.14.3|
|  4.2| 10.0|2018-09-17|      10.13.6|
|  4.1|  9.3|2018-03-29|      10.13.2|
|  4.0|  9.0|2017-09-12|      10.12.6|
|  3.1|  8.3|2017-03-27|      10.12.0|
|  3.0|  8.0|2016-09-13|      10.11.5|
|  2.2|  7.3|2016-03-21|      10.11.0|
|  2.1|  7.1|2015-10-21|      10.10.5|
|  2.0|  7.0|2015-09-16|      10.10.3|
|  1.2|  6.3|2015-04-08|      10.10.0|
|  1.1|  6.1|2014-10-20|       10.9.4|
|  1.0|  6.0|2014-09-09|       10.9.4|

## ウェブ上で確認できる

ウェブ上でもまとめているサイトがあるため調べるのは比較的簡単にできる。

-   [公式サイト](https://developer.apple.com/jp/support/xcode/)
-   [非公式サイト](https://xcodereleases.com/?scope=release)