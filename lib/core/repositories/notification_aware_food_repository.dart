import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';

final class NotificationAwareFoodRepository implements FoodRepository {
  const NotificationAwareFoodRepository({
    required FoodRepository delegate,
    required Future<void> Function() onChanged,
  }) : _delegate = delegate,
       _onChanged = onChanged;

  final FoodRepository _delegate;
  final Future<void> Function() _onChanged;

  @override
  Future<void> add(Food food) async {
    await _delegate.add(food);
    await _notifySafely();
  }

  @override
  Future<List<Food>> getActiveFoods() => _delegate.getActiveFoods();

  @override
  Future<Food> getById(String id) => _delegate.getById(id);

  @override
  Future<void> softDelete(
    String id, {
    required DateTime deletedAt,
  }) async {
    await _delegate.softDelete(id, deletedAt: deletedAt);
    await _notifySafely();
  }

  @override
  Future<void> update(Food food) async {
    await _delegate.update(food);
    await _notifySafely();
  }

  @override
  Stream<List<Food>> watchActiveFoods() => _delegate.watchActiveFoods();

  Future<void> _notifySafely() async {
    try {
      await _onChanged();
    } on Object {
      // 通知重调度不得改变已经成功的食品写入结果。
    }
  }
}
