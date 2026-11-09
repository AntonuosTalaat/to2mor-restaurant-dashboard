import 'package:flutter/material.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StatusBadge.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/data/utils/restaurant_line_price.dart';

/// انسخ الملف لمشروع الـ dashboard مع تعديل مسارات الـ import حسب هيكل مشروعك.
class OrderDetailsBottomSheet {
  static void show(BuildContext context, RestaurantOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => _OrderDetailsSheet(order: order),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final RestaurantOrderModel order;
  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.grey.shade50;
    final cardColor = isDark ? theme.colorScheme.surface : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                _buildHeader(context, order, theme),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderInfo(context, order, theme, cardColor),
                        const SizedBox(height: 16),
                        _buildItemsList(
                          context,
                          order,
                          theme,
                          surfaceColor,
                          cardColor,
                        ),
                        const SizedBox(height: 16),
                        _buildTotalSection(context, order, theme),
                        const SizedBox(height: 16),
                        _buildCloseButton(context, theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RestaurantOrderModel order,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            status: order.currentRestaurantStatus,
            fontSize: 12,
            isPickup: order.isPickup,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(
    BuildContext context,
    RestaurantOrderModel order,
    ThemeData theme,
    Color cardColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات الطلب',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.payment_rounded,
            'طريقة الدفع',
            order.paymentMethod,
            theme,
          ),
          if (order.orderComment?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              context,
              Icons.note_alt_rounded,
              'ملاحظات',
              order.orderComment!,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: theme.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    RestaurantOrderModel order,
    ThemeData theme,
    Color surfaceColor,
    Color cardColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 18,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'الأصناف والإضافات',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${order.items.length} صنف',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            final lineType = item['lineType'] as String? ?? 'dish';
            if (lineType == 'restaurant_extra') {
              return _buildRestaurantExtraCard(
                context,
                item,
                theme,
                surfaceColor,
              );
            }
            return _buildDishCard(context, item, theme, surfaceColor);
          }),
        ],
      ),
    );
  }

  Widget _buildDishCard(
    BuildContext context,
    Map<String, dynamic> item,
    ThemeData theme,
    Color surfaceColor,
  ) {
    final itemData = _asMap(item['item']);
    const imgSize = 72.0;

    if (itemData == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        ),
        child: Text('سطر غير مكتمل', style: theme.textTheme.bodySmall),
      );
    }

    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final lineTotal = RestaurantLinePrice.totalOf(item);
    final sizeInfo = _getSizeInfo(item);
    final selectedExtras = _getSelectedExtras(item);
    final hasDetails =
        item['details'] != null && item['details'].toString().isNotEmpty;
    final itemImageUrl = itemData['imageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── الصورة
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                itemImageUrl != null && itemImageUrl.isNotEmpty
                    ? AppNetworkImage(
                      imageUrl: itemImageUrl,
                      height: imgSize,
                      width: imgSize,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => _PlaceholderIcon(
                            theme: theme,
                            isExtra: false,
                            size: imgSize,
                          ),
                    )
                    : _PlaceholderIcon(
                      theme: theme,
                      isExtra: false,
                      size: imgSize,
                    ),
          ),
          const SizedBox(width: 12),
          // ── التفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemData['name']?.toString() ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QuantityBadge(quantity: quantity, theme: theme),
                  ],
                ),
                if (sizeInfo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sizeInfo,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (hasDetails) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.28)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note_rounded,
                          size: 12,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['details'].toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.amber.shade900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (selectedExtras.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        selectedExtras
                            .map(
                              (extra) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.09),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.18),
                                  ),
                                ),
                                child: Text(
                                  '+ ${extra['name'] ?? ''}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${lineTotal.toStringAsFixed(0)} ج.م',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryColor,
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

  Widget _buildRestaurantExtraCard(
    BuildContext context,
    Map<String, dynamic> item,
    ThemeData theme,
    Color surfaceColor,
  ) {
    final extra = _asMap(item['extra']) ?? <String, dynamic>{};
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final name = extra['name']?.toString() ?? 'إضافة';
    final img = extra['img']?.toString();
    final total = RestaurantLinePrice.totalOf(item);
    const imgSize = 72.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.primaryColor.withOpacity(0.08),
            theme.primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primaryColor.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── الصورة
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                img != null && img.isNotEmpty
                    ? AppNetworkImage(
                      imageUrl: img,
                      height: imgSize,
                      width: imgSize,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => _PlaceholderIcon(
                            theme: theme,
                            isExtra: true,
                            size: imgSize,
                          ),
                    )
                    : _PlaceholderIcon(
                      theme: theme,
                      isExtra: true,
                      size: imgSize,
                    ),
          ),
          const SizedBox(width: 12),
          // ── التفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'إضافة',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _QuantityBadge(quantity: quantity, theme: theme),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${total.toStringAsFixed(0)} ج.م',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryColor,
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

  Widget _buildTotalSection(
    BuildContext context,
    RestaurantOrderModel order,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.primaryColor.withOpacity(0.15),
            theme.primaryColor.withOpacity(0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          if (order.voucherShare > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'خصم الكوبون',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '- ${order.voucherShare.toStringAsFixed(0)} ج.م',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.summarize_rounded,
                    size: 20,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'إجمالي هذا المطعم',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '${order.itemsPrice.toStringAsFixed(0)} ج.م',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.check_rounded, size: 20),
        label: const Text(
          'إغلاق',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: theme.primaryColor,
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} — ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  static List<Map<String, dynamic>> _getSelectedExtras(
    Map<String, dynamic> item,
  ) {
    if (!item.containsKey('selectedExtras') || item['selectedExtras'] == null) {
      return [];
    }
    final list = item['selectedExtras'];
    if (list is! List) return [];
    return list
        .map(
          (e) =>
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
        )
        .toList();
  }

  static String _getSizeInfo(Map<String, dynamic> item) {
    if (item.containsKey('selectedSize') && item['selectedSize'] is Map) {
      final selectedSize = item['selectedSize'] as Map<String, dynamic>;
      if (selectedSize.containsKey('name')) {
        String sizeInfo = '${selectedSize['name']}';
        if (selectedSize.containsKey('discountPercent') &&
            (selectedSize['discountPercent'] as num) > 0) {
          final discount = (selectedSize['discountPercent'] as num).toInt();
          sizeInfo += ' — خصم $discount%';
        }
        return sizeInfo;
      }
    }
    return '';
  }
}

// ─── Reusable small widgets ──────────────────────────────────────────────────

class _QuantityBadge extends StatelessWidget {
  final int quantity;
  final ThemeData theme;
  const _QuantityBadge({required this.quantity, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '×$quantity',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final ThemeData theme;
  final bool isExtra;
  final double size;
  const _PlaceholderIcon({
    required this.theme,
    required this.isExtra,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = (size * 0.45).clamp(22.0, 30.0);
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isExtra ? Icons.add_circle_outline_rounded : Icons.fastfood_rounded,
        color: theme.primaryColor.withOpacity(0.45),
        size: iconSize,
      ),
    );
  }
}
