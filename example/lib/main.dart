import 'package:blurhash_ffi_example/config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:unsplash_client/unsplash_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool hasError = false;
  String errorMessage = '';

  static const AppCredentials credential = AppCredentials(
      accessKey: Config.unsplashAccessKey, secretKey: Config.unsplashSecretKey);

  final client = UnsplashClient(
    settings: const ClientSettings(credentials: credential),
  );

  final List<Photo> photos = [];

  void loadProtraits() async {
    client.search
        .photos('fashion',
            page: 1,
            perPage: 30,
            orientation: PhotoOrientation.portrait,
            orderBy: PhotoOrder.relevant,
            contentFilter: ContentFilter.high)
        .goAndGet()
        .then((value) async {
      setState(() {
        photos.addAll(value.results);
      });
    }).catchError((e) {
      debugPrint('error while loading images: $e');
      setState(() {
        hasError = true;
        errorMessage = e.toString();
      });
    });
  }

  @override
  void initState() {
    setStatusBarColor();
    PaintingBinding.instance.imageCache.maximumSizeBytes = cacheSize200M;
    loadProtraits();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Builder(builder: (context) {
        if (hasError) {
          return Center(
            child: Text(errorMessage),
          );
        }
        if (photos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return PageView.builder(
            itemCount: photos.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) => CachedNetworkImage(
                  imageUrl: photos[index].urls.raw.toString(),
                  placeholder: (context, url) {
                    if (photos[index].blurHash == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return BlurhashFfi(
                      hash: photos[index].blurHash!,
                      imageFit: BoxFit.cover,
                    );
                  },
                  errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.error)),
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                  fadeInDuration: const Duration(milliseconds: 600),
                  fadeInCurve: Curves.easeIn,
                  fadeOutDuration: const Duration(milliseconds: 600),
                  fadeOutCurve: Curves.easeOut,
                ));
      })),
    );
  }
}

class ImageSelect extends StatelessWidget {
  final ImageProvider imageProvider;
  final bool isSelected;
  const ImageSelect(
      {super.key, required this.imageProvider, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: Colors.black, width: 4) : null,
        ),
        child: Image(
          image: imageProvider,
          height: 400,
        ),
      ),
    );
  }
}
