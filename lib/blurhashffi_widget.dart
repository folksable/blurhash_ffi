// ignore: constant_identifier_names
import 'package:blurhash_ffi/blurhash.dart';
import 'package:blurhash_ffi/uiImage.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class BlurhashFfi extends StatefulWidget {
  const BlurhashFfi({
    required this.hash,
    Key? key,
    this.color = Colors.blueGrey,
    this.imageFit = BoxFit.fill,
    this.decodingWidth = 32,
    this.decodingHeight = 32,
    this.image,
    this.onDecoded,
    this.onDisplayed,
    this.onReady,
    this.onStarted,
    this.duration = const Duration(milliseconds: 1000),
    this.httpHeaders = const {},
    this.curve = Curves.easeOut,
    this.errorBuilder,
  })  : assert(decodingWidth > 0),
        assert(decodingHeight != 0),
        super(key: key);

  /// Callback when hash is decoded
  final VoidCallback? onDecoded;

  /// Callback when hash is decoded
  final VoidCallback? onDisplayed;

  /// Callback when image is downloaded
  final VoidCallback? onReady;

  /// Callback when image is downloaded
  final VoidCallback? onStarted;

  /// Hash to decode
  final String hash;

  /// Displayed background color before decoding
  final Color color;

  /// How to fit decoded & downloaded image
  final BoxFit imageFit;

  /// Decoding definition
  final int decodingWidth;

  /// Decoding definition
  final int decodingHeight;

  /// Remote resource to download
  final String? image;

  final Duration duration;

  final Curve curve;

  /// Http headers for secure call like bearer
  final Map<String, String> httpHeaders;

  /// Network image errorBuilder
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<BlurhashFfi> createState() => _BlurhashFfiState();
}

class _BlurhashFfiState extends State<BlurhashFfi> {
  late Future<ui.Image> _image;
  late bool loaded;
  late bool loading;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _decodeImage();
    loaded = false;
    loading = false;
  }

  @override
  void didUpdateWidget(BlurhashFfi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hash != oldWidget.hash ||
        widget.image != oldWidget.image ||
        widget.decodingWidth != oldWidget.decodingWidth ||
        widget.decodingHeight != oldWidget.decodingHeight) {
      _init();
    }
  }

  void _decodeImage() {
    _image = BlurhashFFI.decode(
      widget.hash,
      width: widget.decodingWidth,
      height: widget.decodingHeight,
    );

    _image.whenComplete(() => widget.onDecoded?.call());
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          BlurhashBackground(
              image: _image,
              color: widget.color,
              fit: widget.imageFit,
              errorBuilder: widget.errorBuilder),
          if (widget.image != null) prepareDisplayedImage(widget.image!),
        ],
      );

  Widget prepareDisplayedImage(String image) => Image.network(
        image,
        fit: widget.imageFit,
        headers: widget.httpHeaders,
        errorBuilder: widget.errorBuilder,
        loadingBuilder: (context, img, loadingProgress) {
          // Download started
          if (loading == false) {
            loading = true;
            widget.onStarted?.call();
          }

          if (loadingProgress == null) {
            // Image is now loaded, trigger the event
            loaded = true;
            widget.onReady?.call();
            return _DisplayImage(
              duration: widget.duration,
              curve: widget.curve,
              onCompleted: () => widget.onDisplayed?.call(),
              child: img,
            );
          } else {
            return const SizedBox();
          }
        },
      );
}

class BlurhashBackground extends StatelessWidget {
  const BlurhashBackground({
    super.key,
    required Future<ui.Image> image,
    this.color = Colors.blueGrey,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  }) : _image = image;

  final Future<ui.Image> _image;
  final ImageErrorWidgetBuilder? errorBuilder;
  final BoxFit? fit;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
        future: _image,
        builder: (ctx, snap) {
          if (snap.hasError && errorBuilder != null) {
            return errorBuilder!(ctx, snap.error!, StackTrace.current);
          }
          if (snap.hasData) {
            return Image(
              image: UiImage(snap.data!),
              fit: fit,
              errorBuilder: errorBuilder,
            );
          }
          return AnimatedContainer(color: color, duration: const Duration(milliseconds: 100),);
        });
  }
}

// Inner display details & controls
class _DisplayImage extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback onCompleted;

  const _DisplayImage({
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    required this.curve,
    required this.onCompleted,
    Key? key,
  }) : super(key: key);

  @override
  _DisplayImageState createState() => _DisplayImageState();
}

class _DisplayImageState extends State<_DisplayImage>
    with SingleTickerProviderStateMixin {
  late Animation<double> opacity;
  late AnimationController controller;

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: opacity,
        child: widget.child,
      );

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: widget.duration, vsync: this);
    final curved = CurvedAnimation(parent: controller, curve: widget.curve);
    opacity = Tween<double>(begin: .0, end: 1.0).animate(curved);
    controller.forward();

    curved.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted.call();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
