import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StateComponents.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/widgets/StatisticsGrid.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/widgets/dashboard_insights.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/widgets/tab_filte.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_state.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context.read<DashboardCubit>().load(
      restaurantProvider: context.read<RestaurantProvider>(),
      ordersCubit: context.read<OrdersCubit>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state.isLoading) return const LoadingState();

            if (state.lastError != null) {
              return ErrorState(message: state.lastError!, onRetry: _load);
            }

            return BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, ordersState) {
                return Consumer<RestaurantProvider>(
                  builder: (context, restaurantProvider, _) {
                    final cubit = context.read<DashboardCubit>();
                    final data = cubit.calculateFilteredData(
                      orders: ordersState.orders,
                      restaurant: restaurantProvider.restaurant,
                      wallet: restaurantProvider.wallet,
                      formattedTotalEarnings:
                          restaurantProvider.formattedTotalEarnings,
                      formattedLastEarningsUpdate:
                          restaurantProvider.formattedLastEarningsUpdate,
                    );
                    final isWide = MediaQuery.sizeOf(context).width > 900;
                    final activeOrders =
                        (data['activeOrders'] as List<RestaurantOrderModel>);
                    void openOrders() => context
                        .read<NavigationCubit>()
                        .navigateTo(NavigationItem.orders);

                    final topItems =
                        data['topItems'] as List<Map<String, dynamic>>;
                    final dailyRevenue =
                        data['dailyRevenue'] as Map<String, double>;

                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
                        children: [
                          TabFilter(
                            selectedPeriod: state.selectedPeriod,
                            onPeriodChanged: cubit.selectPeriod,
                          ),
                          const SizedBox(height: 8),
                          StatisticsSection(
                            data: data,
                            selectedPeriod: state.selectedPeriod,
                          ),
                          const SizedBox(height: 8),
                          DashboardInsights(
                            data: data,
                            onOpenOrders: openOrders,
                          ),
                          const SizedBox(height: 8),
                          ActiveOrdersPanel(
                            orders: activeOrders,
                            onOpenOrders: openOrders,
                          ),
                          const SizedBox(height: 8),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ChartCard(
                                    title: 'الأصناف الأكثر مبيعاً',
                                    subtitle: 'حسب ${state.selectedPeriod}',
                                    icon: Icons.restaurant_menu_outlined,
                                    child: _TopItemsChart(topItems: topItems),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ChartCard(
                                    title: 'الإيرادات اليومية',
                                    subtitle: 'اتجاه الإيراد خلال الفترة',
                                    icon: Icons.show_chart_rounded,
                                    child: _RevenueChart(
                                      dailyRevenue: dailyRevenue,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _ChartCard(
                              title: 'الأصناف الأكثر مبيعاً',
                              subtitle: 'حسب ${state.selectedPeriod}',
                              icon: Icons.restaurant_menu_outlined,
                              child: _TopItemsChart(topItems: topItems),
                            ),
                            const SizedBox(height: 12),
                            _ChartCard(
                              title: 'الإيرادات اليومية',
                              subtitle: 'اتجاه الإيراد خلال الفترة',
                              icon: Icons.show_chart_rounded,
                              child: _RevenueChart(dailyRevenue: dailyRevenue),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(AppColors.primary, 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 280, child: child),
          ],
        ),
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.withOpacity(scheme.onSurfaceVariant, 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.onSurfaceVariant, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ستظهر البيانات عند توفر طلبات في الفترة المختارة',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopItemsChart extends StatelessWidget {
  const _TopItemsChart({required this.topItems});

  final List<Map<String, dynamic>> topItems;

  @override
  Widget build(BuildContext context) {
    if (topItems.isEmpty) {
      return const _ChartEmptyState(
        icon: Icons.bar_chart_rounded,
        message: 'لا توجد أصناف مبيعة بعد',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final maxY = (topItems.first['quantity'] as int).toDouble() + 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (group.x.toInt() >= topItems.length) return null;
              return BarTooltipItem(
                '${topItems[group.x.toInt()]['name']}\n${rod.toY.round()} قطعة',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= topItems.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${topItems[index]['name']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        barGroups:
            topItems.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: (entry.value['quantity'] as int).toDouble(),
                    color: AppColors.primary,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.dailyRevenue});

  final Map<String, double> dailyRevenue;

  @override
  Widget build(BuildContext context) {
    if (dailyRevenue.isEmpty) {
      return const _ChartEmptyState(
        icon: Icons.show_chart_rounded,
        message: 'لا توجد إيرادات للعرض',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final keys = dailyRevenue.keys.toList();
    final values = dailyRevenue.values.toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget:
                  (value, meta) => Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= keys.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  keys[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                values
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.withOpacity(AppColors.success, 0.12),
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    final index = spot.x.toInt();
                    if (index < 0 || index >= keys.length) return null;
                    return LineTooltipItem(
                      '${keys[index]}\n${spot.y.toStringAsFixed(0)} ج.م',
                      const TextStyle(color: Colors.white),
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
      ),
    );
  }
}
