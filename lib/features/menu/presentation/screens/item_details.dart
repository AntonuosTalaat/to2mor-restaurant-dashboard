import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/Components/CommonComponents/CustomFormField.dart';
import 'package:restaurantdashboard/Providers/SettingProvider.dart';
import 'package:restaurantdashboard/Services/firebase_storage_service.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_state.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/widgets/item_extra_selector.dart';

class ItemDetailsScreen extends StatefulWidget {
  final ItemModel? itemToEdit;
  final Future<void> Function(ItemModel, Uint8List?) onSubmit;

  const ItemDetailsScreen({super.key, this.itemToEdit, required this.onSubmit});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late final TextEditingController nameController;
  late final TextEditingController descController;
  late final TextEditingController imageUrlController;
  late String selectedCategory;
  late String selectedCategoryEn;
  late String selectedMartCategoryId;
  late String selectedMartSubCategoryId;
  Uint8List? imageBytes;
  String? imageName;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  bool allowCustomDetails = false;

  List<ItemSizeInput> sizes = [];

  // ✅ بنخزن الـ IDs بس مش الـ objects
  List<String> _selectedExtraIds = [];
  bool _extrasLoaded = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.itemToEdit?.name ?? '');
    descController = TextEditingController(
      text: widget.itemToEdit?.description ?? '',
    );
    imageUrlController = TextEditingController(
      text: widget.itemToEdit?.imageUrl ?? '',
    );
    imageUrlController.addListener(_onImageUrlControllerChanged);
    selectedCategory = widget.itemToEdit?.category ?? '';
    selectedCategoryEn = widget.itemToEdit?.categoryEn ?? '';
    selectedMartCategoryId = widget.itemToEdit?.martCategoryId ?? '';
    selectedMartSubCategoryId = widget.itemToEdit?.martSubCategoryId ?? '';
    allowCustomDetails = widget.itemToEdit?.allowCustomDetails ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isMart =
          context.read<AuthProvider>().restaurant?.restaurantType == 'mart';
      if (isMart) {
        context.read<MartCategoriesCubit>().initialize();
      } else if (selectedCategory.isEmpty) {
        final categories =
            context.read<SettingsProvider>().settings?.categories ?? [];
        final available =
            categories.where((category) => category != 'الكل').toList();
        if (available.isNotEmpty) {
          setState(() => selectedCategory = available.first);
        }
      }
    });

    // ✅ جيب الـ IDs المحفوظة لو بنعدل
    _selectedExtraIds = List<String>.from(widget.itemToEdit?.extrasIds ?? []);

    if (widget.itemToEdit != null && widget.itemToEdit!.sizes.isNotEmpty) {
      sizes =
          widget.itemToEdit!.sizes
              .map(
                (size) => ItemSizeInput(
                  nameController: TextEditingController(text: size.name),
                  priceController: TextEditingController(
                    text: size.price.toString(),
                  ),
                  discountController: TextEditingController(
                    text: size.discountPercent.toString(),
                  ),
                ),
              )
              .toList();
    } else {
      _addNewSize();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExtrasIfNeeded());
  }

  Future<void> _loadExtrasIfNeeded() async {
    if (!mounted || _extrasLoaded) return;
    _extrasLoaded = true;

    final cubit = context.read<MenuCubit>();
    if (cubit.state.extrasList.isNotEmpty) return;

    await cubit.fetchRestaurantExtras();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final categories = settingsProvider.settings?.categories ?? [];

    if (selectedCategory.isEmpty && categories.isNotEmpty) {
      selectedCategory = categories.firstWhere(
        (e) => e != 'الكل',
        orElse: () => categories.first,
      );
    }
  }

  void _setImageUrlSilently(String url) {
    imageUrlController.removeListener(_onImageUrlControllerChanged);
    imageUrlController.text = url;
    imageUrlController.addListener(_onImageUrlControllerChanged);
  }

  void _clearImageUrlSilently() {
    imageUrlController.removeListener(_onImageUrlControllerChanged);
    imageUrlController.clear();
    imageUrlController.addListener(_onImageUrlControllerChanged);
  }

  void _onImageUrlControllerChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (imageBytes != null) {
        setState(() {
          imageBytes = null;
          imageName = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  String? get _currentImageUrl {
    if (imageBytes != null) return null;
    final url = imageUrlController.text.trim();
    if (url.isNotEmpty) return url;
    return null;
  }

  void _copyImageUrl() {
    final url = _currentImageUrl;
    if (url == null) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
  }

  @override
  void dispose() {
    imageUrlController.removeListener(_onImageUrlControllerChanged);
    nameController.dispose();
    descController.dispose();
    imageUrlController.dispose();
    for (var size in sizes) {
      size.dispose();
    }
    super.dispose();
  }

  void _addNewSize() {
    setState(() {
      sizes.add(
        ItemSizeInput(
          nameController: TextEditingController(),
          priceController: TextEditingController(),
          discountController: TextEditingController(text: '0'),
        ),
      );
    });
  }

  void _removeSize(int index) {
    if (sizes.length > 1) {
      setState(() {
        sizes[index].dispose();
        sizes.removeAt(index);
      });
    }
  }

  Future<Uint8List> _readPickerStream(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowCompression: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) && file.readStream != null) {
        bytes = await _readPickerStream(file.readStream!);
      }
      if (bytes == null || bytes.isEmpty) {
        throw Exception('تعذر قراءة ملف الصورة');
      }

      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('يجب تسجيل الدخول لرفع الصورة');
      }

      _clearImageUrlSilently();
      setState(() {
        _isUploading = true;
        imageBytes = bytes;
        imageName = file.name;
        _uploadedImageUrl = null;
      });

      final itemLabel = nameController.text.trim().isEmpty
          ? 'item'
          : nameController.text.trim().replaceAll(' ', '_');
      final uploadName =
          '${itemLabel}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final url = await FirebaseStorageService().uploadItemImage(
        bytes,
        uploadName,
      );

      if (!mounted) return;
      _setImageUrlSilently(url);
      setState(() {
        _uploadedImageUrl = url;
        imageBytes = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الصورة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          imageBytes = null;
          imageName = null;
          _uploadedImageUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصورة: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اسم الصنف مطلوب')));
      return;
    }

    List<ItemSize> validSizes = [];
    for (int i = 0; i < sizes.length; i++) {
      final sizeInput = sizes[i];

      if (sizeInput.nameController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('اسم الحجم ${i + 1} مطلوب')));
        return;
      }

      final price = double.tryParse(sizeInput.priceController.text);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى إدخال سعر صحيح للحجم ${i + 1}')),
        );
        return;
      }

      final discount =
          double.tryParse(sizeInput.discountController.text) ?? 0.0;
      if (discount < 0 || discount > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('نسبة الخصم يجب أن تكون بين 0 و 100 للحجم ${i + 1}'),
          ),
        );
        return;
      }

      validSizes.add(
        ItemSize(
          name: sizeInput.nameController.text.trim(),
          price: price,
          discountPercent: discount,
        ),
      );
    }

    final imageUrl = imageUrlController.text.trim();
    if (widget.itemToEdit == null && imageUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text('صورة الصنف مطلوبة — اختر صورة أو أدخل رابط'),
        ),
      );
      return;
    }

    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر حتى ينتهي رفع الصورة')),
      );
      return;
    }

    final restaurantId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final isMart =
        context.read<AuthProvider>().restaurant?.restaurantType == 'mart';
    if (isMart) {
      final martCategories =
          context
              .read<MartCategoriesCubit>()
              .state
              .items
              .where((category) => category.isActive)
              .toList();
      if (martCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار فئة مارت')),
        );
        return;
      }
      final selectedId = _resolveMartCategoryId(martCategories);
      final category = martCategories.firstWhere(
        (item) => item.id == selectedId,
      );
      selectedMartCategoryId = category.id;
      selectedCategory = category.nameAr;
      selectedCategoryEn = category.nameEn;
      selectedMartSubCategoryId = _resolveMartSubCategoryId(category);
    }

    final newItem = ItemModel(
      id: widget.itemToEdit?.id ?? UniqueKey().toString(),
      name: nameController.text.trim(),
      description: descController.text.trim(),
      category: selectedCategory,
      categoryEn: selectedCategoryEn,
      martCategoryId: selectedMartCategoryId,
      martSubCategoryId: selectedMartSubCategoryId,
      imageUrl: imageUrl.isNotEmpty
          ? imageUrl
          : (widget.itemToEdit?.imageUrl ?? ''),
      restaurantId: restaurantId,
      sizes: validSizes,
      allowCustomDetails: allowCustomDetails,
      extrasIds: _selectedExtraIds, // ✅ بنبعت الـ IDs
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(newItem, null);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ الصنف: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isMart =
        context.watch<AuthProvider>().restaurant?.restaurantType == 'mart';

    Widget child;
    if (isMart) {
      child = BlocBuilder<MartCategoriesCubit, MartCategoriesState>(
        builder: (context, martState) {
          final martCategories =
              martState.items.where((category) => category.isActive).toList();

          if (martState.isLoading && martCategories.isEmpty) {
            return _buildCategoriesUnavailableSheet(
              context,
              theme: theme,
              scheme: scheme,
              muted: muted,
              title: 'جاري تحميل فئات المارت...',
              subtitle: 'يرجى الانتظار',
              showLoader: true,
            );
          }

          if (martCategories.isEmpty) {
            return _buildCategoriesUnavailableSheet(
              context,
              theme: theme,
              scheme: scheme,
              muted: muted,
              title: 'لا توجد فئات مارت متاحة',
              subtitle: 'يرجى إضافة فئات من قسم فئات المارت أولاً',
            );
          }

          return _buildDialogBody(
            context,
            isEditing: isEditing,
            theme: theme,
            scheme: scheme,
            muted: muted,
            martCategories: martCategories,
          );
        },
      );
    } else {
      final categories = settingsProvider.settings?.categories ?? [];
      final availableCategories =
          categories.where((e) => e != 'الكل').toList();

      if (availableCategories.isEmpty) {
        child = _buildCategoriesUnavailableSheet(
          context,
          theme: theme,
          scheme: scheme,
          muted: muted,
          title: 'لا توجد فئات متاحة',
          subtitle: 'يرجى إضافة فئات من لوحة الإعدادات أولاً',
        );
      } else {
        child = _buildDialogBody(
          context,
          isEditing: isEditing,
          theme: theme,
          scheme: scheme,
          muted: muted,
          availableCategories: availableCategories,
        );
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    );
  }

  String _resolveMartCategoryId(List<MartCategoryModel> martCategories) {
    if (selectedMartCategoryId.isNotEmpty &&
        martCategories.any((category) => category.id == selectedMartCategoryId)) {
      return selectedMartCategoryId;
    }
    for (final category in martCategories) {
      if (category.nameAr == selectedCategory) {
        return category.id;
      }
    }
    return martCategories.first.id;
  }

  MartCategoryModel _selectedMartCategory(
    List<MartCategoryModel> martCategories,
  ) {
    final id = _resolveMartCategoryId(martCategories);
    return martCategories.firstWhere((item) => item.id == id);
  }

  String _resolveMartSubCategoryId(MartCategoryModel category) {
    final activeSubs = category.activeSubCategories;
    if (activeSubs.isEmpty) return '';
    if (selectedMartSubCategoryId.isNotEmpty &&
        activeSubs.any((sub) => sub.id == selectedMartSubCategoryId)) {
      return selectedMartSubCategoryId;
    }
    return activeSubs.first.id;
  }

  Widget _buildCategoriesUnavailableSheet(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme scheme,
    required Color muted,
    required String title,
    required String subtitle,
    bool showLoader = false,
  }) {
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(widget.itemToEdit != null ? 'تعديل الصنف' : 'إضافة صنف جديد'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showLoader)
                const CircularProgressIndicator()
              else
                Icon(
                  Icons.warning_amber_rounded,
                  size: 52,
                  color: scheme.error,
                ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: showLoader ? null : () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(showLoader ? 'جاري التحميل' : 'حسناً'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogBody(
    BuildContext context, {
    required bool isEditing,
    required ThemeData theme,
    required ColorScheme scheme,
    required Color muted,
    List<String>? availableCategories,
    List<MartCategoryModel>? martCategories,
  }) {
    return Scaffold(
      backgroundColor:
          theme.brightness == Brightness.dark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد'),
      ),
      body: _buildDialogContent(
        context,
        isEditing: isEditing,
        theme: theme,
        scheme: scheme,
        muted: muted,
        availableCategories: availableCategories,
        martCategories: martCategories,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    side: BorderSide(color: scheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (_isUploading || _isSaving) ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'تحديث' : 'إضافة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(
    BuildContext context, {
    required bool isEditing,
    required ThemeData theme,
    required ColorScheme scheme,
    required Color muted,
    List<String>? availableCategories,
    List<MartCategoryModel>? martCategories,
  }) {
    final isMart = martCategories != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final formColumn = _buildFormSections(
          context,
          isEditing: isEditing,
          theme: theme,
          scheme: scheme,
          muted: muted,
          availableCategories: availableCategories,
          martCategories: martCategories,
          isMart: isMart,
          includeImage: !isWide,
        );
        final imageColumn = _buildImageSection(
          theme: theme,
          scheme: scheme,
          isEditing: isEditing,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // RTL: image on the right.
                    Expanded(flex: 4, child: imageColumn),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: formColumn),
                  ],
                )
              : formColumn,
        );
      },
    );
  }

  Widget _buildFormSections(
    BuildContext context, {
    required bool isEditing,
    required ThemeData theme,
    required ColorScheme scheme,
    required Color muted,
    required bool isMart,
    required bool includeImage,
    List<String>? availableCategories,
    List<MartCategoryModel>? martCategories,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── المعلومات الأساسية ──
        Card(
          elevation: 0,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المعلومات الأساسية',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                CustomFormField(
                  controller: nameController,
                  labelText: 'اسم الصنف',
                  prefixIcon: const Icon(Icons.fastfood),
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: descController,
                  labelText: 'الوصف',
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.description),
                ),
                const SizedBox(height: 12),
                if (isMart && martCategories != null) ...[
                  DropdownButtonFormField<String>(
                    value: _resolveMartCategoryId(martCategories),
                    items: martCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.nameAr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final category = martCategories.firstWhere(
                        (item) => item.id == value,
                      );
                      setState(() {
                        selectedMartCategoryId = category.id;
                        selectedCategory = category.nameAr;
                        selectedCategoryEn = category.nameEn;
                        selectedMartSubCategoryId =
                            category.activeSubCategories.isEmpty
                                ? ''
                                : category.activeSubCategories.first.id;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'فئة المارت',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  if (_selectedMartCategory(martCategories)
                      .activeSubCategories
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _resolveMartSubCategoryId(
                        _selectedMartCategory(martCategories),
                      ),
                      items: _selectedMartCategory(martCategories)
                          .activeSubCategories
                          .map(
                            (sub) => DropdownMenuItem(
                              value: sub.id,
                              child: Text(sub.nameAr),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedMartSubCategoryId = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'الفئة الفرعية',
                        prefixIcon: Icon(Icons.subdirectory_arrow_right),
                      ),
                    ),
                  ],
                ] else if (!isMart)
                  DropdownButtonFormField<String>(
                    value: availableCategories!.contains(selectedCategory)
                        ? selectedCategory
                        : availableCategories.first,
                    items: availableCategories
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value!),
                    decoration: const InputDecoration(
                      labelText: 'الفئة',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 24,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'السماح بإضافة تفاصيل مخصصة',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    Switch(
                      value: allowCustomDetails,
                      activeTrackColor: AppColors.primary,
                      onChanged: (value) =>
                          setState(() => allowCustomDetails = value),
                    ),
                  ],
                ),
                if (allowCustomDetails)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'سيتمكن العملاء من إضافة ملاحظات خاصة لهذا الصنف',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── الأحجام والأسعار ──
        Card(
          elevation: 0,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الأحجام والأسعار',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: _addNewSize,
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.success,
                      ),
                      tooltip: 'إضافة حجم جديد',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'أضف أحجام مختلفة للصنف مع أسعارها (مثل: صغير، وسط، كبير)',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sizes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'الحجم ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              if (sizes.length > 1)
                                IconButton(
                                  onPressed: () => _removeSize(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: sizes[index].nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم الحجم',
                                    hintText: 'مثل: صغير، وسط، كبير',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: sizes[index].priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'السعر',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    prefixText: 'ج.م ',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: sizes[index].discountController,
                                  decoration: const InputDecoration(
                                    labelText: 'خصم %',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ✅ ── الإضافات ──
        Card(
          elevation: 0,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.add_shopping_cart,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الإضافات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر الإضافات المتاحة لهذا الصنف',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 12),
                ItemExtrasSelector(
                  selectedIds: _selectedExtraIds,
                  onChanged: (updatedIds) =>
                      setState(() => _selectedExtraIds = updatedIds),
                ),
              ],
            ),
          ),
        ),

        if (includeImage) ...[
          const SizedBox(height: 16),
          _buildImageSection(
            theme: theme,
            scheme: scheme,
            isEditing: isEditing,
          ),
        ],
      ],
    );
  }

  Widget _buildImageSection({
    required ThemeData theme,
    required ColorScheme scheme,
    required bool isEditing,
  }) {
    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صورة الصنف',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            CustomFormField(
              controller: imageUrlController,
              labelText: 'رابط الصورة',
              hintText: 'أدخل رابط الصورة أو اخترها من الجهاز',
              prefixIcon: const Icon(Icons.link),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  if (imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes!,
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(imageName ?? '', style: theme.textTheme.bodySmall),
                  ] else if (_currentImageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppNetworkImage(
                        imageUrl: _currentImageUrl!,
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_currentImageUrl != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentImageUrl!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'نسخ الرابط',
                            onPressed: _copyImageUrl,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image),
                    label: Text(
                      _isUploading ? 'جاري الرفع...' : 'اختيار من الجهاز',
                    ),
                  ),
                  if (_uploadedImageUrl != null && !_isUploading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'تم رفع الصورة على Firebase Storage',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!isEditing &&
                      imageUrlController.text.trim().isEmpty &&
                      !_isUploading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'صورة الصنف مطلوبة (رابط أو من الجهاز)',
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemSizeInput {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController discountController;

  ItemSizeInput({
    required this.nameController,
    required this.priceController,
    required this.discountController,
  });

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    discountController.dispose();
  }
}

