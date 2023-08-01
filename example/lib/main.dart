import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
                if (selectedImage != -1)
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                        height: 120,
                        width: 120,
                        child: Image(
                          image: BlurhashTheImage(
                            AssetImage(selectedImage == 2
                                ? 'assets/images/$selectedImage.png'
                                : 'assets/images/$selectedImage.jpg'),
                            decodingWidth: 120,
                            decodingHeight: 120,
                          ),
                          loadingBuilder: (context, child, loadingProgress) =>
                              loadingProgress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFF1D4D4),
                                      ),
                                    ),
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) =>
                                  child,
                        )),
                  )
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

class BlurhashMyImage extends StatelessWidget {
  final String imageUrl;
  const BlurhashMyImage({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Image(
      image: BlurhashTheImage(
        NetworkImage(imageUrl), // you can use any image provider of your choice.
          decodingHeight: 1920, decodingWidth: 1080),
      alignment: Alignment.center,
      fit: BoxFit.cover,
    );
  }
}
