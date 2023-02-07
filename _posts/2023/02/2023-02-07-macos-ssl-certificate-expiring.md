---
layout: post
title:  macOSで期限切れのSSL証明書を更新する
date:   2023/02/07 12:35:19 +0900
tags:   macos ssl
---

## 古いmacOSではSSL通信がエラーになる

古い端末でHTTPSなどのSSL通信を行うと`certificate has expired`というエラーになる。

```sh
$ curl https://example.com
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.haxx.se/docs/sslcerts.html

curl performs SSL certificate verification by default, using a "bundle"
 of Certificate Authority (CA) public keys (CA certs). If the default
 bundle file isn't adequate, you can specify an alternate file
 using the --cacert option.
If this HTTPS server uses a certificate signed by a CA represented in
 the bundle, the certificate verification probably failed due to a
 problem with the certificate (it might be expired, or the name might
 not match the domain name in the URL).
If you'd like to turn off curl's verification of the certificate, use
 the -k (or --insecure) option.
HTTPS-proxy has similar options --proxy-cacert and --proxy-insecure.
```

macOSのOpenSSLは/etc/ssl/cert.pemを使用して認証しており、この証明書ファイルの期限が切れていると上記のエラーになる。

## 新しい証明書をダウンロードする

Mozillaから抽出した証明書が [CA certificates extracted from Mozilla](https://curl.se/docs/caextract.html) にアップロードされているためダウンロードして置き換えることでエラーが発生なくなる。

```sh
cd ~/Downloads
open -a Safari https://curl.se/ca/cacert.pem && sleep 3
open -a Safari https://curl.se/ca/cacert.pem.sha256 && sleep 3
osascript -e "tell application \"Safari\" to close current tab of front window"
if shasum -c cacert.pem.sha256
then
    sudo cp /etc/ssl/cert.pem{,.$(date +%Y%m%d%H%M%S)}
    sudo mv cacert.pem /etc/ssl/cert.pem
fi
```
