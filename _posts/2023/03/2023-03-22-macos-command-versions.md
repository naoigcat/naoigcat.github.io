---
layout: post
title:  macOSに付属するコマンドのバージョンを調べる
date:   2023/03/22 12:13:36 +0900
tags:   macos
---

## macOSに付属するコマンドのバージョンをまとめる

|macOS  |emacs     |vi        |awk       |perl      |
|:------|:---------|:---------|:---------|:---------|
|       |1976-xx-xx|1976-xx-xx|1977-xx-xx|1987-12-18|
|10.7.5 |22.1.1    |7.3       |20070501  |5.12.3    |
|10.8.5 |22.1.1    |7.3       |20070501  |5.12.4    |
|10.10.5|22.1.1    |7.3       |20070501  |5.18.2    |
|10.11.6|22.1.1    |7.3       |20070501  |5.18.2    |
|10.12.6|22.1.1    |7.4       |20070501  |5.18.2    |
|10.13.6|22.1.1    |8.0       |20070501  |5.18.2    |
|10.14.6|22.1.1    |8.0       |20070501  |5.18.4    |
|10.15.7|-         |8.1       |20070501  |5.18.4    |
|11.7.4 |-         |9.0       |20200816  |5.30.2    |
|12.6.3 |-         |9.0       |20200816  |5.30.3    |
|13.2.1 |-         |9.0       |20200816  |5.30.3    |

|macOS  |bash      |zsh       |python    |ruby      |php       |
|:------|:---------|:---------|:---------|:---------|:---------|
|       |1989-06-08|1990-12-15|1991-02-20|1993-02-24|1995-06-08|
|10.7.5 |3.2.48    |4.3.11    |2.7.1     |1.8.7     |5.3.15    |
|10.8.5 |3.2.48    |4.3.11    |2.7.2     |1.8.7     |5.3.26    |
|10.10.5|3.2.57    |5.0.5     |2.7.10    |2.0.0p481 |5.5.27    |
|10.11.6|3.2.57    |5.0.8     |2.7.10    |2.0.0p648 |5.5.36    |
|10.12.6|3.2.57    |5.2       |2.7.10    |2.0.0p648 |5.6.30    |
|10.13.6|3.2.57    |5.3       |2.7.10    |2.3.7p456 |7.1.16    |
|10.14.6|3.2.57    |5.3       |2.7.10    |2.3.7p456 |7.1.23    |
|10.15.7|3.2.57    |5.7.1     |2.7.16    |2.6.3p62  |7.3.11    |
|11.7.4 |3.2.57    |5.8       |2.7.16    |2.6.10p210|-         |
|12.6.3 |3.2.57    |5.8.1     |-         |2.6.10p210|-         |
|13.2.1 |3.2.57    |5.8.1     |-         |2.6.10p210|-         |

|macOS  |curl      |openssl        |iconv     |ssh       |sqlite3   |
|:------|:---------|:--------------|:---------|:---------|:---------|
|       |1996-11-11|1998-12-23     |1999-12-31|2000-03-05|2000-08-17|
|10.7.5 |7.21.4    |OpenSSL 0.9.8r |1.11      |5.6p1     |3.7.7     |
|10.8.5 |7.24.0    |OpenSSL 0.9.8y |1.11      |5.9p1     |3.7.12    |
|10.10.5|7.43.0    |OpenSSL 0.9.8zg|1.11      |6.2p2     |3.8.5     |
|10.11.6|7.43.0    |OpenSSL 0.9.8zh|1.11      |6.9p1     |3.8.10.2  |
|10.12.6|7.54.0    |OpenSSL 0.9.8zh|1.11      |7.4p1     |3.16.0    |
|10.13.6|7.54.0    |LibreSSL 2.2.7 |1.11      |7.6p1     |3.19.3    |
|10.14.6|7.54.0    |LibreSSL 2.6.5 |1.11      |7.9p1     |3.24.0    |
|10.15.7|7.64.1    |LibreSSL 2.8.3 |1.11      |8.1p1     |3.28.0    |
|11.7.4 |7.64.1    |LibreSSL 2.8.3 |1.11      |8.1p1     |3.32.3    |
|12.6.3 |7.79.1    |LibreSSL 2.8.3 |1.11      |8.6p1     |3.37.0    |
|13.2.1 |7.86.0    |LibreSSL 3.3.6 |1.11      |9.0p1     |3.39.5    |

