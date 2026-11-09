import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_sub_category_model.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';

/// تصدير / استيراد الأصناف من Excel بدون تعديل على ItemModel.
/// كل صف = حجم واحد؛ الأصناف متعددة الأحجام تظهر في أكثر من صف بنفس الاسم.
class ItemsExcelService {
  static const _sheetName = 'الأصناف';

  // أعمدة عربية (للتصدير والعرض)
  static const colName = 'الاسم';
  static const colDescription = 'الوصف';
  static const colCategory = 'التصنيف';
  static const colSubCategory = 'التصنيف الفرعي';
  static const colImageUrl = 'رابط الصورة';
  static const colAvailable = 'متاح';
  static const colCustomDetails = 'تفاصيل مخصصة';
  static const colExtrasIds = 'معرفات الإضافات';
  static const colSizeName = 'الحجم';
  static const colPrice = 'السعر';
  static const colDiscount = 'الخصم%';

  static const List<String> _headers = [
    colName,
    colDescription,
    colCategory,
    colSubCategory,
    colImageUrl,
    colAvailable,
    colCustomDetails,
    colExtrasIds,
    colSizeName,
    colPrice,
    colDiscount,
  ];

  /// مرادفات إنجليزية/عربية لرؤوس الأعمدة عند الاستيراد
  static const Map<String, List<String>> _headerAliases = {
    colName: ['الاسم', 'name', 'item name', 'اسم الصنف'],
    colDescription: ['الوصف', 'description', 'desc'],
    colCategory: [
      'التصنيف',
      'category',
      'category name',
      'mart category',
      'تصنيف المارت',
    ],
    colSubCategory: [
      'التصنيف الفرعي',
      'subcategory',
      'sub category',
      'mart subcategory',
      'sub_name_ar',
    ],
    colImageUrl: ['رابط الصورة', 'imageurl', 'image url', 'image'],
    colAvailable: ['متاح', 'isavailable', 'available', 'availability'],
    colCustomDetails: [
      'تفاصيل مخصصة',
      'allowcustomdetails',
      'custom details',
      'custom',
    ],
    colExtrasIds: ['معرفات الإضافات', 'extrasids', 'extras', 'extra ids'],
    colSizeName: ['الحجم', 'size', 'size name', 'اسم الحجم'],
    colPrice: ['السعر', 'price'],
    colDiscount: ['الخصم%', 'الخصم', 'discount', 'discountpercent', 'discount%'],
  };

  // ── Export ───────────────────────────────────────────────────────────────

  Uint8List exportItems(
    List<ItemModel> items, {
    List<MartCategoryModel> martCategories = const [],
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != _sheetName) {
      excel.rename(defaultSheet, _sheetName);
    }
    final sheet = excel[_sheetName];

    for (var i = 0; i < _headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(_headers[i]);
    }

    var rowIndex = 1;
    for (final item in items) {
      final sizes =
          item.sizes.isEmpty
              ? [ItemSize(name: '', price: 0, discountPercent: 0)]
              : item.sizes;
      final categoryName = _exportCategoryName(item, martCategories);
      final subCategoryName = _exportSubCategoryName(item, martCategories);

      for (final size in sizes) {
        final values = [
          item.name,
          item.description,
          categoryName,
          subCategoryName,
          item.imageUrl,
          item.isAvailable ? 'نعم' : 'لا',
          item.allowCustomDetails ? 'نعم' : 'لا',
          item.extrasIds.join(','),
          size.name,
          size.price == 0 && size.name.isEmpty ? '' : size.price.toString(),
          size.discountPercent.toString(),
        ];

        for (var c = 0; c < values.length; c++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: c,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(values[c]);
        }
        rowIndex++;
      }
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('فشل إنشاء ملف الإكسل');
    }
    return Uint8List.fromList(encoded);
  }

