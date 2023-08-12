import 'package:flutter/material.dart';
import 'dart:async';

import 'package:blurhash_ffi/blurhash_ffi.dart';

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
                        blurHashResult = BlurhashFFI.encode(
                          AssetImage(assetName),
                        );
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
                // if (blurHashResult != null)
                //   Align(
                //     alignment: Alignment.center,
                //     child: SizedBox(
                //       height: 120,
                //       width: 120,
                //       child: FutureBuilder(
                //           future: blurHashResult,
                //           builder: (context, snapshot) {
                //             if (snapshot.hasData) {
                //               return BlurhashFfi(
                //                 hash: snapshot.data!,
                //                 decodingWidth: 120,
                //                 decodingHeight: 120,
                //                 imageFit: BoxFit.cover,
                //                 color: Colors.grey,
                //                 onReady: () => debugPrint('Blurhash ready'),
                //                 onDisplayed: () => debugPrint('Blurhash displayed'),
                //                 errorBuilder: (context, error, stackTrace) => Container(
                //                   color: Colors.red,
                //                   child: const Center(child: Text('Error', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
                //               );
                //             }
                //             return const Center(
                //               child: CircularProgressIndicator(),
                //             );
                //           }),
                //     ),
                //   )
              ],
            ),
          ),
        ),
      ),
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