|macOS  |make      |svn       |git       |clang     |swift     |
|:------|:---------|:---------|:---------|:---------|:---------|
|       |1977-xx-xx|2000-10-20|2005-12-21|2007-09-26|2014-06-02|
|10.7.5 |-         |1.6.17    |-         |-         |-         |
|10.8.5 |-         |-         |-         |-         |-         |
|10.10.5|3.81      |1.7.20    |2.5.4     |7.0.2     |2.1.1     |
|10.11.6|3.81      |1.9.4     |2.10.1    |8.0.0     |3.0.2     |
|10.12.6|3.81      |1.9.4     |2.14.3    |9.0.0     |4.0.3     |
|10.13.6|3.81      |1.10.0    |2.17.2    |10.0.0    |4.2.1     |
|10.14.6|3.81      |1.10.3    |2.20.1    |10.0.1    |5.0.1     |
|10.15.7|3.81      |-         |2.24.3    |12.0.0    |5.3.2     |
|11.7.4 |3.81      |-         |2.30.1    |12.0.5    |5.4.2     |
|12.6.3 |3.81      |-         |2.37.1    |14.0.0    |5.7.2     |
|13.2.1 |3.81      |-         |2.37.1    |14.0.0    |5.7.2     |

## macOS毎にバージョンを調べる

### [OS X Lion 10.7](https://updates.cdn-apple.com/2021/macos/041-7683-20210614-E610947E-C7CE-46EB-8860-D26D71F0D3EA/InstallMacOSX.dmg)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.7.5
BuildVersion:   11G63
$ emacs --version | head -n 1
GNU Emacs 22.1.1
$ vi --version | head -n 1
VIM - Vi IMproved 7.3 (2010 Aug 15, compiled Feb 21 2012 18:42:47)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.12.3
$ bash --version | head -n 1
GNU bash, version 3.2.48(1)-release (x86_64-apple-darwin11)
$ zsh --version
zsh 4.3.11 (i386-apple-darwin11.0)
$ python --version
Python 2.7.1
$ ruby --version
ruby 1.8.7 (2012-02-08 patchlevel 358) [universal-darwin11.0]
$ php --version | head -n 1
PHP 5.3.15 with Suhosin-Patch (cli) (built: Jul 31 2012 14:49:18)
$ curl --version | head -n 1
curl 7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5
$ openssl version
OpenSSL 0.9.8r 8 Feb 2011
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_5.6p1, OpenSSL 0.9.8r 8 Feb 2011
$ sqlite3 --version
3.7.7 2011-06-25 16:35:41 8f8b373eed7052e6e93c1805fc1effcf1db09366
$ xcode-select --install
Usage: xcode-select -print-path
   or: xcode-select -switch <xcode_folder_path>
   or: xcode-select -version
Arguments:
   -print-path                     Prints the path of the current Xcode folder
   -switch <xcode_folder_path>     Sets the path for the current Xcode folder
   -version                        Prints xcode-select version information