  Future<void> downloadItemsExcel(
    List<ItemModel> items, {
    List<MartCategoryModel> martCategories = const [],
  }) async {
    final bytes = exportItems(items, martCategories: martCategories);
    final fileName =
        'menu_items_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ أصناف القائمة',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: bytes,
    );
  }

  // ── Import ───────────────────────────────────────────────────────────────

  Future<List<ItemModel>?> pickAndParseItems({
    required String restaurantId,
    List<MartCategoryModel> martCategories = const [],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('تعذر قراءة ملف الإكسل');
    }

    return parseItems(
      bytes,
      restaurantId: restaurantId,
      martCategories: martCategories,
    );
  }

  List<ItemModel> parseItems(
    Uint8List bytes, {
    required String restaurantId,
    List<MartCategoryModel> martCategories = const [],
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw Exception('ملف الإكسل فارغ');
    }

    final sheet =
        excel.tables[_sheetName] ?? excel.tables.values.first;
    if (sheet.maxRows < 2) {
      throw Exception('لا توجد بيانات في الملف');
    }

    final headerRow = sheet.rows.first;
    final colIndex = _mapHeaders(headerRow);

    if (!colIndex.containsKey(colName)) {
      throw Exception('عمود "الاسم" مطلوب في ملف الإكسل');
    }

    final isMart = martCategories.isNotEmpty;

    // الاسم -> صفوف الأحجام
    final Map<String, _ItemDraft> drafts = {};
    final List<String> order = [];

    for (var r = 1; r < sheet.maxRows; r++) {
      final row = sheet.rows[r];
      final name = _cellString(_cellAt(row, colIndex[colName]!)).trim();
      if (name.isEmpty) continue;

      final sizeName =
          colIndex.containsKey(colSizeName)
              ? _cellString(_cellAt(row, colIndex[colSizeName]!)).trim()
              : '';
      final priceRaw =
          colIndex.containsKey(colPrice)
              ? _cellNum(_cellAt(row, colIndex[colPrice]!))
              : null;
      final discountRaw =
          colIndex.containsKey(colDiscount)
              ? (_cellNum(_cellAt(row, colIndex[colDiscount]!)) ?? 0.0)
              : 0.0;

      ItemSize? size;
      if (sizeName.isNotEmpty) {
        if (priceRaw == null || priceRaw <= 0) {
          throw Exception(
            'سعر غير صالح للصنف "$name" والحجم "$sizeName" (صف ${r + 1})',
          );
        }
        if (discountRaw < 0 || discountRaw > 100) {
          throw Exception(
            'نسبة خصم غير صالحة للصنف "$name" والحجم "$sizeName" (صف ${r + 1})',
          );
        }
        size = ItemSize(
          name: sizeName,
          price: priceRaw,
          discountPercent: discountRaw,
        );
      }

      final categoryRaw =
          colIndex.containsKey(colCategory)
              ? _cellString(_cellAt(row, colIndex[colCategory]!)).trim()
              : '';
      final subCategoryRaw =
          colIndex.containsKey(colSubCategory)
              ? _cellString(_cellAt(row, colIndex[colSubCategory]!)).trim()
              : '';

      if (!drafts.containsKey(name)) {
        order.add(name);

        var category = categoryRaw;
        var categoryEn = '';
        var martCategoryId = '';
        var martSubCategoryId = '';

        if (isMart) {
          final resolved = _resolveMartFields(
            categoryName: categoryRaw,
            subCategoryName: subCategoryRaw,
            martCategories: martCategories,
            itemName: name,
            rowNumber: r + 1,
          );
          category = resolved.category;
          categoryEn = resolved.categoryEn;
          martCategoryId = resolved.martCategoryId;
          martSubCategoryId = resolved.martSubCategoryId;
        }

        drafts[name] = _ItemDraft(
          name: name,
          description:
              colIndex.containsKey(colDescription)
                  ? _cellString(_cellAt(row, colIndex[colDescription]!)).trim()
                  : '',
          category: category,
          categoryEn: categoryEn,
          martCategoryId: martCategoryId,
          martSubCategoryId: martSubCategoryId,
          imageUrl:
              colIndex.containsKey(colImageUrl)
                  ? _cellString(_cellAt(row, colIndex[colImageUrl]!)).trim()
                  : '',
          isAvailable:
              colIndex.containsKey(colAvailable)
                  ? _parseBool(
                    _cellString(_cellAt(row, colIndex[colAvailable]!)),
                    defaultValue: true,
                  )
                  : true,
          allowCustomDetails:
              colIndex.containsKey(colCustomDetails)
                  ? _parseBool(
                    _cellString(_cellAt(row, colIndex[colCustomDetails]!)),
                    defaultValue: false,
                  )
                  : false,
          extrasIds:
              colIndex.containsKey(colExtrasIds)
                  ? _parseExtrasIds(
                    _cellString(_cellAt(row, colIndex[colExtrasIds]!)),
                  )
                  : const [],
          sizes: [],
        );
      }

      final draft = drafts[name]!;
      // حدّث الحقول الأساسية من أول صف غير فاضي لو الصف الحالي فيه قيم
      if (draft.description.isEmpty && colIndex.containsKey(colDescription)) {
        draft.description =
            _cellString(_cellAt(row, colIndex[colDescription]!)).trim();
      }
      if (draft.imageUrl.isEmpty && colIndex.containsKey(colImageUrl)) {
        draft.imageUrl =
            _cellString(_cellAt(row, colIndex[colImageUrl]!)).trim();
      }
      if (!isMart &&
          draft.category.isEmpty &&
          colIndex.containsKey(colCategory)) {
        draft.category =
            _cellString(_cellAt(row, colIndex[colCategory]!)).trim();
      }

      if (size != null) {
        // لو نفس اسم الحجم موجود، استبدل السعر/الخصم
        final existingIdx = draft.sizes.indexWhere((s) => s.name == size!.name);
        if (existingIdx >= 0) {
          draft.sizes[existingIdx] = size;
        } else {
          draft.sizes.add(size);
        }
      }
    }

    if (drafts.isEmpty) {
      throw Exception('لم يتم العثور على أصناف صالحة في الملف');
    }

    return order.map((name) {
      final d = drafts[name]!;
      return ItemModel(
        name: d.name,
        description: d.description,
        category: d.category,
        categoryEn: d.categoryEn,
        martCategoryId: d.martCategoryId,
        martSubCategoryId: d.martSubCategoryId,
        imageUrl: d.imageUrl,
        restaurantId: restaurantId,
        sizes: List.unmodifiable(d.sizes),
        extrasIds: List.unmodifiable(d.extrasIds),
        allowCustomDetails: d.allowCustomDetails,
        isAvailable: d.isAvailable,
      );
    }).toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _exportCategoryName(
    ItemModel item,
    List<MartCategoryModel> martCategories,
  ) {
    if (martCategories.isEmpty) return item.category;
    if (item.martCategoryId.isNotEmpty) {
      for (final category in martCategories) {
        if (category.id == item.martCategoryId) return category.nameAr;
      }
    }
    return item.category;
  }

  String _exportSubCategoryName(
    ItemModel item,
    List<MartCategoryModel> martCategories,
  ) {
    if (martCategories.isEmpty || item.martSubCategoryId.isEmpty) return '';
    for (final category in martCategories) {
      if (item.martCategoryId.isNotEmpty &&
          category.id != item.martCategoryId) {
        continue;
      }
      for (final sub in category.subCategories) {
        if (sub.id == item.martSubCategoryId) return sub.nameAr;
      }
    }
    return '';
  }

  ({
    String category,
    String categoryEn,
    String martCategoryId,
    String martSubCategoryId,
  }) _resolveMartFields({
    required String categoryName,
    required String subCategoryName,
    required List<MartCategoryModel> martCategories,
    required String itemName,
    required int rowNumber,
  }) {
    if (categoryName.isEmpty) {
      throw Exception(
        'تصنيف المارت مطلوب للصنف "$itemName" (صف $rowNumber)',
      );
    }

    final category = _findMartCategory(martCategories, categoryName);
    if (category == null) {
      throw Exception(
        'تصنيف المارت "$categoryName" غير موجود للصنف "$itemName" (صف $rowNumber)',
      );
    }

    var martSubCategoryId = '';
    if (subCategoryName.isNotEmpty) {
      final sub = _findMartSubCategory(category, subCategoryName);
      if (sub == null) {
        throw Exception(
          'التصنيف الفرعي "$subCategoryName" غير موجود تحت "${category.nameAr}" '
          'للصنف "$itemName" (صف $rowNumber)',
        );
      }
      martSubCategoryId = sub.id;
    } else if (category.activeSubCategories.isNotEmpty) {
      // لو فيه فروع وما اتكتبش فرع، ناخد أول فرع نشط زي شاشة التعديل.
      martSubCategoryId = category.activeSubCategories.first.id;
    }

    return (
      category: category.nameAr,
      categoryEn: category.nameEn,
      martCategoryId: category.id,
      martSubCategoryId: martSubCategoryId,
    );
  }

  MartCategoryModel? _findMartCategory(
    List<MartCategoryModel> categories,
    String raw,
  ) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final category in categories) {
      if (category.id == raw.trim()) return category;
      if (category.nameAr.trim().toLowerCase() == key) return category;
      if (category.nameEn.trim().toLowerCase() == key) return category;
    }
    return null;
  }

  MartSubCategoryModel? _findMartSubCategory(
    MartCategoryModel category,
    String raw,
  ) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final sub in category.subCategories) {
      if (sub.id == raw.trim()) return sub;
      if (sub.nameAr.trim().toLowerCase() == key) return sub;
      if (sub.nameEn.trim().toLowerCase() == key) return sub;
    }
    return null;
  }

  Map<String, int> _mapHeaders(List<Data?> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final raw = _cellString(headerRow[i]).trim().toLowerCase();
      if (raw.isEmpty) continue;

      for (final entry in _headerAliases.entries) {
        final aliases = entry.value.map((a) => a.toLowerCase()).toList();
        if (aliases.contains(raw)) {
          map[entry.key] = i;
          break;
        }
      }
    }
    return map;
  }

  Data? _cellAt(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return row[index];
  }

  String _cellString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final v = cell.value;
    if (v is TextCellValue) return v.value.toString();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) {
      final d = v.value;
      return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
    }
    if (v is BoolCellValue) return v.value ? 'نعم' : 'لا';
    return v.toString();
  }

  double? _cellNum(Data? cell) {
    if (cell == null || cell.value == null) return null;
    final v = cell.value;
    if (v is IntCellValue) return v.value.toDouble();
    if (v is DoubleCellValue) return v.value;
    if (v is TextCellValue) {
      return double.tryParse(v.value.toString().replaceAll(',', '').trim());
    }
    return double.tryParse(_cellString(cell).replaceAll(',', '').trim());
  }

  bool _parseBool(String raw, {required bool defaultValue}) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return defaultValue;
    if (['نعم', 'yes', 'true', '1', 'y', 'متاح'].contains(v)) return true;
    if (['لا', 'no', 'false', '0', 'n', 'غير متاح'].contains(v)) return false;
    return defaultValue;
  }

  List<String> _parseExtrasIds(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[,;|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class _ItemDraft {
  final String name;
  String description;
  String category;
  String categoryEn;
  String martCategoryId;
  String martSubCategoryId;
  String imageUrl;
  bool isAvailable;
  bool allowCustomDetails;
  List<String> extrasIds;
  final List<ItemSize> sizes;

  _ItemDraft({
    required this.name,
    required this.description,
    required this.category,
    required this.categoryEn,
    required this.martCategoryId,
    required this.martSubCategoryId,
    required this.imageUrl,
    required this.isAvailable,
    required this.allowCustomDetails,
    required this.extrasIds,
    required this.sizes,
  });
}
