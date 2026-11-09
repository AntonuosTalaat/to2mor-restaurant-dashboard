import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StateComponents.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StatusBadge.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/orders/data/models/RestaurantOrderModel.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_state.dart';
import 'package:restaurantdashboard/features/orders/presentation/widgets/OrderCard.dart';
import 'package:restaurantdashboard/features/orders/presentation/widgets/OrderDetailsDialog.dart';
import 'package:restaurantdashboard/features/orders/presentation/widgets/OrderStatusSheet.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table_config.dart';
import 'package:restaurantdashboard/shared/shared_data_table/table_cell_builders.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';
import 'package:restaurantdashboard/shared/widgets/responsive_filter_row.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _statusFilters = <String>[
    'الكل',
    'قيد الانتظار',
    'قيد التنفيذ',
    'جاهز للاستلام',
    'تم التسليم',
    'ملغي',
  ];

  static const _typeFilters = <String>['الكل', 'توصيل', 'استلام'];

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatusFilter = 'الكل';
  String _selectedTypeFilter = 'الكل';
  String _searchQuery = '';
  String? _restaurantId;

  static const _columns = <DataTableColumn>[
    DataTableColumn(label: 'الطلب', icon: Icons.receipt_long_rounded),
    DataTableColumn(label: 'النوع', icon: Icons.local_shipping_outlined),
    DataTableColumn(label: 'الحالة', icon: Icons.flag_outlined),
    DataTableColumn(label: 'الأصناف', icon: Icons.restaurant_menu_outlined),
    DataTableColumn(label: 'المبلغ', icon: Icons.payments_outlined),
    DataTableColumn(label: 'الوقت', icon: Icons.schedule_outlined),
    DataTableColumn(label: 'إجراءات', icon: Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initialize() {
    final authProvider = context.read<AuthProvider>();
    _restaurantId = authProvider.restaurant?.id;
    if (_restaurantId != null) {
      context.read<OrdersCubit>().listenToOrders(_restaurantId!);
    }
    if (mounted) setState(() {});
  }

  List<RestaurantOrderModel> _applyFilters(List<RestaurantOrderModel> orders) {
    final query = _searchQuery.toLowerCase();

    return orders.where((order) {
      final status = order.currentRestaurantStatus;
      final matchesStatus = switch (_selectedStatusFilter) {
        'الكل' => true,
        'قيد الانتظار' => status == 'pending',
        'قيد التنفيذ' => status == 'preparing',
        'جاهز للاستلام' => status == 'ready',
        'تم التسليم' => status == 'shipped' || status == 'delivered',
        'ملغي' => status == 'cancelled',
        _ => true,
      };
      if (!matchesStatus) return false;

      final matchesType = switch (_selectedTypeFilter) {
        'توصيل' => order.isDelivery,
        'استلام' => order.isPickup,
        _ => true,
      };
      if (!matchesType) return false;

      if (query.isEmpty) return true;

      final haystack =
          [
            order.id,
            order.userId,
            order.orderComment ?? '',
            order.deliveryAddress ?? '',
            order.delivery?.name ?? '',
            order.delivery?.phone ?? '',
            order.isPickup ? 'استلام' : 'توصيل',
            order.paymentMethod,
          ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  Widget _buildDropdownFilter({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    bool compact = false,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: compact ? 18 : 22),
        prefixIconConstraints:
            compact
                ? const BoxConstraints(minWidth: 32, minHeight: 32)
                : null,
        isDense: true,
        contentPadding:
            compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items:
              options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (next) {
            if (next == null) return;
            onChanged(next);
          },
        ),
      ),
    );
  }

  List<CompactStatItem> _buildStats(List<RestaurantOrderModel> orders) {
    final pending =
        orders.where((o) => o.currentRestaurantStatus == 'pending').length;
    final preparing =
        orders.where((o) => o.currentRestaurantStatus == 'preparing').length;
    final ready =
        orders.where((o) => o.currentRestaurantStatus == 'ready').length;
    final revenue = orders
        .where(
          (o) =>
              o.currentRestaurantStatus == 'shipped' ||
              o.currentRestaurantStatus == 'delivered',
        )
        .fold<double>(0, (sum, order) => sum + order.itemsPrice);

    return [
      CompactStatItem(
        title: 'قيد الانتظار',
        value: '$pending',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
      ),
      CompactStatItem(
        title: 'قيد التنفيذ',
        value: '$preparing',
        icon: Icons.soup_kitchen_outlined,
        color: AppColors.info,
      ),
      CompactStatItem(
        title: 'جاهز',
        value: '$ready',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      CompactStatItem(
        title: 'الإيرادات',
        value: '${revenue.toStringAsFixed(0)} ج.م',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
    ];
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} د';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} س';
    return '${dateTime.day}/${dateTime.month}';
  }

  DataTableConfig _tableConfig(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return DataTableConfig(
      containerMargin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      containerColor: theme.colorScheme.surface,
      containerBorderRadius: BorderRadius.circular(12),
      containerShadow: [
        BoxShadow(
          color: AppColors.withOpacity(AppColors.black, isDark ? 0.28 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      columnSpacing: 16,
      horizontalMargin: 12,
      headingRowHeight: 52,
      dataRowHeight: 72,
      headingRowColor:
          isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      dividerThickness: 1,
      showCheckboxColumn: false,
    );
  }

  DataRow _buildRow(BuildContext context, RestaurantOrderModel order) {
    final restaurantId = _restaurantId!;
    final typeColor = order.isPickup ? AppColors.warning : AppColors.info;

    return DataRow(
      cells: [
        DataCell(
          TableCellBuilders.buildIdCell(
            order.id,
            backgroundColor: AppColors.withOpacity(AppColors.primary, 0.12),
            textColor: AppColors.primaryDark,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                order.isPickup
                    ? Icons.storefront_outlined
                    : Icons.delivery_dining,
                size: 18,
                color: typeColor,
              ),
              const SizedBox(width: 6),
              Text(
                order.isPickup ? 'استلام' : 'توصيل',
                style: TextStyle(color: typeColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        DataCell(
          StatusBadge(
            status: order.currentRestaurantStatus,
            isPickup: order.isPickup,
          ),
        ),
        DataCell(Text('${order.items.length}')),
        DataCell(
          Text(
            '${order.itemsPrice.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
        DataCell(Text(_formatTime(order.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed:
                    () => OrderStatusSheet.show(context, order, restaurantId),
                child: const Text('تحديث'),
              ),
              IconButton(
                tooltip: 'التفاصيل',
                onPressed: () => OrderDetailsBottomSheet.show(context, order),
                icon: const Icon(Icons.info_outline, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            if (_restaurantId == null) {
              return const ErrorState(message: 'خطأ في تحديد المطعم');
            }

            if (state.isLoading && state.orders.isEmpty) {
              return const LoadingState();
            }

            if (state.error != null) {
              return ErrorState(message: state.error!, onRetry: _initialize);
            }

            final filtered = _applyFilters(state.orders);
            final hasActiveFilters =
                _searchQuery.isNotEmpty ||
                _selectedStatusFilter != 'الكل' ||
                _selectedTypeFilter != 'الكل';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompactStatsBanner(
                  items: _buildStats(state.orders),
                  margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Builder(
                    builder: (context) {
                      final isCompact = MediaQuery.sizeOf(context).width < 768;
                      return ResponsiveFilterRow(
                        spacing: isCompact ? 6 : 8,
                        items: [
                          ResponsiveFilterRowItem(
                            flex: isCompact ? 3 : 2,
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                labelText: 'بحث',
                                hintText:
                                    isCompact
                                        ? 'رقم...'
                                        : 'رقم الطلب، العنوان، الهاتف...',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: isCompact ? 18 : 22,
                                ),
                                prefixIconConstraints:
                                    isCompact
                                        ? const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        )
                                        : null,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: isCompact ? 8 : 12,
                                ),
                                suffixIcon:
                                    _searchQuery.isEmpty
                                        ? null
                                        : IconButton(
                                          tooltip: 'مسح',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                          icon: Icon(
                                            Icons.close_rounded,
                                            size: isCompact ? 18 : 22,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          ResponsiveFilterRowItem(
                            flex: isCompact ? 2 : 1,
                            child: _buildDropdownFilter(
                              label: isCompact ? 'الحالة' : 'حالة الطلب',
                              icon: Icons.filter_list_rounded,
                              value: _selectedStatusFilter,
                              options: _statusFilters,
                              compact: isCompact,
                              onChanged:
                                  (value) => setState(
                                    () => _selectedStatusFilter = value,
                                  ),
                            ),
                          ),
                          ResponsiveFilterRowItem(
                            flex: isCompact ? 2 : 1,
                            child: _buildDropdownFilter(
                              label: isCompact ? 'النوع' : 'نوع الطلب',
                              icon: Icons.swap_horiz_rounded,
                              value: _selectedTypeFilter,
                              options: _typeFilters,
                              compact: isCompact,
                              onChanged:
                                  (value) => setState(
                                    () => _selectedTypeFilter = value,
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh:
                        () => context.read<OrdersCubit>().fetchOrders(
                          _restaurantId!,
                        ),
                    child: SharedDataTable<RestaurantOrderModel>(
                      items: filtered,
                      columns: _columns,
                      rowBuilder: _buildRow,
                      config: _tableConfig(theme),
                      itemsPerPage: 10,
                      mobileCardWidth: 320,
                      mobileCardHeight: 132,
                      mobileCardSpacing: 8,
                      mobilePreferList: true,
                      mobileCardBuilder:
                          (context, order) => OrderCard(
                            order: order,
                            restaurantId: _restaurantId!,
                          ),
                      emptyWidget: EmptyState(
                        title: 'لا توجد طلبات',
                        subtitle:
                            hasActiveFilters
                                ? 'لا توجد نتائج مطابقة للبحث أو الفلاتر'
                                : 'لم يتم استلام أي طلبات بعد',
                        icon: Icons.receipt_long_rounded,
                      ),
                      paginationLabelBuilder:
                          (from, to, total) =>
                              'عرض $from-$to من أصل $total طلب',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
