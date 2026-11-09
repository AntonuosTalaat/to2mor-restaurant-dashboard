import 'package:flutter/material.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StatusBadge.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';

class DashboardInsights extends StatelessWidget {
  const DashboardInsights({
    super.key,
    required this.data,
    required this.onOpenOrders,
  });

  final Map<String, dynamic> data;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 900;

    final statusPanel = _StatusBreakdown(
      pending: data['pendingCount'] as int,
      preparing: data['preparingCount'] as int,
      ready: data['readyCount'] as int,
      cancelled: data['cancelledCount'] as int,
      onOpenOrders: onOpenOrders,
    );

    final typePanel = _OrderTypeSplit(
      deliveryCount: data['deliveryCount'] as int,
      pickupCount: data['pickupCount'] as int,
      averageOrderValue: (data['averageOrderValue'] as num).toDouble(),
      completionRate: (data['completionRate'] as num).toDouble(),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: statusPanel),
          const SizedBox(width: 12),
          Expanded(child: typePanel),
        ],
      );
    }

    return Column(
      children: [
        statusPanel,
        const SizedBox(height: 12),
        typePanel,
      ],
    );
  }
}

class ActiveOrdersPanel extends StatelessWidget {
  const ActiveOrdersPanel({
    super.key,
    required this.orders,
    required this.onOpenOrders,
  });

  final List<RestaurantOrderModel> orders;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(AppColors.primary, 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pending_actions_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلبات تحتاج متابعة',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (orders.isNotEmpty)
                        Text(
                          '${orders.length} طلب نشط',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpenOrders,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: const Text('كل الطلبات'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              _EmptyHint(
                icon: Icons.inbox_outlined,
                title: 'لا توجد طلبات نشطة حالياً',
                subtitle: 'الطلبات الجديدة ستظهر هنا للمتابعة',
              )
            else
              ...orders.map(
                (order) => _ActiveOrderTile(
                  order: order,
                  onTap: onOpenOrders,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({
    required this.pending,
    required this.preparing,
    required this.ready,
    required this.cancelled,
    required this.onOpenOrders,
  });

  final int pending;
  final int preparing;
  final int ready;
  final int cancelled;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiles = [
      _StatusTileData(
        label: 'قيد الانتظار',
        value: pending,
        color: AppColors.warning,
        icon: Icons.hourglass_top_rounded,
      ),
      _StatusTileData(
        label: 'قيد التنفيذ',
        value: preparing,
        color: AppColors.info,
        icon: Icons.restaurant_rounded,
      ),
      _StatusTileData(
        label: 'جاهز',
        value: ready,
        color: AppColors.success,
        icon: Icons.check_circle_outline,
      ),
      _StatusTileData(
        label: 'ملغي',
        value: cancelled,
        color: AppColors.error,
        icon: Icons.cancel_outlined,
      ),
    ];

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.donut_large_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'حالات الطلبات',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (pending > 0)
                  FilledButton.tonalIcon(
                    onPressed: onOpenOrders,
                    icon: const Icon(Icons.notifications_active_outlined, size: 14),
                    label: Text('$pending بانتظارك'),
                    style: FilledButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      backgroundColor:
                          AppColors.withOpacity(AppColors.warning, 0.14),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                // Prefer 4-up when the panel itself is wide enough.
                final fourUp = constraints.maxWidth >= 520;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tiles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: fourUp ? 4 : 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: fourUp ? 2.2 : 2.55,
                  ),
                  itemBuilder:
                      (context, index) => _StatusTile(data: tiles[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTileData {
  const _StatusTileData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.data});

  final _StatusTileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(data.color, 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.withOpacity(data.color, 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.withOpacity(data.color, 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${data.value}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: data.color,
                          height: 1,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (data.value > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: data.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeSplit extends StatelessWidget {
  const _OrderTypeSplit({
    required this.deliveryCount,
    required this.pickupCount,
    required this.averageOrderValue,
    required this.completionRate,
  });

  final int deliveryCount;
  final int pickupCount;
  final double averageOrderValue;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = deliveryCount + pickupCount;
    final deliveryRatio = total == 0 ? 0.0 : deliveryCount / total;
    final pickupRatio = total == 0 ? 0.0 : pickupCount / total;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'نوع الطلبات والأداء',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricChip(
                    icon: Icons.delivery_dining,
                    label: 'توصيل',
                    value: '$deliveryCount',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricChip(
                    icon: Icons.storefront_outlined,
                    label: 'استلام',
                    value: '$pickupCount',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        if (deliveryRatio > 0)
                          Expanded(
                            flex: (deliveryRatio * 100).round().clamp(1, 100),
                            child: const ColoredBox(color: AppColors.info),
                          ),
                        if (pickupRatio > 0)
                          Expanded(
                            flex: (pickupRatio * 100).round().clamp(1, 100),
                            child: const ColoredBox(color: AppColors.warning),
                          ),
                        if (total == 0)
                          Expanded(
                            child: ColoredBox(
                              color: AppColors.withOpacity(
                                scheme.onSurfaceVariant,
                                0.18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LegendDot(color: AppColors.info, label: 'توصيل'),
                    const SizedBox(width: 12),
                    _LegendDot(color: AppColors.warning, label: 'استلام'),
                    const Spacer(),
                    Text(
                      total == 0 ? 'لا بيانات' : '$total طلب',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricChip(
                    icon: Icons.payments_outlined,
                    label: 'متوسط الطلب',
                    value: '${averageOrderValue.toStringAsFixed(0)} ج.م',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricChip(
                    icon: Icons.trending_up_rounded,
                    label: 'نسبة الإكمال',
                    value: '${completionRate.toStringAsFixed(0)}%',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(color, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.withOpacity(color, 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.withOpacity(color, 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(scheme.onSurfaceVariant, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderTile extends StatelessWidget {
  const _ActiveOrderTile({required this.order, required this.onTap});

  final RestaurantOrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final diff = DateTime.now().difference(order.createdAt);
    final timeLabel =
        diff.inMinutes < 60
            ? 'منذ ${diff.inMinutes} د'
            : 'منذ ${diff.inHours} س';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.withOpacity(scheme.onSurfaceVariant, 0.04),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(AppColors.primary, 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    order.isPickup
                        ? Icons.storefront_outlined
                        : Icons.delivery_dining,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلب #$shortId',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${order.isPickup ? 'استلام' : 'توصيل'} • $timeLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  status: order.currentRestaurantStatus,
                  isPickup: order.isPickup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
