import 'package:flutter/material.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StatusBadge.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/presentation/widgets/OrderDetailsDialog.dart';
import 'package:restaurantdashboard/features/orders/presentation/widgets/OrderStatusSheet.dart';

class OrderCard extends StatelessWidget {
  final RestaurantOrderModel order;
  final String restaurantId;

  /// When true and parent height is bounded, card fills the parent (grid cells).
  final bool fillFixedSize;

  const OrderCard({
    super.key,
    required this.order,
    required this.restaurantId,
    this.fillFixedSize = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expand =
            fillFixedSize &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite;

        return _buildCard(context, expand: expand);
      },
    );
  }

  Widget _buildCard(BuildContext context, {required bool expand}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shortId = order.id.substring(0, order.id.length.clamp(0, 8));
    final typeColor = order.isPickup ? AppColors.warning : AppColors.info;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(AppColors.primary, 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$shortId',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} أصناف · ${_formatTime(order.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              StatusBadge(
                status: order.currentRestaurantStatus,
                isPickup: order.isPickup,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(typeColor, 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.isPickup
                          ? Icons.storefront_outlined
                          : Icons.delivery_dining,
                      size: 13,
                      color: typeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.isPickup ? 'استلام' : 'توصيل',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${order.itemsPrice.toStringAsFixed(0)} ج.م',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  height: 1,
                ),
              ),
            ],
          ),
          if (expand) const Spacer() else const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: () => _showStatusSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _getActionText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton.outlined(
                  onPressed: () => _showOrderDetails(context),
                  tooltip: 'التفاصيل',
                  style: IconButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                    side: BorderSide(color: scheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.info_outline, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final card = Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        child: expand ? SizedBox.expand(child: content) : content,
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: expand ? SizedBox.expand(child: card) : card,
    );
  }

  String _getActionText() {
    if (order.currentRestaurantStatus == 'ready') {
      return order.isPickup ? 'تأكيد الاستلام' : 'تأكيد الشحن';
    }
    if (order.currentRestaurantStatus == 'pending') {
      return 'بدء التحضير';
    }
    if (order.currentRestaurantStatus == 'preparing') {
      return 'تم الانتهاء';
    }
    return 'تغيير الحالة';
  }

  void _showStatusSheet(BuildContext context) {
    OrderStatusSheet.show(context, order, restaurantId);
  }

  void _showOrderDetails(BuildContext context) {
    OrderDetailsBottomSheet.show(context, order);
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} د';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} س';
    return '${dateTime.day}/${dateTime.month}';
  }
}
