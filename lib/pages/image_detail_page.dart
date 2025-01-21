import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewerPage extends StatelessWidget {
  final Uint8List imageBytes;
  final int imageId;

  ImageViewerPage({
    Key? key,
    required this.imageBytes,
    required this.imageId,
  }) : super(key: key);

  // GlobalKey for RepaintBoundary
  final GlobalKey _globalKey = GlobalKey();

  // Function to capture widget and convert it to image
  Future<void> _captureAndShare(BuildContext context) async {
    try {
      // Capture the widget as an image
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image =
          await boundary.toImage(pixelRatio: 3.0); // Capture widget as image
      ByteData? byteData = await image.toByteData(
          format: ImageByteFormat.png); // Convert to byte data
      Uint8List uint8List = byteData!.buffer.asUint8List();

      // Save image to temporary directory
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/captured_image_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(uint8List);

      // Use XFile to share the image
      final xFile = XFile(file.path); // Convert to XFile
      final result = await Share.shareXFiles([xFile], text: 'Text bisa di custom');
      if (result != null) {
        print("Image shared successfully!");
      } else {
        print("Sharing failed");
      }
    } catch (e) {
      print('Error capturing and sharing the image: $e');
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Penghapusan'),
          content: const Text('Apakah Anda yakin ingin menghapus gambar ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Jika 'Tidak'
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Jika 'Ya'
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      Navigator.pop(context); // Kembali ke halaman sebelumnya setelah menghapus
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: RepaintBoundary(
              key: _globalKey, // Wrap the widget in RepaintBoundary
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.memory(imageBytes),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  // Tambahkan fungsionalitas untuk mengedit gambar jika diperlukan
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  _captureAndShare(context); // Capture and share the image
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
