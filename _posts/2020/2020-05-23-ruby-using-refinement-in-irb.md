---
layout: post
title:  IRBでRefinementを使用する
date:   2020/05/23 22:10:12 +0900
tags:   ruby
---

IRBを起動し、

```sh
irb
```

Refinementを使用しようとすると、

```rb
module Double
  refine Integer do
    def doubled
      self * 2
    end
  end
end

using Double
```

`RuntimeError (main.using is permitted only at toplevel)`というエラーになる。このエラーはIRBの起動オプションで回避できる。

```sh
irb --context-mode=1
```
