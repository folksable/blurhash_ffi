## 0.0.1

* a minimum viable alternative to blurhash_dart and flutter_blurhash but faster.

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

## 1.0.2
 * short description for pub.dev

## 1.0.3
  ### Issues Fixed/Improvements from [flutter_blurhash](https://github.com/fluttercommunity/flutter_blurhash/)
  * [Universal Blurhash support](https://github.com/fluttercommunity/flutter_blurhash/issues/51) (all types of ImageProviders are supported) 
  * added errorBuilder support incase of failure in decoding blurhash [#48](https://github.com/fluttercommunity/flutter_blurhash/issues/48)
  * Decoding happens in a separate isolate to avoid UI jank [#33](https://github.com/fluttercommunity/flutter_blurhash/issues/33)
  * encoding support [#50](https://github.com/fluttercommunity/flutter_blurhash/issues/50)

## 1.0.4
  * added a method to free the isolate and it's memory using `BlurhashFFi.free()`.
  * improved readme.md and pubspec.yaml

## 1.0.5
  * smaller image size for pub.dev