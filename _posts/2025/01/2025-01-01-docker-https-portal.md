---
layout: post
title:  DockerコンテナでHTTPSでのローカル開発に対応する
date:   2025/01/01 18:31:01 +0900
tags:   docker
---

## DockerコンテナでHTTPS対応する

ローカル開発時コンテナを一つ追加するだけでHTTPSに対応できる。

```sh
grep naoigcat\.github\.test /etc/hosts || echo '127.0.0.1       naoigcat.github.test' | sudo tee -a /etc/hosts
cat <<YAML > compose.yaml
services:
  https-portal:
    image: steveltn/https-portal:1
    ports:
      - "80:80"
      - "443:443"
    environment:
      DOMAINS: "naoigcat.github.test -> http://web:80"
      STAGE: "local"
    restart: always
    networks:
      - app-network

  web:
    image: nginx:latest
    volumes:
      - ./_site:/usr/share/nginx/html
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
YAML
docker compose up
```

SSL証明書はLet's Encryptから自動的に取得・更新されていて、詳細な説明は[GitHubリポジトリ](https://github.com/SteveLTN/https-portal)にある。
