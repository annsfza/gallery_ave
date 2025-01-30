import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:your_gallery/pages/login_page.dart';
import '../helpers/database_helper.dart';
import 'image_detail_page.dart'; // Import halaman detail gambar

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker(); // Instance untuk memilih gambar
  List<Map<String, dynamic>> _imageFileList = []; // Menyimpan daftar gambar dari database
  Set<int> _selectedImageIds = Set<int>(); // Menyimpan ID gambar yang dipilih untuk dihapus

  @override
  void initState() {
    super.initState();
    _loadImages(); // Memuat gambar dari database saat halaman pertama kali dibuka
  }

  Future<void> _loadImages() async {
    final images = await DatabaseHelper.instance.getAllImages(); // Mengambil gambar dari database
    setState(() {
      _imageFileList = images; // Menyimpan gambar dalam list
    });
  }

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage(); // Memilih banyak gambar

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        final imageFile = File(pickedFile.path); // Mengubah gambar menjadi file
        final date = DateTime.now(); // Menyimpan tanggal saat gambar diunggah

        await DatabaseHelper.instance.insertImage(imageFile, date); // Simpan ke database
        _loadImages(); // Perbarui daftar gambar
      }
    }
  }

  Future<void> _deleteImage(int imageId) async {
    await DatabaseHelper.instance.deleteImage(imageId); // Menghapus gambar dari database

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image deleted successfully')),
    );

    _loadImages(); // Memuat ulang daftar gambar setelah dihapus
  }

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
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteImage(imageId); // Hapus gambar
                Navigator.of(context).pop(); // Tutup dialog setelah dihapus
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                // Navigasi ke halaman login dan menghapus semua halaman sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                  (route) => false,
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Hi Dear'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _showLogoutConfirmation,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What is your outfit today',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                _imageFileList.isEmpty
                    ? const Center(child: Text('No images available.'))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: _imageFileList.length,
                        itemBuilder: (context, index) {
                          final imageData = _imageFileList[index];
                          final imageBytes = imageData['image'] as List<int>;
                          final image = Image.memory(Uint8List.fromList(imageBytes), fit: BoxFit.cover);
                          final imageId = imageData['id'];
                          bool isSelected = _selectedImageIds.contains(imageId);

                          return GestureDetector(
                            onLongPress: () {
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (isSelected)
                                    Container(color: Colors.blue.withOpacity(0.3)),
                                  InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageViewerPage(
                                            imageBytes: Uint8List.fromList(imageBytes),
                                            imageId: imageId,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadImages();
                                      }
                                    },
                                    child: image,
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
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
          onPressed: _pickImage,
          child: const Icon(Icons.add),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          tooltip: 'Add Image',
        ),
      ),
    );
  }
}
