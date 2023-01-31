---
layout: post
title:  既存のLaravelプロジェクトでもキーを生成する
date:   2023/01/31 12:31:39 +0900
tags:   php laravel
---

## 新規プロジェクトの作成時にはキーが生成される

Laravelのプロジェクトを`composer`のコマンドで生成すると、

```sh
composer create-project laravel/laravel example-app
```

下記のような`composer.json`ファイルが作成され、

-   `post-root-package-install`
-   `post-create-project-cmd`
-   `post-autoload-dump`

のスクリプトが実行される。

```json
{
    "name": "laravel/laravel",
    "type": "project",
    "description": "The Laravel Framework.",
    "keywords": ["framework", "laravel"],
    "license": "MIT",
    "require": {
        ...
    },
    "require-dev": {
        ...
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Database\\Factories\\": "database/factories/",
            "Database\\Seeders\\": "database/seeders/",
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    },
    "extra": {
        "laravel": {
            "dont-discover": [
            ]
        }
    },
    "scripts": {
        "post-root-package-install": [
            "@php -r \"file_exists('.env') || copy('.env.example', '.env');\""
        ],
        "post-create-project-cmd": [
            "@php artisan key:generate"
        ],
        "post-autoload-dump": [
            "Illuminate\\Foundation\\ComposerScripts::postAutoloadDump",
            "@php artisan package:discover"
        ]
    },
    "config": {
        "preferred-install": "dist",
        "sort-packages": true,
        "optimize-autoloader": true
    }
}
```

上記の結果、`.env`ファイルが作成されて、`APP_KEY`がセットされる。

## 既存プロジェクトのクローン時は生成されない

上記の`composer.json`を含むプロジェクトをクローンして`composer install`を実行すると、

-   `post-root-package-install`
-   `post-create-project-cmd`

が実行されず、

-   `post-autoload-dump`

のみ実行される。そのため、`.env`ファイルが作成されず、`APP_KEY`の値も生成されない。

プロジェクトを実行するには`APP_KEY`が必要になるため手動で生成する必要がある。

## 既存プロジェクトでも生成させる

既存プロジェクトで`composer install`を実行した場合でも生成されるようにするにはスクリプトを変更すれば良い。

```json
{
    ...
    "scripts": {
        "post-autoload-dump": [
            "Illuminate\\Foundation\\ComposerScripts::postAutoloadDump",
            "php -r \"file_exists('.env') || copy('.env.example', '.env');\"",
            "grep ^APP_KEY=. .env > /dev/null || php artisan key:generate",
            "php artisan package:discover"
        ]
    },
    ...
}
```

`post-autoload-dump`は`composer install`の度に実行されるため`APP_KEY`が生成済みかチェックする必要がある。

`@php`は`php`の実体に書き変わるが、先頭でしか有効でないため全て`php`を直接指定している。
