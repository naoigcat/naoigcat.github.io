---
layout: post
title:  iOSで画像の色を動的に変える
date:   2023/01/16 13:29:48 +0900
tags:   ios
---

## 画像のレンダリングモードを変更する

`UIImageView`や`UIButton`に画像を設定すると画像データに設定された色が使用される。

レンダリングモードを`.alwaysTemplate`にするとコードで描画されるようになる。

```swift
let imageView = UIImageView(image: UIImage(named: "image")?.withRenderingMode(.alwaysTemplate))
imageView.tintColor = .blue
```

## UIKitのドキュメントを確認する

`UIImage.RenderingMode`のドキュメントを確認するとデフォルトでは

-   `UINavigationBar`
-   `UITabBar`
-   `UIToolbar`
-   `UISegmentedControl`

に設定した画像はUIコンポーネントの前景色が使用され、これら以外の

-   `UIImageView`
-   `UIButton`

などでは画像に設定された色が使用される。

この挙動を`alwaysOriginal`や`alwaysTemplate`を使用することで変更することができる。

```swift
/*
 * Images are created with UIImageRenderingModeAutomatic by default.
 * An image with this mode is interpreted as a template image or an original image based on the context in which it is rendered.
 * For example, navigation bars, tab bars, toolbars, and segmented controls automatically treat their foreground images as templates,
 * while image views and web views treat their images as originals.
 * You can use UIImageRenderingModeAlwaysTemplate to force your image to always be rendered as a template
 * or UIImageRenderingModeAlwaysOriginal to force your image to always be rendered as an original.
 */
@available(iOS 7.0, *)
public enum RenderingMode : Int, @unchecked Sendable {
    case automatic = 0 // Use the default rendering mode for the context where the image is used
    case alwaysOriginal = 1 // Always draw the original image, without treating it as a template
    case alwaysTemplate = 2 // Always draw the image as a template image, ignoring its color information
}
```
