---
layout: post
title:  Laravelで環境変数を定義せずにライブラリをインストールする
date:   2023/02/01 12:05:54 +0900
tags:   php laravel
---

## 環境変数が定義されていないとエラーになる

```sh
docker run --rm -i -v ${PWD}:/opt -w /opt laravelsail/php74-composer:latest \
bash <<SCRIPT
composer create-project laravel/laravel project 8.5.24 --remove-vcs --prefer-dist
ls -1A project | xargs -n1 -I{} mv project/{} .
rm -fr project
php artisan sail:install --with=mysql,redis
SCRIPT
```

Laravelの新規プロジェクトを作成すると、

-   `composer install`
-   `post-root-package-install` -> `@php -r "copy('.env.example', '.env');"`
-   `post-autoload-dump` -> `@php artisan package:discover --ansi`

という順番で実行される。

この状態で`.env`ファイルを削除して`composer install`を実行すると、`post-root-package-install`が実行されないため、環境変数が定義されていない状態で`@php artisan package:discover --ansi`が実行され、

```log
TypeError

  Argument 1 passed to Pusher\Pusher::__construct() must be of the type string, null given,
  called in vendor/laravel/framework/src/Illuminate/Broadcasting/BroadcastManager.php on line 218
```

というエラーが発生する。

## 設定値が空のためエラーになっている

`@php artisan package:discover --ansi`を実行すると、

1.  `App\Providers\BroadcastServiceProvider::boot()`
1.  `Broadcast::routes()` (`routes/channels.php`が読み込まれる)
1.  `Broadcast::channel()`
1.  `Illuminate\Broadcasting\BroadcastManager::createPusherDriver()`
1.  `Pusher\Pusher::__construct()`

と実行される。

`Illuminate\Broadcasting\BroadcastManager::createPusherDriver()`では

```php
$pusher = new Pusher(
    $config['key'], $config['secret'],
    $config['app_id'], $config['options'] ?? []
);
```

とコンフィグで設定された値をそのまま渡しているが、`Pusher\Pusher::__construct()`は

```php
public function __construct(string $auth_key, string $secret, string $app_id, array $options = [], ClientInterface $client = null)
```

と宣言されており、先頭3つの引数は`null`を受け付けない。

一方、`config/broadcasting.php`では、それぞれの初期値を設定していないため環境変数が定義されていない場合は`null`になる。

```php
return [

    /* ... */

    'connections' => [

        'pusher' => [
            'driver' => 'pusher',
            'key' => env('PUSHER_APP_KEY'),
            'secret' => env('PUSHER_APP_SECRET'),
            'app_id' => env('PUSHER_APP_ID'),
            'options' => [
                'cluster' => env('PUSHER_APP_CLUSTER'),
                'useTLS' => true,
                'host' => env('PUSHER_HOST', 'adjustmentmachine.localhost'),
                'port' => env('PUSHER_PORT', 6001),
                'scheme' => env('PUSHER_SCHEME', 'http'),
            ],
        ],

        /* ... */

    ],

    /* ... */

];
```

結果、`null`を受け付けない引数に`null`を渡しているためエラーになる。

## 初期値を設定しておけばエラーにならない

`env`メソッドに初期値を渡しておけば`null`にはならないためエラーにならない。

```php
'pusher' => [
    'driver' => 'pusher',
    'key' => env('PUSHER_APP_KEY', ''),
    'secret' => env('PUSHER_APP_SECRET', ''),
    'app_id' => env('PUSHER_APP_ID', ''),
    /* ... */
],
```
