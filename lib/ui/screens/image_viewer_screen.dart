import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatelessWidget {
  final String path;
  final String title;
  const ImageViewerScreen({super.key, required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PhotoView(
        imageProvider: kIsWeb ? NetworkImage(path) : FileImage(File(path)) as ImageProvider,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
