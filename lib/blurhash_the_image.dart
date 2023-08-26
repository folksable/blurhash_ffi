// A single step encoder and decoder widget
// that can take a image and blurhash it and then decode the blurhash
// and display the blurhash image.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'blurhash.dart';

class BlurhashTheImage extends ImageProvider<BlurhashTheImage> {
  const BlurhashTheImage(this.inputImage,
      {this.decodingWidth = 32, this.decodingHeight = 32, this.scale = 1.0});

  final ImageProvider inputImage;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// Decoding definition
  final int decodingWidth;

  /// Decoding definition
  final int decodingHeight;

  @override
  Future<BlurhashTheImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<BlurhashTheImage>(this);

  @override
  ImageStreamCompleter load(BlurhashTheImage key, decode) =>
      OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(BlurhashTheImage key) async {
    assert(key == this);

    final blurhash = await BlurhashFFI.encode(inputImage);
    final image = await BlurhashFFI.decode(blurhash,
        width: decodingWidth, height: decodingHeight);
    return ImageInfo(image: image, scale: key.scale);
  }

  @override
  bool operator ==(Object other) => other.runtimeType != runtimeType
      ? false
      : other is BlurhashTheImage &&
          other.inputImage == inputImage &&
          other.scale == scale;

  @override
  int get hashCode => Object.hash(inputImage.hashCode, scale);

  @override
  String toString() => '$runtimeType($inputImage, scale: $scale)';
}
