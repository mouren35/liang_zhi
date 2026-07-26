import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/logging/safe_logger.dart';

void main() {
  test('错误日志仅包含内部事件名和异常类型', () {
    final List<String> messages = <String>[];
    final SafeLogger logger = SafeLogger(enabled: true, output: messages.add);

    logger.error(
      'food_save_failed',
      Exception('秘密备注 C:\\Users\\demo\\food.jpg'),
    );

    expect(messages, hasLength(1));
    expect(messages.single, contains('event=food_save_failed'));
    expect(messages.single, contains('error_type=_Exception'));
    expect(messages.single, isNot(contains('秘密备注')));
    expect(messages.single, isNot(contains(r'C:\Users')));
  });

  test('正式环境关闭应用日志', () {
    final List<String> messages = <String>[];
    final SafeLogger logger = SafeLogger(enabled: false, output: messages.add);

    logger.event('app_started');
    logger.error('flutter_error', StateError('private'));

    expect(messages, isEmpty);
  });
}
