import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/app_routes.dart';
import 'package:liangzhi/app/app_theme.dart';
import 'package:liangzhi/core/notifications/notification_navigation_service.dart';
import 'package:liangzhi/core/notifications/notification_reschedule_registry.dart';
import 'package:liangzhi/core/providers/notification_providers.dart';
import 'package:liangzhi/core/providers/service_providers.dart';

class LiangZhiApp extends ConsumerStatefulWidget {
  LiangZhiApp({AppConfig? config, GoRouter? router, super.key})
    : config = config ?? AppConfig.current,
      router = router ?? createAppRouter();

  final AppConfig config;
  final GoRouter router;

  @override
  ConsumerState<LiangZhiApp> createState() => _LiangZhiAppState();
}

class _LiangZhiAppState extends ConsumerState<LiangZhiApp> with WidgetsBindingObserver {
  late final void Function(String route) _notificationRouteHandler;
  late final Future<void> Function() _notificationRescheduleHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationRouteHandler = (String route) => widget.router.go(route);
    _notificationRescheduleHandler = _rescheduleNotifications;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      NotificationNavigationService.instance.attach(
        _notificationRouteHandler,
      );
      NotificationRescheduleRegistry.instance.attach(
        _notificationRescheduleHandler,
      );
      _rescheduleNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationNavigationService.instance.detach(
      _notificationRouteHandler,
    );
    NotificationRescheduleRegistry.instance.detach(
      _notificationRescheduleHandler,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rescheduleNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '粮知',
      theme: AppTheme.light(defaultTargetPlatform),
      routerConfig: widget.router,
      builder: (BuildContext context, Widget? child) {
        final Widget content = child ?? const SizedBox.shrink();
        if (!widget.config.showEnvironmentBadge) {
          return content;
        }
        return Banner(
          message: widget.config.environment.label,
          location: BannerLocation.topEnd,
          child: content,
        );
      },
    );
  }

  Future<void> _rescheduleNotifications() async {
    try {
      await ref.read(notificationCoordinatorProvider).reschedule();
      ref.invalidate(notificationPermissionStatusProvider);
    } on Object {
      // 启动和恢复不因通知平台暂不可用而阻断主流程。
    }
  }
}
