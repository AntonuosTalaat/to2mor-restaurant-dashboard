import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/Services/firebase_storage_service.dart';
import 'package:restaurantdashboard/features/menu/data/models/item_extra_model.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_state.dart';

/// ديالوج إدارة إضافات المطعم — يُعرض كـ Bottom Sheet
class ExtrasManagementDialog extends StatefulWidget {
  const ExtrasManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    final menuCubit = context.read<MenuCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => BlocProvider.value(
            value: menuCubit,
            child: const ExtrasManagementDialog(),
          ),
    );
  }

  /// Opens only the add/edit form sheet (for the dedicated Extras screen).
  static Future<void> showEditor(
    BuildContext context, {
    ItemExtra? extra,
  }) {
    final menuCubit = context.read<MenuCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => BlocProvider.value(
            value: menuCubit,
            child: Builder(
              builder: (sheetContext) {
                return _ExtraFormSheet(
                  extra: extra,
                  onCancel: () => Navigator.pop(sheetContext),
                  onSave: (updated) async {
                    final cubit = sheetContext.read<MenuCubit>();
                    if (extra == null) {
                      await cubit.saveRestaurantExtras([
                        ...cubit.state.extrasList,
                        updated,
                      ]);
                    } else {
                      await cubit.saveRestaurantExtras(
                        cubit.state.extrasList
                            .map((e) => e.id == extra.id ? updated : e)
                            .toList(),
                      );
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                );
              },
            ),
          ),
    );
  }

  @override
  State<ExtrasManagementDialog> createState() => _ExtrasManagementDialogState();
}

