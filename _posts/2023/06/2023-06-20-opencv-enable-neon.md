---
layout: post
title:  OpenCV 3.1.0はiOSの実機向けにビルドできない
date:   2023/06/20 12:07:23 +0900
tags:   opencv ios
---

## 3.1.0からiOSに対応しているが実機ではビルドできない

[OpenCV](https://github.com/opencv/opencv)は[3.1.0](https://github.com/opencv/opencv/releases/tag/3.1.0)からopencv2.frameworkを配布している。

しかし、arm64でNEONが有効化されていないためiOSの実機 (arm64) 向けにビルドすると、下記のエラーでビルドできない。

```stderr
Undefined symbols for architecture arm64:
  "_png_init_filter_functions_neon", referenced from:
      _png_read_filter_row in opencv2(pngrutil.o)
ld: symbol(s) not found for architecture arm64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

## 3.2.0で修正されている

上記エラーは [Enable NEON for the arm64 architecture too](https://github.com/opencv/opencv/pull/5924) で修正されており、3.2.0以降ではiOSの実機 (arm64) 向けにビルドできる。

```diff
-if arch.startswith("armv"):
+if arch.startswith("armv") or arch.startswith("arm64"):
     cmakecmd.append("-DENABLE_NEON=ON")
```
