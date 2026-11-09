import 'dart:typed_data';

import 'package:restaurantdashboard/Components/CommonComponents/MapLocationPicker.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_sub_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_state.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/widgets/mart_sub_category_form_sheet.dart';
import 'package:restaurantdashboard/shared/widgets/app_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

class MartCategoryDetailsScreen extends StatefulWidget {
  const MartCategoryDetailsScreen({
    super.key,
    required this.categoryId,
  });

  final String categoryId;

  @override
  State<MartCategoryDetailsScreen> createState() =>
      _MartCategoryDetailsScreenState();
}

class _MartCategoryDetailsScreenState extends State<MartCategoryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  late final TextEditingController _shortAr;
  late final TextEditingController _shortEn;
  late final TextEditingController _address;
  LatLng? _selectedLocation;
  bool _isActive = true;
  String _imageUrl = '';
  Uint8List? _previewBytes;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameAr = TextEditingController();
    _nameEn = TextEditingController();
    _shortAr = TextEditingController();
    _shortEn = TextEditingController();
    _address = TextEditingController();
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _shortAr.dispose();
    _shortEn.dispose();
    _address.dispose();
    super.dispose();
  }

  void _hydrateFrom(MartCategoryModel item) {
    _nameAr.text = item.nameAr;
    _nameEn.text = item.nameEn;
    _shortAr.text = item.shortDescAr ?? '';
    _shortEn.text = item.shortDescEn ?? '';
    _address.text = item.address;
    _selectedLocation = LatLng(item.lat, item.lng);
    _isActive = item.isActive;
    _imageUrl = item.imageUrl;
    _initialized = true;
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<MartCategoriesCubit, MartCategoriesState>(
        builder: (context, state) {
          MartCategoryModel? item;
          for (final e in state.items) {
            if (e.id == widget.categoryId) {
              item = e;
              break;
            }
          }

          if (item == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('تفاصيل الفئة')),
              body: const Center(child: Text('الفئة غير موجودة')),
            );
          }

          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_initialized) {
                setState(() => _hydrateFrom(item!));
              }
            });
          }

          final cubit = context.read<MartCategoriesCubit>();
          final subs = [...item.subCategories]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            appBar: AppBar(
              title: Text(item.nameAr),
              actions: [
                IconButton(
                  tooltip: 'إضافة فئة فرعية',
                  onPressed: () => _openSubSheet(cubit),
                  icon: const Icon(Icons.add_box_outlined),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openSubSheet(cubit),
              icon: const Icon(Icons.add),
              label: const Text('فئة فرعية'),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final image = _ImagePickerHeader(
                  imageUrl: _imageUrl,
                  previewBytes: _previewBytes,
                  isUploading: _isUploadingImage,
                  surfaceAlt: surfaceAlt,
                  borderColor: borderColor,
                  height: isWide ? 320 : 170,
                  onPick:
                      _isUploadingImage ? null : () => _pickImage(cubit),
                );
                final fields = _buildDetailsFields(
                  theme: theme,
                  item: item!,
                  cubit: cubit,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    Text(
                      'تفاصيل الفئة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // RTL: first child sits on the right.
                                Expanded(flex: 5, child: image),
                                const SizedBox(width: 16),
                                Expanded(flex: 6, child: fields),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                image,
                                const SizedBox(height: 14),
                                fields,
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'الفئات الفرعية (${subs.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openSubSheet(cubit),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (subs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Text(
                          'لا توجد فئات فرعية بعد. اضغط إضافة لإضافة أول فئة فرعية.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...subs.map(
                        (sub) => _SubCategoryTile(
                          sub: sub,
                          borderColor: borderColor,
                          onEdit: () => _openSubSheet(cubit, item: sub),
                          onDelete: () => _confirmDeleteSub(
                            cubit: cubit,
                            categoryId: item!.id,
                            sub: sub,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSubSheet(
    MartCategoriesCubit cubit, {
    MartSubCategoryModel? item,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MartSubCategoryFormSheet(
        cubit: cubit,
        categoryId: widget.categoryId,
        item: item,
      ),
    );
  }

  Widget _buildDetailsFields({
    required ThemeData theme,
    required MartCategoryModel item,
    required MartCategoriesCubit cubit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameAr,
                decoration: _fieldDecoration('الاسم (عربي)'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'الاسم العربي مطلوب'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _nameEn,
                decoration: _fieldDecoration('الاسم (English)'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'الاسم الإنجليزي مطلوب'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _shortAr,
          decoration: _fieldDecoration('وصف قصير (عربي) - اختياري'),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _shortEn,
          decoration: _fieldDecoration(
            'Short description (English) - optional',
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _address,
          readOnly: true,
          onTap: _selectLocation,
          decoration: _fieldDecoration('العنوان').copyWith(
            prefixIcon: Icon(
              Icons.location_on,
              color: _selectedLocation != null ? Colors.green : Colors.grey,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'العنوان مطلوب';
            }
            if (_selectedLocation == null) {
              return 'يرجى تحديد الموقع على الخريطة';
            }
            return null;
          },
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 6),
          Text(
            'lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}'
            ' · lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SwitchListTile(
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('نشط'),
        ),
        FilledButton(
          onPressed: (_isUploadingImage || _isSaving)
              ? null
              : () => _saveCategory(item, cubit),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('حفظ تعديلات الفئة'),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteSub({
    required MartCategoriesCubit cubit,
    required String categoryId,
    required MartSubCategoryModel sub,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الفئة الفرعية "${sub.nameAr}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await cubit.deleteSubCategory(
      categoryId: categoryId,
      subCategoryId: sub.id,
    );
  }

  Future<void> _selectLocation() async {
    final initial = _selectedLocation ?? const LatLng(30.0444, 31.2357);
    final result = await showMapLocationPickerDialog(
      context,
      initialLocation: initial,
    );
    if (result != null && result['latlng'] != null) {
      final destination = result['latlng'] as LatLng;
      setState(() {
        _selectedLocation = destination;
        _address.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _pickImage(MartCategoriesCubit cubit) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null || file == null) return;

    setState(() {
      _previewBytes = Uint8List.fromList(bytes);
      _isUploadingImage = true;
    });

    try {
      final fileName = file.name;
      final ext = file.extension ?? fileName.split('.').lastOrNull ?? 'jpg';
      final url = await cubit.uploadImage(
        categoryId: widget.categoryId,
        bytes: bytes,
        extension: ext,
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _previewBytes = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفع الصورة: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveCategory(
    MartCategoryModel item,
    MartCategoriesCubit cubit,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر حتى ينتهي رفع الصورة')),
      );
      return;
    }
    if (_imageUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الصورة مطلوبة')),
      );
      return;
    }
    final location = _selectedLocation;
    if (location == null) return;

    setState(() => _isSaving = true);
    try {
      await cubit.updateCategory(
        item.copyWith(
          nameAr: _nameAr.text.trim(),
          nameEn: _nameEn.text.trim(),
          shortDescAr: _shortAr.text.trim(),
          shortDescEn: _shortEn.text.trim(),
          imageUrl: _imageUrl.trim(),
          address: _address.text.trim(),
          lat: location.latitude,
          lng: location.longitude,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SubCategoryTile extends StatelessWidget {
  const _SubCategoryTile({
    required this.sub,
    required this.borderColor,
    required this.onEdit,
    required this.onDelete,
  });

  final MartSubCategoryModel sub;
  final Color borderColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = sub.isActive ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: sub.imageUrl.isEmpty
                ? ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.category_outlined),
                  )
                : AppNetworkImage(
                    url: sub.imageUrl,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.category_outlined,
                    placeholderIconSize: 22,
                  ),
          ),
        ),
        title: Text(
          sub.nameAr,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${sub.nameEn} · #${sub.sortOrder + 1}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sub.isActive ? 'نشط' : 'موقوف',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
            IconButton(
              tooltip: 'تعديل',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'حذف',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _ImagePickerHeader extends StatelessWidget {
  const _ImagePickerHeader({
    required this.imageUrl,
    required this.previewBytes,
    required this.isUploading,
    required this.surfaceAlt,
    required this.borderColor,
    required this.onPick,
    this.height = 170,
  });

  final String imageUrl;
  final Uint8List? previewBytes;
  final bool isUploading;
  final Color surfaceAlt;
  final Color borderColor;
  final VoidCallback? onPick;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPreview = previewBytes != null || imageUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (previewBytes != null)
                  Image.memory(previewBytes!, fit: BoxFit.cover)
                else if (imageUrl.isNotEmpty)
                  Positioned.fill(
                    child: AppNetworkImage(
                      url: imageUrl,
                      height: height,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.image_outlined,
                      placeholderIconSize: 36,
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط لاختيار صورة الفئة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (hasPreview)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'تغيير الصورة',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isUploading)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