$ make --version | head -n 1
-bash: make: command not found
$ svn --version | head -n 1
svn, version 1.6.17 (r1128011)
$ git --version
-bash: git: command not found
$ clang --version | head -n 1
-bash: clang: command not found
$ swift --version | head -n 1
-bash: swift: command not found
```

### [OS X Mountain Lion 10.8](https://updates.cdn-apple.com/2021/macos/031-0627-20210614-90D11F33-1A65-42DD-BBEA-E1D9F43A6B3F/InstallMacOSX.dmg)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.8.5
BuildVersion:   12F45
$ emacs --version | head -n 1
GNU Emacs 22.1.1
$ vi --version | head -n 1
VIM - Vi IMproved 7.3 (2010 Aug 15, compiled May 15 2013 15:38:58)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.12.4
$ bash --version | head -n 1
GNU bash, version 3.2.48(1)-release (x86_64-apple-darwin12)
$ zsh --version
zsh 4.3.11 (i386-apple-darwin12.0)
$ python --version
Python 2.7.2
$ ruby --version
ruby 1.8.7 (2012-02-08 patchlevel 358) [universal-darwin12.0]
$ php --version | head -n 1
PHP 5.3.26 (cli) (built: Jul  7 2013 19:05:08) 
$ curl --version | head -n 1
curl 7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8y zlib/1.2.5
$ openssl version
OpenSSL 0.9.8y 5 Feb 2013
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_5.9p1, OpenSSL 0.9.8y 5 Feb 2013
$ sqlite3 --version
3.7.12 2012-04-03 19:43:07 86b8481be7e76cccc92d14ce762d21bfb69504af
$ xcode-select --install
xcode-select: Error: unknown command option '--install'.

xcode-select: Report or change the path to the active
              Xcode installation for this machine.

Usage: xcode-select --print-path
           Prints the path of the active Xcode folder
   or: xcode-select --switch <xcode_path>
           Sets the path for the active Xcode folder
   or: xcode-select --version
           Prints the version of xcode-select

$ make --version | head -n 1
-bash: make: command not found
$ svn --version | head -n 1
-bash: svn: command not found
$ git --version
-bash: git: command not found
$ clang --version | head -n 1
-bash: clang: command not found
$ swift --version | head -n 1
-bash: swift: command not found
```

### [OS X Yosemite 10.10](http://updates-http.cdn-apple.com/2019/cert/061-41343-20191023-02465f92-3ab5-4c92-bfe2-b725447a070d/InstallMacOSX.dmg)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.10.5
BuildVersion:   14F27
$ emacs --version | head -n 1
GNU Emacs 22.1.1
$ vi --version | head -n 1
VIM - Vi IMproved 7.3 (2010 Aug 15, compiled Jul  9 2015 23:58:42)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.18.2
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin14)
$ zsh --version
zsh 5.0.5 (x86_64-apple-darwin14.0)
$ python --version
Python 2.7.10
$ ruby --version
ruby 2.0.0p481 (2014-05-08 revision 45883) [universal.x86_64-darwin14]
$ php --version | head -n 1
PHP 5.5.27 (cli) (built: Jul 23 2015 00:21:59)
$ curl --version | head -n 1
curl 7.43.0 (x86_64-apple-darwin14.0) libcurl/7.43.0 SecureTransport zlib/1.2.5
$ openssl version
OpenSSL 0.9.8zg 14 July 2015
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_6.2p2, OSSLShim 0.9.8r 8 Dec 2011
$ sqlite3 --version
3.8.5 2014-08-15 22:37:57 c8ade949d4a2eb3bba4702a4a0e17b405e9b6ace
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
svn, version 1.7.20 (r1667490)
$ git --version
git version 2.5.4 (Apple Git-61)
$ clang --version | head -n 1
Apple LLVM version 7.0.2 (clang-700.1.81)
$ swift --version | head -n 1
Apple Swift version 2.1.1 (swiftlang-700.1.101.15 clang-700.1.81)
```

### [OS X El Capitan 10.11](http://updates-http.cdn-apple.com/2019/cert/061-41424-20191024-218af9ec-cf50-4516-9011-228c78eda3d2/InstallMacOSX.dmg)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.11.6
BuildVersion:   15G31
$ emacs --version | head -n 1
GNU Emacs 22.1.1
$ vi --version | head -n 1
VIM - Vi IMproved 7.3 (2010 Aug 15, compiled Jun 14 2016 16:06:49)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.18.2
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin15)
$ zsh --version
zsh 5.0.8 (x86_64-apple-darwin15.0)
$ python --version
Python 2.7.10
$ ruby --version
ruby 2.0.0p648 (2015-12-16 revision 53162) [universal.x86_64-darwin15]
$ php --version | head -n 1
PHP 5.5.36 (cli) (built: May 29 2016 01:07:06)
$ curl --version | head -n 1
curl 7.43.0 (x86_64-apple-darwin15.0) libcurl/7.43.0 SecureTransport zlib/1.2.5
$ openssl version
OpenSSL 0.9.8zh 14 Jan 2016
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_6.9p1, LibreSSL 2.1.8
$ sqlite3 --version
3.8.10.2 2015-05-20 18:17:19 2ef4f3a5b1d1d0c4338f8243d40a2452cc1f7fe4
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
svn, version 1.9.4 (r1740329)
$ git --version
git version 2.10.1 (Apple Git-78)
$ clang --version | head -n 1
Apple LLVM version 8.0.0 (clang-800.0.42.1)
$ swift --version | head -n 1
Apple Swift version 3.0.2 (swiftlang-800.0.63 clang-800.0.42.1)
```

