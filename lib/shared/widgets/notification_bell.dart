import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/shared/widgets/header_icon_chip.dart';
import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    this.count = 0,
    this.onPressed,
    this.size = 34,
    this.iconSize = 19,
  });

  final int count;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  String get _badgeLabel {
    if (count <= 0) return '';
    if (count > 9) return '9+';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = _badgeLabel;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        HeaderIconChip(
          icon: Icons.notifications_outlined,
          onPressed: onPressed,
          tooltip: 'الإشعارات',
          size: size,
          iconSize: iconSize,
        ),
        if (badge.isNotEmpty)
          Positioned(
            top: -4,
            left: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
