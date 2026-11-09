import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/features/orders/data/datasources/OrdersService.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrdersService _ordersService;
  StreamSubscription<List<RestaurantOrderModel>>? _ordersSubscription;

  OrdersCubit(this._ordersService) : super(const OrdersState());

  Future<void> initialize(String restaurantId) async {
    if (state.currentRestaurantId == restaurantId && state.isInitialized) {
      return;
    }

    await _ordersSubscription?.cancel();
    emit(
      state.copyWith(
        currentRestaurantId: restaurantId,
        isInitialized: false,
        clearError: true,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      listenToOrders(restaurantId);
      emit(state.copyWith(isInitialized: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> fetchOrders(String restaurantId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final orders = await _ordersService.getOrdersForRestaurant(restaurantId);
      emit(
        state.copyWith(
          orders: orders,
          isLoading: false,
          currentRestaurantId: restaurantId,
          clearError: true,
        ),
      );
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        emit(
          state.copyWith(
            orders: const [],
            isLoading: false,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            orders: const [],
            isLoading: false,
            error: e.toString(),
          ),
        );
      }
    }
  }

  void listenToOrders(String restaurantId) {
    _ordersSubscription?.cancel();

    emit(
      state.copyWith(
        isLoading: true,
        currentRestaurantId: restaurantId,
        clearError: true,
      ),
    );

    try {
      _ordersSubscription = _ordersService.listenToOrders(restaurantId).listen(
        (orders) {
          emit(
            state.copyWith(
              orders: orders,
              isLoading: false,
              clearError: true,
            ),
          );
        },
        onError: (e) {
          if (e.toString().contains('permission-denied')) {
            emit(
              state.copyWith(
                orders: const [],
                isLoading: false,
                clearError: true,
              ),
            );
          } else {
            emit(
              state.copyWith(
                orders: const [],
                isLoading: false,
                error: e.toString(),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        emit(
          state.copyWith(
            orders: const [],
            isLoading: false,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            orders: const [],
            isLoading: false,
            error: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String restaurantId,
    String newStatus,
  ) async {
    try {
      await _ordersService.updateOrderStatus(
        orderId: orderId,
        restaurantId: restaurantId,
        newStatus: newStatus,
      );

      emit(state.copyWith(clearError: true));

      if (_ordersSubscription == null) {
        await fetchOrders(restaurantId);
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void reset() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    emit(const OrdersState());
  }

  Map<String, int> getOrdersStatistics() {
    final stats = <String, int>{
      'pending': 0,
      'preparing': 0,
      'ready': 0,
      'shipped': 0,
      'cancelled': 0,
    };

    for (final order in state.orders) {
      final status = order.currentRestaurantStatus;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  double getRevenue() {
    return state.orders
        .where((order) => order.currentRestaurantStatus == 'shipped')
        .fold(0.0, (sum, order) => sum + order.itemsPrice);
  }

  List<RestaurantOrderModel> getOrdersByGeneralStatus(String generalStatus) {
    return state.orders
        .where((order) => order.generalStatus == generalStatus)
        .toList();
  }

  bool isOrderComplete(RestaurantOrderModel order) {
    final statuses = order.restaurantStatuses.values.toList();
    return statuses.every(
      (status) => status == 'shipped' || status == 'cancelled',
    );
  }

  List<Map<String, String>> getNextStatusOptions(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return [
          {
            'status': 'preparing',
            'title': 'قيد التنفيذ',
            'description': 'بدء تحضير الطلب',
          },
          {
            'status': 'cancelled',
            'title': 'إلغاء الطلب',
            'description': 'إلغاء الطلب نهائياً',
          },
        ];
      case 'preparing':
        return [
          {
            'status': 'ready',
            'title': 'جاهز للتسليم',
            'description': 'الطلب جاهز للتسليم',
          },
          {
            'status': 'cancelled',
            'title': 'إلغاء الطلب',
            'description': 'إلغاء الطلب نهائياً',
          },
        ];
      case 'ready':
        return [
          {
            'status': 'shipped',
            'title': 'تم الاستلام',
            'description':
                'تأكيد تسليم الطلب (سيتم نقله للطلبات المكتملة)',
          },
        ];
      default:
        return [];
    }
  }

  Future<void> refreshOrders() async {
    final restaurantId = state.currentRestaurantId;
    if (restaurantId != null) {
      await fetchOrders(restaurantId);
    }
  }

  Future<void> fixAllOrdersGeneralStatus() async {
    try {
      await _ordersService.fixGeneralStatusForAllOrders();
      final restaurantId = state.currentRestaurantId;
      if (restaurantId != null) {
        await fetchOrders(restaurantId);
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  String getDetailedError() {
    final error = state.error;
    if (error == null) return 'No error';

    if (error.contains('failed-precondition')) {
      return '''
Firebase Index Error:
- يحتاج Firebase إلى إنشاء composite index
- هذا يحدث عند استخدام where + orderBy معاً
- الحل: انتظر 2-5 دقائق لإنشاء الفهرس تلقائياً
- أو انقر على رابط الخطأ في Firebase Console
      ''';
    }

    if (error.contains('permission-denied')) {
      return '''
Permission Error:
- ليس لديك صلاحية للوصول للطلبات
- تأكد من تسجيل الدخول بحساب المطعم الصحيح
- تحقق من Firestore Rules
      ''';
    }

    if (error.contains('network')) {
      return '''
Network Error:
- تحقق من اتصال الإنترنت
- حاول مرة أخرى بعد قليل
      ''';
    }

    return error;
  }

  @override
  Future<void> close() async {
    await _ordersSubscription?.cancel();
    return super.close();
  }
}
