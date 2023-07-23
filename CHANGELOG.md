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