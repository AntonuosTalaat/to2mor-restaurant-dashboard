import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// أيقونة داخل إطار مضغوط — للهيدر وشريط الإجراءات.
class HeaderIconChip extends StatelessWidget {
  const HeaderIconChip({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 34,
    this.iconSize = 19,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor =
        isActive
            ? AppColors.withOpacity(AppColors.primary, isDark ? 0.24 : 0.16)
            : (isDark
                ? AppColors.darkSurfaceAlt
                : AppColors.withOpacity(AppColors.primary, 0.08));

    final borderColor =
        isActive
            ? AppColors.withOpacity(AppColors.primary, 0.55)
            : AppColors.withOpacity(AppColors.primary, isDark ? 0.32 : 0.2);

    final iconColor =
        isActive ? AppColors.primary : theme.colorScheme.onSurfaceVariant;

    Widget chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      chip = Tooltip(message: tooltip!, child: chip);
    }

    return chip;
  }
}
