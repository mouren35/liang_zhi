sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class DataNotFoundException extends AppException {
  const DataNotFoundException([super.message = '没有找到这条数据']);
}

final class DataValidationException extends AppException {
  const DataValidationException([super.message = '数据格式不正确']);
}

final class DataWriteException extends AppException {
  const DataWriteException([super.message = '保存失败，请稍后重试']);
}

final class DatabaseUnavailableException extends AppException {
  const DatabaseUnavailableException([super.message = '本地数据暂时不可用']);
}

final class NetworkUnavailableException extends AppException {
  const NetworkUnavailableException([super.message = '网络暂时不可用']);
}

final class RemoteNotFoundException extends AppException {
  const RemoteNotFoundException([super.message = '暂未查询到该商品']);
}

final class RemoteRateLimitedException extends AppException {
  const RemoteRateLimitedException([super.message = '查询过于频繁，请稍后再试']);
}

final class RemoteServiceException extends AppException {
  const RemoteServiceException([super.message = '商品服务暂时不可用']);
}

final class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message = '所需权限未开启']);
}

final class NotificationSchedulingException extends AppException {
  const NotificationSchedulingException([super.message = '提醒设置失败']);
}
