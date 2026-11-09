import 'package:flutter/material.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/notifications/data/models/restaurant_notification_model.dart';
import 'package:restaurantdashboard/features/notifications/presentation/widgets/notifications_bottom_sheet.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDismiss,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  final RestaurantNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  IconData get _icon {
    return switch (notification.type) {
      RestaurantNotificationType.newOrder => Icons.shopping_bag_outlined,
      RestaurantNotificationType.orderCancelled => Icons.cancel_outlined,
      RestaurantNotificationType.unknown => Icons.notifications_outlined,
    };
  }

  Color _iconColor(bool isDark) {
    return switch (notification.type) {
      RestaurantNotificationType.newOrder =>
        isDark ? AppColors.primaryLight : AppColors.primary,
      RestaurantNotificationType.orderCancelled => AppColors.error,
      RestaurantNotificationType.unknown => AppColors.textHint,
    };
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final tileColor = selectionMode && isSelected
        ? AppColors.withOpacity(AppColors.error, isDark ? 0.14 : 0.08)
        : notification.read
            ? surfaceAlt.withValues(alpha: isDark ? 0.55 : 0.75)
            : AppColors.withOpacity(AppColors.primary, isDark ? 0.12 : 0.08);

    final tileBorder = selectionMode && isSelected
        ? AppColors.withOpacity(AppColors.error, 0.45)
        : notification.read
            ? borderColor
            : AppColors.withOpacity(AppColors.primary, 0.35);

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tileBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectionToggle?.call(),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(_iconColor(isDark), 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _iconColor(isDark), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.read
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.read && !selectionMode)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatNotificationTime(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!selectionMode && onDismiss != null)
                IconButton(
                  tooltip: 'حذف',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (selectionMode || onDismiss == null) {
      return content;
    }

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: content,
    );
  }
}
