import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';

class StatisticsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final String selectedPeriod;

  const StatisticsSection({
    super.key,
    required this.data,
    this.selectedPeriod = 'اليوم',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'ملخص $selectedPeriod',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CompactStatsBanner(
          margin: EdgeInsets.zero,
          items: [
            CompactStatItem(
              title: 'إجمالي المبيعات',
              value: '${(data['totalSales'] as num).toStringAsFixed(0)} ج.م',
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            CompactStatItem(
              title: 'عدد الطلبات',
              value: '${data['totalOrders']}',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.info,
            ),
            CompactStatItem(
              title: 'المكتملة',
              value: '${data['shippedOrdersCount']}',
              icon: Icons.check_circle_outline,
              color: AppColors.primary,
            ),
            CompactStatItem(
              title: 'متوسط الطلب',
              value:
                  '${(data['averageOrderValue'] as num).toStringAsFixed(0)} ج.م',
              icon: Icons.analytics_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _WalletCard(),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final restaurantProvider = context.watch<RestaurantProvider>();

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.withOpacity(AppColors.success, 0.14),
              scheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(AppColors.success, 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المحفظة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurantProvider.formattedTotalEarnings,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'آخر تحديث: ${restaurantProvider.formattedLastEarningsUpdate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final narrow = MediaQuery.sizeOf(context).width < 420;
                  Future<void> refresh() async {
                    await restaurantProvider.fetchRestaurantData();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث بيانات المحفظة'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  if (narrow) {
                    return IconButton.filledTonal(
                      onPressed: refresh,
                      tooltip: 'تحديث',
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.success,
                        backgroundColor:
                            AppColors.withOpacity(AppColors.success, 0.14),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                    );
                  }

                  return FilledButton.tonalIcon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('تحديث'),
                    style: FilledButton.styleFrom(
                      foregroundColor: AppColors.success,
                      backgroundColor:
                          AppColors.withOpacity(AppColors.success, 0.14),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
