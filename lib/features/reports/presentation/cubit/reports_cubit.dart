import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:restaurantdashboard/features/reports/presentation/cubit/reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit() : super(const ReportsState());

  Future<void> load({
    required OrdersCubit ordersCubit,
    required String restaurantId,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await ordersCubit.fetchOrders(restaurantId);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'فشل تحميل التقارير: $e',
        ),
      );
    }
  }

  void selectDateRange(DateTimeRange range) {
    emit(state.copyWith(selectedDateRange: range));
  }

  void clearDateRange() {
    emit(state.copyWith(clearDateRange: true));
  }

  List<RestaurantOrderModel> filteredOrders(
    List<RestaurantOrderModel> orders,
  ) {
    final range = state.selectedDateRange;
    if (range == null) return orders;

    return orders.where((order) {
      return order.createdAt.isAfter(
            range.start.subtract(const Duration(seconds: 1)),
          ) &&
          order.createdAt.isBefore(
            range.end.add(const Duration(seconds: 1)),
          );
    }).toList();
  }

  Map<String, List<RestaurantOrderModel>> groupOrdersByDate(
    List<RestaurantOrderModel> orders,
  ) {
    final filtered = filteredOrders(orders);
    final groupedOrders = <String, List<RestaurantOrderModel>>{};

    for (final order in filtered) {
      final dateKey = DateFormat('yyyy-MM-dd').format(order.createdAt);
      groupedOrders.putIfAbsent(dateKey, () => []).add(order);
    }

    return groupedOrders;
  }

  List<RestaurantOrderModel> ordersForDate(
    List<RestaurantOrderModel> orders,
    DateTime date,
  ) {
    final filtered = filteredOrders(orders);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    return filtered.where((order) {
      final orderDateKey = DateFormat('yyyy-MM-dd').format(order.createdAt);
      return orderDateKey == dateKey;
    }).toList();
  }

  bool _isCompleted(RestaurantOrderModel order) {
    return ['shipped', 'delivered'].contains(order.currentRestaurantStatus);
  }

  double calculateDayRevenue(List<RestaurantOrderModel> orders) {
    return orders
        .where(_isCompleted)
        .fold(0.0, (sum, order) => sum + order.itemsPrice);
  }

  int countCompletedOrders(List<RestaurantOrderModel> orders) {
    return orders.where(_isCompleted).length;
  }

  double calculateTotalRevenue(List<RestaurantOrderModel> orders) {
    return filteredOrders(orders)
        .where(_isCompleted)
        .fold(0.0, (sum, order) => sum + order.itemsPrice);
  }

  int calculateTotalCompletedOrders(List<RestaurantOrderModel> orders) {
    return filteredOrders(orders).where(_isCompleted).length;
  }
}
