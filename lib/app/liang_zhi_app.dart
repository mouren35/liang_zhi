import 'package:flutter/material.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/features/home/home_page.dart';

class LiangZhiApp extends StatelessWidget {
  LiangZhiApp({AppConfig? config, super.key}) : config = config ?? AppConfig.current;

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '粮知',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3F854C)),
      home: config.showEnvironmentBadge
          ? Banner(
              message: config.environment.label,
              location: BannerLocation.topEnd,
              child: const HomePage(),
            )
          : const HomePage(),
    );
  }
}
