import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restaurantdashboard/Services/firebase_storage_service.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';
import 'package:restaurantdashboard/features/menu/data/models/item_extra_model.dart';

class MenuService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorageService _storageService;

  MenuService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorageService storageService,
  }) : _firestore = firestore,
       _auth = auth,
       _storageService = storageService;

  String get _restaurantId => _auth.currentUser!.uid;

  Future<Restaurant?> getRestaurantData() async {
    try {
      final doc =
          await _firestore.collection('restaurants').doc(_restaurantId).get();
      if (doc.exists) return Restaurant.fromMap(doc.id, doc.data()!);
      return null;
    } catch (e) {
      throw Exception('Failed to fetch restaurant data: ${e.toString()}');
    }
  }

  /// Create or update menu items (بدون extras)
  Future<void> saveItem({
    required ItemModel item,
    required String? oldItemName,
    dynamic imageFile,
  }) async {
    try {
      String? imageUrl;

      if (imageFile != null && imageFile is Uint8List) {
        final fileName =
            '${item.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _storageService.uploadItemImage(imageFile, fileName);
      } else if (item.imageUrl.isNotEmpty) {
        imageUrl = item.imageUrl;
      }

      final docRef = _firestore.collection('restaurants').doc(_restaurantId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Restaurant document not found');

      final data = doc.data()!;
      final List<Map<String, dynamic>> menu =
          (data['menu'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      if (oldItemName == null) {
        if (imageUrl == null) {
          throw Exception('Image is required for new items');
        }

        final itemId = _firestore.collection('restaurants').doc().id;
        final newItem = item.copyWith(
          id: itemId,
          imageUrl: imageUrl,
          restaurantId: _restaurantId,
        );

        await docRef.update({
          'menu': FieldValue.arrayUnion([newItem.toMap()]),
        });
        return;
      }

      final updatedMenu =
          menu.map((existingItem) {
            if (existingItem['name'] == oldItemName) {
              return item
                  .copyWith(imageUrl: imageUrl ?? existingItem['imageUrl'])
                  .toMap();
            }
            return existingItem;
          }).toList();

      await docRef.update({'menu': updatedMenu});
    } catch (e) {
      throw Exception('Failed to save item: ${e.toString()}');
    }
  }

  Future<void> toggleItemAvailability(
    String itemId,
    bool newAvailability,
  ) async {
    try {
      if (itemId.isEmpty) throw Exception('Item ID cannot be empty');

      final docRef = _firestore.collection('restaurants').doc(_restaurantId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Restaurant document not found');

      final data = doc.data()!;
      final List<Map<String, dynamic>> menu =
          (data['menu'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      var itemFound = false;
      final updatedMenu =
          menu.map((item) {
            var currentItemId = item['id']?.toString() ?? '';

            if (currentItemId.isEmpty) {
              currentItemId = _firestore.collection('restaurants').doc().id;
              item['id'] = currentItemId;
            }

            if (currentItemId == itemId) {
              itemFound = true;
              return {...item, 'isAvailable': newAvailability};
            }
            return item;
          }).toList();

      if (!itemFound) throw Exception('Item not found with ID: $itemId');
      await docRef.update({'menu': updatedMenu});
    } catch (e) {
      throw Exception('Failed to update item availability: ${e.toString()}');
    }
  }

  Future<void> updateItemExtras(String itemId, List<ItemExtra> extras) async {
    try {
      if (itemId.isEmpty) throw Exception('Item ID cannot be empty');

      final docRef = _firestore.collection('restaurants').doc(_restaurantId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Restaurant document not found');

      final data = doc.data()!;
      final List<Map<String, dynamic>> menu =
          (data['menu'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      var itemFound = false;
      final updatedMenu =
          menu.map((itemMap) {
            final currentItemId = itemMap['id']?.toString() ?? '';
            if (currentItemId == itemId) {
              itemFound = true;
              return {
                ...Map<String, dynamic>.from(itemMap),
                'extras': extras.map((e) => e.toMap()).toList(),
              };
            }
            return itemMap;
          }).toList();

      if (!itemFound) throw Exception('Item not found with ID: $itemId');
      await docRef.update({'menu': updatedMenu});
    } catch (e) {
      throw Exception('Failed to update item extras: ${e.toString()}');
    }
  }

  Future<({int added, int updated, int skipped})> upsertItemsFromExcel(
    List<ItemModel> importedItems,
  ) async {
    try {
      final docRef = _firestore.collection('restaurants').doc(_restaurantId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Restaurant document not found');

      final data = doc.data()!;
      final List<Map<String, dynamic>> menu =
          (data['menu'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

      var added = 0;
      var updated = 0;
      var skipped = 0;

      for (final imported in importedItems) {
        final name = imported.name.trim();
        if (name.isEmpty) {
          skipped++;
          continue;
        }

        final existingIndex = menu.indexWhere(
          (m) => (m['name']?.toString() ?? '') == name,
        );

        if (existingIndex >= 0) {
          final existing = menu[existingIndex];
          final existingItem = ItemModel.fromMap(
            existing,
            id: existing['id']?.toString() ?? '',
          );

          final merged = existingItem.copyWith(
            description:
                imported.description.isNotEmpty
                    ? imported.description
                    : existingItem.description,
            category:
                imported.category.isNotEmpty
                    ? imported.category
                    : existingItem.category,
            categoryEn:
                imported.categoryEn.isNotEmpty
                    ? imported.categoryEn
                    : existingItem.categoryEn,
            martCategoryId:
                imported.martCategoryId.isNotEmpty
                    ? imported.martCategoryId
                    : existingItem.martCategoryId,
            martSubCategoryId:
                imported.martCategoryId.isNotEmpty
                    ? imported.martSubCategoryId
                    : (imported.martSubCategoryId.isNotEmpty
                        ? imported.martSubCategoryId
                        : existingItem.martSubCategoryId),
            imageUrl:
                imported.imageUrl.isNotEmpty
                    ? imported.imageUrl
                    : existingItem.imageUrl,
            sizes:
                imported.sizes.isNotEmpty
                    ? imported.sizes
                    : existingItem.sizes,
            extrasIds:
                imported.extrasIds.isNotEmpty
                    ? imported.extrasIds
                    : existingItem.extrasIds,
            allowCustomDetails: imported.allowCustomDetails,
            isAvailable: imported.isAvailable,
            restaurantId: _restaurantId,
          );

          menu[existingIndex] = merged.toMap();
          updated++;
        } else {
          if (imported.imageUrl.isEmpty) {
            skipped++;
            continue;
          }

          final itemId = _firestore.collection('restaurants').doc().id;
          final newItem = imported.copyWith(
            id: itemId,
            restaurantId: _restaurantId,
          );
          menu.add(newItem.toMap());
          added++;
        }
      }

      await docRef.update({'menu': menu});
      return (added: added, updated: updated, skipped: skipped);
    } catch (e) {
      throw Exception('Failed to import items: ${e.toString()}');
    }
  }

  Future<void> deleteItem(String itemName) async {
    try {
      if (itemName.isEmpty) throw Exception('Item name cannot be empty');

      final docRef = _firestore.collection('restaurants').doc(_restaurantId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Restaurant document not found');

      final data = doc.data()!;
      final List<Map<String, dynamic>> menu =
          (data['menu'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      final updatedMenu =
          menu.where((item) => item['name'] != itemName).toList();
      await docRef.update({'menu': updatedMenu});
    } catch (e) {
      throw Exception('Failed to delete item: ${e.toString()}');
    }
  }

  static const String _itemExtraCollection = 'item_extra';

  Future<ExtraModel?> getRestaurantExtras() async {
    try {
      final doc =
          await _firestore
              .collection(_itemExtraCollection)
              .doc(_restaurantId)
              .get();
      if (!doc.exists || doc.data() == null) return null;
      try {
        return ExtraModel.fromMap(doc.data()!);
      } catch (_) {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to fetch restaurant extras: ${e.toString()}');
    }
  }

  Future<void> saveRestaurantExtras(List<ItemExtra> extras) async {
    try {
      await _firestore.collection(_itemExtraCollection).doc(_restaurantId).set({
        'restaurantId': _restaurantId,
        'extras': extras.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save restaurant extras: ${e.toString()}');
    }
  }
}
