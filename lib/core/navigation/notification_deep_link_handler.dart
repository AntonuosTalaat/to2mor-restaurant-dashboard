import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/core/navigation/notification_deep_link.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/orders/data/datasources/OrdersService.dart';
import 'package:restaurantdashboard/features/orders/presentation/widgets/OrderDetailsDialog.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';

/// Registers [NotificationDeepLink] while [MainScreen] is mounted.
class NotificationDeepLinkHandler extends StatefulWidget {
  const NotificationDeepLinkHandler({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationDeepLinkHandler> createState() =>
      _NotificationDeepLinkHandlerState();
}

class _NotificationDeepLinkHandlerState
    extends State<NotificationDeepLinkHandler> {
  final OrdersService _ordersService =
      OrdersService(firestore: FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    NotificationDeepLink.setHandler(_handle);
    _consumeWebQueryOrderId();
  }

  void _consumeWebQueryOrderId() {
    if (!kIsWeb) return;
    final orderId = Uri.base.queryParameters['orderId']?.trim();
    if (orderId == null || orderId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationDeepLink.navigate(NotificationOrderTarget(orderId));
    });
  }

  @override
  void dispose() {
    NotificationDeepLink.setHandler(null);
    super.dispose();
  }

  Future<void> _handle(NotificationTarget target) async {
    if (!mounted) return;
    final nav = context.read<NavigationCubit>();

    switch (target) {
      case NotificationOrderTarget(:final orderId):
        nav.navigateTo(NavigationItem.orders);
        await _openOrder(context, orderId);
      case NotificationOrdersListTarget():
        nav.navigateTo(NavigationItem.orders);
      case NotificationInboxTarget():
        break;
    }
  }

  Future<void> _openOrder(BuildContext context, String orderId) async {
    try {
      final restaurantId = context.read<AuthProvider>().restaurant?.id;
      if (restaurantId == null || restaurantId.isEmpty) return;

      final order = await _ordersService.getOrderById(orderId, restaurantId);
      if (!context.mounted || order == null) return;

      OrderDetailsBottomSheet.show(context, order);
    } catch (e) {
      debugPrint('[NotificationDeepLinkHandler] Failed to open order: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
