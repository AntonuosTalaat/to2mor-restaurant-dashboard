import 'dart:typed_data';

import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MartCategoriesService {
  MartCategoriesService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  static const _collection = 'settings_mart_categories';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  Stream<List<MartCategoryModel>> streamCategories() {
    return _ref.orderBy('sort_order').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => MartCategoryModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<List<MartCategoryModel>> fetchCategories() async {
    final snapshot = await _ref.orderBy('sort_order').get();
    return snapshot.docs
        .map((doc) => MartCategoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> createCategory(MartCategoryModel category) async {
    await _ref.doc(category.id).set(category.toMap());
  }

  Future<void> updateCategory(MartCategoryModel category) async {
    await _ref.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _ref.doc(id).delete();
  }

  Future<void> replaceAll(List<MartCategoryModel> categories) async {
    final batch = _firestore.batch();
    final existing = await _ref.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final item in categories) {
      batch.set(_ref.doc(item.id), item.toMap());
    }
    await batch.commit();
  }

  Future<void> updateSortOrders(List<MartCategoryModel> categories) async {
    final batch = _firestore.batch();
    for (var i = 0; i < categories.length; i++) {
      final item = categories[i];
      batch.update(_ref.doc(item.id), {
        'sort_order': i,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<String> uploadImage({
    required String categoryId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final normalizedExt = extension.toLowerCase().replaceAll('.', '');
    final path =
        'settings/mart_categories/$categoryId-${DateTime.now().millisecondsSinceEpoch}.$normalizedExt';
    final ref = _storage.ref(path);
    final metadata = SettableMetadata(contentType: 'image/$normalizedExt');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}
