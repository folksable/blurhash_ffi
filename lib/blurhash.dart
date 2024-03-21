// ignore_for_file: unused_element

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:blurhash_ffi/uiImage.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'blurhash_ffi_bindings_generated.dart';

const String _libName = 'blurhash_ffi';

final Logger _log = Logger('blurhash_ffi');

void configureLogger() {
  Logger.root.level =
      Level.ALL; // Set the log level (You can adjust this as needed)

  Logger.root.onRecord.listen((record) {
    // Define ANSI escape code sequences for different log levels and colors
    final Map<Level, String> colorMap = {
      Level.INFO: '\x1B[32m', // Green for INFO
      Level.WARNING: '\x1B[33m', // Yellow for WARNING
      Level.SEVERE: '\x1B[31m', // Red for SEVERE
      Level.SHOUT: '\x1B[35m', // Magenta for SHOUT (if used)
      Level.CONFIG: '\x1B[36m', // Cyan for CONFIG (if used)
      // Add more colors for other log levels if needed
    };

    // Reset color at the end of the log message
    const String colorReset = '\x1B[0m';

    // Get the color code for the log level
    final String colorCode = colorMap[record.level] ?? '';

    // You can customize the log message format here, including color
    debugPrint(
        '$colorCode${record.level.name}: ${record.time}: ${record.message}$colorReset');
  });
}

/// Create a neat class to handle all the glue code and expose a nice API.
class BlurhashFFI {
  // singleton class
  static final BlurhashFFI _instance = BlurhashFFI._internal();

  // Logger
  bool _isInitialized = false;

  factory BlurhashFFI() {
    if (!_instance._isInitialized) {
      _instance._isInitialized = true;
      configureLogger();
    }
    return _instance;
  }

  BlurhashFFI._internal();

  void _free() {
    for (var isolate in _helperIsolates) {
      isolate.kill();
    }
  }

  static void free() => _instance._free();

  static bool isValidBlurHash(String blurHash) =>
      _instance._isValidBlurHash(blurHash);

  final List<Isolate> _helperIsolates = <Isolate>[];

  static Future<String> encode(
    ImageProvider imageProvider, {
    int componentX = 4,
    int componentY = 3,
  }) async {
    try {
      final BlurHashImageInfo info =
          await _instance._getImageInfoFromImageProvider(imageProvider);
      return _instance._encodeBlurHash(info, componentX, componentY);
    } catch (e) {
      throw BlurhashFFIException(
          'Could not encode Image', StackTrace.current, e);
    }
  }

  static Future<ui.Image> decode(
    String blurhash, {
    int width = 32,
    int height = 32,
    int punch = 1,
  }) async {
    try {
      return _instance._blurHashDecodeImage(blurhash, width, height, punch);
    } catch (e) {
      throw BlurhashFFIException(
          'Could not decode Image', StackTrace.current, e);
    }
  }

  bool _isValidBlurHash(String blurHash) {
    Pointer<Utf8> bhptr = blurHash.toNativeUtf8();
    bool result = _bindings.isValidBlurhash(bhptr.cast<Char>());
    malloc.free(bhptr);
    return result;
  }

  /// The dynamic library in which the symbols for [BlurhashFfiBindings] can be found.
  DynamicLibrary get _dylib {
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
  }

  BlurhashFfiBindings get _bindings => BlurhashFfiBindings(_dylib);

  // encode requests
  int _nextEncodeRequestId = 0;
  final Map<int, Completer<String>> _encodeRequests =
      <int, Completer<String>>{};

  // decode requests
  int _nextDecodeRequestId = 0;
  final Map<int, Completer<Uint8List>> _decodeRequests =
      <int, Completer<Uint8List>>{};

  // decode to array requests
  int _nextDecodeToArrayRequestId = 0;
  final Map<int, Completer<int>> _decodeToArrayRequests =
      <int, Completer<int>>{};

  /// Encoder A longer lived native function, which occupies the thread calling it.
  ///
  /// Parameters :
  ///     `info` - The image info
  ///     `componentX` - The number of components in the X direction. Must be between 1 and 9. 3 to 5 is usually a good range for this.
  ///     `componentY` - The number of components in the Y direction. Must be between 1 and 9. 3 to 5 is usually a good range for this.
  Future<String> _encodeBlurHash(BlurHashImageInfo info,
      [int componentX = 4, int componentY = 3]) async {
    final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
    final int requestId = _nextEncodeRequestId++;
    final _EncodeRequest request = _EncodeRequest(requestId, info.rgbBytes,
        info.width, info.height, componentX, componentY, info.rowStride);
    final Completer<String> completer = Completer<String>();
    _encodeRequests[requestId] = completer;
    helperIsolateSendPort.send(request);
    return completer.future;
  }

  Future<Uint8List> _decodeBlurHash(
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

  Future<BlurHashImageInfo> _getImageInfoFromImageProvider(
      ImageProvider imageProvider) async {
    final completer = Completer<BlurHashImageInfo>();
    final listener = ImageStreamListener((imageInfo, _) async {
      final ByteData? bytes =
          await imageInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) {
        completer.completeError(BlurhashFFIException(
            'Could not decode Image from Image provider',
            StackTrace.current,
            null));
        return;
      }
      final Uint8List list = bytes.buffer.asUint8List();

      if (!completer.isCompleted) {
        completer.complete(BlurHashImageInfo(imageInfo.image.height,
            imageInfo.image.width, imageInfo.image.width * 4, list));
      }
    }, onError: (dynamic exception, StackTrace? stackTrace) {
      completer.completeError(exception, stackTrace);
    });
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    imageStream.addListener(listener);
    completer.future.whenComplete(() {
      imageStream.removeListener(listener);
    });
    return completer.future;
  }