### [macOS Sierra 10.12](http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.12.6
BuildVersion:   16G29
$ emacs --version | head -n 1
GNU Emacs 22.1.1
$ vi --version | head -n 1
VIM - Vi IMproved 7.4 (2013 Aug 10, compiled Apr  4 2017 18:14:54)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.18.2
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16)
$ zsh --version
zsh 5.2 (x86_64-apple-darwin16.0)
$ python --version
Python 2.7.10
$ ruby --version
ruby 2.0.0p648 (2015-12-16 revision 53162) [universal.x86_64-darwin16]
$ php --version | head -n 1
PHP 5.6.30 (cli) (built: Feb  7 2017 16:18:37)
$ curl --version | head -n 1
curl 7.54.0 (x86_64-apple-darwin16.0) libcurl/7.54.0 SecureTransport zlib/1.2.8
$ openssl version
OpenSSL 0.9.8zh 14 Jan 2016
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_7.4p1, LibreSSL 2.5.0
$ sqlite3 --version
3.16.0 2016-11-04 19:09:39 0e5ffd9123d6d2d2b8f3701e8a73cc98a3a7ff5f
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
svn, version 1.9.4 (r1740329)
$ git --version
git version 2.14.3 (Apple Git-98)
$ clang --version | head -n 1
Apple LLVM version 9.0.0 (clang-900.0.39.2)
$ swift --version | head -n 1
Apple Swift version 4.0.3 (swiftlang-900.0.74.1 clang-900.0.39.2)
```

### [macOS High Sierra 10.13](macappstores://apps.apple.com/jp/app/macos-high-sierra/id1246284741)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.13.6
BuildVersion:   17G66
$ emacs --version | head -n 1
GNU Emacs 22.1.1
$ vi --version | head -n 1
VIM - Vi IMproved 8.0 (2016 Sep 12, compiled Nov 29 2017 18:37:46)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.18.2
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin17)
$ zsh --version
zsh 5.3 (x86_64-apple-darwin18.0)
$ python --version
Python 2.7.10
$ ruby --version
ruby 2.3.7p456 (2018-03-28 revision 63024) [universal.x86_64-darwin17]
$ php --version | head -n 1
PHP 7.1.16 (cli) (built: Mar 31 2018 02:59:59) ( NTS )
$ curl --version | head -n 1
curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
$ openssl version
LibreSSL 2.2.7
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_7.6p1, LibreSSL 2.6.2
$ sqlite3 --version
3.19.3 2017-06-27 16:48:08 2b0954060fe10d6de6d479287dd88890f1bef6cc1beca11bc6cdb79f72e2377b
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
svn, version 1.10.0 (r1827917)
$ git --version
git version 2.17.2 (Apple Git-113)
$ clang --version | head -n 1
Apple LLVM version 10.0.0 (clang-1000.10.44.4)
$ swift --version | head -n 1
Apple Swift version 4.2.1 (swiftlang-1000.0.42 clang-1000.10.45.1)
```

