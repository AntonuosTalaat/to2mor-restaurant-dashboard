import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:restaurantdashboard/Components/CommonComponents/StatusBadge.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StateComponents.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/data/utils/restaurant_line_price.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';

class DayOrdersSheet {
  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<RestaurantOrderModel> orders,
    required double revenue,
    required int completedOrders,
  }) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return showDialog<void>(
        context: context,
        builder:
            (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(ctx).width > 1200 ? 900 : 720,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
                ),
                child: _DayOrdersPanel(
                  date: date,
                  orders: orders,
                  revenue: revenue,
                  completedOrders: completedOrders,
                  showCloseButton: true,
                ),
              ),
            ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.96,
            builder:
                (context, scrollController) => Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _DayOrdersPanel(
                    date: date,
                    orders: orders,
                    revenue: revenue,
                    completedOrders: completedOrders,
                    scrollController: scrollController,
                    showDragHandle: true,
                  ),
                ),
          ),
    );
  }
}

class _DayOrdersPanel extends StatelessWidget {
  const _DayOrdersPanel({
    required this.date,
    required this.orders,
    required this.revenue,
    required this.completedOrders,
    this.scrollController,
    this.showCloseButton = false,
    this.showDragHandle = false,
  });

  final DateTime date;
  final List<RestaurantOrderModel> orders;
  final double revenue;
  final int completedOrders;
  final ScrollController? scrollController;
  final bool showCloseButton;
  final bool showDragHandle;

  String get _title {
    try {
      return 'تقرير يوم ${DateFormat('dd/MM/yyyy', 'ar').format(date)}';
    } catch (_) {
      return 'تقرير يوم ${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          if (showDragHandle)
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                if (showCloseButton)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'إغلاق',
                  ),
                Expanded(
                  child: Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (showCloseButton) const SizedBox(width: 48),
              ],
            ),
          ),
          CompactStatsBanner(
            items: [
              CompactStatItem(
                title: 'إجمالي الطلبات',
                value: '${orders.length}',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.info,
              ),
              CompactStatItem(
                title: 'المكتملة',
                value: '$completedOrders',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              CompactStatItem(
                title: 'الإيرادات',
                value: '${revenue.toStringAsFixed(0)} ج.م',
                icon: Icons.payments_outlined,
                color: AppColors.warning,
              ),
            ],
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                orders.isEmpty
                    ? const EmptyState(
                      title: 'لا توجد طلبات',
                      subtitle: 'لا توجد طلبات في هذا اليوم',
                      icon: Icons.inbox_outlined,
                    )
                    : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder:
                          (context, index) =>
                              DayOrderTile(order: orders[index]),
                    ),
          ),
        ],
      ),
    );
  }
}

class DayOrderTile extends StatelessWidget {
  const DayOrderTile({super.key, required this.order});

  final RestaurantOrderModel order;

  String _formatTime(DateTime date) {
    try {
      return DateFormat('hh:mm a', 'ar').format(date);
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shortId =
        order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'طلب #$shortId',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(
                    status: order.currentRestaurantStatus,
                    isPickup: order.isPickup,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatTime(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.itemsPrice.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'عدد الأصناف: ${order.items.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          children: [_OrderItemsDetails(order: order)],
        ),
      ),
    );
  }
}

class _OrderItemsDetails extends StatelessWidget {
  const _OrderItemsDetails({required this.order});

  final RestaurantOrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تفاصيل الأصناف',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...order.items.map((item) {
          final itemData = item['item'] as Map<String, dynamic>?;
          final itemName = itemData?['name']?.toString() ?? 'صنف غير معروف';
          final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

          final itemPrice = RestaurantLinePrice.totalOf(item);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$itemName × $quantity',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${itemPrice.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          );
        }),
        if (order.orderComment != null && order.orderComment!.isNotEmpty) ...[
          const Divider(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.comment_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.orderComment!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
