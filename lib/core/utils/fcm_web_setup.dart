import 'fcm_web_setup_stub.dart'
    if (dart.library.html) 'fcm_web_setup_web.dart';

export 'fcm_web_setup_stub.dart' show WebNotificationClickHandler;

Future<void> ensureFcmWebReady() => ensureFcmWebReadyImpl();

Future<void> requestBrowserNotificationPermission() =>
    requestBrowserNotificationPermissionImpl();

Future<void> showWebForegroundNotification({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) =>
    showWebForegroundNotificationImpl(
      title: title,
      body: body,
      data: data,
    );

void initWebNotificationClickListener(WebNotificationClickHandler onClick) =>
    initWebNotificationClickListenerImpl(onClick);

String webNotificationIconUrl() => getWebNotificationIconUrlImpl();

String fcmServiceWorkerPath() => getFcmServiceWorkerPathImpl();
