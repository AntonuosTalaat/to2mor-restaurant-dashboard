import 'package:restaurantdashboard/features/notifications/data/models/restaurant_notification_model.dart';

class ForegroundPushAlert {
  const ForegroundPushAlert({
    required this.id,
    required this.title,
    required this.body,
    this.data = const {},
  });

  final int id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
}

class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isInitialized = false,
    this.isLoading = false,
    this.errorMessage,
    this.foregroundAlert,
  });

  final List<RestaurantNotificationModel> notifications;
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;
  final ForegroundPushAlert? foregroundAlert;

  int get unreadCount => notifications.where((n) => !n.read).length;

  NotificationState copyWith({
    List<RestaurantNotificationModel>? notifications,
    bool? isInitialized,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    ForegroundPushAlert? foregroundAlert,
    bool clearForegroundAlert = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      foregroundAlert: clearForegroundAlert
          ? null
          : (foregroundAlert ?? this.foregroundAlert),
    );
  }
}
