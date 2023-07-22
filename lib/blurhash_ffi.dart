import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'blurhash_ffi_bindings_generated.dart';
import 'package:image/image.dart' as imgpkg;

/// A very short-lived native function.
///
/// For very short-lived functions, it is fine to call them on the main isolate.
/// They will block the Dart execution while running the native function, so
/// only do this for native functions which are guaranteed to be short-lived.
bool isValidBlurHash(String blurHash) {
  Pointer<Utf8> bhptr = blurHash.toNativeUtf8();
  bool result = _bindings.isValidBlurhash(bhptr.cast<Char>());
  malloc.free(bhptr);
  return result;
}

/// Encoder A longer lived native function, which occupies the thread calling it.
///
/// Parameters :
///     `info` - The image info
///     `componentX` - The number of components in the X direction. Must be between 1 and 9. 3 to 5 is usually a good range for this.
///     `componentY` - The number of components in the Y direction. Must be between 1 and 9. 3 to 5 is usually a good range for this.
Future<String> encodeBlurHash(BlurHashImageInfo info,[int componentX = 4, int componentY=3]) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextEncodeRequestId++;
  final _EncodeRequest request =
      _EncodeRequest(requestId, info.rgbBytes, info.width, info.height, componentX, componentY, info.rowStride);
  final Completer<String> completer = Completer<String>();
  _encodeRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

Future<Uint8List> decodeBlurHash(
    String blurHash, int width, int height, int punch, int channels) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextDecodeRequestId++;
  final _DecodeRequest request =
      _DecodeRequest(requestId, blurHash, width, height, punch, channels);
  final Completer<Uint8List> completer = Completer<Uint8List>();
  _decodeRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

Future<int> decodeToArray(
  String blurHash,
  int width,
  int height,
  int punch,
  int channels,
  Pointer<Uint8> pixelArray,
) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;

  final int requestId = _nextDecodeToArrayRequestId++;
  final _DecodeToArrayRequest request = _DecodeToArrayRequest(
      requestId, blurHash, width, height, punch, channels, pixelArray);
  final Completer<int> completer = Completer<int>();
  _decodeToArrayRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

class _DecodeToArrayRequest {
  final int id;
  final String blurHash;
  final int width;
  final int height;
  final int punch;
  final int channels;
  final Pointer<Uint8> pixelArray;
  Pointer<Utf8>? _bhptr;

  _DecodeToArrayRequest(this.id, this.blurHash, this.width, this.height,
      this.punch, this.channels, this.pixelArray);

  Pointer<Char> get blurHashPointer {
    if (_bhptr != null) {
      _bhptr = blurHash.toNativeUtf8();
      return _bhptr!.cast<Char>();
    }
    return _bhptr!.cast<Char>();
  }

  void free() {
    if (_bhptr != null) {
      malloc.free(_bhptr!);
      _bhptr = null;
    }
  }
}

class _DecodeRequest {
  final int id;
  final String blurHash;
  final int width;
  final int height;
  final int punch;
  final int channels;
  Pointer<Utf8>? _bhptr;

  _DecodeRequest(this.id, this.blurHash, this.width, this.height, this.punch,
      this.channels);

  Pointer<Char> get blurHashPointer {
    if (_bhptr == null) {
      _bhptr = blurHash.toNativeUtf8();
      return _bhptr!.cast<Char>();
    }
    return _bhptr!.cast<Char>();
  }

  void free() {
    if (_bhptr != null) {
      malloc.free(_bhptr!);
      _bhptr = null;
    }
  }
}

class _EncodeRequest {
  final int id;
  final Uint8List pixels;
  final int width;
  final int height;
  final int componentX;
  final int componentY;
  final int rowStride;
  Pointer<Uint8>? pixelsPtr;

  _EncodeRequest(this.id, this.pixels, this.width, this.height, this.componentX,
      this.componentY, this.rowStride);

  Pointer<Uint8> get pixelsPointer {
    if (pixelsPtr == null) {
      pixelsPtr = calloc.allocate<Uint8>(pixels.lengthInBytes);
      pixelsPtr!.asTypedList(pixels.lengthInBytes).setAll(0, pixels);
    }
    return pixelsPtr!;
  }

  void free() {
    if (pixelsPtr != null) {
      calloc.free(pixelsPtr!);
      pixelsPtr = null;
    }
  }
}

class _EncodeResponse {
  final int id;
  final String result;

  const _EncodeResponse(this.id, this.result);
}

class _DecodeResponse {
  final int id;
  final Uint8List result;

  const _DecodeResponse(this.id, this.result);
}

class _DecodeToArrayResponse {
  final int id;
  final int result;

  const _DecodeToArrayResponse(this.id, this.result);
}

// encode requests
int _nextEncodeRequestId = 0;
final Map<int, Completer<String>> _encodeRequests = <int, Completer<String>>{};

// decode requests
int _nextDecodeRequestId = 0;
final Map<int, Completer<Uint8List>> _decodeRequests =
    <int, Completer<Uint8List>>{};

// decode to array requests
int _nextDecodeToArrayRequestId = 0;
final Map<int, Completer<int>> _decodeToArrayRequests = <int, Completer<int>>{};

const String _libName = 'blurhash_ffi';

/// The dynamic library in which the symbols for [BlurhashFfiBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

void _validateBlurHash(String blurHash) {
  if (!isValidBlurHash(blurHash)) {
    throw ArgumentError.value(
        blurHash, 'blurHash', 'Invalid blur hash $blurHash');
  }
}

