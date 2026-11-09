import 'dart:typed_data';

import 'package:restaurantdashboard/Components/CommonComponents/MapLocationPicker.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/shared/widgets/app_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MartCategoryFormSheet extends StatefulWidget {
  const MartCategoryFormSheet({
    super.key,
    required this.cubit,
    this.item,
  });

  final MartCategoriesCubit cubit;
  final MartCategoryModel? item;

  @override
  State<MartCategoryFormSheet> createState() => _MartCategoryFormSheetState();
}

class _MartCategoryFormSheetState extends State<MartCategoryFormSheet> {
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

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameAr = TextEditingController(text: item?.nameAr ?? '');
    _nameEn = TextEditingController(text: item?.nameEn ?? '');
    _shortAr = TextEditingController(text: item?.shortDescAr ?? '');
    _shortEn = TextEditingController(text: item?.shortDescEn ?? '');
    _address = TextEditingController(text: item?.address ?? '');
    if (item != null) {
      _selectedLocation = LatLng(item.lat, item.lng);
    }
    _isActive = item?.isActive ?? true;
    _imageUrl = item?.imageUrl ?? '';
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
            maxHeight: mediaQuery.size.height * 0.92,
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
                          isEdit ? 'تعديل فئة المارت' : 'إضافة فئة مارت',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ImagePickerHeader(
                          imageUrl: _imageUrl,
                          previewBytes: _previewBytes,
                          isUploading: _isUploadingImage,
                          surfaceAlt: surfaceAlt,
                          borderColor: borderColor,
                          onPick: _isUploadingImage ? null : _pickAndUploadImage,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameAr,
                                decoration: _fieldDecoration('الاسم (عربي)'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'الاسم العربي مطلوب'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _nameEn,
                                decoration: _fieldDecoration('الاسم (English)'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
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
                              color: _selectedLocation != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            hintText: _selectedLocation == null
                                ? 'انقر لتحديد الموقع على الخريطة'
                                : null,
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
                          onPressed:
                              _isUploadingImage ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
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
      final categoryId =
          widget.item?.id ?? 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      final url = await widget.cubit.uploadImage(
        categoryId: categoryId,
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
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
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
    if (_imageUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الصورة مطلوبة')),
      );
      return;
    }

    final location = _selectedLocation;
    if (location == null) return;

    final lat = location.latitude;
    final lng = location.longitude;
    final item = widget.item;

    if (item == null) {
      await widget.cubit.addCategory(
        nameAr: _nameAr.text,
        nameEn: _nameEn.text,
        shortDescAr: _shortAr.text,
        shortDescEn: _shortEn.text,
        imageUrl: _imageUrl,
        address: _address.text,
        lat: lat,
        lng: lng,
        isActive: _isActive,
      );
    } else {
      await widget.cubit.updateCategory(
        item.copyWith(
          nameAr: _nameAr.text.trim(),
          nameEn: _nameEn.text.trim(),
          shortDescAr: _shortAr.text.trim(),
          shortDescEn: _shortEn.text.trim(),
          imageUrl: _imageUrl.trim(),
          address: _address.text.trim(),
          lat: lat,
          lng: lng,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
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
  });

  final String imageUrl;
  final Uint8List? previewBytes;
  final bool isUploading;
  final Color surfaceAlt;
  final Color borderColor;
  final VoidCallback? onPick;

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
          height: 170,
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
                      height: 170,
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
