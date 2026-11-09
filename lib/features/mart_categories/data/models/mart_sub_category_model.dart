class MartSubCategoryModel {
  const MartSubCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.sortOrder,
    required this.isActive,
    this.imageUrl = '',
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final int sortOrder;
  final bool isActive;

  MartSubCategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) {
    return MartSubCategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameAr.trim(),
      'name_en': nameEn.trim(),
      'image_url': imageUrl.trim(),
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  factory MartSubCategoryModel.fromMap(Map<String, dynamic> map) {
    return MartSubCategoryModel(
      id: (map['id'] ?? '').toString(),
      nameAr: (map['name_ar'] ?? '').toString(),
      nameEn: (map['name_en'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      sortOrder: _asInt(map['sort_order']),
      isActive: map['is_active'] is bool ? map['is_active'] as bool : true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
