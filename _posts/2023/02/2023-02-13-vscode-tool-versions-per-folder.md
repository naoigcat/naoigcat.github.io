---
layout: post
title:  VSCodeで使用するPHP拡張機能を使用する
date:   2023/02/13 12:00:47 +0900
tags:   vscode asdf
---

## 補完機能は標準機能ではなく拡張機能を使用する

VSCodeにはPHPの補完機能が標準でインストールされているが、機能的に優れた拡張[PHP Intelephense](https://marketplace.visualstudio.com/items?itemName=bmewburn.vscode-intelephense-client)があるためそちらを使用する。

```sh
code --install-extension bmewburn.vscode-intelephense-client
```

補完機能が重複するため標準の補完機能を無効化する。

```sh
brew install jq moreutils
(
    cd ~/Library/Application\ Support/Code/User/ &&
    cat settings.json | jq '."php.suggest.basic"|=false | ."php.validate.enable"|=false' | sponge settings.json
)
```

拡張機能で同様の機能を持った[PHP IntelliSense](https://marketplace.visualstudio.com/items?itemName=zobo.php-intellisense)もあるが、更新頻度が低く機能的に劣るため理由がなければPHP Intelephenseを使用する。

## デバッグ機能を有効にする拡張機能を使用する

PHPではXdebugを用いたデバッグを行うことになるため[PHP Debug](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug)を使用する。

```sh
code --install-extension debug.php-debug
```

PHP DebugはPHPの実行ファイルのパスを設定に指定する必要がある。

[asdf](https://asdf-vm.com)を使用している場合は各プロジェクトディレクトリでパスを指定する。

```sh
cd ${PROJECT_DIR}
mkdir -p .vscode
echo '{}' | jq '."php.debug.executablePath"|="'$(asdf where php)'"' > .vscode/settings.json
```