Future<ui.Image> blurHashDecodeImage(
    String hash, int width, int height, int punch) async {
  _validateBlurHash(hash);

  final completer = Completer<ui.Image>();
  final pixels = await decodeBlurHash(hash, width, height, punch, 4);
  if (kIsWeb) {
    // https://github.com/flutter/flutter/issues/45190
    completer.complete(_createBmp(pixels, width, height, 4));
  } else {
    ui.decodeImageFromPixels(
        pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
  }

  return completer.future;
}
class BlurHashImageInfo {
  int height;
  int width;
  int rowStride;
  Uint8List rgbBytes;
  BlurHashImageInfo(this.height, this.width, this.rowStride, this.rgbBytes);

  @override
  String toString() {
    return 'ImageInfo{height: $height, width: $width,  channels: $numChannels, rowStride: $rowStride}';
  }

  int get numChannels => rowStride~/width;
}

Future<BlurHashImageInfo> getImageInfoFromImageProvider(ImageProvider imageProvider) async {
    final Completer<BlurHashImageInfo> completer = Completer<BlurHashImageInfo>();
    ImageStream imageStream = imageProvider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;

    listener = ImageStreamListener((image, synchronousCall) async {
      final ByteData? byteData = await image.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('ByteData is null');
      final Uint8List list = byteData.buffer.asUint8List();
      
      imgpkg.Image? img = imgpkg.decodeImage(list);
      if (img == null) throw Exception('Image is null');
      completer.complete(
        BlurHashImageInfo(img.height, img.width, 
        img.numChannels * image.image.width, img.getBytes(order: imgpkg.ChannelOrder.rgba)));
      imageStream.removeListener(listener);
    });
    imageStream.addListener(listener);
    return completer.future;
  }

  Future<BlurHashImageInfo> getBlurHashImageInfoFromAsset(String assetName) async {
    final ByteData byteData = await rootBundle.load(assetName);
    final Uint8List list = byteData.buffer.asUint8List();

    // decode image
    imgpkg.Image? image = imgpkg.decodeImage(list);
    if (image == null) throw Exception('Image is null');
    return BlurHashImageInfo(
      image.height,
      image.width,
      image.width * image.numChannels,
      image.getBytes(order: imgpkg.ChannelOrder.rgba),
    );
  }

  Future<BlurHashImageInfo> getBlurHashInfoFromUiImage(ui.Image image) async {
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if(bytes == null) throw Exception('ByteData is null');
    final Uint8List list = bytes.buffer.asUint8List();
    return BlurHashImageInfo(image.height, image.width, image.width * 4, list);
  }

Future<ui.Image> _createBmp(
    Uint8List pixels, int width, int height, int channels) async {
  int size = (width * height * channels) + 122;
  final bmp = Uint8List(size);
  final ByteData header = bmp.buffer.asByteData();
  header.setUint8(0x0, 0x42);
  header.setUint8(0x1, 0x4d);
  header.setInt32(0x2, size, Endian.little);
  header.setInt32(0xa, 122, Endian.little);
  header.setUint32(0xe, 108, Endian.little);
  header.setUint32(0x12, width, Endian.little);
  header.setUint32(0x16, -height, Endian.little);
  header.setUint16(0x1a, 1, Endian.little);
  header.setUint32(0x1c, 32, Endian.little);
  header.setUint32(0x1e, channels, Endian.little);
  header.setUint32(0x22, width * height * channels, Endian.little);
  header.setUint32(0x36, 0x000000ff, Endian.little);
  header.setUint32(0x3a, 0x0000ff00, Endian.little);
  header.setUint32(0x3e, 0x00ff0000, Endian.little);
  header.setUint32(0x42, 0xff000000, Endian.little);
  bmp.setRange(122, size, pixels);
  final codec = await ui.instantiateImageCodec(bmp);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// The bindings to the native functions in [_dylib].
final BlurhashFfiBindings _bindings = BlurhashFfiBindings(_dylib);

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is _EncodeResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<String> completer = _encodeRequests[data.id]!;
        _encodeRequests.remove(data.id);
        completer.complete(data.result);
        return;
      } else if (data is _DecodeResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<Uint8List> completer = _decodeRequests[data.id]!;
        _decodeRequests.remove(data.id);
        completer.complete(data.result);
        return;
      } else if (data is _DecodeToArrayResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<int> completer = _decodeToArrayRequests[data.id]!;
        _decodeToArrayRequests.remove(data.id);
        completer.complete(data.result);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) async {
    final ReceivePort helperReceivePort = ReceivePort()
      ..listen((dynamic data) {
        // On the helper isolate listen to requests and respond to them.
        if (data is _EncodeRequest) {
          final Pointer<Char> result = _bindings.blurHashForPixels(
            data.componentX,
            data.componentY,
            data.width,
            data.height,
            data.pixelsPointer,
            data.rowStride,
          );
          data.free();
          final String resultString = result.cast<Utf8>().toDartString();
          final _EncodeResponse response =
              _EncodeResponse(data.id, resultString);
          sendPort.send(response);
          return;
        } else if (data is _DecodeRequest) {
          final Pointer<Uint8> result = _bindings.decode(data.blurHashPointer,
              data.width, data.height, data.punch, data.channels);
          data.free();
          final Uint8List resultImage =
              result.asTypedList(data.width * data.height * data.channels);
          _bindings.freePixelArray(result);
          final _DecodeResponse response =
              _DecodeResponse(data.id, resultImage);
          sendPort.send(response);
          return;
        } else if (data is _DecodeToArrayRequest) {
          final int result = _bindings.decodeToArray(
              data.blurHashPointer,
              data.width,
              data.height,
              data.punch,
              data.channels,
              data.pixelArray);
          data.free();
          final _DecodeToArrayResponse response =
              _DecodeToArrayResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort /* from the main thread */);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}();
