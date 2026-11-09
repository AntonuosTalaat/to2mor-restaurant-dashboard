import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';

class OrdersService {
  final FirebaseFirestore _firestore;

  OrdersService({required FirebaseFirestore firestore}) : _firestore = firestore;

  /// Get all orders for a specific restaurant
  Future<List<RestaurantOrderModel>> getOrdersForRestaurant(
    String restaurantId,
  ) async {
    try {
      // First, try the query with orderBy
      QuerySnapshot querySnapshot;
      try {
        querySnapshot =
            await _firestore
                .collection('orders')
                .where('restaurantIds', arrayContains: restaurantId)
                .orderBy('createdAt', descending: true)
                .get();
      } catch (indexError) {
        // If index error, try without orderBy
        querySnapshot =
            await _firestore
                .collection('orders')
                .where('restaurantIds', arrayContains: restaurantId)
                .get();
      }

      final orders = <RestaurantOrderModel>[];
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        try {
          final doc = querySnapshot.docs[i];

          final data = doc.data() as Map<String, dynamic>;

          // ✅ FIXED: Pass currentRestaurantId as parameter
          final order = RestaurantOrderModel.fromMap(
            data,
            doc.id,
            currentRestaurantId: restaurantId, // ✅ Pass as parameter
          );

          orders.add(order);
        } catch (e) {
          print(
            '❌ [OrdersService] Error processing document ',
          );
          // Continue with other documents
        }
      }

      // Sort manually if we couldn't use orderBy
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      print('❌ [OrdersService] Error type}');
      rethrow;
    }
  }

  /// Update order status for a restaurant with generalStatus logic
  Future<void> updateOrderStatus({
    required String orderId,
    required String restaurantId,
    required String newStatus,
  }) async {
    try {
      final docRef = _firestore.collection('orders').doc(orderId);

      // Get current order data to calculate new generalStatus
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Order $orderId not found');
      }

      final currentData = docSnapshot.data() as Map<String, dynamic>;
      final restaurantStatuses = Map<String, String>.from(
        currentData['restaurantStatuses'] ?? {},
      );
      final restaurantIds = List<String>.from(
        currentData['restaurantIds'] ?? [],
      );

      // Update the specific restaurant status
      restaurantStatuses[restaurantId] = newStatus;

      // Calculate new general status
      final newGeneralStatus = _calculateGeneralStatus(
        restaurantStatuses,
        restaurantIds,
      );

      // ✅ FIXED: Split the update into two separate operations to avoid permission issues
      try {
        // First update the restaurant status
        await docRef.update({'restaurantStatuses.$restaurantId': newStatus});

        // Then update the general status
        await docRef.update({'generalStatus': newGeneralStatus});
      } catch (permissionError) {
        await docRef.update({'restaurantStatuses.$restaurantId': newStatus});
      }
    } catch (e) {
      print('❌ [OrdersService] Failed to update order');
      rethrow;
    }
  }

  /// Calculate general status based on all restaurant statuses
  String _calculateGeneralStatus(
    Map<String, String> restaurantStatuses,
    List<String> restaurantIds,
  ) {
    // Status priority order (lowest to highest)
    const statusPriority = {
      'cancelled': 0,
      'pending': 1,
      'preparing': 2,
      'ready': 3,
      'shipped': 4,
    };

    // Get all statuses for restaurants that exist in the order
    final activeStatuses = <String>[];
    for (final restaurantId in restaurantIds) {
      final status = restaurantStatuses[restaurantId] ?? 'pending';
      activeStatuses.add(status);
    }

    if (activeStatuses.isEmpty) {
      return 'pending';
    }

    // Check if any restaurant is cancelled
    if (activeStatuses.contains('cancelled')) {
      return 'cancelled';
    }

    // Check if all restaurants have the same status
    final uniqueStatuses = activeStatuses.toSet();
    if (uniqueStatuses.length == 1) {
      final singleStatus = uniqueStatuses.first;
      return singleStatus;
    }

    // If mixed statuses, return the lowest priority (earliest stage)
    int lowestPriority = statusPriority.values.reduce((a, b) => a > b ? a : b);
    String generalStatus = 'pending';

    for (final status in activeStatuses) {
      final priority = statusPriority[status] ?? 1;
      if (priority < lowestPriority) {
        lowestPriority = priority;
        generalStatus = status;
      }
    }

    return generalStatus;
  }

  /// Listen to real-time updates for restaurant orders
  Stream<List<RestaurantOrderModel>> listenToOrders(String restaurantId) {
    // Start with simple query without orderBy to avoid index issues
    final stream =
    _firestore
        .collection('orders')
        .where('restaurantIds', arrayContains: restaurantId)
        .where('generalStatus', whereIn: [
      'pending',
      'preparing',
      'ready',
      'shipped',
      'delivered',
    ])
        .snapshots();

    return stream
        .map((snapshot) {
          final orders = <RestaurantOrderModel>[];
          for (int i = 0; i < snapshot.docs.length; i++) {
            try {
              final doc = snapshot.docs[i];

              final data = doc.data() as Map<String, dynamic>;

              // ✅ FIXED: Pass currentRestaurantId as parameter
              final order = RestaurantOrderModel.fromMap(
                data,
                doc.id,
                currentRestaurantId: restaurantId, // ✅ Pass as parameter
              );

              orders.add(order);
            } catch (e) {
              print(
                '❌ [OrdersService] Stream error processing document ',
              );
              // Continue with other documents
            }
          }

          // Sort manually by createdAt (newest first)
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return orders;
        })
        .handleError((error) {
          print('❌ [OrdersService] Error type');

          // Check if it's an index error
          if (error.toString().contains('failed-precondition')) {
            print(
              '🔧 [OrdersService] This is a Firebase index error - the app should still work without orderBy',
            );
          }

          throw error;
        });
  }

  /// Helper method to get order details for debugging
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ [OrdersService] Error getting order details');
      return null;
    }
  }

  Future<RestaurantOrderModel?> getOrderById(
    String orderId,
    String restaurantId,
  ) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return RestaurantOrderModel.fromMap(
        doc.data()!,
        doc.id,
        currentRestaurantId: restaurantId,
      );
    } catch (e) {
      print('❌ [OrdersService] Error getting order by id');
      return null;
    }
  }

  /// Utility method to check and fix general status for existing orders
  Future<void> fixGeneralStatusForAllOrders() async {
    try {
      final querySnapshot = await _firestore.collection('orders').get();

      int fixed = 0;
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final restaurantStatuses = Map<String, String>.from(
            data['restaurantStatuses'] ?? {},
          );
          final restaurantIds = List<String>.from(data['restaurantIds'] ?? []);
          final currentGeneralStatus = data['generalStatus'] ?? 'pending';

          final correctGeneralStatus = _calculateGeneralStatus(
            restaurantStatuses,
            restaurantIds,
          );

          if (currentGeneralStatus != correctGeneralStatus) {
            await doc.reference.update({'generalStatus': correctGeneralStatus});
            fixed++;
          }
        } catch (e) {
          print('❌ [OrdersService] Error fixing order ');
        }
      }
    } catch (e) {
      print('❌ [OrdersService] Error in fixGeneralStatusForAllOrders');
      rethrow;
    }
  }
}
