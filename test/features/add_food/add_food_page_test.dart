import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/features/add_food/add_food_page.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/repositories/reference_data_repository.dart';

import '../../support/test_scope.dart';

void main() {
  testWidgets('校验必填字段并保存规范化食品', (WidgetTester tester) async {
    final _AddRepository repository = _AddRepository();
    Food? saved;
    await _pump(
      tester,
      repository: repository,
      page: AddFoodPage(
        initialExpiryDate: DateTime(2026, 8),
        onSaved: (Food food) => saved = food,
        onCancel: () {},
      ),
    );

    await _showSaveButton(tester);
    await tester.tap(find.byKey(const ValueKey<String>('save-food')));
    await tester.pump();
    expect(find.text('请输入食品名称'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey<String>('food-name')), '  苹果  ');
    await tester.enterText(find.byKey(const ValueKey<String>('food-quantity')), '1.25');
    await _showSaveButton(tester);
    await tester.tap(find.byKey(const ValueKey<String>('save-food')));
    await tester.pumpAndSettle();

    expect(repository.addCount, 1);
    expect(saved?.name, '苹果');
    expect(saved?.quantity, 1.25);
    expect(saved?.categoryId, DefaultIds.categoryOther);
    expect(saved?.locationId, DefaultIds.locationOther);
  });

  testWidgets('保存失败保留输入且不会重复提交', (WidgetTester tester) async {
    final _AddRepository repository = _AddRepository()..error = StateError('failed');
    await _pump(
      tester,
      repository: repository,
      page: AddFoodPage(
        initialExpiryDate: DateTime(2026, 8),
        onSaved: (Food food) {},
        onCancel: () {},
      ),
    );
    await tester.enterText(find.byKey(const ValueKey<String>('food-name')), '牛奶');
    await _showSaveButton(tester);
    await tester.tap(find.byKey(const ValueKey<String>('save-food')));
    await tester.pumpAndSettle();

    expect(find.text('牛奶'), findsOneWidget);
    expect(find.text('保存失败，输入内容已保留'), findsOneWidget);
    expect(repository.addCount, 1);
  });

  testWidgets('有输入时取消需要确认放弃', (WidgetTester tester) async {
    bool cancelled = false;
    await _pump(
      tester,
      repository: _AddRepository(),
      page: AddFoodPage(
        onSaved: (Food food) {},
        onCancel: () => cancelled = true,
      ),
    );
    await tester.enterText(find.byKey(const ValueKey<String>('food-name')), '面包');
    await tester.tap(find.byTooltip('取消添加'));
    await tester.pumpAndSettle();
    expect(find.text('放弃本次编辑？'), findsOneWidget);

    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(cancelled, isFalse);
    expect(find.text('面包'), findsOneWidget);

    await tester.tap(find.byTooltip('取消添加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
  });

  testWidgets('扫码商品基础信息可编辑并随条码保存', (WidgetTester tester) async {
    final _AddRepository repository = _AddRepository();
    Food? saved;
    await _pump(
      tester,
      repository: repository,
      page: AddFoodPage(
        initialBarcode: '6901234567892',
        initialName: '远程名称',
        initialBrand: '远程品牌',
        initialSpecification: '250 ml',
        initialExpiryDate: DateTime(2026, 8),
        onSaved: (Food food) => saved = food,
        onCancel: () {},
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('food-name')),
      '用户名称',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('food-brand')),
      '用户品牌',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('food-specification')),
      '300 ml',
    );
    await _showSaveButton(tester);
    await tester.tap(find.byKey(const ValueKey<String>('save-food')));
    await tester.pumpAndSettle();

    expect(saved?.barcode, '6901234567892');
    expect(saved?.name, '用户名称');
    expect(saved?.brand, '用户品牌');
    expect(saved?.specification, '300 ml');
  });

  testWidgets('远程图片加载失败显示占位且表单仍可使用', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      repository: _AddRepository(),
      page: AddFoodPage(
        initialName: '测试商品',
        initialRemoteImageUrl: Uri.parse(
          'https://invalid.example/product.jpg',
        ),
        initialExpiryDate: DateTime(2026, 8),
        onSaved: (Food food) {},
        onCancel: () {},
      ),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('food-name')), findsOneWidget);
  });
}

Future<void> _showSaveButton(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey<String>('save-food')));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  required _AddRepository repository,
  required AddFoodPage page,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        foodRepositoryProvider.overrideWithValue(repository),
        categoryRepositoryProvider.overrideWithValue(const _CategoryRepository()),
        locationRepositoryProvider.overrideWithValue(const _LocationRepository()),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

final class _AddRepository extends EmptyFoodRepository {
  int addCount = 0;
  Object? error;
  Completer<void>? completer;

  @override
  Future<void> add(Food food) async {
    addCount += 1;
    if (error case final Object value) {
      throw value;
    }
    await completer?.future;
  }
}

final class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository();

  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.categoryOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}

final class _LocationRepository implements LocationRepository {
  const _LocationRepository();

  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.locationOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}
