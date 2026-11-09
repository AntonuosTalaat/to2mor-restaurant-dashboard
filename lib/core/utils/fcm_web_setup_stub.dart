typedef WebNotificationClickHandler = void Function(Map<String, dynamic> data);

Future<void> ensureFcmWebReadyImpl() async {}

Future<void> requestBrowserNotificationPermissionImpl() async {}

Future<void> showWebForegroundNotificationImpl({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {}

void initWebNotificationClickListenerImpl(
  WebNotificationClickHandler onClick,
) {}

String getWebNotificationIconUrlImpl() => 'favicon.png';

String getFcmServiceWorkerPathImpl() => '/firebase-messaging-sw.js';
