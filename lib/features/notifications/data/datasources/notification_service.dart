import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurantdashboard/config/fcm_config.dart';
import 'package:restaurantdashboard/core/utils/fcm_web_setup.dart';
import 'package:restaurantdashboard/features/notifications/data/models/restaurant_notification_model.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  static const String restaurantsCollection = 'restaurants';
  static const String notificationsSubcollection = 'notifications';

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _activeRestaurantId;
  String? _lastSavedToken;

  Future<void> initializeForRestaurant(
    String restaurantId, {
    bool force = false,
  }) async {
    if (restaurantId.trim().isEmpty) {
      debugPrint('[NotificationService] Skipping init: empty restaurantId');
      return;
    }

    if (!force &&
        _activeRestaurantId == restaurantId &&
        _lastSavedToken != null) {
      return;
    }

    _activeRestaurantId = restaurantId;

    final permissionGranted = await _requestPermission();
    debugPrint('[NotificationService] Permission granted: $permissionGranted');

    if (!permissionGranted && !kIsWeb) {
      debugPrint('[NotificationService] Notification permission denied');
    }

    if (kIsWeb) {
      await ensureFcmWebReady();
      await requestBrowserNotificationPermission();
    }

    await _saveCurrentToken(restaurantId);
    await _listenToTokenRefresh(restaurantId);
    _configureForegroundPresentation();
  }

  Future<void> disposeForRestaurant() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _activeRestaurantId = null;
    _lastSavedToken = null;
  }

  Future<void> clearTokenForRestaurant(String restaurantId) async {
    if (restaurantId.trim().isEmpty) return;

    try {
      await _firestore.collection(restaurantsCollection).doc(restaurantId).set(
        {
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _lastSavedToken = null;
      debugPrint(
        '[NotificationService] FCM token cleared for restaurant $restaurantId',
      );
    } catch (e, stack) {
      debugPrint('[NotificationService] Failed to clear token: $e');
      debugPrint('$stack');
    }
  }

  Stream<List<RestaurantNotificationModel>> watchNotifications(
    String restaurantId,
  ) {
    return _firestore
        .collection(restaurantsCollection)
        .doc(restaurantId)
        .collection(notificationsSubcollection)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RestaurantNotificationModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> markAsRead(String restaurantId, String notificationId) async {
    await _firestore
        .collection(restaurantsCollection)
        .doc(restaurantId)
        .collection(notificationsSubcollection)
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead(String restaurantId) async {
    final unread = await _firestore
        .collection(restaurantsCollection)
        .doc(restaurantId)
        .collection(notificationsSubcollection)
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(
    String restaurantId,
    String notificationId,
  ) async {
    await _firestore
        .collection(restaurantsCollection)
        .doc(restaurantId)
        .collection(notificationsSubcollection)
        .doc(notificationId)
        .delete();
  }

  Future<void> deleteNotifications(
    String restaurantId,
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) return;

    final batch = _firestore.batch();
    for (final id in notificationIds) {
      batch.delete(
        _firestore
            .collection(restaurantsCollection)
            .doc(restaurantId)
            .collection(notificationsSubcollection)
            .doc(id),
      );
    }
    await batch.commit();
  }

  Future<void> deleteAllNotifications(String restaurantId) async {
    final snapshot = await _firestore
        .collection(restaurantsCollection)
        .doc(restaurantId)
        .collection(notificationsSubcollection)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<bool> _requestPermission() async {
    if (kIsWeb) {
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint(
          '[NotificationService] Android notification status: $status',
        );
      }
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _saveCurrentToken(String restaurantId) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final token = await _getToken();
        if (token == null || token.isEmpty) {
          debugPrint(
            '[NotificationService] No FCM token (attempt $attempt/3)',
          );
          if (attempt < 3) {
            await Future<void>.delayed(Duration(seconds: attempt));
            continue;
          }
          return;
        }

        if (_lastSavedToken == token && _activeRestaurantId == restaurantId) {
          debugPrint('[NotificationService] Token unchanged, skip save');
          return;
        }

        await _firestore
            .collection(restaurantsCollection)
            .doc(restaurantId)
            .set(
          {
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        _lastSavedToken = token;
        debugPrint(
          '[NotificationService] FCM token saved for restaurant $restaurantId '
          '(${token.substring(0, 20)}...)',
        );
        return;
      } catch (e, stack) {
        debugPrint(
          '[NotificationService] Failed to save token (attempt $attempt/3): $e',
        );
        debugPrint('$stack');
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: attempt));
        }
      }
    }
  }

  Future<String?> _getToken() async {
    if (kIsWeb) {
      await ensureFcmWebReady();
      return _messaging.getToken(
        vapidKey: kFcmWebVapidKey,
        serviceWorkerScriptPath: fcmServiceWorkerPath(),
      );
    }
    return _messaging.getToken();
  }

  Future<void> _listenToTokenRefresh(String restaurantId) async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      try {
        await _firestore
            .collection(restaurantsCollection)
            .doc(restaurantId)
            .set(
          {
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        _lastSavedToken = token;
        debugPrint(
          '[NotificationService] FCM token refreshed for $restaurantId',
        );
      } catch (e, stack) {
        debugPrint('[NotificationService] Failed to refresh token: $e');
        debugPrint('$stack');
      }
    });
  }

  void _configureForegroundPresentation() {
    if (kIsWeb) return;
    unawaited(
      _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      ),
    );
  }
}
