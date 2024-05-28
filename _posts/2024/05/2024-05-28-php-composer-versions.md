---
layout: post
title:  Composerイメージが使用しているPHPバージョンを調べる
date:   2024/05/28 11:49:04 +0900
tags:   php
---

## Docker HubでComposerイメージが公開されている

Docker Hubで[Composer](https://hub.docker.com/_/composer)の公式イメージが公開されている。

このイメージで使用しているPHPのバージョンはイメージ毎に異なるがどのバージョンが使用されているかはドキュメントに記載されていない。

## PHPのバージョンを調べる

```sh
rm -fr $TMPDIR/tags.txt
next="https://hub.docker.com/v2/repositories/library/composer/tags?page_size=100"
while test "$next" != "null"
do
    echo $next
    curl -fsSL $next > $TMPDIR/response.json
    jq -r ".results.[].name" $TMPDIR/response.json | grep -E "^\d+\.\d+\.\d+$" >> $TMPDIR/tags.txt
    next=$(jq -r ".next" $TMPDIR/response.json)
done
for tag in $(cat $TMPDIR/tags.txt | sort --version-sort --reverse)
do
    echo
    if test "$tag" = "$(echo -e "1.6.5\n$tag" | sort --version-sort | tail -n1)"
    then
        docker run --rm composer:$tag bash -c '
            composer --version && composer diagnose |
            sed -n "/PHP version/,\$p" |
            sed -e "s/OpenSSL version: //" |
            sed -e "s/version: //" |
            grep -v "PHP binary path" ;
        ' 2>/dev/null | grep -v '^Deprecated\|^zip' | tr '\n' '\t'
    elif test "$tag" = "$(echo -e "1.6.0\n$tag" | sort --version-sort | tail -n1)"
    then
        docker run --rm --platform linux/amd64 composer:$tag bash -c '
            composer --version && composer diagnose |
            sed -n "/PHP version/,\$p" |
            sed -e "s/OpenSSL version: //" |
            sed -e "s/version: //" |
            grep -v "PHP binary path" ;
        ' 2>/dev/null | grep -v '^Deprecated\|^zip' | tr '\n' '\t'
    else
        docker run --rm --platform linux/amd64 composer:$tag bash -c '
            composer --version && php --version |
            grep -v "^Copyright" |
            sed -e "s/, Copyright.*//" ;
        ' 2>/dev/null | grep -v '^Deprecated\|^zip' | tr '\n' '\t'
    fi
done | sed -e 's/^\t*//' -e 's/Composer version/Composer/'
```

```txt
https://hub.docker.com/v2/repositories/library/composer/tags?page_size=100
https://hub.docker.com/v2/repositories/library/composer/tags?page=2&page_size=100

Composer 2.7.6 2024-05-04 23:03:15      PHP 8.3.7      OpenSSL 3.3.0 9 Apr 2024       curl 8.7.1 libz 1.3.1 ssl OpenSSL/3.3.0
Composer 2.7.4 2024-04-22 21:17:03      PHP 8.3.6      OpenSSL 3.1.4 24 Oct 2023      cURL 8.5.0 libz 1.3.1 ssl OpenSSL/3.1.4
Composer 2.7.2 2024-03-11 17:12:18      PHP 8.3.6      OpenSSL 3.1.4 24 Oct 2023      cURL 8.5.0 libz 1.3.1 ssl OpenSSL/3.1.4
Composer 2.7.1 2024-02-09 15:26:28      PHP 8.3.3      OpenSSL 3.1.4 24 Oct 2023      cURL 8.5.0 libz 1.3.1 ssl OpenSSL/3.1.4
Composer 2.6.6 2023-12-08 18:32:26      PHP 8.3.7      OpenSSL 3.3.0 9 Apr 2024       cURL 8.7.1 libz 1.3.1 ssl OpenSSL/3.3.0
Composer 2.6.5 2023-10-06 10:11:52      PHP 8.3.0      OpenSSL 3.1.4 24 Oct 2023      cURL 8.4.0 libz 1.2.13 ssl OpenSSL/3.1.4
Composer 2.6.4 2023-09-29 10:54:46      PHP 8.2.11     OpenSSL 3.1.3 19 Sep 2023      cURL 8.3.0 libz 1.2.13 ssl OpenSSL/3.1.3
Composer 2.6.3 2023-09-15 09:38:21      PHP 8.2.10     OpenSSL 3.1.3 19 Sep 2023      cURL 8.3.0 libz 1.2.13 ssl OpenSSL/3.1.3
Composer 2.6.2 2023-09-03 14:09:15      PHP 8.2.10     OpenSSL 3.1.2 1 Aug 2023       cURL 8.2.1 libz 1.2.13 ssl OpenSSL/3.1.2
Composer 2.5.8 2023-06-09 17:13:21      PHP 8.3.7      OpenSSL 3.3.0 9 Apr 2024       cURL 8.7.1 libz 1.3.1 ssl OpenSSL/3.3.0
Composer 2.5.7 2023-05-24 15:00:39      PHP 8.2.7      OpenSSL 3.1.0 14 Mar 2023      cURL 8.1.1 libz 1.2.13 ssl OpenSSL/3.1.0
Composer 2.5.5 2023-03-21 11:50:05      PHP 8.2.6      OpenSSL 3.1.0 14 Mar 2023      cURL 8.0.1 libz 1.2.13 ssl OpenSSL/3.1.0
Composer 2.5.4 2023-02-15 13:10:06      PHP 8.2.3      OpenSSL 3.0.8 7 Feb 2023       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.8
Composer 2.5.3 2023-02-10 13:23:52      PHP 8.2.3      OpenSSL 3.0.8 7 Feb 2023       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.8
Composer 2.5.2 2023-02-04 14:33:22      PHP 8.2.2      OpenSSL 3.0.7 1 Nov 2022       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.7
Composer 2.5.1 2022-12-22 15:33:54      PHP 8.2.2      OpenSSL 3.0.7 1 Nov 2022       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.7
Composer 2.5.0 2022-12-20 10:44:08      PHP 8.2.0      OpenSSL 3.0.7 1 Nov 2022       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.7
Composer 2.4.4 2022-10-27 14:39:29      PHP 8.3.7      OpenSSL 3.3.0 9 Apr 2024       cURL 8.7.1 libz 1.3.1 ssl OpenSSL/3.3.0
Composer 2.4.3 2022-10-14 16:56:41      PHP 8.1.11     OpenSSL 1.1.1q  5 Jul 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.4.2 2022-09-14 16:11:15      PHP 8.1.11     OpenSSL 1.1.1q  5 Jul 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.4.1 2022-08-20 11:44:50      PHP 8.1.10     OpenSSL 1.1.1q  5 Jul 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.4.0 2022-08-16 16:10:48      PHP 8.1.9      OpenSSL 1.1.1q  5 Jul 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.3.10 2022-07-13 15:48:23     PHP 8.3.7      OpenSSL 3.3.0 9 Apr 2024       cURL 8.7.1 libz 1.3.1 ssl OpenSSL/3.3.0
Composer 2.3.9 2022-07-05 16:52:11      PHP 8.1.8      OpenSSL 1.1.1q  5 Jul 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.3.8 2022-07-01 12:10:47      PHP 8.1.7      OpenSSL 1.1.1o  3 May 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.3.7 2022-06-06 16:43:28      PHP 8.1.7      OpenSSL 1.1.1o  3 May 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1o
Composer 2.3.5 2022-04-13 16:43:00      PHP 8.1.6      OpenSSL 1.1.1o  3 May 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1o
Composer 2.3.4 2022-04-07 21:16:35      PHP 8.1.4      OpenSSL 1.1.1n  15 Mar 2022    cURL 7.80.0 libz 1.2.12 ssl OpenSSL/1.1.1n
Composer 2.3.3 2022-04-01 22:15:35      PHP 8.1.4      OpenSSL 1.1.1n  15 Mar 2022    cURL 7.80.0 libz 1.2.12 ssl OpenSSL/1.1.1n
Composer 2.3.2 2022-03-30 20:45:25      PHP 8.1.4      OpenSSL 1.1.1n  15 Mar 2022    cURL 7.80.0 libz 1.2.12 ssl OpenSSL/1.1.1n
Composer 2.2.23 2024-02-08 15:08:53     PHP 8.3.6      OpenSSL 3.1.4 24 Oct 2023      cURL 8.5.0 libz 1.3.1 ssl OpenSSL/3.1.4
Composer 2.2.22 2023-09-29 10:53:45     PHP 8.3.2      OpenSSL 3.1.4 24 Oct 2023      cURL 8.5.0 libz 1.3.1 ssl OpenSSL/3.1.4
Composer 2.2.21 2023-02-15 13:07:40     PHP 8.2.10     OpenSSL 3.1.3 19 Sep 2023      cURL 8.3.0 libz 1.2.13 ssl OpenSSL/3.1.3
Composer 2.2.20 2023-02-10 14:11:10     PHP 8.2.3      OpenSSL 3.0.8 7 Feb 2023       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.8
Composer 2.2.19 2023-02-04 14:54:48     PHP 8.2.2      OpenSSL 3.0.7 1 Nov 2022       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.7
Composer 2.2.18 2022-08-20 11:33:38     PHP 8.2.2      OpenSSL 3.0.7 1 Nov 2022       cURL 7.87.0 libz 1.2.13 ssl OpenSSL/3.0.7
Composer 2.2.17 2022-07-13 15:27:38     PHP 8.1.9      OpenSSL 1.1.1q  5 Jul 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.2.16 2022-07-05 16:50:29     PHP 8.1.8      OpenSSL 1.1.1q  5 Jul 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.2.15 2022-07-01 12:01:26     PHP 8.1.7      OpenSSL 1.1.1o  3 May 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1q
Composer 2.2.14 2022-06-06 16:32:50     PHP 8.1.7      OpenSSL 1.1.1o  3 May 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1o
Composer 2.2.13 2022-05-25 21:37:25     PHP 8.1.6      OpenSSL 1.1.1o  3 May 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1o
Composer 2.2.12 2022-04-13 16:42:25     PHP 8.1.6      OpenSSL 1.1.1o  3 May 2022     cURL 7.83.1 libz 1.2.12 ssl OpenSSL/1.1.1o
Composer 2.2.11 2022-04-01 22:00:52     PHP 8.1.4      OpenSSL 1.1.1n  15 Mar 2022    cURL 7.80.0 libz 1.2.12 ssl OpenSSL/1.1.1n
Composer 2.2.10 2022-03-29 21:55:35     PHP 8.1.4      OpenSSL 1.1.1n  15 Mar 2022    cURL 7.80.0 libz 1.2.12 ssl OpenSSL/1.1.1n
Composer 2.2.9 2022-03-15 22:13:37      PHP 8.1.4      OpenSSL 1.1.1n  15 Mar 2022    cURL 7.80.0 libz 1.2.12 ssl OpenSSL/1.1.1n
Composer 2.2.7 2022-02-25 11:12:27      PHP 8.1.3      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.2.6 2022-02-04 17:00:38      PHP 8.1.3      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.2.5 2022-01-21 17:25:52      PHP 8.1.2      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.2.4 2022-01-08 12:30:42      PHP 8.1.2      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.2.3 2021-12-31 12:18:53      PHP 8.1.1      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.2.2 2021-12-29 14:15:27      PHP 8.1.1      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.2.1 2021-12-22 22:21:31      PHP 8.1.1      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.2.0 2021-12-22 11:03:27      PHP 8.1.1      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.14 2021-11-30 10:51:43     PHP 8.1.1      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.12 2021-11-09 16:02:04     PHP 8.1.0      OpenSSL 1.1.1l  24 Aug 2021    cURL 7.80.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.11 2021-11-02 12:10:25     PHP 8.0.12     OpenSSL 1.1.1l  24 Aug 2021    cURL 7.79.1 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.10 2021-10-29 22:34:57     PHP 8.0.12     OpenSSL 1.1.1l  24 Aug 2021    cURL 7.79.1 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.9 2021-10-05 09:47:38      PHP 8.0.12     OpenSSL 1.1.1l  24 Aug 2021    cURL 7.79.1 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.8 2021-09-15 13:55:14      PHP 8.0.11     OpenSSL 1.1.1l  24 Aug 2021    cURL 7.79.1 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.6 2021-08-19 17:11:08      PHP 8.0.10     OpenSSL 1.1.1l  24 Aug 2021    cURL 7.78.0 libz 1.2.11 ssl OpenSSL/1.1.1l
Composer 2.1.5 2021-07-23 10:35:47      PHP 8.0.9      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.78.0 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.1.4 2021-07-22 13:55:24      PHP 8.0.8      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.77.0 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.1.3 2021-06-09 16:31:20      PHP 8.0.8      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.77.0 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.1.2 2021-06-07 16:03:06      PHP 8.0.7      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.77.0 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.1.1 2021-06-04 08:46:46      PHP 8.0.7      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.77.0 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.1.0 2021-06-03 11:30:09      PHP 8.0.6      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.77.0 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.0.14 2021-05-21 17:03:37     PHP 8.0.6      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.76.1 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.0.13 2021-04-27 13:11:08     PHP 8.0.6      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.76.1 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.0.12 2021-04-01 10:14:59     PHP 8.0.3      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.76.1 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.0.11 2021-02-24 14:57:23     PHP 8.0.3      OpenSSL 1.1.1k  25 Mar 2021    cURL 7.74.0 libz 1.2.11 ssl OpenSSL/1.1.1k
Composer 2.0.10 2021-02-23 16:11:37     PHP 8.0.2      OpenSSL 1.1.1j  16 Feb 2021    cURL 7.74.0 libz 1.2.11 ssl OpenSSL/1.1.1j
Composer 2.0.9 2021-01-27 16:09:27      PHP 8.0.2      OpenSSL 1.1.1j  16 Feb 2021    cURL 7.74.0 libz 1.2.11 ssl OpenSSL/1.1.1j
Composer 2.0.8 2020-12-03 17:20:38      PHP 7.4.14     OpenSSL 1.1.1i  8 Dec 2020     cURL 7.74.0 libz 1.2.11 ssl OpenSSL/1.1.1i
Composer 2.0.7 2020-11-13 17:31:06      PHP 7.4.13     OpenSSL 1.1.1g  21 Apr 2020    cURL 7.69.1 libz 1.2.11 ssl OpenSSL/1.1.1g
Composer 2.0.6 2020-11-07 11:21:17      PHP 7.4.12     OpenSSL 1.1.1g  21 Apr 2020    cURL 7.69.1 libz 1.2.11 ssl OpenSSL/1.1.1g
Composer 2.0.4 2020-10-30 22:39:11      PHP 7.4.12     OpenSSL 1.1.1g  21 Apr 2020    cURL 7.69.1 libz 1.2.11 ssl OpenSSL/1.1.1g
Composer 2.0.3 2020-10-28 15:50:55      PHP 7.4.12     OpenSSL 1.1.1g  21 Apr 2020    cURL 7.69.1 libz 1.2.11 ssl OpenSSL/1.1.1g
Composer 2.0.2 2020-10-25 23:03:59      PHP 7.4.11     OpenSSL 1.1.1g  21 Apr 2020    cURL 7.69.1 libz 1.2.11 ssl OpenSSL/1.1.1g
Composer 1.10.27 2023-09-29 10:50:23    PHP 8.3.7      OpenSSL 3.3.0 9 Apr 2024
Composer 1.10.26 2022-04-13 16:39:56    PHP 8.2.10     OpenSSL 3.1.3 19 Sep 2023
Composer 1.10.25 2022-01-21 10:02:15    PHP 8.1.4      OpenSSL 1.1.1n  15 Mar 2022
Composer 1.10.24 2021-12-09 20:06:33    PHP 8.1.1      OpenSSL 1.1.1l  24 Aug 2021
Composer 1.10.23 2021-10-05 09:44:27    PHP 8.1.0      OpenSSL 1.1.1l  24 Aug 2021
Composer 1.10.22 2021-04-27 13:10:45    PHP 8.0.11     OpenSSL 1.1.1l  24 Aug 2021
Composer 1.10.21 2021-04-01 09:16:34    PHP 8.0.3      OpenSSL 1.1.1k  25 Mar 2021
Composer 1.10.20 2021-01-27 15:41:06    PHP 8.0.3      OpenSSL 1.1.1k  25 Mar 2021
Composer 1.10.19 2020-12-04 09:14:16    PHP 7.4.14     OpenSSL 1.1.1i  8 Dec 2020
Composer 1.10.17 2020-10-30 22:31:58    PHP 7.4.13     OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.16 2020-10-24 09:55:59    PHP 7.4.12     OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.15 2020-10-13 15:59:09    PHP 7.4.11     OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.13 2020-09-09 11:46:34    PHP 7.4.11     OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.12 2020-09-08 22:58:51    PHP 7.4.10     OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.10 2020-08-03 11:35:19    PHP 7.4.10     OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.9 2020-07-16 12:57:00     PHP 7.4.9      OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.8 2020-06-24 21:23:30     PHP 7.4.8      OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.7 2020-06-03 10:03:56     PHP 7.4.7      OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.6 2020-05-06 10:28:10     PHP 7.4.6      OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.5 2020-04-10 11:44:22     PHP 7.4.5      OpenSSL 1.1.1g  21 Apr 2020
Composer 1.10.4 2020-04-09 17:05:50     PHP 7.4.4      OpenSSL 1.1.1d  10 Sep 2019
Composer 1.10.1 2020-03-13 20:34:27     PHP 7.4.4      OpenSSL 1.1.1d  10 Sep 2019
Composer 1.10.0 2020-03-10 14:08:05     PHP 7.4.3      OpenSSL 1.1.1d  10 Sep 2019
Composer 1.9.3 2020-02-04 12:58:49      PHP 7.4.11
Composer 1.9.2 2020-01-14 16:30:31      PHP 7.4.2
Composer 1.9.1 2019-11-01 17:20:17      PHP 7.4.2
Composer 1.9.0 2019-08-02 20:55:32      PHP 7.3.11
Composer 1.8.6 2019-06-11 15:03:05      PHP 7.4.3
Composer 1.8.5 2019-04-09 17:46:47      PHP 7.3.5
Composer 1.8.4 2019-02-11 10:52:10      PHP 7.3.4
Composer 1.8.3 2019-01-30 08:31:33      PHP 7.3.2
Composer 1.8.2 2019-01-29 15:00:53      PHP 7.3.1
Composer 1.8.0 2018-12-03 10:31:16      PHP 7.2.12
Composer 1.7.3 2018-11-01 10:05:06      PHP 7.3.8
Composer 1.7.2 2018-08-16 16:57:12      PHP 7.2.11
Composer 1.7.1 2018-08-07 09:39:23      PHP 7.2.8
Composer 1.7.0 2018-08-03 15:39:07      PHP 7.2.8
Composer 1.6.5 2018-05-04 11:44:59      PHP 7.2.12
Composer 1.6.4 2018-04-13 12:04:24      PHP 7.2.5
Composer 1.6.3 2018-01-31 16:28:17      PHP 7.2.4
Composer 1.6.2 2018-01-05 15:28:41      PHP 7.2.1
Composer 1.6.1 2018-01-04 14:45:25      PHP 7.2.1
Composer 1.5.6 2017-12-18 12:09:18      PHP 7.2.11 (cli) (built: Oct 15 2018 19:06:05) ( NTS )  Zend Engine v3.2.0
Composer 1.5.5 2017-12-01 14:42:57      PHP 7.2.0 (cli) (built: Dec  1 2017 18:53:11) ( NTS )   Zend Engine v3.2.0
Composer 1.5.2 2017-09-11 16:59:25      PHP 7.2.0 (cli) (built: Dec  1 2017 01:26:25) ( NTS )   Zend Engine v3.2.0
Composer 1.5.1 2017-08-09 16:07:22      PHP 7.1.9 (cli) (built: Sep  1 2017 20:27:28) ( NTS )   Zend Engine v3.1.0
Composer 1.5.0 2017-08-08 11:08:04      PHP 7.1.8 (cli) (built: Aug  4 2017 18:52:01) ( NTS )   Zend Engine v3.1.0
Composer 1.4.3 2017-08-06 15:00:25      PHP 7.2.8 (cli) (built: Jul 21 2018 08:05:40) ( NTS )   Zend Engine v3.2.0
Composer 1.4.2 2017-05-17 08:17:52      PHP 7.1.8 (cli) (built: Aug  4 2017 18:52:01) ( NTS )   Zend Engine v3.1.0
Composer 1.4.1 2017-03-10 09:29:45      PHP 7.1.5 (cli) (built: May 13 2017 00:09:07) ( NTS )   Zend Engine v3.1.0
Composer 1.3.3 2017-03-08 11:06:43      PHP 7.1.8 (cli) (built: Aug  4 2017 18:52:01) ( NTS )   Zend Engine v3.1.0
Composer 1.3.2 2017-01-27 18:23:41      PHP 7.1.2 (cli) (built: Mar  3 2017 22:52:39) ( NTS )   Zend Engine v3.1.0
Composer 1.3.1 2017-01-07 18:08:51      PHP 7.1.1 (cli) (built: Jan 24 2017 18:30:51) ( NTS )   Zend Engine v3.1.0
Composer 1.3.0 2016-12-24 00:47:03      PHP 7.1.0 (cli) (built: Dec 27 2016 19:29:33) ( NTS )   Zend Engine v3.1.0-dev
Composer 1.2.4 2016-12-06 22:00:51      PHP 7.1.8 (cli) (built: Aug  4 2017 18:52:01) ( NTS )   Zend Engine v3.1.0
Composer 1.2.3 2016-12-01 14:33:53      PHP 7.1.0 (cli) (built: Dec  6 2016 21:26:05) ( NTS )   Zend Engine v3.1.0-dev
Composer 1.2.2 2016-11-03 17:43:15      PHP 7.0.13 (cli) (built: Nov 15 2016 00:01:10) ( NTS )  Zend Engine v3.0.0
Composer 1.1.3 2016-06-26 15:42:08      PHP 7.1.8 (cli) (built: Aug  4 2017 18:52:01) ( NTS )   Zend Engine v3.1.0
```

## PHPのバージョンを表にまとめる

|Composer|PHP   |OpenSSL|cURL  |
|:-------|:-----|:------|:-----|
|2.7.6   |8.3.7 |3.3.0  |8.7.1 |
|2.7.4   |8.3.6 |3.1.4  |8.5.0 |
|2.7.2   |8.3.6 |3.1.4  |8.5.0 |
|2.7.1   |8.3.3 |3.1.4  |8.5.0 |
|2.6.6   |8.3.7 |3.3.0  |8.7.1 |
|2.6.5   |8.3.0 |3.1.4  |8.4.0 |
|2.6.4   |8.2.11|3.1.3  |8.3.0 |
|2.6.3   |8.2.10|3.1.3  |8.3.0 |
|2.6.2   |8.2.10|3.1.2  |8.2.1 |
|2.5.8   |8.3.7 |3.3.0  |8.7.1 |
|2.5.7   |8.2.7 |3.1.0  |8.1.1 |
|2.5.5   |8.2.6 |3.1.0  |8.0.1 |
|2.5.4   |8.2.3 |3.0.8  |7.87.0|
|2.5.3   |8.2.3 |3.0.8  |7.87.0|
|2.5.2   |8.2.2 |3.0.7  |7.87.0|
|2.5.1   |8.2.2 |3.0.7  |7.87.0|
|2.5.0   |8.2.0 |3.0.7  |7.87.0|
|2.4.4   |8.3.7 |3.3.0  |8.7.1 |
|2.4.3   |8.1.11|1.1.1q |7.83.1|
|2.4.2   |8.1.11|1.1.1q |7.83.1|
|2.4.1   |8.1.10|1.1.1q |7.83.1|
|2.4.0   |8.1.9 |1.1.1q |7.83.1|
|2.3.10  |8.3.7 |3.3.0  |8.7.1 |
|2.3.9   |8.1.8 |1.1.1q |7.83.1|
|2.3.8   |8.1.7 |1.1.1o |7.83.1|
|2.3.7   |8.1.7 |1.1.1o |7.83.1|
|2.3.5   |8.1.6 |1.1.1o |7.83.1|
|2.3.4   |8.1.4 |1.1.1n |7.80.0|
|2.3.3   |8.1.4 |1.1.1n |7.80.0|
|2.3.2   |8.1.4 |1.1.1n |7.80.0|
|2.2.23  |8.3.6 |3.1.4  |8.5.0 |
|2.2.22  |8.3.2 |3.1.4  |8.5.0 |
|2.2.21  |8.2.10|3.1.3  |8.3.0 |
|2.2.20  |8.2.3 |3.0.8  |7.87.0|
|2.2.19  |8.2.2 |3.0.7  |7.87.0|
|2.2.18  |8.2.2 |3.0.7  |7.87.0|
|2.2.17  |8.1.9 |1.1.1q |7.83.1|
|2.2.16  |8.1.8 |1.1.1q |7.83.1|
|2.2.15  |8.1.7 |1.1.1o |7.83.1|
|2.2.14  |8.1.7 |1.1.1o |7.83.1|
|2.2.13  |8.1.6 |1.1.1o |7.83.1|
|2.2.12  |8.1.6 |1.1.1o |7.83.1|
|2.2.11  |8.1.4 |1.1.1n |7.80.0|
|2.2.10  |8.1.4 |1.1.1n |7.80.0|
|2.2.9   |8.1.4 |1.1.1n |7.80.0|
|2.2.7   |8.1.3 |1.1.1l |7.80.0|
|2.2.6   |8.1.3 |1.1.1l |7.80.0|
|2.2.5   |8.1.2 |1.1.1l |7.80.0|
|2.2.4   |8.1.2 |1.1.1l |7.80.0|
|2.2.3   |8.1.1 |1.1.1l |7.80.0|
|2.2.2   |8.1.1 |1.1.1l |7.80.0|
|2.2.1   |8.1.1 |1.1.1l |7.80.0|
|2.2.0   |8.1.1 |1.1.1l |7.80.0|
|2.1.14  |8.1.1 |1.1.1l |7.80.0|
|2.1.12  |8.1.0 |1.1.1l |7.80.0|
|2.1.11  |8.0.12|1.1.1l |7.79.1|
|2.1.10  |8.0.12|1.1.1l |7.79.1|
|2.1.9   |8.0.12|1.1.1l |7.79.1|
|2.1.8   |8.0.11|1.1.1l |7.79.1|
|2.1.6   |8.0.10|1.1.1l |7.78.0|
|2.1.5   |8.0.9 |1.1.1k |7.78.0|
|2.1.4   |8.0.8 |1.1.1k |7.77.0|
|2.1.3   |8.0.8 |1.1.1k |7.77.0|
|2.1.2   |8.0.7 |1.1.1k |7.77.0|
|2.1.1   |8.0.7 |1.1.1k |7.77.0|
|2.1.0   |8.0.6 |1.1.1k |7.77.0|
|2.0.14  |8.0.6 |1.1.1k |7.76.1|
|2.0.13  |8.0.6 |1.1.1k |7.76.1|
|2.0.12  |8.0.3 |1.1.1k |7.76.1|
|2.0.11  |8.0.3 |1.1.1k |7.74.0|
|2.0.10  |8.0.2 |1.1.1j |7.74.0|
|2.0.9   |8.0.2 |1.1.1j |7.74.0|
|2.0.8   |7.4.14|1.1.1i |7.74.0|
|2.0.7   |7.4.13|1.1.1g |7.69.1|
|2.0.6   |7.4.12|1.1.1g |7.69.1|
|2.0.4   |7.4.12|1.1.1g |7.69.1|
|2.0.3   |7.4.12|1.1.1g |7.69.1|
|2.0.2   |7.4.11|1.1.1g |7.69.1|
|1.10.27 |8.3.7 |3.3.0  |      |
|1.10.26 |8.2.10|3.1.3  |      |
|1.10.25 |8.1.4 |1.1.1n |      |
|1.10.24 |8.1.1 |1.1.1l |      |
|1.10.23 |8.1.0 |1.1.1l |      |
|1.10.22 |8.0.11|1.1.1l |      |
|1.10.21 |8.0.3 |1.1.1k |      |
|1.10.20 |8.0.3 |1.1.1k |      |
|1.10.19 |7.4.14|1.1.1i |      |
|1.10.17 |7.4.13|1.1.1g |      |
|1.10.16 |7.4.12|1.1.1g |      |
|1.10.15 |7.4.11|1.1.1g |      |
|1.10.13 |7.4.11|1.1.1g |      |
|1.10.12 |7.4.10|1.1.1g |      |
|1.10.10 |7.4.10|1.1.1g |      |
|1.10.9  |7.4.9 |1.1.1g |      |
|1.10.8  |7.4.8 |1.1.1g |      |
|1.10.7  |7.4.7 |1.1.1g |      |
|1.10.6  |7.4.6 |1.1.1g |      |
|1.10.5  |7.4.5 |1.1.1g |      |
|1.10.4  |7.4.4 |1.1.1d |      |
|1.10.1  |7.4.4 |1.1.1d |      |
|1.10.0  |7.4.3 |1.1.1d |      |
|1.9.3   |7.4.11|       |      |
|1.9.2   |7.4.2 |       |      |
|1.9.1   |7.4.2 |       |      |
|1.9.0   |7.3.11|       |      |
|1.8.6   |7.4.3 |       |      |
|1.8.5   |7.3.5 |       |      |
|1.8.4   |7.3.4 |       |      |
|1.8.3   |7.3.2 |       |      |
|1.8.2   |7.3.1 |       |      |
|1.8.0   |7.2.12|       |      |
|1.7.3   |7.3.8 |       |      |
|1.7.2   |7.2.11|       |      |
|1.7.1   |7.2.8 |       |      |
|1.7.0   |7.2.8 |       |      |
|1.6.5   |7.2.12|       |      |
|1.6.4   |7.2.5 |       |      |
|1.6.3   |7.2.4 |       |      |
|1.6.2   |7.2.1 |       |      |
|1.6.1   |7.2.1 |       |      |
|1.5.6   |7.2.11|       |      |
|1.5.5   |7.2.0 |       |      |
|1.5.2   |7.2.0 |       |      |
|1.5.1   |7.1.9 |       |      |
|1.5.0   |7.1.8 |       |      |
|1.4.3   |7.2.8 |       |      |
|1.4.2   |7.1.8 |       |      |
|1.4.1   |7.1.5 |       |      |
|1.3.3   |7.1.8 |       |      |
|1.3.2   |7.1.2 |       |      |
|1.3.1   |7.1.1 |       |      |
|1.3.0   |7.1.0 |       |      |
|1.2.4   |7.1.8 |       |      |
|1.2.3   |7.1.0 |       |      |
|1.2.2   |7.0.13|       |      |
|1.1.3   |7.1.8 |       |      |
