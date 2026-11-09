import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:restaurantdashboard/features/orders/data/models/DeliveryModel.dart';
import 'package:restaurantdashboard/features/orders/data/utils/restaurant_line_price.dart';

enum OrderType { delivery, pickup }

/// نسخة معدّلة: تدعم سطور `lineType: restaurant_extra` بالإضافة إلى أصناف `dish`.
/// انسخ الملف إلى مشروع الـ dashboard عند `Models/RestaurantOrderModel.dart` (مع مسار import لـ DeliveryModel الصحيح).
class RestaurantOrderModel {
  final String id;
  final String userId;
  final List<String> restaurantIds;
  final Map<String, String> restaurantStatuses;
  final List<Map<String, dynamic>> items;
  final double itemsPrice;
  final double voucherShare;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;
  final String generalStatus;
  final String? orderComment;
  final String currentRestaurantId;
  final DeliveryModel? delivery;
  final OrderType orderType;
  final String? deliveryAddress;

  RestaurantOrderModel({
    this.id = '',
    required this.userId,
    required this.restaurantIds,
    required this.restaurantStatuses,
    required this.items,
    required this.itemsPrice,
    this.voucherShare = 0,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.generalStatus,
    this.orderComment,
    this.delivery,
    required this.currentRestaurantId,
    this.orderType = OrderType.delivery,
    this.deliveryAddress,
  });

  String get currentRestaurantStatus {
    return restaurantStatuses[currentRestaurantId] ?? 'pending';
  }

  bool get isDelivery => orderType == OrderType.delivery;
  bool get isPickup => orderType == OrderType.pickup;

  String get finalStatusForOrderType {
    return isPickup ? 'delivered' : 'shipped';
  }

  String get finalStatusDisplayText {
    return isPickup ? 'تم الاستلام' : 'تم الشحن';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantIds': restaurantIds,
      'restaurantStatuses': restaurantStatuses,
      'items': items,
      'itemsPrice': itemsPrice,
      'total': total,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'generalStatus': generalStatus,
      'orderComment': orderComment,
      'currentRestaurantId': currentRestaurantId,
      'delivery': delivery?.toMap(),
      'orderType': orderType.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
    };
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  factory RestaurantOrderModel.fromMap(
    Map<String, dynamic> data,
    String id, {
    required String currentRestaurantId,
  }) {
    try {
      if (currentRestaurantId.isEmpty) {
        throw Exception(
          'Current restaurant ID is required and cannot be empty',
        );
      }

      DateTime parsedCreatedAt = DateTime.now();
      final createdAtRaw = data['createdAt'];

      if (createdAtRaw != null) {
        try {
          if (createdAtRaw is String) {
            parsedCreatedAt = DateTime.parse(createdAtRaw);
          } else if (createdAtRaw is Timestamp) {
            parsedCreatedAt = createdAtRaw.toDate();
          }
        } catch (e) {
          // Use default DateTime.now()
        }
      }

      final restaurantIds =
          data['restaurantIds'] != null
              ? List<String>.from(data['restaurantIds'])
              : <String>[];

      final restaurantStatuses =
          data['restaurantStatuses'] != null
              ? Map<String, String>.from(data['restaurantStatuses'])
              : <String, String>{};

      final orderTypeString = data['orderType']?.toString() ?? 'delivery';
      final orderType =
          orderTypeString == 'pickup' ? OrderType.pickup : OrderType.delivery;
      final deliveryAddress = data['deliveryAddress']?.toString();

      final List<dynamic> allItems =
          (data['items'] as List<dynamic>?) ?? <dynamic>[];
      final filteredItems = <Map<String, dynamic>>[];
      double restaurantItemsPrice = 0.0;

      for (final raw in allItems) {
        final line = _asStringKeyedMap(raw);
        if (line == null) continue;

        final lineType = line['lineType'] as String? ?? 'dish';

        if (lineType == 'restaurant_extra') {
          final rid = line['restaurantId']?.toString() ?? '';
          if (rid != currentRestaurantId) continue;

          restaurantItemsPrice += RestaurantLinePrice.totalOf(line);
          filteredItems.add(Map<String, dynamic>.from(line));
          continue;
        }

        if (!line.containsKey('item')) continue;

        final itemData = _asStringKeyedMap(line['item']);
        if (itemData == null) continue;

        final itemRestaurantId = itemData['restaurantId']?.toString() ?? '';
        if (itemRestaurantId != currentRestaurantId) continue;

        restaurantItemsPrice += RestaurantLinePrice.totalOf(line);
        filteredItems.add(Map<String, dynamic>.from(line));
      }

      final voucherDiscount = (data['voucherDiscount'] as num?)?.toDouble() ?? 0;
      final voucherType = data['voucherType']?.toString();
      final pricing = _asStringKeyedMap(data['pricingSnapshot']);
      final customerItemsPrice =
          (pricing?['customerItemsPrice'] as num?)?.toDouble() ?? 0;
      final voucherShare = restaurantVoucherShare(
        restaurantGross: restaurantItemsPrice,
        voucherDiscount: voucherDiscount,
        voucherType: voucherType,
        customerItemsPrice: customerItemsPrice,
      );
      final netItemsPrice = (restaurantItemsPrice - voucherShare)
          .clamp(0.0, double.infinity);

      final userId = data['userId']?.toString() ?? '';
      final paymentMethod = data['paymentMethod']?.toString() ?? 'Cash';
      final generalStatus = data['generalStatus']?.toString() ?? 'pending';
      final orderComment = data['orderComment']?.toString();
      final finalOrderComment =
          (orderComment == null || orderComment.isEmpty) ? null : orderComment;

      return RestaurantOrderModel(
        id: id,
        userId: userId,
        restaurantIds: restaurantIds,
        restaurantStatuses: restaurantStatuses,
        items: filteredItems,
        itemsPrice: netItemsPrice,
        voucherShare: voucherShare,
        total: netItemsPrice,
        paymentMethod: paymentMethod,
        createdAt: parsedCreatedAt,
        generalStatus: generalStatus,
        orderComment: finalOrderComment,
        currentRestaurantId: currentRestaurantId,
        orderType: orderType,
        deliveryAddress: deliveryAddress,
      );
    } catch (e, stackTrace) {
      throw Exception('Error parsing RestaurantOrderModel: $e\n$stackTrace');
    }
  }

  RestaurantOrderModel copyWith({
    String? id,
    String? userId,
    List<String>? restaurantIds,
    Map<String, String>? restaurantStatuses,
    List<Map<String, dynamic>>? items,
    double? itemsPrice,
    double? voucherShare,
    double? total,
    String? paymentMethod,
    DateTime? createdAt,
    String? generalStatus,
    String? orderComment,
    String? currentRestaurantId,
    DeliveryModel? delivery,
    OrderType? orderType,
    String? deliveryAddress,
  }) {
    return RestaurantOrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantIds: restaurantIds ?? this.restaurantIds,
      restaurantStatuses: restaurantStatuses ?? this.restaurantStatuses,
      items: items ?? this.items,
      itemsPrice: itemsPrice ?? this.itemsPrice,
      voucherShare: voucherShare ?? this.voucherShare,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      generalStatus: generalStatus ?? this.generalStatus,
      orderComment: orderComment ?? this.orderComment,
      delivery: delivery ?? this.delivery,
      currentRestaurantId: currentRestaurantId ?? this.currentRestaurantId,
      orderType: orderType ?? this.orderType,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}
