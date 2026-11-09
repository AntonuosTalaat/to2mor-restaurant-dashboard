import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/core/navigation/notification_deep_link.dart';
import 'package:restaurantdashboard/core/utils/fcm_web_setup.dart';
import 'package:restaurantdashboard/features/notifications/data/datasources/notification_service.dart';
import 'package:restaurantdashboard/features/notifications/data/models/restaurant_notification_model.dart';

import 'notification_state.dart';

export 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService(),
        super(const NotificationState());

  final NotificationService _notificationService;
  StreamSubscription<List<RestaurantNotificationModel>>?
      _notificationsSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  String? _restaurantId;
  int _foregroundAlertId = 0;

  Future<void> initialize(String restaurantId, {bool force = false}) async {
    if (restaurantId.trim().isEmpty) {
      debugPrint(
        '[NotificationCubit] Cannot initialize with empty restaurantId',
      );
      return;
    }

    if (!force && _restaurantId == restaurantId && state.isInitialized) {
      return;
    }

    _restaurantId = restaurantId;
    emit(state.copyWith(isLoading: true, clearError: true));

    await _notificationsSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();

    try {
      await _notificationService.initializeForRestaurant(
        restaurantId,
        force: force,
      );
      _listenToNotifications(restaurantId);
      _listenToPushMessages();
      if (kIsWeb) {
        initWebNotificationClickListener(_handleRemoteMessageData);
      }

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageData(initialMessage.data);
      }

      emit(state.copyWith(isInitialized: true, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'فشل في تهيئة الإشعارات: $e',
        ),
      );
    }
  }

  void _listenToNotifications(String restaurantId) {
    _notificationsSubscription = _notificationService
        .watchNotifications(restaurantId)
        .listen(
          (notifications) {
            emit(
              state.copyWith(
                notifications: notifications,
                isInitialized: true,
              ),
            );
          },
          onError: (Object error) {
            emit(
              state.copyWith(
                errorMessage: 'فشل في تحميل الإشعارات: $error',
              ),
            );
          },
        );
  }

  void _listenToPushMessages() {
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[NotificationCubit] Foreground message: ${message.data}');
      unawaited(_showForegroundNotification(message));
    });

    _openedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessageData(message.data);
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title'] as String? ??
        'إشعار جديد';
    final body = message.notification?.body ??
        message.data['body'] as String? ??
        '';

    if (kIsWeb) {
      try {
        await showWebForegroundNotification(
          title: title,
          body: body,
          data: Map<String, dynamic>.from(message.data),
        );
      } catch (e, stack) {
        debugPrint('[NotificationCubit] Web notification show failed: $e');
        debugPrint('$stack');
      }
    }

    emit(
      state.copyWith(
        foregroundAlert: ForegroundPushAlert(
          id: ++_foregroundAlertId,
          title: title,
          body: body,
          data: Map<String, dynamic>.from(message.data),
        ),
      ),
    );
  }

  void clearForegroundAlert() {
    if (state.foregroundAlert == null) return;
    emit(state.copyWith(clearForegroundAlert: true));
  }

  void _handleRemoteMessageData(Map<String, dynamic> data) {
    NotificationDeepLink.navigateFromData(data);
  }

  Future<void> markAsRead(String notificationId) async {
    final restaurantId = _restaurantId;
    if (restaurantId == null) return;
    await _notificationService.markAsRead(restaurantId, notificationId);
  }

  Future<void> markAllAsRead() async {
    final restaurantId = _restaurantId;
    if (restaurantId == null) return;
    await _notificationService.markAllAsRead(restaurantId);
  }

  Future<void> deleteNotification(String notificationId) async {
    final restaurantId = _restaurantId;
    if (restaurantId == null) return;
    await _notificationService.deleteNotification(
      restaurantId,
      notificationId,
    );
  }

  Future<void> deleteNotifications(List<String> notificationIds) async {
    final restaurantId = _restaurantId;
    if (restaurantId == null || notificationIds.isEmpty) return;
    await _notificationService.deleteNotifications(
      restaurantId,
      notificationIds,
    );
  }

  Future<void> deleteAllNotifications() async {
    final restaurantId = _restaurantId;
    if (restaurantId == null) return;
    await _notificationService.deleteAllNotifications(restaurantId);
  }

  void handleNotificationTap(RestaurantNotificationModel notification) {
    unawaited(markAsRead(notification.id));

    final data = <String, dynamic>{
      'type': notification.type.value,
      if (notification.orderId != null) 'orderId': notification.orderId,
      'title': notification.title,
      'body': notification.body,
    };
    NotificationDeepLink.navigateFromData(data);
  }

  Future<void> disposeForLogout() async {
    final restaurantId = _restaurantId;
    if (restaurantId != null) {
      await _notificationService.clearTokenForRestaurant(restaurantId);
      await _notificationService.disposeForRestaurant();
    }

    await _notificationsSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _notificationsSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _restaurantId = null;
    emit(const NotificationState());
  }

  @override
  Future<void> close() async {
    await _notificationsSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _notificationService.disposeForRestaurant();
    return super.close();
  }
}