class _ExtrasManagementDialogState extends State<ExtrasManagementDialog> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExtras());
  }

  Future<void> _loadExtras() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<MenuCubit>().fetchRestaurantExtras();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveExtras(List<ItemExtra> extras) async {
    try {
      await context.read<MenuCubit>().saveRestaurantExtras(extras);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  void _showAddExtraDialog() {
    _showExtraFormSheet(
      extra: null,
      onSave: (extra) async {
        final cubit = context.read<MenuCubit>();
        final updated = List<ItemExtra>.from(cubit.state.extrasList)..add(extra);
        await _saveExtras(updated);
        await _loadExtras();
      },
    );
  }

  void _showEditExtraDialog(ItemExtra extra) {
    _showExtraFormSheet(
      extra: extra,
      onSave: (updated) async {
        final cubit = context.read<MenuCubit>();
        final list =
            cubit.state.extrasList
                .map((e) => e.id == extra.id ? updated : e)
                .toList();
        await _saveExtras(list);
        await _loadExtras();
      },
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
    await _saveExtras(updated);
    await _loadExtras();
  }

  void _showExtraFormSheet({
    required ItemExtra? extra,
    required Future<void> Function(ItemExtra) onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _ExtraFormSheet(
            extra: extra,
            onSave: onSave,
            onCancel: () => Navigator.pop(ctx),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: theme.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'إدارة الإضافات',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                          ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _loadExtras,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          )
                          : BlocBuilder<MenuCubit, MenuState>(
                            builder: (_, state) {
                              final extras = state.extrasList;
                              if (extras.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 72,
                                        color: theme.colorScheme.outline,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'لا توجد إضافات بعد',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'أضف إضافات يمكن ربطها بالأصناف لاحقاً',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: extras.length,
                                itemBuilder: (context, index) {
                                  // ✅ ItemExtra مش ExtraModel
                                  final ItemExtra e = extras[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: theme.dividerColor.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      leading:
                                          e.img != null && e.img!.isNotEmpty
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: AppNetworkImage(
                                                  imageUrl: e.img!,
                                                  width: 52,
                                                  height: 52,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) => Icon(
                                                        Icons
                                                            .add_photo_alternate,
                                                        color:
                                                            theme.primaryColor,
                                                      ),
                                                ),
                                              )
                                              : CircleAvatar(
                                                radius: 26,
                                                backgroundColor: theme
                                                    .primaryColor
                                                    .withOpacity(0.15),
                                                child: Icon(
                                                  Icons.add,
                                                  color: theme.primaryColor,
                                                ),
                                              ),
                                      title: Text(
                                        e.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${e.price.toStringAsFixed(0)} ج.م'
                                          '${e.hasDiscount ? ' · خصم ${e.discountPercent!.toStringAsFixed(0)}%' : ''}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton.filled(
                                            style: IconButton.styleFrom(
                                              backgroundColor: theme
                                                  .primaryColor
                                                  .withOpacity(0.12),
                                              foregroundColor:
                                                  theme.primaryColor,
                                            ),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                            ),
                                            onPressed:
                                                () => _showEditExtraDialog(e),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton.filled(
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  theme
                                                      .colorScheme
                                                      .errorContainer,
                                              foregroundColor:
                                                  theme
                                                      .colorScheme
                                                      .onErrorContainer,
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                            onPressed: () => _deleteExtra(e),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      12 + bottomPadding,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: theme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _showAddExtraDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('إضافة إضافة'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('إغلاق'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// نموذج إضافة/تعديل إضافة واحدة
class _ExtraFormSheet extends StatefulWidget {
  // ✅ ItemExtra مش ExtraModel
  final ItemExtra? extra;
  final Future<void> Function(ItemExtra) onSave;
  final VoidCallback onCancel;

  const _ExtraFormSheet({
    this.extra,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ExtraFormSheet> createState() => _ExtraFormSheetState();
}

class _ExtraFormSheetState extends State<_ExtraFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  String? _existingImageUrl;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.extra?.name ?? '');
    _priceController = TextEditingController(
      text: widget.extra?.price.toString() ?? '',
    );
    _discountController = TextEditingController(
      text: widget.extra?.discountPercent?.toString() ?? '',
    );
    _existingImageUrl = widget.extra?.img;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isUploading = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        setState(() {
          _imageBytes =
              (bytes != null && bytes.isNotEmpty)
                  ? Uint8List.fromList(bytes)
                  : null;
          _imageName = file.name;
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل اختيار الصورة: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الاسم مطلوب')));
      return;
    }
    final price = double.tryParse(_priceController.text);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('أدخل سعراً صحيحاً')));
      return;
    }
    final discountVal =
        _discountController.text.trim().isEmpty
            ? null
            : double.tryParse(_discountController.text);
    if (discountVal != null && (discountVal < 0 || discountVal > 100)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('نسبة الخصم بين 0 و 100')));
      return;
    }

    setState(() => _saving = true);
    String? imgUrl = _existingImageUrl;

    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      try {
        final fileName =
            _imageName != null &&
                    _imageName!.isNotEmpty &&
                    _imageName!.toLowerCase().endsWith('.jpg')
                ? _imageName!
                : 'extra_${DateTime.now().millisecondsSinceEpoch}.jpg';

        imgUrl = await FirebaseStorageService().uploadExtraImage(
          Uint8List.fromList(_imageBytes!),
          fileName,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل رفع الصورة: $e')));
        }
        setState(() => _saving = false);
        return;
      }
    }

    // ✅ بناء ItemExtra مش ExtraModel
    final extra = ItemExtra(
      id: widget.extra?.id ?? 'ex_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      price: price,
      discountPercent: discountVal,
      img: imgUrl,
    );

    await widget.onSave(extra);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      widget.extra == null ? 'إضافة إضافة' : 'تعديل الإضافة',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'الاسم',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'السعر (ج.م)',
                          prefixText: 'ج.م ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _discountController,
                        decoration: InputDecoration(
                          labelText: 'نسبة الخصم % (اختياري)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'صورة الإضافة',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Column(
                          children: [
                            if (_imageBytes != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _imageBytes!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (_imageName != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _imageName!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 12),
                            ] else if (_existingImageUrl != null &&
                                _existingImageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AppNetworkImage(
                                  imageUrl: _existingImageUrl!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'الصورة الحالية',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                            ],
                            FilledButton.tonalIcon(
                              onPressed: _isUploading ? null : _pickImage,
                              icon:
                                  _isUploading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.image_outlined),
                              label: Text(
                                _isUploading ? 'جاري التحميل...' : 'تحميل صورة',
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
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
                      flex: 2,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _saving
                                ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
