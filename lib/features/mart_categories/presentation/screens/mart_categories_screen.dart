import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_state.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/screens/mart_category_details_screen.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/widgets/mart_categories_filters_bar.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/widgets/mart_categories_table.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/widgets/mart_category_form_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MartCategoriesScreen extends StatefulWidget {
  const MartCategoriesScreen({super.key});

  @override
  State<MartCategoriesScreen> createState() => _MartCategoriesScreenState();

  static Future<void> importExcel(BuildContext context) async {
    final cubit = context.read<MartCategoriesCubit>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    await cubit.importFromExcel(bytes);
  }

  static Future<void> exportExcel(BuildContext context) async {
    final cubit = context.read<MartCategoriesCubit>();
    if (cubit.state.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
      return;
    }
    final bytes = cubit.exportToExcelBytes();
    await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ ملف فئات المارت',
      fileName: 'mart_categories.xlsx',
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: bytes,
    );
  }
}

class _MartCategoriesScreenState extends State<MartCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MartCategoriesCubit>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MartCategoryModel> _filteredItems(List<MartCategoryModel> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      return item.nameAr.toLowerCase().contains(query) ||
          item.nameEn.toLowerCase().contains(query) ||
          (item.shortDescAr?.toLowerCase().contains(query) ?? false) ||
          (item.shortDescEn?.toLowerCase().contains(query) ?? false) ||
          item.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<MartCategoriesCubit, MartCategoriesState>(
        listenWhen: (previous, current) => previous.error != current.error,
        listener: (context, state) {
          if (state.error == null || state.error!.isEmpty) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          final cubit = context.read<MartCategoriesCubit>();
          final filteredItems = _filteredItems(state.items);

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            body: Column(
              children: [
                MartCategoriesFiltersBar(
                  searchController: _searchController,
                  isBusy: state.isBusy,
                  onSearchChanged:
                      (value) => setState(() => _searchQuery = value),
                  onAdd: () => _openFormSheet(context, cubit),
                ),
                Expanded(
                  child: MartCategoriesTable(
                    items: filteredItems,
                    onEdit: (MartCategoryModel item) =>
                        _openDetails(context, item),
                    onDelete: (MartCategoryModel item) =>
                        cubit.deleteCategory(item.id),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, MartCategoryModel item) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<MartCategoriesCubit>(),
          child: MartCategoryDetailsScreen(categoryId: item.id),
        ),
      ),
    );
  }

  Future<void> _openFormSheet(
    BuildContext context,
    MartCategoriesCubit cubit,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MartCategoryFormSheet(cubit: cubit),
    );
  }
}
