import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/data/utils/restaurant_line_price.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  Future<void> load({
    required RestaurantProvider restaurantProvider,
    required OrdersCubit ordersCubit,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await restaurantProvider.fetchRestaurantData();
      final restaurantId = restaurantProvider.restaurant?.ownerId ?? '';
      await ordersCubit.fetchOrders(restaurantId);
      restaurantProvider.setupEarningsListener();

      emit(
        state.copyWith(
          isLoading: false,
          restaurantId: restaurantId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'فشل تحميل لوحة التحكم: $e',
        ),
      );
    }
  }

  void selectPeriod(String period) {
    if (period == state.selectedPeriod) return;
    emit(state.copyWith(selectedPeriod: period));
  }

  Map<String, DateTime?> dateRangeFor(String period) {
    final now = DateTime.now();

    switch (period) {
      case 'اليوم':
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return {'start': startOfDay, 'end': endOfDay};
      case 'الأسبوع':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        return {'start': startOfWeekDate, 'end': now};
      case 'الشهر':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return {'start': startOfMonth, 'end': now};
      default:
        return {'start': null, 'end': null};
    }
  }

  Map<String, dynamic> calculateFilteredData({
    required List<RestaurantOrderModel> orders,
    required Restaurant? restaurant,
    required double wallet,
    required String formattedTotalEarnings,
    required String formattedLastEarningsUpdate,
    String? period,
  }) {
    final dateRange = dateRangeFor(period ?? state.selectedPeriod);

    final filteredShippedOrders =
        orders.where((order) {
          if (order.currentRestaurantStatus != 'shipped' &&
              order.currentRestaurantStatus != 'delivered') {
            return false;
          }

          if (dateRange['start'] == null || dateRange['end'] == null) {
            return true;
          }

          final orderDate = order.createdAt;
          return orderDate.isAfter(dateRange['start']!) &&
              orderDate.isBefore(dateRange['end']!);
        }).toList();

    final filteredAllOrders =
        orders.where((order) {
          if (dateRange['start'] == null || dateRange['end'] == null) {
            return true;
          }

          final orderDate = order.createdAt;
          return orderDate.isAfter(dateRange['start']!) &&
              orderDate.isBefore(dateRange['end']!);
        }).toList();

    final totalSales = filteredShippedOrders.fold<double>(
      0.0,
      (sum, order) => sum + order.itemsPrice,
    );

    final totalOrders = filteredAllOrders.length;
    final completedCount = filteredShippedOrders.length;
    final totalMenuItems = restaurant?.menu.length ?? 0;
    final averageOrderValue =
        completedCount == 0 ? 0.0 : totalSales / completedCount;

    var pendingCount = 0;
    var preparingCount = 0;
    var readyCount = 0;
    var cancelledCount = 0;
    var deliveryCount = 0;
    var pickupCount = 0;

    for (final order in filteredAllOrders) {
      switch (order.currentRestaurantStatus) {
        case 'pending':
          pendingCount++;
        case 'preparing':
          preparingCount++;
        case 'ready':
          readyCount++;
        case 'cancelled':
          cancelledCount++;
      }
      if (order.isPickup) {
        pickupCount++;
      } else {
        deliveryCount++;
      }
    }

    final activeOrders =
        filteredAllOrders
            .where(
              (order) => const {
                'pending',
                'preparing',
                'ready',
              }.contains(order.currentRestaurantStatus),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Map<String, Map<String, dynamic>> itemSales = {};

    for (final order in filteredShippedOrders) {
      for (final item in order.items) {
        final itemData = item['item'] as Map<String, dynamic>?;
        if (itemData == null) continue;

        final itemName = itemData['name'] as String? ?? 'Unknown';
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final totalPrice = RestaurantLinePrice.totalOf(item);

        if (itemSales.containsKey(itemName)) {
          itemSales[itemName]!['quantity'] += quantity;
          itemSales[itemName]!['revenue'] += totalPrice;
        } else {
          itemSales[itemName] = {
            'quantity': quantity,
            'revenue': totalPrice,
            'name': itemName,
          };
        }
      }
    }

    var topItems =
        itemSales.values.toList()..sort(
          (a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int),
        );
    topItems = topItems.take(5).toList();

    final Map<String, double> dailyRevenue = {};
    for (final order in filteredShippedOrders) {
      final dateKey = '${order.createdAt.day}/${order.createdAt.month}';
      dailyRevenue[dateKey] =
          (dailyRevenue[dateKey] ?? 0.0) + order.itemsPrice;
    }

    final completionRate =
        totalOrders == 0 ? 0.0 : (completedCount / totalOrders) * 100;

    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'totalMenuItems': totalMenuItems,
      'topItems': topItems,
      'dailyRevenue': dailyRevenue,
      'shippedOrdersCount': completedCount,
      'averageOrderValue': averageOrderValue,
      'completionRate': completionRate,
      'pendingCount': pendingCount,
      'preparingCount': preparingCount,
      'readyCount': readyCount,
      'cancelledCount': cancelledCount,
      'deliveryCount': deliveryCount,
      'pickupCount': pickupCount,
      'activeOrders': activeOrders.take(5).toList(),
      'wallet': wallet,
      'formattedTotalEarnings': formattedTotalEarnings,
      'formattedLastEarningsUpdate': formattedLastEarningsUpdate,
    };
  }
}
