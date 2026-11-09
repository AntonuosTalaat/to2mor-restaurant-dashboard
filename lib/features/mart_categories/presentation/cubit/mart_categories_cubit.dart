import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/features/mart_categories/data/datasources/mart_categories_service.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_sub_category_model.dart';

import 'mart_categories_state.dart';

class MartCategoriesCubit extends Cubit<MartCategoriesState> {
  MartCategoriesCubit({MartCategoriesService? service})
    : _service = service ?? MartCategoriesService(),
      super(const MartCategoriesState());

  final MartCategoriesService _service;
  StreamSubscription<List<MartCategoryModel>>? _subscription;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _subscription?.cancel();
    _subscription = _service.streamCategories().listen(
      (items) {
        emit(state.copyWith(items: items, isLoading: false, clearError: true));
      },
      onError: (error) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'تعذر تحميل فئات المارت: $error',
          ),
        );
      },
    );
  }

  Future<void> refresh() async {
    final items = await _service.fetchCategories();
    emit(state.copyWith(items: items, clearError: true));
  }

  Future<void> addCategory({
    required String nameAr,
    required String nameEn,
    String? shortDescAr,
    String? shortDescEn,
    required String imageUrl,
    required String address,
    required double lat,
    required double lng,
    bool isActive = true,
  }) async {
    await _runBusy(() async {
      final now = DateTime.now();
      final id = _generateId();
      final item = MartCategoryModel(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        shortDescAr: shortDescAr,
        shortDescEn: shortDescEn,
        imageUrl: imageUrl,
        address: address,
        lat: lat,
        lng: lng,
        sortOrder: state.items.length,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );
      await _service.createCategory(item);
    });
  }

  Future<void> updateCategory(MartCategoryModel item) async {
    await _runBusy(() async {
      await _service.updateCategory(item.copyWith(updatedAt: DateTime.now()));
    });
  }

  Future<void> addSubCategory({
    required String categoryId,
    required String nameAr,
    required String nameEn,
    String imageUrl = '',
    bool isActive = true,
  }) async {
    await _runBusy(() async {
      final category = _findCategory(categoryId);
      if (category == null) {
        throw Exception('الفئة غير موجودة');
      }
      final sub = MartSubCategoryModel(
        id: _generateSubId(),
        nameAr: nameAr,
        nameEn: nameEn,
        imageUrl: imageUrl,
        sortOrder: category.subCategories.length,
        isActive: isActive,
      );
      final updated = category.copyWith(
        subCategories: [...category.subCategories, sub],
        updatedAt: DateTime.now(),
      );
      await _service.updateCategory(updated);
    });
  }

  Future<void> updateSubCategory({
    required String categoryId,
    required MartSubCategoryModel subCategory,
  }) async {
    await _runBusy(() async {
      final category = _findCategory(categoryId);
      if (category == null) {
        throw Exception('الفئة غير موجودة');
      }
      final list = category.subCategories
          .map((e) => e.id == subCategory.id ? subCategory : e)
          .toList();
      await _service.updateCategory(
        category.copyWith(subCategories: list, updatedAt: DateTime.now()),
      );
    });
  }

  Future<void> deleteSubCategory({
    required String categoryId,
    required String subCategoryId,
  }) async {
    await _runBusy(() async {
      final category = _findCategory(categoryId);
      if (category == null) {
        throw Exception('الفئة غير موجودة');
      }
      final list = [
        for (var i = 0; i < category.subCategories.length; i++)
          if (category.subCategories[i].id != subCategoryId)
            category.subCategories[i],
      ];
      final normalized = [
        for (var i = 0; i < list.length; i++)
          list[i].copyWith(sortOrder: i),
      ];
      await _service.updateCategory(
        category.copyWith(
          subCategories: normalized,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> deleteCategory(String id) async {
    await _runBusy(() async {
      await _service.deleteCategory(id);
      final updated = [...state.items]..removeWhere((e) => e.id == id);
      await _service.updateSortOrders(updated);
    });
  }

  Future<void> moveUp(String id) async {
    await _reorder(id, isUp: true);
  }

  Future<void> moveDown(String id) async {
    await _reorder(id, isUp: false);
  }

  Future<String> uploadImage({
    required String categoryId,
    required Uint8List bytes,
    required String extension,
  }) {
    return _service.uploadImage(
      categoryId: categoryId,
      bytes: bytes,
      extension: extension,
    );
  }

  Future<void> importFromExcel(Uint8List bytes) async {
    await _runBusy(() async {
      try {
        await _importFromExcelBytes(bytes);
      } catch (e, st) {
        debugPrint('[Excel import] $e');
        debugPrintStack(stackTrace: st, label: 'Excel import');
        rethrow;
      }
    });
  }

  Future<void> _importFromExcelBytes(Uint8List bytes) async {
      final excel = Excel.decodeBytes(bytes);
      final table = excel.tables.values.firstOrNull;
      if (table == null || table.rows.isEmpty) {
        throw Exception('ملف Excel فارغ');
      }

      final rows = table.rows;
      final header = rows.first.map((cell) => _cell(cell).trim().toLowerCase()).toList();
      final index = <String, int>{};
      for (var i = 0; i < header.length; i++) {
        index[header[i]] = i;
      }

      const required = ['name_ar', 'name_en', 'image_url', 'address', 'lat', 'lng'];
      for (final key in required) {
        if (!index.containsKey(key)) {
          throw Exception('العمود $key غير موجود');
        }
      }

      final existingById = {for (final c in state.items) c.id: c};
      final existingByName = {
        for (final c in state.items) _categoryNameKey(c.nameAr, c.nameEn): c,
      };
      final drafts = <String, _CategoryDraft>{};
      final draftOrder = <String>[];
      final assignedIds = <String>{};
      final now = DateTime.now();

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final nameAr = _get(row, index, 'name_ar');
        final nameEn = _get(row, index, 'name_en');
        if (nameAr.isEmpty || nameEn.isEmpty) continue;

        final rawId = _get(row, index, 'id');
        final nameKey = _categoryNameKey(nameAr, nameEn);
        final groupKey = rawId.isNotEmpty ? 'id:$rawId' : 'name:$nameKey';

        final draft = drafts.putIfAbsent(groupKey, () {
          draftOrder.add(groupKey);
          final existing =
              (rawId.isNotEmpty ? existingById[rawId] : null) ??
              existingByName[nameKey];
          var categoryId = rawId.isNotEmpty ? rawId : (existing?.id ?? '');
          if (categoryId.isEmpty || assignedIds.contains(categoryId)) {
            categoryId = _generateId();
          }
          assignedIds.add(categoryId);

          return _CategoryDraft(
            id: categoryId,
            nameAr: nameAr,
            nameEn: nameEn,
            shortDescAr: _nullable(_get(row, index, 'short_desc_ar')),
            shortDescEn: _nullable(_get(row, index, 'short_desc_en')),
            imageUrl: _get(row, index, 'image_url'),
            address: _get(row, index, 'address'),
            lat: double.tryParse(_get(row, index, 'lat')) ?? 0,
            lng: double.tryParse(_get(row, index, 'lng')) ?? 0,
            sortOrder:
                int.tryParse(_get(row, index, 'sort_order')) ??
                draftOrder.length - 1,
            isActive: _parseBool(_get(row, index, 'is_active')),
            createdAt: existing?.createdAt ?? now,
            existingSubs: existing?.subCategories ?? const [],
          );
        });

        final subNameAr = _get(row, index, 'sub_name_ar');
        final subNameEn = _get(row, index, 'sub_name_en');
        if (subNameAr.isEmpty && subNameEn.isEmpty) continue;

        final rawSubId = _get(row, index, 'sub_id');
        final existingSub = draft.findExistingSub(
          rawSubId: rawSubId,
          nameAr: subNameAr,
          nameEn: subNameEn,
        );
        final subId =
            rawSubId.isNotEmpty
                ? rawSubId
                : (existingSub?.id ?? _generateSubId());

        // Keep first occurrence if the same sub already appears in this import.
        if (draft.subs.any(
          (s) =>
              s.id == subId ||
              _categoryNameKey(s.nameAr, s.nameEn) ==
                  _categoryNameKey(subNameAr, subNameEn),
        )) {
          continue;
        }

        draft.subs.add(
          MartSubCategoryModel(
            id: subId,
            nameAr: subNameAr.isNotEmpty ? subNameAr : subNameEn,
            nameEn: subNameEn.isNotEmpty ? subNameEn : subNameAr,
            imageUrl: _get(row, index, 'sub_image_url'),
            sortOrder:
                int.tryParse(_get(row, index, 'sub_sort_order')) ??
                draft.subs.length,
            isActive: _parseBool(_get(row, index, 'sub_is_active')),
          ),
        );
      }

      final imported = <MartCategoryModel>[];
      for (final key in draftOrder) {
        final draft = drafts[key]!;
        final subs = [...draft.subs]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final normalizedSubs = [
          for (var i = 0; i < subs.length; i++)
            subs[i].copyWith(sortOrder: i),
        ];
        imported.add(
          MartCategoryModel(
            id: draft.id,
            nameAr: draft.nameAr,
            nameEn: draft.nameEn,
            shortDescAr: draft.shortDescAr,
            shortDescEn: draft.shortDescEn,
            imageUrl: draft.imageUrl,
            address: draft.address,
            lat: draft.lat,
            lng: draft.lng,
            sortOrder: draft.sortOrder,
            isActive: draft.isActive,
            createdAt: draft.createdAt,
            updatedAt: now,
            subCategories: normalizedSubs,
          ),
        );
      }

      imported.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final normalized = [
        for (var i = 0; i < imported.length; i++)
          imported[i].copyWith(sortOrder: i),
      ];
      await _service.replaceAll(normalized);
  }

  Uint8List exportToExcelBytes() {
    final excel = Excel.createExcel();
    final sheet = excel['mart_categories'];
    sheet.appendRow([
      TextCellValue('id'),
      TextCellValue('name_ar'),
      TextCellValue('name_en'),
      TextCellValue('short_desc_ar'),
      TextCellValue('short_desc_en'),
      TextCellValue('image_url'),
      TextCellValue('address'),
      TextCellValue('lat'),
      TextCellValue('lng'),
      TextCellValue('sort_order'),
      TextCellValue('is_active'),
      TextCellValue('sub_id'),
      TextCellValue('sub_name_ar'),
      TextCellValue('sub_name_en'),
      TextCellValue('sub_image_url'),
      TextCellValue('sub_sort_order'),
      TextCellValue('sub_is_active'),
    ]);
    for (final item in state.items) {
      final subs = [...item.subCategories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (subs.isEmpty) {
        sheet.appendRow(_categoryExcelRow(item, sub: null));
        continue;
      }
      for (final sub in subs) {
        sheet.appendRow(_categoryExcelRow(item, sub: sub));
      }
    }
    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('تعذر إنشاء ملف Excel');
    }
    return Uint8List.fromList(encoded);
  }

  List<CellValue> _categoryExcelRow(
    MartCategoryModel item, {
    required MartSubCategoryModel? sub,
  }) {
    return [
      TextCellValue(item.id),
      TextCellValue(item.nameAr),
      TextCellValue(item.nameEn),
      TextCellValue(item.shortDescAr ?? ''),
      TextCellValue(item.shortDescEn ?? ''),
      TextCellValue(item.imageUrl),
      TextCellValue(item.address),
      TextCellValue(item.lat.toString()),
      TextCellValue(item.lng.toString()),
      IntCellValue(item.sortOrder),
      TextCellValue(item.isActive ? 'true' : 'false'),
      TextCellValue(sub?.id ?? ''),
      TextCellValue(sub?.nameAr ?? ''),
      TextCellValue(sub?.nameEn ?? ''),
      TextCellValue(sub?.imageUrl ?? ''),
      TextCellValue(sub == null ? '' : sub.sortOrder.toString()),
      TextCellValue(sub == null ? '' : (sub.isActive ? 'true' : 'false')),
    ];
  }

  String _categoryNameKey(String nameAr, String nameEn) {
    return '${nameAr.trim().toLowerCase()}|${nameEn.trim().toLowerCase()}';
  }

  Future<void> _reorder(String id, {required bool isUp}) async {
    await _runBusy(() async {
      final list = [...state.items];
      final idx = list.indexWhere((e) => e.id == id);
      if (idx == -1) return;
      final target = isUp ? idx - 1 : idx + 1;
      if (target < 0 || target >= list.length) return;
      final item = list.removeAt(idx);
      list.insert(target, item);
      final normalized = [
        for (var i = 0; i < list.length; i++)
          list[i].copyWith(sortOrder: i, updatedAt: DateTime.now()),
      ];
      await _service.updateSortOrders(normalized);
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      await action();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      emit(state.copyWith(isBusy: false));
    }
  }

  MartCategoryModel? _findCategory(String id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    // Avoid `1 << 32`: on web it evaluates to 0 and breaks nextInt.
    final rnd = Random().nextInt(0x7FFFFFFF).toRadixString(16);
    return 'mc_$ts$rnd';
  }

  String _generateSubId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(0x7FFFFFFF).toRadixString(16);
    return 'msc_$ts$rnd';
  }

  String _cell(Data? data) => data?.value?.toString() ?? '';

  String _get(List<Data?> row, Map<String, int> map, String key) {
    final idx = map[key];
    if (idx == null || idx >= row.length) return '';
    return _cell(row[idx]).trim();
  }

  bool _parseBool(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _CategoryDraft {
  _CategoryDraft({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.shortDescAr,
    required this.shortDescEn,
    required this.imageUrl,
    required this.address,
    required this.lat,
    required this.lng,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.existingSubs,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String? shortDescAr;
  final String? shortDescEn;
  final String imageUrl;
  final String address;
  final double lat;
  final double lng;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final List<MartSubCategoryModel> existingSubs;
  final List<MartSubCategoryModel> subs = [];

  MartSubCategoryModel? findExistingSub({
    required String rawSubId,
    required String nameAr,
    required String nameEn,
  }) {
    if (rawSubId.isNotEmpty) {
      for (final sub in existingSubs) {
        if (sub.id == rawSubId) return sub;
      }
    }
    final key =
        '${nameAr.trim().toLowerCase()}|${nameEn.trim().toLowerCase()}';
    for (final sub in existingSubs) {
      final subKey =
          '${sub.nameAr.trim().toLowerCase()}|${sub.nameEn.trim().toLowerCase()}';
      if (subKey == key) return sub;
    }
    return null;
  }
}
