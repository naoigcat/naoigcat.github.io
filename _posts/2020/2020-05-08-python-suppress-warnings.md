---
layout: post
title:  Tensorflowの警告を抑制する
date:   2020/05/08 12:33:06 +0900
tags:   python tensorflow
---

Tensorflowを使用していると`Warning`や`FutureWarning`の警告メッセージが表示されることがある。

開発中は必要なメッセージだが、最終的な成果物としてJupyter Notebookを作成する際には不要なメッセージなため抑制するコードを実行しておく。

## Warning

```py
import tensorflow as tf
tf.logging.set_verbosity(tf.logging.ERROR)
```

## FutureWarning

```py
import warnings
warnings.simplefilter(action="ignore", category=FutureWarning)
```
