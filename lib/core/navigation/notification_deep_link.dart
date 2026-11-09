/// Deep-link targets from push / inbox notification taps.
sealed class NotificationTarget {
  const NotificationTarget();

  factory NotificationTarget.fromData(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final orderId = data['orderId'] as String?;

    if (orderId != null && orderId.trim().isNotEmpty) {
      switch (type) {
        case 'new_order':
        case 'order_cancelled':
          return NotificationOrderTarget(orderId.trim());
        default:
          return NotificationOrderTarget(orderId.trim());
      }
    }

    switch (type) {
      case 'new_order':
      case 'order_cancelled':
        return const NotificationOrdersListTarget();
      default:
        return const NotificationInboxTarget();
    }
  }
}

class NotificationOrderTarget extends NotificationTarget {
  const NotificationOrderTarget(this.orderId);
  final String orderId;
}

class NotificationOrdersListTarget extends NotificationTarget {
  const NotificationOrdersListTarget();
}

class NotificationInboxTarget extends NotificationTarget {
  const NotificationInboxTarget();
}

/// Queues navigation until [MainScreen] registers a handler (e.g. after login).
class NotificationDeepLink {
  NotificationDeepLink._();

  static NotificationTarget? _pending;
  static void Function(NotificationTarget target)? _handler;

  static void setHandler(void Function(NotificationTarget target)? handler) {
    _handler = handler;
    final pending = _pending;
    if (handler != null && pending != null) {
      _pending = null;
      handler(pending);
    }
  }

  static void navigate(NotificationTarget target) {
    final handler = _handler;
    if (handler != null) {
      handler(target);
    } else {
      _pending = target;
    }
  }

  static void navigateFromData(Map<String, dynamic> data) {
    navigate(NotificationTarget.fromData(data));
  }
}