  Future<ui.Image> _blurHashDecodeImage(
      String hash, int width, int height, int punch) async {
    _validateBlurhash(hash);

    final completer = Completer<ui.Image>();
    final pixels = await _decodeBlurHash(hash, width, height, punch, 4);
    if (kIsWeb) {
      // https://github.com/flutter/flutter/issues/45190
      completer.complete(_createBmp(pixels, width, height, 4));
    } else {
      ui.decodeImageFromPixels(
          pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
    }

    return completer.future;
  }

  void _validateBlurhash(String hash) {
    if (!_isValidBlurHash(hash)) {
      throw Exception('Invalid blurhash');
    }
  }

  Future<BlurHashImageInfo> _getBlurHashImageInfoFromAsset(String assetName) {
    return _getImageInfoFromImageProvider(AssetImage(assetName));
  }

  Future<BlurHashImageInfo> _getBlurHashInfoFromUiImage(ui.Image image) {
    return _getImageInfoFromImageProvider(UiImage(image));
  }

  Future<int> _decodeToArray(
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

  late final Future<SendPort> _helperIsolateSendPort =
      _helperIsolateSendPortFunc();

  /// The SendPort belonging to the helper isolate.
  Future<SendPort> _helperIsolateSendPortFunc() async {
    // The helper isolate is going to send us back a SendPort, which we want to
    // wait for.
    final Completer<SendPort> completer = Completer<SendPort>();

    // Receive port on the main isolate to receive messages from the helper.
    // We receive two types of messages:
    // 1. A port to send messages on.
    // 2. Responses to requests we sent.
    void onData(dynamic data) {
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
    }

    final ReceivePort receivePort = ReceivePort()..listen(onData);
    final ReceivePort errorPort = ReceivePort()
      ..listen((message) {
        final isolateDebugName =
            'blurhash_ffi#native#${_helperIsolates.length}';
        if (message is BlurhashFFIException) {
          switch (message.level) {
            case Level.SEVERE:
              _log.severe('Error $isolateDebugName: ${message.message}',
                  message.error, message.stackTrace);
              break;
            case Level.INFO:
              _log.info('Error $isolateDebugName: ${message.message}',
                  message.error, message.stackTrace);
              break;
            case Level.WARNING:
              _log.warning('Error $isolateDebugName: ${message.message}',
                  message.error, message.stackTrace);
              break;
            default:
              _log.shout(
                  'Error ${message.level} $isolateDebugName: ${message.message}',
                  message.error,
                  message.stackTrace);
          }
        } else {
          _log.shout('Error $isolateDebugName: $message');
        }
      });
    // Start the helper isolate.
    final isolate = await Isolate.spawn<SendPort>(
      isolateEntryPoint,
      receivePort.sendPort,
      errorsAreFatal: false,
      onError: errorPort.sendPort,
      debugName: 'blurhash_ffi#native#${_helperIsolates.length}}',
    );

    _helperIsolates.add(isolate);

    // Wait until the helper isolate has sent us back the SendPort on which we
    // can start sending requests.
    return completer.future;
  }

  void isolateEntryPoint(SendPort sendPort) async {
    void onSend(dynamic data) {
      try {
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
          final String resultString = result.cast<Utf8>().toDartString();
          final _EncodeResponse response =
              _EncodeResponse(data.id, resultString);
          sendPort.send(response);
          return;
        } else if (data is _DecodeRequest) {
          final Pointer<Uint8> result = _bindings.decode(data.blurHashPointer,
              data.width, data.height, data.punch, data.channels);
          final Uint8List resultImage = result.asTypedList(
            data.width * data.height * data.channels,
            // preffer way but works only from dart 3.1.0, and requre to change generated bindings
            // finalizer: _bindings.freePixelArrayPtr.cast(),
          );
          final _DecodeResponse response = _DecodeResponse(
            data.id,
            // copy image data to prevent 'use after free' error
            Uint8List.fromList(resultImage),
          );
          // free c side memory
          _bindings.freePixelArray(result);
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
        throw BlurhashFFIException(
            'EXCEPTION: Unsupported message type: ${data.runtimeType}',
            null,
            null);
      } catch (e) {
        final stackTrace = StackTrace.current;
        throw BlurhashFFIException(
            'ERORR: ${Isolate.current.debugName}', stackTrace, e);
      }
    }

    final ReceivePort helperReceivePort = ReceivePort()..listen(onSend);

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }
}

class BlurhashFFIException extends Error {
  final String message;
  final Level? level;
  @override
  final StackTrace? stackTrace;
  final Object? error;

  BlurhashFFIException(this.message, this.stackTrace, this.error,
      [this.level = Level.SEVERE]);
}

mixin Freeable {
  void free();
}

class _DecodeToArrayRequest with Freeable {
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

  @override
  void free() {
    if (_bhptr != null) {
      malloc.free(_bhptr!);
      _bhptr = null;
    }
  }
}

class _DecodeRequest with Freeable {
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

  @override
  void free() {
    if (_bhptr != null) {
      malloc.free(_bhptr!);
      _bhptr = null;
    }
  }
}

class _EncodeRequest with Freeable {
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

  @override
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

  int get numChannels => rowStride ~/ width;
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
