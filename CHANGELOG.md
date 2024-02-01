## 1.2.4
  * dart version constraint to >=3.0.0 <4.0.0

## [1.2.3](https://github.com/folksable/blurhash_ffi/tree/3fafbaaca9898db37d25d4cb8f5b613f7716c2e8)
  * Fix changelog order

## [1.2.2](https://github.com/folksable/blurhash_ffi/tree/709e0c6ed1f6e9e96000adb2dae643e400fe76d4)
  * Thanks to @wh201906 for the initiative to add support for Windows.
  * Thanks to @iliser for the PR to fix Memory Bugs on the Native Part.
  * fixes [[#13](https://github.com/folksable/blurhash_ffi/issues/13)]
  * Support for Windows

## 1.2.1
  * fixed [#11](https://github.com/folksable/blurhash_ffi/issues/11)
  * format code

## 1.2.0
  * remove depricated code from ImageProvider implementations

## 1.1.3
  * format code

## 1.1.2
  * replace colored container while loading blurhash with `AnimatedContainer`
  * format code


## 1.1.1
  * modify readme.md to explain how to use `BlurhashTheImage` widget

## 1.1.0
  * added a `BlurhashTheImage` widget which takes an `ImageProvider` and gives out `ImageProvider` of the resulting blurry Image in one step.
  * also made it clear that `BlurhashFFI.free()` should be only run when you are sure there are no more blurhashes to be decoded/encoded in your app.

## 1.0.6
  * pubspec.yaml and readme.md changes

## 1.0.5
  * smaller image size for pub.dev

## 1.0.4
  * added a method to free the isolate and it's memory using `BlurhashFFi.free()`.
  * improved readme.md and pubspec.yaml

## 1.0.3
  ### Issues Fixed/Improvements from [flutter_blurhash](https://github.com/fluttercommunity/flutter_blurhash/)
  * [Universal Blurhash support](https://github.com/fluttercommunity/flutter_blurhash/issues/51) (all types of ImageProviders are supported) 
  * added errorBuilder support incase of failure in decoding blurhash [#48](https://github.com/fluttercommunity/flutter_blurhash/issues/48)
  * Decoding happens in a separate isolate to avoid UI jank [#33](https://github.com/fluttercommunity/flutter_blurhash/issues/33)
  * encoding support [#50](https://github.com/fluttercommunity/flutter_blurhash/issues/50)

## 1.0.2
 * short description for pub.dev

## 1.0.0
  ### Breaking Changes & Stable API (v1.0.0)
  * added a uniform API that's similar to both blurhash_dart and flutter_blurhash
  * now all types of `ImageProviders` are supported (which was not the case in 0.0.1)
  * added a `BlurhashFfi` Widget to directly integrate with flutter's widget system which does all the decoding and redering in one go.
  * added a `BlurhashFfiImage` ImageProvider to support your own custom widgets. 
  * added Logging support to help you debug your blurhashes.
  * this package now no longer depends on `image` package or other packages for the core logic, so you have everything in one place.

## 1.0.1
 * making pubspec.yaml and readme.md clear, for better visibility on pub.dev

## 0.0.1
 * a minimum viable alternative to blurhash_dart and flutter_blurhash but faster.
