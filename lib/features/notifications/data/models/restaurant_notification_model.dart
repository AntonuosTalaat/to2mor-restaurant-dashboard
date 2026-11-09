import 'package:cloud_firestore/cloud_firestore.dart';

enum RestaurantNotificationType {
  newOrder('new_order'),
  orderCancelled('order_cancelled'),
  unknown('unknown');

  const RestaurantNotificationType(this.value);
  final String value;

  static RestaurantNotificationType fromString(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return RestaurantNotificationType.values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => RestaurantNotificationType.unknown,
    );
  }
}

class RestaurantNotificationModel {
  const RestaurantNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.read = false,
  });

  final String id;
  final RestaurantNotificationType type;
  final String title;
  final String body;
  final String? orderId;
  final bool read;
  final DateTime createdAt;

  factory RestaurantNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAtRaw = data['createdAt'];

    DateTime createdAt = DateTime.now();
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    }

    return RestaurantNotificationModel(
      id: doc.id,
      type: RestaurantNotificationType.fromString(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      orderId: data['orderId'] as String?,
      read: data['read'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  RestaurantNotificationModel copyWith({bool? read}) {
    return RestaurantNotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
