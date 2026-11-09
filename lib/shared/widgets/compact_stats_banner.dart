import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CompactStatItem {
  const CompactStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

/// Compact horizontal stats row for list screens (couriers, restaurants, etc.).
class CompactStatsBanner extends StatelessWidget {
  const CompactStatsBanner({
    super.key,
    required this.items,
    this.margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.compactBreakpoint = 768,
    this.mobileTileWidth = 118,
    this.bannerHeight = 52,
    this.hideWhenEmpty = true,
  });

  final List<CompactStatItem> items;
  final EdgeInsetsGeometry margin;
  final double compactBreakpoint;
  final double mobileTileWidth;
  final double bannerHeight;
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context) {
    if (hideWhenEmpty && items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = MediaQuery.sizeOf(context).width < compactBreakpoint;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: margin,
      height: bannerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(AppColors.black, isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          isCompact
              ? ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder:
                    (_, __) => VerticalDivider(
                      width: 16,
                      thickness: 1,
                      color: borderColor.withValues(alpha: 0.6),
                    ),
                itemBuilder:
                    (context, index) => SizedBox(
                      width: mobileTileWidth,
                      child: _CompactStatTile(
                        item: items[index],
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    ),
              )
              : Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      VerticalDivider(
                        width: 24,
                        thickness: 1,
                        color: borderColor.withValues(alpha: 0.6),
                      ),
                    Expanded(
                      child: _CompactStatTile(
                        item: items[i],
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ],
              ),
    );
  }
}

class _CompactStatTile extends StatelessWidget {
  const _CompactStatTile({
    required this.item,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  final CompactStatItem item;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.withOpacity(item.color, isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, size: 16, color: item.color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
