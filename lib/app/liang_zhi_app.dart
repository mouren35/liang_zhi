import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/app_routes.dart';
import 'package:liangzhi/app/app_theme.dart';

class LiangZhiApp extends StatelessWidget {
  LiangZhiApp({AppConfig? config, GoRouter? router, super.key})
    : config = config ?? AppConfig.current,
      router = router ?? createAppRouter();

  final AppConfig config;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '粮知',
      theme: AppTheme.light(defaultTargetPlatform),
      routerConfig: router,
      builder: (BuildContext context, Widget? child) {
        final Widget content = child ?? const SizedBox.shrink();
        if (!config.showEnvironmentBadge) {
          return content;
        }
        return Banner(
          message: config.environment.label,
          location: BannerLocation.topEnd,
          child: content,
        );
      },
    );
  }
}
