import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';

class OrderStatusSheet {
  static void show(BuildContext context, RestaurantOrderModel order, String restaurantId) {
    final options = _getStatusOptions(order.currentRestaurantStatus, order.orderType, order.delivery);

    if (options.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(order),
          ...options.map((option) => _buildOption(
            context,
            option,
            order,
            restaurantId,
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _buildHeader(RestaurantOrderModel order) {
    final orderTypeText = order.isPickup ? '(استلام)' : '(توصيل)';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'تغيير حالة الطلب #${order.id.substring(0, 8)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            orderTypeText,
            style: TextStyle(
              fontSize: 14,
              color: order.isPickup ? Colors.orange : Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildOption(
      BuildContext context,
      Map<String, dynamic> option,
      RestaurantOrderModel order,
      String restaurantId,
      ) {
    final bool isDisabled = option['disabled'] ?? false;
    final String? disabledReason = option['disabledReason'];

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: ListTile(
        enabled: !isDisabled,
        leading: _getStatusIcon(option['status']!),
        title: Text(option['title']!),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (option['subtitle'] != null)
              Text(
                option['subtitle']!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (isDisabled && disabledReason != null)
              Text(
                disabledReason,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
          ],
        ),
        onTap: isDisabled ? null : () async {
          Navigator.pop(context);

          if (option['status'] == 'cancelled') {
            _showCancelConfirmationDialog(context, order, restaurantId);
          } else {
            await _updateOrderStatus(context, order.id, restaurantId, option['status']!);
          }
        },
      ),
    );
  }

  static void _showCancelConfirmationDialog(
      BuildContext context,
      RestaurantOrderModel order,
      String restaurantId,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الإلغاء'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد من إلغاء الطلب #${order.id.substring(0, 8)}؟'),
              const SizedBox(height: 8),
              const Text(
                'لا يمكن التراجع عن هذا الإجراء',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'لا',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateOrderStatus(context, order.id, restaurantId, 'cancelled');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('نعم، إلغاء الطلب'),
            ),
          ],
        );
      },
    );
  }

  static Icon _getStatusIcon(String status) {
    switch (status) {
      case 'preparing':
        return const Icon(Icons.restaurant, color: Colors.blue);
      case 'ready':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'shipped':
        return const Icon(Icons.local_shipping, color: Colors.purple);
      case 'delivered':
        return const Icon(Icons.how_to_reg, color: Colors.green);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.update, color: Colors.grey);
    }
  }

  static List<Map<String, dynamic>> _getStatusOptions(
      String currentStatus,
      OrderType orderType,
      dynamic delivery,
      ) {
    switch (currentStatus) {
      case 'pending':
        return [
          {
            'status': 'preparing',
            'title': 'قيد التنفيذ',
            'subtitle': 'بدء تحضير الطلب',
            'disabled': false,
          },
          {
            'status': 'cancelled',
            'title': 'إلغاء الطلب',
            'subtitle': 'إلغاء الطلب نهائياً',
            'disabled': false,
          },
        ];

      case 'preparing':
        return [
          {
            'status': 'ready',
            'title': 'جاهز للاستلام',
            'subtitle': orderType == OrderType.pickup
                ? 'الطلب جاهز للاستلام من المطعم'
                : 'الطلب جاهز للشحن',
            'disabled': false,
          },
          {
            'status': 'cancelled',
            'title': 'إلغاء الطلب',
            'subtitle': 'إلغاء الطلب نهائياً',
            'disabled': false,
          },
        ];

      case 'ready':
        if (orderType == OrderType.pickup) {
          return [
            {
              'status': 'delivered',
              'title': 'تم الاستلام',
              'subtitle': 'العميل استلم الطلب من المطعم',
              'disabled': false,
            },
          ];
        } else {
          // ✅ Check if delivery exists for delivery orders
          final bool hasDelivery = delivery != null;
          return [
            {
              'status': 'shipped',
              'title': 'تم الشحن',
              'subtitle': 'تم تسليم الطلب لخدمة التوصيل',
              'disabled': !hasDelivery,
              'disabledReason': !hasDelivery ? 'يجب تعيين مندوب توصيل أولاً' : null,
            },
          ];
        }

      default:
        return [];
    }
  }

  static Future<void> _updateOrderStatus(
      BuildContext context,
      String orderId,
      String restaurantId,
      String status,
      ) async {
    try {
      await context.read<OrdersCubit>().updateOrderStatus(
        orderId,
        restaurantId,
        status,
      );

      if (context.mounted) {
        String successMessage = _getSuccessMessage(status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث حالة الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _getSuccessMessage(String status) {
    switch (status) {
      case 'preparing':
        return 'تم بدء تحضير الطلب';
      case 'ready':
        return 'الطلب أصبح جاهزاً';
      case 'shipped':
        return 'تم شحن الطلب';
      case 'delivered':
        return 'تم استلام الطلب بنجاح';
      case 'cancelled':
        return 'تم إلغاء الطلب';
      default:
        return 'تم تحديث حالة الطلب';
    }
  }
}