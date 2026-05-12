---
layout:    post
title:     Docker内のClaspにログインする
date:      2023-02-02 13:18:34 +0900
tags:      google gas clasp
---

## 以前のログイン方法を使用できなくなった

Docker内の`clasp`コマンドにログインする場合OAuth認証を利用するがDocker内のブラウザを開くことができないため、

```sh
clasp login --no-localhost
```

コマンドで返されるURIにアクセスして生成されるトークンをコピーペーストで入力することでログインしていた。

この帯域外フローはリモートフィッシングのリスクがあるため[2022年10月03日から非推奨](https://developers.google.com/identity/protocols/oauth2/resources/oob-migration)となった。

現在は上記のコマンドでログインしようとすると下記のエラーになる。

> Access blocked: clasp – The Apps Script CLI’s request is invalid
>
> You can’t sign in because clasp – The Apps Script CLI sent an invalid request.
> You can try again later, or contact the developer about this issue. [Learn more about this error](https://support.google.com/accounts/answer/12379384)
>
> Error 400: invalid_request
>
> The out-of-band (OOB) flow has been blocked in order to keep users secure.
> Follow the Out-of-Band (OOB) flow migration guide linked in the developer docs below to migrate your app to an alternative method.

## リダイレクトURIに直接アクセスする

オプションを付けずにバックグラウンドで`clasp login`を実行し、返されるURIにローカルのブラウザでアクセスしてリダイレクトURIにDocker内で`curl`コマンドでアクセスすることでログインできる。

`curl`コマンドのレスポンスが返ってくるとプロセスが終了してしまうため`wait`コマンドで`バックグラウンドプロセスの終了を待つ必要がある。

```docker
FROM node:18-alpine3.16
RUN apk add curl && \
    npm -v && \
    npm i -g @google/clasp
WORKDIR /app
ENTRYPOINT [ "clasp" ]
```

```yml
services:
  clasp:
    build: .
    volumes:
      - login:/root
      - $PWD:/app
volumes:
  login:
    driver: local
```

```sh
$ docker compose run --rm --entrypoint sh clasp -c $'clasp login & \n read url \n curl $url \n wait'
> Logging in globally…
> 🔑 Authorize clasp by visiting this url:
> https://accounts.google.com/o/oauth2/v2/auth?access_type=offline&scope={SCOPE}&response_type=code&client_id={CLIENT_ID}&redirect_uri=http%3A%2F%2Flocalhost%3A{PORT}
>
< http://localhost:{PORT}/?code={CODE}&scope={SCOPE}&authuser=0&hd={DOMAIN}&prompt=consent
> Logged in! You may close this page. Authorization successful.
>
> Default credentials saved to: /root/.clasprc.json.
```
