---
layout: post
title:  PhpStorm+DockerでXDebugを使用する
date:   2020/10/17 05:30:30 +0900
tags:   php phpstorm docker
---

## XDebugをDockerコンテナにインストールする

DockerfileにXDebugをインストールするコマンドを追加する。

```dockerfile
# xdebug
RUN pecl install xdebug && \
    docker-php-ext-enable xdebug
```

## php.iniにXDebug用の設定を追加する

Dockerコンテナにコピーするphp.iniにXDebug用の設定を追加する。

```php.ini
[xdebug]
xdebug.idekey = www-data
xdebug.max_nesting_level = 512
xdebug.remote_enable = On
xdebug.remote_autostart = On
xdebug.remote_host = host.docker.internal
xdebug.remote_port = 9000
```

## Dockerコンテナを起動する

```sh
docker-compose up -d
```

## PhpStormの設定を変更する

1.  PhpStorm > Preferences...から設定画面を開く。
2.  Languages & Frameworks > PHP > Debug > Pre-configuration > 3. Enable listening for PHP Debug ConnectionsのStar Listeningを押下する。
3.  Languages & Frameworks > PHP > Serversからサーバーを追加する。
    1.  Nameは任意の値を入力する。
    2.  Hostに`localhost`、Portに`8000`を入力し、Debuggerに`Xdebug`を選択する。
    3.  Use path mappingsにチェックを入れる。
    4.  Docker上にマウントされるディレクトリのAbsolute path on the serverにマウント先のパスを入力する。
4.  設定画面を閉じ、ツールバーのEdit Configurations...を押下する。
5.  PHP Remote Debugの設定を追加する。
6.  Configuration > Filter debug connection by IDE keyにチェックを入れる。
7.  Serverに上記で設定したサーバーを選択する。
8.  IDE Key (session id)に`www-data`を入力する。

## デバッグ実行する

Configurationsから上記で設定したものを選択し、Run > Debugを実行する。
