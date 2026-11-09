import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RangeToggleChip extends StatelessWidget {
  const RangeToggleChip({
    super.key,
    required this.isDark,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final bool isDark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor:
          isDark ? AppColors.darkSurfaceAlt : AppColors.silverLight20,
      selectedColor: AppColors.withOpacity(
        AppColors.primary,
        isDark ? 0.24 : 0.16,
      ),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color:
            selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(color: selected ? AppColors.primary : borderColor),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
