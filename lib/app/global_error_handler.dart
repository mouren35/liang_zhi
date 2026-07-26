import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/core/logging/safe_logger.dart';

void installGlobalErrorHandlers(AppConfig config, {SafeLogger? logger}) {
  final SafeLogger safeLogger =
      logger ?? SafeLogger(enabled: config.environment != AppEnvironment.production);
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorWidget(
      technicalMessage: config.environment == AppEnvironment.production
          ? null
          : details.exception.runtimeType.toString(),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    safeLogger.error('flutter_error', details.exception);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    safeLogger.error('uncaught_async_error', error);
    return true;
  };
}

class GlobalErrorWidget extends StatelessWidget {
  const GlobalErrorWidget({this.technicalMessage, super.key});

  final String? technicalMessage;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('页面暂时无法显示'),
              if (technicalMessage case final String message) ...[
                const SizedBox(height: 12),
                SelectableText(message, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
