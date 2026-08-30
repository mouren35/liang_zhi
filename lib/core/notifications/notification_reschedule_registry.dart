final class NotificationRescheduleRegistry {
  NotificationRescheduleRegistry._();

  static final NotificationRescheduleRegistry instance = NotificationRescheduleRegistry._();

  Future<void> Function()? _handler;

  void attach(Future<void> Function() handler) {
    _handler = handler;
  }

  void detach(Future<void> Function() handler) {
    if (identical(_handler, handler)) {
      _handler = null;
    }
  }

  Future<void> notifyFoodChanged() async {
    await _handler?.call();
  }
}