### [macOS Mojave 10.14](macappstores://apps.apple.com/jp/app/macos-mojave/id1398502828)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.14.6
BuildVersion:   18G103
$ emacs --version | head -n 1
GNU Emacs 22.1.1
$ vi --version | head -n 1
VIM - Vi IMproved 8.0 (2016 Sep 12, compiled Jun 19 2019 19:08:44)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.18.4
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin18)
$ zsh --version
zsh 5.3 (x86_64-apple-darwin18.0)
$ python --version
Python 2.7.10
$ ruby --version
ruby 2.3.7p456 (2018-03-28 revision 63024) [universal.x86_64-darwin18]
$ php --version | head -n 1
PHP 7.1.23 (cli) (built: Feb 22 2019 22:19:32) ( NTS )
$ curl --version | head -n 1
curl 7.54.0 (x86_64-apple-darwin18.0) libcurl/7.54.0 LibreSSL/2.6.5 zlib/1.2.11 nghttp2/1.24.1
$ openssl version
LibreSSL 2.6.5
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_7.9p1, LibreSSL 2.7.3
$ sqlite3 --version
3.24.0 2018-06-04 14:10:15 95fbac39baaab1c3a84fdfc82ccb7f42398b2e92f18a2a57bce1d4a713cbaapl
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
svn, version 1.10.3 (r1842928)
$ git --version
git version 2.20.1 (Apple Git-117)
$ clang --version | head -n 1
Apple LLVM version 10.0.1 (clang-1001.0.46.4)
$ swift --version | head -n 1
Apple Swift version 5.0.1 (swiftlang-1001.0.82.4 clang-1001.0.46.5)
```

### [macOS Catalina 10.15](macappstores://apps.apple.com/jp/app/macos-catalina/id1466841314)

```sh
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.15.7
BuildVersion:   19H15
$ emacs --version | head -n 1
zsh: command not found: emacs
$ vi --version | head -n 1
VIM - Vi IMproved 8.1 (2018 May 18, compiled Jun  5 2020 21:30:37)
$ awk --version
awk version 20070501
$ perl -e 'print $^V."\n"'
v5.18.4
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin19)
$ zsh --version
zsh 5.7.1 (x86_64-apple-darwin19.0)
$ python --version
Python 2.7.16
$ ruby --version
ruby 2.6.3p62 (2019-04-16 revision 67580) [universal.x86_64-darwin19]
$ php --version | head -n 1
PHP 7.3.11 (cli) (built: Jun  5 2020 23:50:40) ( NTS )
$ curl --version | head -n 1
curl 7.64.1 (x86_64-apple-darwin19.0) libcurl/7.64.1 (SecureTransport) LibreSSL/2.8.3 zlib/1.2.11 nghttp2/1.39.2
$ openssl version
LibreSSL 2.8.3
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_8.1p1, LibreSSL 2.7.3
$ sqlite3 --version
3.28.0 2019-04-15 14:49:49 378230ae7f4b721c8b8d83c8ceb891449685cd23b1702a57841f1be40b5daapl
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
svn: error: The subversion command line tools are no longer provided by Xcode.
$ git --version
git version 2.24.3 (Apple Git-128)
$ clang --version | head -n 1
Apple clang version 12.0.0 (clang-1200.0.32.29)
$ swift --version | head -n 1
Apple Swift version 5.3.2 (swiftlang-1200.0.45 clang-1200.0.32.28)
```

### [macOS Big Sur 11](macappstores://apps.apple.com/jp/app/macos-big-sur/id1526878132)

```sh
$ sw_vers
ProductName:    macOS
ProductVersion: 11.7.4
BuildVersion:   20G1120
$ emacs --version | head -n 1
zsh: command not found: emacs
$ vi --version | head -n 1
VIM - Vi IMproved 9.0 (2022 Jun 28, compiled Dec 19 2022 00:34:58)
$ awk --version
awk version 20200816
$ perl -e 'print $^V."\n"'
v5.30.2
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin20)
$ zsh --version
zsh 5.8 (x86_64-apple-darwin20.0)
$ python --version
Python 2.7.16
$ ruby --version
ruby 2.6.10p210 (2022-04-12 revision 67958) [universal.x86_64-darwin20]
$ php --version | head -n 4
WARNING: PHP is not recommended
PHP is included in macOS for compatibility with legacy software.
Future versions of macOS will not include PHP.
PHP 7.3.29-to-be-removed-in-future-macOS (cli) (built: Aug 29 2022 08:54:14) ( NTS )
$ curl --version | head -n 1
curl 7.64.1 (x86_64-apple-darwin20.0) libcurl/7.64.1 (SecureTransport) LibreSSL/2.8.3 zlib/1.2.11 nghttp2/1.41.0
$ openssl version
LibreSSL 2.8.3
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_8.1p1, LibreSSL 2.7.3
$ sqlite3 --version
3.32.3 2020-06-18 14:16:19 02c344aceaea0d177dd42e62c8541e3cab4a26c757ba33b3a31a43ccc7d4aapl
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
zsh: command not found: svn
$ git --version
git version 2.30.1 (Apple Git-130)
$ clang --version | head -n 1
Apple clang version 12.0.5 (clang-1205.0.22.11)
$ swift --version | head -n 1
Apple Swift version 5.4.2 (swiftlang-1205.0.28.2 clang-1205.0.19.57)
```

### [macOS Monterey 12](macappstores://apps.apple.com/jp/app/macos-monterey/id1576738294)

```sh
$ sw_vers
ProductName:    macOS
ProductVersion: 12.6.3
BuildVersion:   21G419
$ emacs --version | head -n 1
zsh: command not found: emacs
$ vi --version | head -n 1
VIM - Vi IMproved 9.0 (2022 Jun 28, compiled Dec 12 2022 20:02:12)
$ awk --version
awk version 20200816
$ perl -e 'print $^V."\n"'
v5.30.3
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin21)
$ zsh --version
zsh 5.8.1 (x86_64-apple-darwin21.0)
$ python --version
zsh: command not found: python
$ ruby --version
ruby 2.6.10p210 (2022-04-12 revision 67958) [universal.x86_64-darwin21]
$ php --version | head -n 1
zsh: command not found: php
$ curl --version | head -n 1
curl 7.79.1 (x86_64-apple-darwin21.0) libcurl/7.79.1 (SecureTransport) LibreSSL/3.3.6 zlib/1.2.11 nghttp2/1.45.1
$ openssl version
LibreSSL 2.8.3
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_8.6p1, LibreSSL 3.3.6
$ sqlite3 --version
3.37.0 2021-12-09 01:34:53 9ff244ce0739f8ee52a3e9671adb4ee54c83c640b02e3f9d185fd2f9a179aapl
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
zsh: command not found: svn
$ git --version
git version 2.37.1 (Apple Git-137.1)
$ clang --version | head -n 1
Apple clang version 14.0.0 (clang-1400.0.29.202)
$ swift --version | head -n 1
Apple Swift version 5.7.2 (swiftlang-5.7.2.135.5 clang-1400.0.29.51)
```

### [macOS Ventura 13](macappstores://apps.apple.com/jp/app/macos-ventura/id1638787999)

```sh
$ sw_vers
ProductName:            macOS
ProductVersion:         13.2.1
BuildVersion:           22D68
$ emacs --version | head -n 1
zsh: command not found: emacs
$ vi --version | head -n 1
VIM - Vi IMproved 9.0 (2022 Jun 28, compiled Dec 16 2022 23:29:16)
$ awk --version
awk version 20200816
$ perl -e 'print $^V."\n"'
v5.30.3
$ bash --version | head -n 1
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin22)
$ zsh --version
zsh 5.8.1 (x86_64-apple-darwin22.0)
$ python --version
zsh: command not found: python
$ ruby --version
ruby 2.6.10p210 (2022-04-12 revision 67958) [universal.arm64e-darwin22]
$ php --version | head -n 1
zsh: command not found: php
$ curl --version | head -n 1
curl 7.86.0 (x86_64-apple-darwin22.0) libcurl/7.86.0 (SecureTransport) LibreSSL/3.3.6 zlib/1.2.11 nghttp2/1.47.0
$ openssl version
LibreSSL 3.3.6
$ iconv --version | head -n 1
iconv (GNU libiconv 1.11)
$ ssh -V
OpenSSH_9.0p1, LibreSSL 3.3.6
$ sqlite3 --version
3.39.5 2022-10-14 20:58:05 554764a6e721fab307c63a4f98cd958c8428a5d9d8edfde951858d6fd02daapl
$ make --version | head -n 1
GNU Make 3.81
$ svn --version | head -n 1
zsh: command not found: svn
$ git --version
git version 2.37.1 (Apple Git-137.1)
$ clang --version | head -n 1
Apple clang version 14.0.0 (clang-1400.0.29.202)
$ swift --version | head -n 1
swift-driver version: 1.62.15 Apple Swift version 5.7.2 (swiftlang-5.7.2.135.5 clang-1400.0.29.51)
```
