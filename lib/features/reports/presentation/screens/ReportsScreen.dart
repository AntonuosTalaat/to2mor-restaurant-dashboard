import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:restaurantdashboard/Components/CommonComponents/DateRangePickerDialog.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StateComponents.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_state.dart';
import 'package:restaurantdashboard/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:restaurantdashboard/features/reports/presentation/cubit/reports_state.dart';
import 'package:restaurantdashboard/features/reports/presentation/widgets/date_report_card.dart';
import 'package:restaurantdashboard/features/reports/presentation/widgets/day_orders_sheet.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_action.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_slot_controller.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final Object _headerOwner = Object();
  PageHeaderSlotController? _headerSlot;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReportsData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _headerSlot = context.read<PageHeaderSlotController>();
  }

  @override
  void dispose() {
    _headerSlot?.clear(_headerOwner);
    super.dispose();
  }

  void _syncHeaderActions(bool isActive, {required bool hasRange}) {
    if (!mounted) return;
    final slot = _headerSlot;
    if (slot == null) return;
    if (!isActive) {
      slot.clear(_headerOwner);
      return;
    }
    slot.setActions(_headerOwner, [
      PageHeaderAction(
        icon: Icons.date_range_rounded,
        label: hasRange ? 'تغيير الفترة' : 'فترة زمنية',
        tooltip: hasRange ? 'تغيير الفترة' : 'اختر فترة زمنية',
        onPressed: _selectDateRange,
      ),
      PageHeaderAction(
        icon: Icons.calendar_today_outlined,
        label: 'يوم محدد',
        tooltip: 'يوم محدد',
        onPressed: _selectDateFromCalendar,
      ),
    ]);
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('ar', null);
    } catch (_) {
      await initializeDateFormatting();
    }
  }

  Future<void> _loadReportsData() async {
    if (!mounted) return;
    final restaurantId = context.read<AuthProvider>().restaurant?.id ?? '';
    await context.read<ReportsCubit>().load(
      ordersCubit: context.read<OrdersCubit>(),
      restaurantId: restaurantId,
    );
  }

  Future<void> _selectDateRange() async {
    final cubit = context.read<ReportsCubit>();
    final result = await DateRangeDialog.show(
      context,
      initialRange: cubit.state.selectedDateRange,
    );
    if (result != null) cubit.selectDateRange(result);
  }

  Future<void> _selectDateFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    _showOrdersForDate(picked);
  }

  void _showOrdersForDate(DateTime date) {
    final reportsCubit = context.read<ReportsCubit>();
    final allOrders = context.read<OrdersCubit>().state.orders;
    final orders = reportsCubit.ordersForDate(allOrders, date);

    DayOrdersSheet.show(
      context,
      date: date,
      orders: orders,
      revenue: reportsCubit.calculateDayRevenue(orders),
      completedOrders: reportsCubit.countCompletedOrders(orders),
    );
  }

  List<CompactStatItem> _buildStats(
    ReportsCubit cubit,
    List<RestaurantOrderModel> orders,
    int daysCount,
  ) {
    final filtered = cubit.filteredOrders(orders);
    return [
      CompactStatItem(
        title: 'إجمالي الطلبات',
        value: '${filtered.length}',
        icon: Icons.shopping_bag_outlined,
        color: AppColors.info,
      ),
      CompactStatItem(
        title: 'المكتملة',
        value: '${cubit.calculateTotalCompletedOrders(orders)}',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      CompactStatItem(
        title: 'الإيرادات',
        value: '${cubit.calculateTotalRevenue(orders).toStringAsFixed(0)} ج.م',
        icon: Icons.payments_outlined,
        color: AppColors.warning,
      ),
      CompactStatItem(
        title: 'عدد الأيام',
        value: '$daysCount',
        icon: Icons.calendar_month_outlined,
        color: AppColors.primary,
      ),
    ];
  }

  String _formatRange(DateTimeRange range) {
    String fmt(DateTime d) {
      try {
        return DateFormat('dd/MM/yyyy', 'ar').format(d);
      } catch (_) {
        return '${d.day}/${d.month}/${d.year}';
      }
    }

    return 'من ${fmt(range.start)} إلى ${fmt(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = context.select(
      (NavigationCubit c) => c.state.currentItem == NavigationItem.reports,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (context, reportsState) {
            final hasRange = reportsState.selectedDateRange != null;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncHeaderActions(isActive, hasRange: hasRange);
            });

            if (reportsState.isLoading) {
              return const LoadingState();
            }

            if (reportsState.lastError != null) {
              return ErrorState(
                message: reportsState.lastError!,
                onRetry: _loadReportsData,
              );
            }

            return BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, ordersState) {
                final reportsCubit = context.read<ReportsCubit>();
                final grouped = reportsCubit.groupOrdersByDate(
                  ordersState.orders,
                );
                final sortedDates =
                    grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  onRefresh: _loadReportsData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: CompactStatsBanner(
                          items: _buildStats(
                            reportsCubit,
                            ordersState.orders,
                            sortedDates.length,
                          ),
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        ),
                      ),
                      if (hasRange)
                        SliverToBoxAdapter(
                          child: _PeriodBanner(
                            label: _formatRange(
                              reportsState.selectedDateRange!,
                            ),
                            onClear:
                                () =>
                                    context
                                        .read<ReportsCubit>()
                                        .clearDateRange(),
                          ),
                        ),
                      if (sortedDates.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            title:
                                hasRange
                                    ? 'لا توجد طلبات في هذه الفترة'
                                    : 'لا توجد طلبات لعرض التقارير',
                            subtitle:
                                hasRange
                                    ? 'جرّب تغيير الفترة الزمنية'
                                    : 'ستظهر التقارير بعد استلام الطلبات',
                            icon: Icons.assessment_outlined,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 10.0;
                              final width = constraints.crossAxisExtent;
                              final rawCount =
                                  ((width + spacing) /
                                          (DateReportCard.preferredWidth +
                                              spacing))
                                      .floor();
                              final crossAxisCount = rawCount.clamp(
                                DateReportCard.minCrossAxisCount,
                                8,
                              );

                              return SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: spacing,
                                      crossAxisSpacing: spacing,
                                      childAspectRatio:
                                          DateReportCard.aspectRatio,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final dateKey = sortedDates[index];
                                    final dayOrders = grouped[dateKey]!;
                                    final date = DateTime.parse(dateKey);
                                    return DateReportCard(
                                      date: date,
                                      orders: dayOrders,
                                      revenue: reportsCubit
                                          .calculateDayRevenue(dayOrders),
                                      completedOrders: reportsCubit
                                          .countCompletedOrders(dayOrders),
                                      onTap: () => _showOrdersForDate(date),
                                    );
                                  },
                                  childCount: sortedDates.length,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PeriodBanner extends StatelessWidget {
  const _PeriodBanner({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.primary, 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.withOpacity(AppColors.primary, 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص الفترة',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إزالة الفلتر',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
