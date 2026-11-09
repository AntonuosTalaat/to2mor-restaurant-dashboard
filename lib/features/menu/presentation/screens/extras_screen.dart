import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StateComponents.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/menu/data/models/item_extra_model.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_state.dart';
import 'package:restaurantdashboard/features/menu/presentation/widgets/ExtrasManagementDialog.dart';
import 'package:restaurantdashboard/features/menu/presentation/widgets/extra_card.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table_config.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_action.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_slot_controller.dart';
import 'package:restaurantdashboard/shared/widgets/responsive_filter_row.dart';

class ExtrasScreen extends StatefulWidget {
  const ExtrasScreen({super.key});

  @override
  State<ExtrasScreen> createState() => _ExtrasScreenState();
}

class _ExtrasScreenState extends State<ExtrasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Object _headerOwner = Object();
  PageHeaderSlotController? _headerSlot;
  String _searchQuery = '';
  String _discountFilter = 'الكل';

  static const _columns = <DataTableColumn>[
    DataTableColumn(label: 'الإضافة', icon: Icons.tune_rounded),
    DataTableColumn(label: 'السعر', icon: Icons.payments_outlined),
    DataTableColumn(label: 'الخصم', icon: Icons.local_offer_outlined),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuCubit>().fetchRestaurantExtras();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _headerSlot = context.read<PageHeaderSlotController>();
  }

  @override
  void dispose() {
    _headerSlot?.clear(_headerOwner);
    _searchController.dispose();
    super.dispose();
  }

  void _syncHeaderActions(bool isActive) {
    if (!mounted) return;
    final slot = _headerSlot;
    if (slot == null) return;
    if (!isActive) {
      slot.clear(_headerOwner);
      return;
    }
    slot.setActions(_headerOwner, [
      PageHeaderAction(
        icon: Icons.add_rounded,
        label: 'إضافة',
        tooltip: 'إضافة',
        onPressed: () => ExtrasManagementDialog.showEditor(context),
      ),
    ]);
  }

  List<ItemExtra> _applyFilters(List<ItemExtra> extras) {
    final query = _searchQuery.toLowerCase();
    return extras.where((extra) {
      final matchSearch =
          query.isEmpty || extra.name.toLowerCase().contains(query);
      final matchDiscount = switch (_discountFilter) {
        'بخصم' => extra.hasDiscount,
        'بدون خصم' => !extra.hasDiscount,
        _ => true,
      };
      return matchSearch && matchDiscount;
    }).toList();
  }

  List<CompactStatItem> _buildStats(List<ItemExtra> extras) {
    final withDiscount = extras.where((e) => e.hasDiscount).length;
    final avg =
        extras.isEmpty
            ? 0.0
            : extras.fold<double>(0, (sum, e) => sum + e.discountedPrice) /
                extras.length;

    return [
      CompactStatItem(
        title: 'إجمالي الإضافات',
        value: '${extras.length}',
        icon: Icons.tune_rounded,
        color: AppColors.primary,
      ),
      CompactStatItem(
        title: 'بخصم',
        value: '$withDiscount',
        icon: Icons.local_offer_outlined,
        color: AppColors.error,
      ),
      CompactStatItem(
        title: 'بدون خصم',
        value: '${extras.length - withDiscount}',
        icon: Icons.sell_outlined,
        color: AppColors.info,
      ),
      CompactStatItem(
        title: 'متوسط السعر',
        value: '${avg.toStringAsFixed(0)} ج.م',
        icon: Icons.payments_outlined,
        color: AppColors.success,
      ),
    ];
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

  Future<void> _deleteExtra(ItemExtra extra) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('حذف الإضافة'),
            content: Text('حذف "${extra.name}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف'),
              ),
            ],
          ),
    );
    if (confirm != true || !mounted) return;

    final cubit = context.read<MenuCubit>();
    final updated =
        cubit.state.extrasList.where((e) => e.id != extra.id).toList();
    try {
      await cubit.saveRestaurantExtras(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحذف: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  DataRow _buildRow(BuildContext context, ItemExtra extra) {
    final scheme = Theme.of(context).colorScheme;
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    (extra.img?.isNotEmpty ?? false)
                        ? AppNetworkImage(
                          imageUrl: extra.img!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: scheme.surfaceContainerHighest,
                                child: const Icon(Icons.image_outlined),
                              ),
                        )
                        : Container(
                          width: 44,
                          height: 44,
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined),
                        ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  extra.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            '${extra.discountedPrice.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
        DataCell(
          Text(
            extra.hasDiscount
                ? '${extra.discountPercent!.toStringAsFixed(0)}%'
                : '—',
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed:
                    () => ExtrasManagementDialog.showEditor(
                      context,
                      extra: extra,
                    ),
                child: const Text('تعديل'),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: () => _deleteExtra(extra),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
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
    final isCompact = MediaQuery.sizeOf(context).width < 768;
    final isActive = context.select(
      (NavigationCubit c) => c.state.currentItem == NavigationItem.extras,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncHeaderActions(isActive);
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocBuilder<MenuCubit, MenuState>(
          builder: (context, state) {
            final extras = state.extrasList;
            final filtered = _applyFilters(extras);
            final hasFilters =
                _searchQuery.isNotEmpty || _discountFilter != 'الكل';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompactStatsBanner(
                  items: _buildStats(extras),
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: ResponsiveFilterRow(
                    spacing: isCompact ? 6 : 8,
                    items: [
                      ResponsiveFilterRowItem(
                        flex: isCompact ? 3 : 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'بحث',
                            hintText: isCompact ? 'اسم...' : 'اسم الإضافة',
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
                            contentPadding:
                                isCompact
                                    ? const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    )
                                    : null,
                            suffixIcon:
                                _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
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
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: isCompact ? 'الخصم' : 'حالة الخصم',
                            prefixIcon: Icon(
                              Icons.local_offer_outlined,
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
                            contentPadding:
                                isCompact
                                    ? const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    )
                                    : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _discountFilter,
                              isExpanded: true,
                              isDense: true,
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 14,
                                color: theme.colorScheme.onSurface,
                              ),
                              items:
                                  const ['الكل', 'بخصم', 'بدون خصم']
                                      .map(
                                        (option) => DropdownMenuItem(
                                          value: option,
                                          child: Text(
                                            option,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _discountFilter = value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh:
                        () =>
                            context.read<MenuCubit>().fetchRestaurantExtras(),
                    child: SharedDataTable<ItemExtra>(
                      items: filtered,
                      columns: _columns,
                      rowBuilder: _buildRow,
                      config: _tableConfig(theme),
                      itemsPerPage: 10,
                      mobileCardWidth: 280,
                      mobileCardHeight: 108,
                      mobileCardSpacing: 12,
                      mobileCardBuilder:
                          (context, extra) => ExtraCard(
                            extra: extra,
                            fillFixedSize: true,
                            onEdit:
                                () => ExtrasManagementDialog.showEditor(
                                  context,
                                  extra: extra,
                                ),
                            onDelete: () => _deleteExtra(extra),
                          ),
                      emptyWidget: EmptyState(
                        title: 'لا توجد إضافات',
                        subtitle:
                            hasFilters
                                ? 'لا توجد نتائج مطابقة للبحث أو الفلاتر'
                                : 'أضف أول إضافة للمطعم',
                        icon: Icons.tune_rounded,
                      ),
                      paginationLabelBuilder:
                          (from, to, total) =>
                              'عرض $from-$to من أصل $total إضافة',
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
