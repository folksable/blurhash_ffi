import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:blurhash_ffi/uiImage.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:blurhash_ffi/blurhash_ffi.dart' as blurhash_ffi;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<String>? blurHashResult;
  String? fbhResult;
  String? blurhashString;
  Future<ui.Image>? decodeBlurHashResult;
  int selectedImage = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Blurhash FFI Example'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2, 3].map<Widget>((e) {
                        var assetName = e == 2
                            ? 'assets/images/$e.png'
                            : 'assets/images/$e.jpg';
                    return MaterialButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        // load bytes from asset image
                        // calculate width and height of the image
                        BlurHashImageInfo info =
                            await getBlurHashImageInfoFromAsset(assetName);
                        debugPrint(info.toString());
                        blurHashResult = blurhash_ffi.encodeBlurHash(info);
                        blurHashResult!.then((String hash) {
                          debugPrint('Blurhash Loaded: $hash');
                          setState(() {
                            blurhashString = hash;
                            decodeBlurHashResult =
                                blurhash_ffi.blurHashDecodeImage(
                                    hash,
                                    MediaQuery.of(context).size.width.toInt(),
                                    MediaQuery.of(context).size.height.toInt(),
                                    1);
                          });
                        });
                        setState(() {
                          selectedImage = e;
                        });
                      },
                      child: ImageSelect(
                        imageProvider: AssetImage(assetName),
                        isSelected: selectedImage == e,
                      ),
                    );
                  }).toList(),
                ),
                if (blurHashResult != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder(
                      future: blurHashResult,
                      builder: (context, snapshot) => snapshot.hasData
                          ? Text('mbh: ${snapshot.data}')
                          : const CircularProgressIndicator(),
                    ),
                  ),
                // if(fbhResult != null)
                //   Padding(
                //     padding: const EdgeInsets.all(8.0),
                //     child: Text('fbh: $fbhResult'),
                //   ),
                if (decodeBlurHashResult != null)
                  BlurhashImageResult(
                      decodeBlurHashResult: decodeBlurHashResult),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Results from flutter blurhash"),
                ),
                // if (blurhashString != null)
                //   Align(
                //     alignment: Alignment.center,
                //     child: SizedBox(
                //         height: 120,
                //         width: 120,
                //         child: LayoutBuilder(
                //             builder: (context, constraints) => fbh.BlurHash(
                //                   hash: blurhashString!,
                //                   imageFit: BoxFit.cover,
                //                   decodingHeight: constraints.maxHeight.toInt(),
                //                   decodingWidth: constraints.maxWidth.toInt(),
                //                 ))),
                //   ),
                // if (fbhResult != null)
                //   Padding(
                //     padding: const EdgeInsets.all(5),
                //     child: Align(
                //       alignment: Alignment.center,
                //       child: SizedBox(
                //           height: 120,
                //           width: 120,
                //           child: LayoutBuilder(
                //               builder: (context, constraints) => fbh.BlurHash(
                //                     hash: fbhResult!,
                //                     imageFit: BoxFit.cover,
                //                     decodingHeight: constraints.maxHeight.toInt(),
                //                     decodingWidth: constraints.maxWidth.toInt(),
                //                   ))),
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BlurhashImageResult extends StatelessWidget {
  const BlurhashImageResult({
    super.key,
    required this.decodeBlurHashResult,
  });

  final Future<ui.Image>? decodeBlurHashResult;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: decodeBlurHashResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return Image(
            image: UiImage(snapshot.data!),
            fit: BoxFit.cover,
          );
        });
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
      child: Container(
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Image(
          image: imageProvider,
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}
