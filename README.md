# blurhash_ffi

A [Blurhash](https://blurha.sh) compact Image placeholder encoder and decoder FFI implementation for flutter in C, Supports Android, iOS, Linux, macOS and Windows.

Matches the official [Blurhash](https://github.com/woltapp/blurhash) implementation in performance and quality.


![blurhash_ffi](https://firebasestorage.googleapis.com/v0/b/folksable-d4dc8.appspot.com/o/blurhash_ffi.png?alt=media&token=e6c7e81b-1798-403b-b055-68a1f767d21f)


## Usage
To use this plugin, add `blurhash_ffi` as a dependency in your pubspec.yaml file

**One Step (both Encoding & Decoding) Usage**
```dart
import 'package:blurhash_ffi/blurhash_ffi.dart';

/// Encoding and Decoding all in One Step
///
/// `ImageProvider` in    -> Send your Image to be encoded.
/// `ImageProvider` out   -> Get your blurry image version.

class BlurhashMyImage extends StatelessWidget {
  final String imageUrl;
  const BlurhashMyImage({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Image(
      image: BlurhashTheImage(
        NetworkImage(imageUrl),  // you can use any image provider of your choice.
          decodingHeight: 1920, decodingWidth: 1080),
      alignment: Alignment.center,
      fit: BoxFit.cover
    );
  }
}


```

**Encoding**

<?code-excerpt "readme_excerpts.dart (Example)"?>
```dart
import 'package:blurhash_ffi/blurhash_ffi.dart';

/// Encoding a blurhash from an image provider
///
/// You can use any ImageProvider you want, including NetworkImage, FileImage, MemoryImage, AssetImage, etc.
final imageProvider = NetworkImage('https://picsum.photos/512');
final imageProvider2 = AssetImage('assets/image.jpg');

/// Signature
/// static Future<String> encode(
///   ImageProvider imageProvider, {
///   int componentX = 4,
///   int componentY = 3,
/// })
/// may throw `BlurhashFFIException` if encoding fails.
final String blurHash = await BlurhashFFI.encode(imageProvider);

```

**Decoding**
```dart
import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'dart:ui' as ui;
/// You have 3 ways to decode a blurhash 
///
/// 1. Using the `BlurhashFfi` widget
/// 2. Using the `BlurhashFfiImage` ImageProvider
/// 3. Using the `BlurhashFfi.decode` static method

/// 1. Using the `BlurhashFfi` widget (same constructor as flutter_blurhash's Blurhash widget)
class BlurHashApp extends StatelessWidget {
  const BlurHashApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text("BlurHash")),
      body: const SizedBox.expand(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: BlurhashFfi(hash: "L5H2EC=PM+yV0g-mq.wG9c010J}I"),
          ),
        ),
      ),
    ),
  );
}

/// 2. Using the `BlurhashFfiImage` ImageProvider
final imageProvider = BlurhashFfiImage("L5H2EC=PM+yV0g-mq.wG9c010J}I");
class BlurHashApp2 extends StatelessWidget {
  const BlurHashApp2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text("BlurHash")),
      body: const SizedBox.expand(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Image(
              image: imageProvider,
              fit: BoxFit.cover, 
            ),
          ),
        ),
      ),
    ),
  );
}

/// 3. Using the `BlurhashFfi.decode` static method which returns dart:ui.Image
/// Signature 
/// static Future<ui.Image> decode(
///   String blurHash, {
///   int width = 32,
///   int height = 32,
///   int punch = 1,
/// })
/// may throw `BlurhashFFIException` if decoding fails.
final ui.Image image = await BlurhashFFI.decode("L5H2EC=PM+yV0g-mq.wG9c010J}I");
```

**Release Isolate and it's memory**

do this only when you are done with encoding/decoding blurhashes
```dart
import 'package:blurhash_ffi/blurhash_ffi.dart';

BlurhashFFi.free();

```
check the [example](./example/) for more details

**contributions in the form of PR's and Issues are a welcome**
