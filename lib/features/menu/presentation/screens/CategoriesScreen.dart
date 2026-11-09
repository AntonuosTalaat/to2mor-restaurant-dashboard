import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StateComponents.dart';
import 'package:restaurantdashboard/Providers/SettingProvider.dart';
import 'package:restaurantdashboard/config/injection_container.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/features/menu/data/datasources/items_excel_service.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_state.dart';
import 'package:restaurantdashboard/features/menu/presentation/widgets/ItemCard.dart';
import 'package:restaurantdashboard/features/menu/presentation/screens/item_details.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table_config.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';
import 'package:restaurantdashboard/shared/widgets/header_icon_chip.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_action.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_slot_controller.dart';
import 'package:restaurantdashboard/shared/widgets/responsive_filter_row.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItemsExcelService _excelService = sl<ItemsExcelService>();
  final Object _headerOwner = Object();
  PageHeaderSlotController? _headerSlot;

  String _selectedCategory = 'الكل';
  String _availabilityFilter = 'الكل';
  String _searchQuery = '';
  bool _isExcelBusy = false;

  static const _columns = <DataTableColumn>[
    DataTableColumn(label: 'الصنف', icon: Icons.restaurant_menu_rounded),
    DataTableColumn(label: 'التصنيف', icon: Icons.category_outlined),
    DataTableColumn(label: 'السعر', icon: Icons.payments_outlined),
    DataTableColumn(label: 'الحالة', icon: Icons.toggle_on_outlined),
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
      context.read<MenuCubit>().loadMenu();
      context.read<SettingsProvider>().loadSettings();
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
      _ExcelHeaderButton(
        busy: _isExcelBusy,
        onExport: _exportItemsToExcel,
        onImport: _importItemsFromExcel,
      ),
      PageHeaderAction(
        icon: Icons.add_rounded,
        label: 'إضافة صنف',
        tooltip: 'إضافة صنف',
        onPressed: () => _openItemDetails(),
      ),
    ]);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  List<String> _categories(List<ItemModel> items) {
    final cats = items.map((e) => e.category).toSet().toList()..sort();
    return ['الكل', ...cats];
  }

  List<ItemModel> _applyFilters(List<ItemModel> items) {
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      final matchCategory =
          _selectedCategory == 'الكل' || item.category == _selectedCategory;
      final matchAvailability = switch (_availabilityFilter) {
        'متاح' => item.isAvailable,
        'غير متاح' => !item.isAvailable,
        _ => true,
      };
      final matchSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchCategory && matchAvailability && matchSearch;
    }).toList();
  }

  List<CompactStatItem> _buildStats(List<ItemModel> items) {
    final available = items.where((e) => e.isAvailable).length;
    final unavailable = items.length - available;
    final categories = items.map((e) => e.category).toSet().length;
    return [
      CompactStatItem(
        title: 'إجمالي الأصناف',
        value: '${items.length}',
        icon: Icons.restaurant_menu_rounded,
        color: AppColors.primary,
      ),
      CompactStatItem(
        title: 'متاح',
        value: '$available',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      CompactStatItem(
        title: 'غير متاح',
        value: '$unavailable',
        icon: Icons.pause_circle_outline,
        color: AppColors.warning,
      ),
      CompactStatItem(
        title: 'التصنيفات',
        value: '$categories',
        icon: Icons.category_outlined,
        color: AppColors.info,
      ),
    ];
  }

  String _priceLabel(ItemModel item) {
    if (item.sizes.isEmpty) return '—';
    final prices =
        item.sizes
            .map((s) => s.price * (1 - s.discountPercent / 100))
            .toList();
    if (prices.length == 1) return '${prices.first.toStringAsFixed(0)} ج.م';
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} ج.م';
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
      dataRowHeight: 76,
      headingRowColor:
          isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      dividerThickness: 1,
      showCheckboxColumn: false,
    );
  }

  bool get _isMartRestaurant =>
      context.read<MenuCubit>().state.restaurantType == 'mart';

  Future<List<MartCategoryModel>> _martCategoriesForExcel() async {
    if (!_isMartRestaurant) return const [];
    final cubit = context.read<MartCategoriesCubit>();
    if (cubit.state.items.isEmpty) {
      await cubit.initialize();
      await cubit.refresh();
    }
    return cubit.state.items;
  }

  Future<void> _exportItemsToExcel() async {
    if (_isExcelBusy) return;
    final items = context.read<MenuCubit>().state.items;
    if (items.isEmpty) {
      _showSnack('لا توجد أصناف للتصدير', isError: true);
      return;
    }
    setState(() => _isExcelBusy = true);
    try {
      final martCategories = await _martCategoriesForExcel();
      if (!mounted) return;
      await _excelService.downloadItemsExcel(
        items,
        martCategories: martCategories,
      );
      _showSnack('تم تصدير ${items.length} صنف إلى Excel');
    } catch (e) {
      _showSnack('فشل التصدير: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExcelBusy = false);
    }
  }

  Future<void> _importItemsFromExcel() async {
    if (_isExcelBusy) return;
    final restaurantId = FirebaseAuth.instance.currentUser?.uid;
    if (restaurantId == null || restaurantId.isEmpty) {
      _showSnack('يجب تسجيل الدخول أولاً', isError: true);
      return;
    }

    final cubit = context.read<MenuCubit>();
    setState(() => _isExcelBusy = true);
    try {
      final martCategories = await _martCategoriesForExcel();
      if (!mounted) return;
      if (_isMartRestaurant && martCategories.isEmpty) {
        _showSnack(
          'لا توجد فئات مارت. أضف الفئات أولاً قبل استيراد الأصناف',
          isError: true,
        );
        return;
      }

      final imported = await _excelService.pickAndParseItems(
        restaurantId: restaurantId,
        martCategories: martCategories,
      );
      if (imported == null) return;
      if (imported.isEmpty) {
        _showSnack('الملف لا يحتوي على أصناف', isError: true);
        return;
      }
      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('استيراد من Excel'),
              content: Text(
                'سيتم تحديث/إضافة ${imported.length} صنف.\n'
                'الأصناف الموجودة تُحدَّث بالاسم.\n'
                'الأصناف الجديدة تحتاج رابط صورة في الشيت.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('استيراد'),
                ),
              ],
            ),
      );
      if (confirm != true || !mounted) return;

      final result = await cubit.upsertItemsFromExcel(imported);
      _showSnack(
        'تم الاستيراد: ${result.added} جديد، ${result.updated} محدّث'
        '${result.skipped > 0 ? '، ${result.skipped} متخطى' : ''}',
      );
    } catch (e, st) {
      debugPrint('[Excel import] $e');
      debugPrintStack(stackTrace: st, label: 'Excel import');
      _showSnack('فشل الاستيراد: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExcelBusy = false);
    }
  }

  Future<void> _onDeleteItem(String itemName) async {
    try {
      await context.read<MenuCubit>().deleteItem(itemName);
    } catch (e) {
      _showSnack('فشل حذف الصنف: $e', isError: true);
    }
  }

  void _openItemDetails({ItemModel? itemToEdit}) {
    final menuCubit = context.read<MenuCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: menuCubit,
          child: ItemDetailsScreen(
            itemToEdit: itemToEdit,
            onSubmit: (newItem, imageBytes) async {
              if (itemToEdit == null &&
                  imageBytes == null &&
                  newItem.imageUrl.isEmpty) {
                throw Exception('Image is required for new items');
              }
              await menuCubit.saveItem(
                item: newItem,
                oldItemName: itemToEdit?.name,
                imageFile: imageBytes,
              );
            },
          ),
        ),
      ),
    );
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

  DataRow _buildRow(BuildContext context, ItemModel item) {
    final scheme = Theme.of(context).colorScheme;
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported, size: 18),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(item.category)),
        DataCell(
          Text(
            _priceLabel(item),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.withOpacity(
                item.isAvailable ? AppColors.success : AppColors.error,
                0.12,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.isAvailable ? 'متاح' : 'غير متاح',
              style: TextStyle(
                color: item.isAvailable ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _openItemDetails(itemToEdit: item),
                child: const Text('تعديل'),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: () => _onDeleteItem(item.name),
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
    final isActive = context.select(
      (NavigationCubit c) => c.state.currentItem == NavigationItem.menu,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncHeaderActions(isActive);
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocBuilder<MenuCubit, MenuState>(
          builder: (context, state) {
            if (state.isLoading && state.items.isEmpty) {
              return const LoadingState();
            }

            final filtered = _applyFilters(state.items);
            final categories = _categories(state.items);
            final isCompact = MediaQuery.sizeOf(context).width < 768;
            final hasFilters =
                _searchQuery.isNotEmpty ||
                _selectedCategory != 'الكل' ||
                _availabilityFilter != 'الكل';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompactStatsBanner(
                  items: _buildStats(state.items),
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
                            hintText: isCompact ? 'اسم...' : 'اسم الصنف أو الوصف أو التصنيف',
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
                        child: _buildDropdownFilter(
                          label: isCompact ? 'التصنيف' : 'تصنيف الصنف',
                          icon: Icons.category_outlined,
                          value:
                              categories.contains(_selectedCategory)
                                  ? _selectedCategory
                                  : 'الكل',
                          options: categories,
                          compact: isCompact,
                          onChanged:
                              (value) =>
                                  setState(() => _selectedCategory = value),
                        ),
                      ),
                      ResponsiveFilterRowItem(
                        flex: isCompact ? 2 : 1,
                        child: _buildDropdownFilter(
                          label: isCompact ? 'التوفر' : 'حالة التوفر',
                          icon: Icons.toggle_on_outlined,
                          value: _availabilityFilter,
                          options: const ['الكل', 'متاح', 'غير متاح'],
                          compact: isCompact,
                          onChanged:
                              (value) =>
                                  setState(() => _availabilityFilter = value),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<MenuCubit>().loadMenu(),
                    child: SharedDataTable<ItemModel>(
                      items: filtered,
                      columns: _columns,
                      rowBuilder: _buildRow,
                      config: _tableConfig(theme),
                      itemsPerPage: 10,
                      mobilePreferList: false,
                      mobileCrossAxisCount: 3,
                      mobileCardHeight: 168,
                      mobileCardSpacing: 6,
                      mobileCardBuilder:
                          (context, item) => ItemCard(
                            item: item,
                            fillFixedSize: true,
                            onEdit: () => _openItemDetails(itemToEdit: item),
                            onDelete: () => _onDeleteItem(item.name),
                          ),
                      emptyWidget: EmptyState(
                        title: 'لا توجد أصناف',
                        subtitle:
                            hasFilters
                                ? 'لا توجد نتائج مطابقة للبحث أو الفلاتر'
                                : 'أضف أول صنف للقائمة',
                        icon: Icons.restaurant_menu_rounded,
                      ),
                      paginationLabelBuilder:
                          (from, to, total) =>
                              'عرض $from-$to من أصل $total صنف',
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

class _ExcelHeaderButton extends StatelessWidget {
  const _ExcelHeaderButton({
    required this.busy,
    required this.onExport,
    required this.onImport,
  });

  final bool busy;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    final items = const [
      PopupMenuItem(
        value: 'export',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.file_download_outlined),
          title: Text('تصدير (تنزيل)'),
        ),
      ),
      PopupMenuItem(
        value: 'import',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.file_upload_outlined),
          title: Text('استيراد (رفع)'),
        ),
      ),
    ];

    if (isMobile) {
      return PopupMenuButton<String>(
        tooltip: 'Excel',
        enabled: !busy,
        offset: const Offset(0, 40),
        onSelected: (value) {
          if (value == 'export') onExport();
          if (value == 'import') onImport();
        },
        itemBuilder: (context) => items,
        child: IgnorePointer(
          child: HeaderIconChip(
            icon: Icons.table_view_rounded,
            tooltip: 'Excel',
            isActive: busy,
          ),
        ),
      );
    }

    return MenuAnchor(
      builder: (context, controller, child) {
        return FilledButton.tonalIcon(
          onPressed:
              busy
                  ? null
                  : () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
          icon:
              busy
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.table_view_rounded, size: 18),
          label: const Text('Excel'),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: onExport,
          leadingIcon: const Icon(Icons.file_download_outlined),
          child: const Text('تصدير (تنزيل)'),
        ),
        MenuItemButton(
          onPressed: onImport,
          leadingIcon: const Icon(Icons.file_upload_outlined),
          child: const Text('استيراد (رفع)'),
        ),
      ],
    );
  }
}
