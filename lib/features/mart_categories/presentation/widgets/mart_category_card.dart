import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

class MartCategoryCard extends StatelessWidget {
  const MartCategoryCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  /// Sized so ~3 cards fit per row on typical phone widths (~360).
  static const double cardWidth = 112;
  static const double cardHeight = 156;

  final MartCategoryModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.lightBorder;
    final statusColor = item.isActive ? AppColors.success : AppColors.error;
    final desc = (item.shortDescAr ?? '').trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(
                key: ValueKey('${item.id}:${item.imageUrl}'),
                url: item.imageUrl,
                height: cardHeight,
                fit: BoxFit.cover,
                placeholderIcon: Icons.store_mall_directory_outlined,
                placeholderIconSize: 28,
              ),
              Positioned(
                top: 6,
                left: 6,
                child: _Chip(
                  label: item.isActive ? 'نشط' : 'موقوف',
                  background: statusColor,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: _Chip(label: '#${item.sortOrder + 1}'),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _Chip(
                        label: item.nameAr,
                        maxWidth: true,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _Chip(
                        label: desc.isEmpty ? 'بدون وصف' : desc,
                        maxWidth: true,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconChip(
                            icon: Icons.edit_outlined,
                            tooltip: 'تعديل',
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: onEdit,
                          ),
                          const SizedBox(width: 4),
                          _IconChip(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'حذف',
                            color: AppColors.error,
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.background,
    this.maxWidth = false,
    this.fontSize = 9,
    this.fontWeight = FontWeight.w700,
  });

  final String label;
  final Color? background;
  final bool maxWidth;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxWidth
          ? const BoxConstraints(maxWidth: double.infinity)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
          height: 1.1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}
