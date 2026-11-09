import 'dart:typed_data';

import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_sub_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/shared/widgets/app_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class MartSubCategoryFormSheet extends StatefulWidget {
  const MartSubCategoryFormSheet({
    super.key,
    required this.cubit,
    required this.categoryId,
    this.item,
  });

  final MartCategoriesCubit cubit;
  final String categoryId;
  final MartSubCategoryModel? item;

  @override
  State<MartSubCategoryFormSheet> createState() =>
      _MartSubCategoryFormSheetState();
}

class _MartSubCategoryFormSheetState extends State<MartSubCategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  bool _isActive = true;
  String _imageUrl = '';
  Uint8List? _previewBytes;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameAr = TextEditingController(text: item?.nameAr ?? '');
    _nameEn = TextEditingController(text: item?.nameEn ?? '');
    _isActive = item?.isActive ?? true;
    _imageUrl = item?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    super.dispose();
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
    final mediaQuery = MediaQuery.of(context);
    final isEdit = widget.item != null;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: mediaQuery.viewInsets.bottom + mediaQuery.viewPadding.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isEdit ? 'تعديل الفئة الفرعية' : 'إضافة فئة فرعية',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SubImagePicker(
                          imageUrl: _imageUrl,
                          previewBytes: _previewBytes,
                          isUploading: _isUploadingImage,
                          surfaceAlt: surfaceAlt,
                          borderColor: borderColor,
                          onPick:
                              _isUploadingImage ? null : _pickAndUploadImage,
                          onClear: _imageUrl.isEmpty && _previewBytes == null
                              ? null
                              : () => setState(() {
                                    _imageUrl = '';
                                    _previewBytes = null;
                                  }),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameAr,
                          decoration: _fieldDecoration('الاسم (عربي)'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'الاسم العربي مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameEn,
                          decoration: _fieldDecoration('الاسم (English)'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'الاسم الإنجليزي مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('نشط'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: (_isUploadingImage || _isSaving)
                              ? null
                              : _submit,
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
                              : Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
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
      final url = await widget.cubit.uploadImage(
        categoryId: '${widget.categoryId}_sub',
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر حتى ينتهي رفع الصورة')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final item = widget.item;
      if (item == null) {
        await widget.cubit.addSubCategory(
          categoryId: widget.categoryId,
          nameAr: _nameAr.text,
          nameEn: _nameEn.text,
          imageUrl: _imageUrl,
          isActive: _isActive,
        );
      } else {
        await widget.cubit.updateSubCategory(
          categoryId: widget.categoryId,
          subCategory: item.copyWith(
            nameAr: _nameAr.text.trim(),
            nameEn: _nameEn.text.trim(),
            imageUrl: _imageUrl.trim(),
            isActive: _isActive,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SubImagePicker extends StatelessWidget {
  const _SubImagePicker({
    required this.imageUrl,
    required this.previewBytes,
    required this.isUploading,
    required this.surfaceAlt,
    required this.borderColor,
    required this.onPick,
    this.onClear,
  });

  final String imageUrl;
  final Uint8List? previewBytes;
  final bool isUploading;
  final Color surfaceAlt;
  final Color borderColor;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

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
          height: 140,
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
                      height: 140,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.image_outlined,
                      placeholderIconSize: 32,
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'صورة اختيارية',
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
                if (onClear != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
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
