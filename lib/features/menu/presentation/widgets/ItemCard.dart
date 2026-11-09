import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool fillFixedSize;

  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.fillFixedSize = false,
  });

  Future<void> _toggleAvailability(BuildContext context) async {
    try {
      final newStatus = !item.isAvailable;
      await context.read<MenuCubit>().toggleItemAvailability(
        item.id,
        newStatus,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'تم تفعيل "${item.name}"' : 'تم إيقاف "${item.name}"',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف "${item.name}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      onDelete();
    }
  }

  String _getPriceRange() {
    if (item.sizes.isEmpty) return 'غير محدد';
    if (item.sizes.length == 1) {
      final size = item.sizes.first;
      final finalPrice = size.price * (1 - size.discountPercent / 100);
      return '${finalPrice.toStringAsFixed(0)} ج.م';
    }
    final prices =
        item.sizes
            .map((s) => s.price * (1 - s.discountPercent / 100))
            .toList();
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} ج.م';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canExpand =
            fillFixedSize &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite;

        if (canExpand) {
          return _buildCompactFixedCard(context);
        }

        final width = constraints.maxWidth;
        final imageHeight =
            width < 250 ? 120.0 : (width < 350 ? 140.0 : 160.0);
        final fontSize = width < 250 ? 12.0 : 14.0;
        return _buildFlexibleCard(context, imageHeight, fontSize);
      },
    );
  }

  Widget _buildFlexibleCard(
    BuildContext context,
    double imageHeight,
    double fontSize,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AppNetworkImage(
                imageUrl: item.imageUrl,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      height: imageHeight,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    ),
              ),
              if (!item.isAvailable)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'غير متاح',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.isAvailable ? 'متاح' : 'غير متاح',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      fontSize: fontSize - 1,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    _getPriceRange(),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap:
                        item.isAvailable
                            ? null
                            : () => _toggleAvailability(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            item.isAvailable ? Colors.green[50] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              item.isAvailable ? Colors.green : Colors.grey[300]!,
                          width: item.isAvailable ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.isAvailable
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color:
                                item.isAvailable ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'متاح',
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              fontWeight:
                                  item.isAvailable
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  item.isAvailable ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap:
                        !item.isAvailable
                            ? null
                            : () => _toggleAvailability(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            !item.isAvailable ? Colors.red[50] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              !item.isAvailable ? Colors.red : Colors.grey[300]!,
                          width: !item.isAvailable ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            !item.isAvailable
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color:
                                !item.isAvailable ? Colors.red : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'غير متاح',
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              fontWeight:
                                  !item.isAvailable
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  !item.isAvailable ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(
                      'تعديل',
                      style: TextStyle(fontSize: fontSize - 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete, size: 16),
                    label: Text(
                      'حذف',
                      style: TextStyle(fontSize: fontSize - 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFixedCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox.expand(
        child: Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 12,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported,
                                size: 22,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                      ),
                      if (!item.isAvailable)
                        const ColoredBox(color: Color(0x88000000)),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                item.isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.isAvailable ? 'متاح' : 'غير متاح',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 72),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _getPriceRange(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactActionButton(
                                icon: Icons.edit_rounded,
                                color: AppColors.primary,
                                filled: true,
                                tooltip: 'تعديل',
                                onPressed: onEdit,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: _CompactActionButton(
                                icon: Icons.delete_outline,
                                color: AppColors.error,
                                tooltip: 'حذف',
                                onPressed: () => _confirmDelete(context),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: _CompactActionButton(
                                icon:
                                    item.isAvailable
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                color:
                                    item.isAvailable
                                        ? AppColors.success
                                        : AppColors.warning,
                                tooltip:
                                    item.isAvailable ? 'إيقاف' : 'تفعيل',
                                onPressed: () => _toggleAvailability(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Tooltip(
        message: tooltip,
        child:
            filled
                ? FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Icon(icon, size: 12),
                )
                : OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Icon(icon, size: 12),
                ),
      ),
    );
  }
}
