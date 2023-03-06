---
layout: post
title:  Dockerコンテナの終了までの猶予期間を設定する
date:   2023/03/01 19:18:01 +0900
tags:   docker
---

## 終了コマンドでシグナルが送られる

Dockerコンテナに対して`docker stop`コマンドを実行するとデフォルトでは`SIGTERM`が送られた後10秒後に`SIGKILL`が送られる。

シグナルを受け取ったタイミングでログを残すNode.jsスクリプトを作成し、

```js
$ <<SCRIPT > main.js
'use strict';
var http = require('http');
var server = http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(80, '0.0.0.0');
console.log('server started');
console.time('server received \`SIGTERM\`');
process.on('SIGTERM', function () {
  console.timeEnd('server received \`SIGTERM\`');
});
SCRIPT
```

Dockerコンテナのエントリポイントで実行して2秒後に`docker stop`コマンドを送ることで確認できる。

```sh
$ <<DOCKERFILE > Dockerfile
FROM node
COPY ./main.js ./main.js
ENTRYPOINT ["node", "main"]
DOCKERFILE
$ docker build -t image .
$ { sleep 2 ; docker stop app > /dev/null } & disown ; TIMEFMT="server stopped by \`SIGKILL\`: %E" ; time docker run --rm --name app image
server started
server received `SIGTERM`: 1.809s
server stopped by `SIGKILL`: 12.23s
```

## 送信されるシグナルは変更できる

`docker stop`で送信されるシグナルは`docker run`のオプション`--stop-signal`もしくは`docker-compose.yml`の`stop_signal`で変更できる。

```sh
$ { sleep 2 ; docker stop app > /dev/null } & disown ; TIMEFMT="server stopped by \`SIGKILL\`: %E" ; time docker run --rm --name app --stop-signal 2 image
server started
server stopped by `SIGKILL`: 12.24s
```

## 強制終了までの猶予期間も変更できる

`docker stop`でシグナルが送信された後、`SIGKILL`が送信されるまでの猶予期間も`docker stop`のオプション`--time`もしくは`docker-compose.yml`の`stop_grace_period`で変更できる。

```sh
$ { sleep 2 ; docker stop -t 2 app > /dev/null } & disown ; TIMEFMT="server stopped by \`SIGKILL\`: %E" ; time docker run --rm --name app image
server started
server received `SIGTERM`: 1.694s
server stopped by `SIGKILL`: 4.22s
```
