import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/repositories/notification_aware_food_repository.dart';
import 'package:liangzhi/shared/models/food.dart';

import '../../support/test_scope.dart';

void main() {
  test('新增、更新和删除成功后均触发重调度', () async {
    final _RecordingFoodRepository delegate = _RecordingFoodRepository();
    int notifications = 0;
    final NotificationAwareFoodRepository repository = NotificationAwareFoodRepository(
      delegate: delegate,
      onChanged: () async => notifications += 1,
    );

    await repository.add(_food());
    await repository.update(_food());
    await repository.softDelete(
      'food',
      deletedAt: DateTime(2026, 7, 2),
    );

    expect(notifications, 3);
  });

  test('重调度失败不回滚已成功的食品写入', () async {
    final _RecordingFoodRepository delegate = _RecordingFoodRepository();
    final NotificationAwareFoodRepository repository = NotificationAwareFoodRepository(
      delegate: delegate,
      onChanged: () async => throw StateError('schedule failed'),
    );

    await repository.add(_food());

    expect(delegate.addCount, 1);
  });
}

final class _RecordingFoodRepository extends EmptyFoodRepository {
  int addCount = 0;

  @override
  Future<void> add(Food food) async {
    addCount += 1;
  }
}

Food _food() {
  return Food(
    id: 'food',
    name: '牛奶',
    quantity: 1,
    unit: '盒',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: DateTime(2026, 8),
    status: FoodStatus.active,
    createdAt: DateTime(2026, 7),
    updatedAt: DateTime(2026, 7),
  );
}
