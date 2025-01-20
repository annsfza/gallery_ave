import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/database_helper.dart';
import 'image_detail_page.dart'; // Import ImageDetailPage

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _imageFileList = [];
  Set<int> _selectedImageIds = Set<int>(); // To track selected images

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final images = await DatabaseHelper.instance.getAllImages();
    setState(() {
      _imageFileList = images;
    });
  }

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        final imageFile = File(pickedFile.path);
        final date = DateTime.now();

        // Save the image to the database
        await DatabaseHelper.instance.insertImage(imageFile, date);

        // Load the latest images from the database
        _loadImages();
      }
    }
  }

  Future<void> _deleteImage(int imageId) async {
    // Hapus gambar dari database
    await DatabaseHelper.instance.deleteImage(imageId);

    // Tampilkan konfirmasi penghapusan gambar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image deleted successfully')),
    );

    // Memuat ulang gambar dari database
    _loadImages();
  }

  // Method untuk menampilkan konfirmasi sebelum menghapus gambar
  void _showDeleteConfirmation(int imageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () {
                // Jika pengguna memilih "Cancel", tutup dialog
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Jika pengguna memilih "Delete", hapus gambar
                await _deleteImage(imageId);
                Navigator.of(context).pop(); // Tutup dialog setelah menghapus
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align title and subtitle
          children: const [
            Text('Hi Dear'),
            SizedBox(height: 4), // Small gap between title and subtitle
            Text(
              'What is your outfit today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        titleSpacing: 12,
      ),
      body: SingleChildScrollView(  // Wrap everything in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Add space between the subtitle and the GridView
              SizedBox(height: 30), 

              _imageFileList.isEmpty
                  ? const Center(
                      child: Text('No images available.'),
                    )
                  : GridView.builder(
                      shrinkWrap: true, // Makes the GridView take only as much space as required
                      physics: NeverScrollableScrollPhysics(), // Prevents scrolling inside GridView
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _imageFileList.length,
                      itemBuilder: (context, index) {
                        final imageData = _imageFileList[index];
                        final imageBytes = imageData['image'] as List<int>;
                        final image = Image.memory(
                          Uint8List.fromList(imageBytes),
                          fit: BoxFit.cover,
                        );
                        final imageId = imageData['id'];

                        bool isSelected = _selectedImageIds.contains(imageId);

                        return GestureDetector(
                          onLongPress: () {
                            // Toggle selection on long press
                            setState(() {
                              if (isSelected) {
                                _selectedImageIds.remove(imageId);
                              } else {
                                _selectedImageIds.add(imageId);
                              }
                            });
                          },
                          child: Card(
                            elevation: 4,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background color when selected
                                if (isSelected)
                                  Container(
                                    color: Colors.blue.withOpacity(0.3), // Opasitas lebih rendah
                                  ),
                                InkWell(
                                  onTap: () async {
                                    // Navigate to ImageDetailPage
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageViewerPage(
                                          imageBytes: Uint8List.fromList(imageBytes),
                                          imageId: imageId,
                                        ),
                                      ),
                                    );

                                    // If the image was deleted, reload images
                                    if (result == true) {
                                      _loadImages();
                                    }
                                  },
                                  child: image,
                                ),
                                // Delete button if selected
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        // Show the confirmation dialog
                                        _showDeleteConfirmation(imageId);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage, // Trigger image picking
        child: const Icon(Icons.add),
        backgroundColor: Colors.white, // White background for the button
        foregroundColor: Colors.black, // Icon color
        tooltip: 'Add Image',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Position at the bottom-right
    );
  }
}
