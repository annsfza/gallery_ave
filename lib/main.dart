import 'package:flutter/material.dart';
import 'package:your_gallery/pages/gallery_page.dart';
import 'package:your_gallery/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  SignInScreen(),
    );
  }
}
