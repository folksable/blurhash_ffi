import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class BlurhashFfiImage extends ImageProvider<BlurhashFfiImage> {
  /// Creates an object that decodes a [blurHash] as an image.
  ///
  /// The arguments must not be null.
  const BlurhashFfiImage(this.blurHash,
      {this.decodingWidth = 32,
      this.decodingHeight = 32,
      this.scale = 1.0});

  /// The bytes to decode into an image.
  final String blurHash;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// Decoding definition
  final int decodingWidth;

  /// Decoding definition
  final int decodingHeight;

  @override
  Future<BlurhashFfiImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<BlurhashFfiImage>(this);

  @override
  ImageStreamCompleter load(BlurhashFfiImage key, decode) =>
      OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(BlurhashFfiImage key) async {
    assert(key == this);

    final image = await BlurhashFFI.decode(blurHash, width: decodingWidth, height: decodingHeight);
    return ImageInfo(image: image, scale: key.scale);
  }

  @override
  bool operator ==(Object other) => other.runtimeType != runtimeType
      ? false
      : other is BlurhashFfiImage &&
          other.blurHash == blurHash &&
          other.scale == scale;

  @override
  int get hashCode => Object.hash(blurHash.hashCode, scale);

  @override
  String toString() => '$runtimeType($blurHash, scale: $scale)';
}
