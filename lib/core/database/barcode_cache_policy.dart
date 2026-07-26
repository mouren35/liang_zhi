abstract final class BarcodeCachePolicy {
  static const Duration foundTtl = Duration(days: 30);
  static const Duration notFoundTtl = Duration(hours: 24);

  static DateTime expiresAt({required String lookupStatus, required DateTime fetchedAt}) {
    return switch (lookupStatus) {
      'found' => fetchedAt.add(foundTtl),
      'not_found' => fetchedAt.add(notFoundTtl),
      _ => throw const FormatException('未知条码缓存状态'),
    };
  }

  static bool isExpired({required int expiresAtUtcMillis, required DateTime now}) {
    return expiresAtUtcMillis <= now.toUtc().millisecondsSinceEpoch;
  }
}
