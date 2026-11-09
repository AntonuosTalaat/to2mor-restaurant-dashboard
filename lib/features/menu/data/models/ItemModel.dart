class ItemModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String categoryEn;
  final String martCategoryId;
  final String martSubCategoryId;
  final String imageUrl;
  final String restaurantId;
  final List<ItemSize> sizes;
  final List<String> extrasIds;

  final bool allowCustomDetails;

  /// هل المنتج متاح حالياً
  final bool isAvailable;

  ItemModel({
    this.id = '',
    required this.name,
    required this.description,
    required this.category,
    this.categoryEn = '',
    this.martCategoryId = '',
    this.martSubCategoryId = '',
    required this.imageUrl,
    required this.restaurantId,
    this.sizes = const [],
    this.extrasIds = const [],
    this.allowCustomDetails = false,
    this.isAvailable = true, // القيمة الافتراضية أن المنتج متاح
  });

  factory ItemModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return ItemModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      categoryEn: data['categoryEn'] ?? '',
      martCategoryId: data['martCategoryId'] ?? '',
      martSubCategoryId: data['martSubCategoryId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      extrasIds:
          (data['extrasIds'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      sizes:
          (data['sizes'] as List<dynamic>? ?? [])
              .map((e) => ItemSize.fromMap(e))
              .toList(),
      allowCustomDetails: (data['allowCustomDetails'] as bool?) ?? false,
      isAvailable:
          (data['isAvailable'] as bool?) ??
          true, // ✅ Fixed: explicit cast to bool?
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'categoryEn': categoryEn,
      'martCategoryId': martCategoryId,
      'martSubCategoryId': martSubCategoryId,
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
      'sizes': sizes.map((e) => e.toMap()).toList(),
      'extrasIds': extrasIds,
      'allowCustomDetails': allowCustomDetails,
      'isAvailable': isAvailable,
    };
  }

  ItemModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? categoryEn,
    String? martCategoryId,
    String? martSubCategoryId,
    String? imageUrl,
    String? restaurantId,
    List<ItemSize>? sizes,
    List<String>? extrasIds,
    bool? allowCustomDetails,
    bool? isAvailable,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryEn: categoryEn ?? this.categoryEn,
      martCategoryId: martCategoryId ?? this.martCategoryId,
      martSubCategoryId: martSubCategoryId ?? this.martSubCategoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      sizes: sizes ?? this.sizes,
      extrasIds: extrasIds ?? this.extrasIds,
      allowCustomDetails: allowCustomDetails ?? this.allowCustomDetails,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class ItemSize {
  final String name;
  final double price;
  final double discountPercent;

  ItemSize({
    required this.name,
    required this.price,
    this.discountPercent = 0.0,
  });

  factory ItemSize.fromMap(Map<String, dynamic> data) {
    return ItemSize(
      name: data['name'] ?? '',
      price:
          (data['price'] is int)
              ? (data['price'] as int).toDouble()
              : (data['price'] ?? 0.0).toDouble(),
      discountPercent:
          (data['discountPercent'] is int)
              ? (data['discountPercent'] as int).toDouble()
              : (data['discountPercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'discountPercent': discountPercent};
  }
}
