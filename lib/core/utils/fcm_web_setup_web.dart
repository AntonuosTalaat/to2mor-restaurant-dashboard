import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

typedef WebNotificationClickHandler = void Function(Map<String, dynamic> data);

final List<html.Notification> _activeNotifications = [];

String _serviceWorkerUrl() {
  final base = html.document.querySelector('base')?.getAttribute('href') ?? '/';
  var baseHref = base;
  if (!baseHref.endsWith('/')) baseHref += '/';
  return '${baseHref}firebase-messaging-sw.js';
}

String _iconUrl() {
  final base = html.document.querySelector('base')?.getAttribute('href') ?? '/';
  var baseHref = base;
  if (!baseHref.endsWith('/')) baseHref += '/';
  return '${html.window.location.origin}$baseHref' 'favicon.png';
}

String getFcmServiceWorkerPathImpl() => _serviceWorkerUrl();

String getWebNotificationIconUrlImpl() => _iconUrl();

Future<void> _waitForActiveWorker(
  html.ServiceWorkerRegistration registration,
) async {
  if (registration.active != null) return;

  for (var attempt = 0; attempt < 50; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (registration.active != null) return;
  }

  debugPrint('[FcmWebSetup] FCM service worker still inactive');
}

Future<html.ServiceWorkerRegistration?> _fcmRegistration() async {
  final sw = html.window.navigator.serviceWorker;
  if (sw == null) return null;

  final swPath = _serviceWorkerUrl();
  html.ServiceWorkerRegistration? fcmRegistration;

  final registrations = await sw.getRegistrations();
  for (final registration in registrations) {
    final scriptUrl = registration.active?.scriptUrl ??
        registration.installing?.scriptUrl ??
        registration.waiting?.scriptUrl ??
        '';
    if (scriptUrl.contains('firebase-messaging-sw.js')) {
      fcmRegistration = registration;
      break;
    }
  }

  fcmRegistration ??= await sw.register(swPath);
  await _waitForActiveWorker(fcmRegistration);
  return fcmRegistration;
}

Future<void> ensureFcmWebReadyImpl() async {
  final sw = html.window.navigator.serviceWorker;
  if (sw == null) {
    debugPrint('[FcmWebSetup] Service workers not supported');
    return;
  }

  final swUrl = _serviceWorkerUrl();
  debugPrint('[FcmWebSetup] Registering service worker: $swUrl');

  try {
    final registration = await _fcmRegistration();
    debugPrint(
      '[FcmWebSetup] FCM service worker ready: '
      'scope=${registration?.scope} '
      'active=${registration?.active != null}',
    );
  } catch (e, stack) {
    debugPrint('[FcmWebSetup] Service worker registration failed: $e');
    debugPrint('$stack');
  }
}

Future<void> requestBrowserNotificationPermissionImpl() async {
  final current = html.Notification.permission;
  debugPrint('[FcmWebSetup] Browser notification permission: $current');
  if (current == 'granted') return;

  final result = await html.Notification.requestPermission();
  debugPrint('[FcmWebSetup] Browser permission result: $result');
}

Map<String, String> _serializeData(Map<String, dynamic>? data) {
  if (data == null) return const {};
  return data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
}

String _notificationTag(Map<String, String> data) {
  final id = data['orderId'] ??
      data['reportId'] ??
      DateTime.now().millisecondsSinceEpoch.toString();
  return '${data['type'] ?? 'admin'}_$id';
}

Future<void> showWebForegroundNotificationImpl({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  debugPrint('[FcmWebSetup] showWebForegroundNotification title="$title"');

  var permission = html.Notification.permission;
  if (permission != 'granted') {
    permission = await html.Notification.requestPermission();
  }
  if (permission != 'granted') {
    debugPrint('[FcmWebSetup] Cannot show notification, permission=$permission');
    return;
  }

  final payload = _serializeData(data);
  final icon = _iconUrl();
  final tag = _notificationTag(payload);
  var shown = false;

  try {
    final notification = html.Notification(
      title,
      body: body,
      icon: icon,
      tag: tag,
    );
    _activeNotifications.add(notification);
    notification.onClose.listen((_) {
      _activeNotifications.remove(notification);
    });
    shown = true;
    debugPrint('[FcmWebSetup] Shown via Notification API');
  } catch (e, stack) {
    debugPrint('[FcmWebSetup] Notification API failed: $e');
    debugPrint('$stack');
  }

  try {
    final registration = await _fcmRegistration();
    if (registration != null) {
      await registration.showNotification(
        title,
        {
          'body': body,
          'icon': icon,
          'badge': icon,
          'data': payload,
          'tag': tag,
          'renotify': true,
          'requireInteraction': true,
        },
      );
      shown = true;
      debugPrint('[FcmWebSetup] Shown via service worker registration');
    }
  } catch (e, stack) {
    debugPrint('[FcmWebSetup] registration.showNotification failed: $e');
    debugPrint('$stack');
  }

  try {
    final registration = await _fcmRegistration();
    registration?.active?.postMessage({
      'type': 'SHOW_NOTIFICATION',
      'title': title,
      'body': body,
      'data': payload,
      'icon': icon,
      'tag': tag,
    });
  } catch (e, stack) {
    debugPrint('[FcmWebSetup] postMessage to SW failed: $e');
    debugPrint('$stack');
  }

  if (!shown) {
    debugPrint('[FcmWebSetup] Failed to show browser notification');
  }
}

void initWebNotificationClickListenerImpl(
  WebNotificationClickHandler onClick,
) {
  html.window.navigator.serviceWorker?.addEventListener('message', (event) {
    final messageEvent = event as html.MessageEvent;
    final payload = messageEvent.data;

    if (payload is! Map) return;
    if (payload['type'] != 'NOTIFICATION_CLICK') return;

    final rawData = payload['data'];
    if (rawData is Map) {
      onClick(Map<String, dynamic>.from(rawData));
    }
  });
}
