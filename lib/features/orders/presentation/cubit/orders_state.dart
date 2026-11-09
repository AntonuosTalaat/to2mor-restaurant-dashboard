import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';

class OrdersState {
  final List<RestaurantOrderModel> orders;
  final bool isLoading;
  final String? error;
  final String? currentRestaurantId;
  final bool isInitialized;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.currentRestaurantId,
    this.isInitialized = false,
  });

  OrdersState copyWith({
    List<RestaurantOrderModel>? orders,
    bool? isLoading,
    String? error,
    String? currentRestaurantId,
    bool? isInitialized,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentRestaurantId: currentRestaurantId ?? this.currentRestaurantId,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
