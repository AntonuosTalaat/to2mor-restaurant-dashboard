import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';

class DateReportCard extends StatelessWidget {
  const DateReportCard({
    super.key,
    required this.date,
    required this.orders,
    required this.revenue,
    required this.completedOrders,
    required this.onTap,
  });

  final DateTime date;
  final List<RestaurantOrderModel> orders;
  final double revenue;
  final int completedOrders;
  final VoidCallback onTap;

  /// Preferred tile size for the reports grid (column count changes, not layout).
  static const double preferredWidth = 188;
  static const double preferredHeight = 112;
  static const double aspectRatio = preferredWidth / preferredHeight;
  static const int minCrossAxisCount = 2;

  static const _weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  String get _weekdayLabel => _weekdays[(date.weekday - 1) % 7];

  String get _dateLabel {
    try {
      return DateFormat('dd/MM/yyyy', 'ar').format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _weekdayLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${orders.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.info,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'طلب',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${revenue.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '$completedOrders مكتمل',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
