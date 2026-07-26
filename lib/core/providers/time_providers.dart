import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/shared/models/food.dart';

final Provider<DateTime> currentDateProvider = Provider<DateTime>(
  (Ref ref) => dateOnly(DateTime.now()),
  name: 'currentDateProvider',
);
