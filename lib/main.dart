import 'package:flutter/material.dart';
import 'package:liangzhi/features/home/home_page.dart';

void main() {
  runApp(const LiangZhiApp());
}

class LiangZhiApp extends StatelessWidget {
  const LiangZhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '粮知',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3F854C)),
      home: const HomePage(),
    );
  }
}
