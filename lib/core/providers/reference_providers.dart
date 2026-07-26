import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/shared/models/reference_item.dart';

final FutureProvider<List<ReferenceItem>> categoryListProvider =
    FutureProvider<List<ReferenceItem>>(
      (Ref ref) => ref.watch(categoryRepositoryProvider).getAll(),
      name: 'categoryListProvider',
      retry: (int retryCount, Object error) => null,
    );

final FutureProvider<List<ReferenceItem>> locationListProvider =
    FutureProvider<List<ReferenceItem>>(
      (Ref ref) => ref.watch(locationRepositoryProvider).getAll(),
      name: 'locationListProvider',
      retry: (int retryCount, Object error) => null,
    );
