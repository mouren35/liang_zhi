final class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance = NotificationNavigationService._();

  void Function(String route)? _handler;
  String? _pendingRoute;

  void handlePayload(String payload) {
    if (payload != '/expirations') {
      return;
    }
    final void Function(String route)? handler = _handler;
    if (handler == null) {
      _pendingRoute = payload;
      return;
    }
    handler(payload);
  }

  void attach(void Function(String route) handler) {
    _handler = handler;
    final String? pendingRoute = _pendingRoute;
    _pendingRoute = null;
    if (pendingRoute != null) {
      handler(pendingRoute);
    }
  }

  void detach(void Function(String route) handler) {
    if (identical(_handler, handler)) {
      _handler = null;
    }
  }
}
