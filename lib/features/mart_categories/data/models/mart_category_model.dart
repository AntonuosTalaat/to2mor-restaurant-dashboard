import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_sub_category_model.dart';

class MartCategoryModel {
  const MartCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.address,
    required this.lat,
    required this.lng,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.shortDescAr,
    this.shortDescEn,
    this.subCategories = const [],
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
  final DateTime updatedAt;
  final List<MartSubCategoryModel> subCategories;

  List<MartSubCategoryModel> get activeSubCategories {
    final list = subCategories.where((e) => e.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  MartCategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? shortDescAr,
    String? shortDescEn,
    String? imageUrl,
    String? address,
    double? lat,
    double? lng,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MartSubCategoryModel>? subCategories,
  }) {
    return MartCategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      shortDescAr: shortDescAr ?? this.shortDescAr,
      shortDescEn: shortDescEn ?? this.shortDescEn,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subCategories: subCategories ?? this.subCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name_ar': nameAr.trim(),
      'name_en': nameEn.trim(),
      'short_desc_ar': shortDescAr?.trim().isEmpty == true ? null : shortDescAr?.trim(),
      'short_desc_en': shortDescEn?.trim().isEmpty == true ? null : shortDescEn?.trim(),
      'image_url': imageUrl.trim(),
      'location': {
        'address': address.trim(),
        'lat': lat,
        'lng': lng,
      },
      'sort_order': sortOrder,
      'is_active': isActive,
      'sub_categories': subCategories.map((e) => e.toMap()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory MartCategoryModel.fromMap(Map<String, dynamic> map, String id) {
    final location = (map['location'] as Map<String, dynamic>?) ?? const {};
    final rawSubs = map['sub_categories'] as List<dynamic>? ?? const [];
    final subs = rawSubs
        .whereType<Map>()
        .map((e) => MartSubCategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return MartCategoryModel(
      id: id,
      nameAr: (map['name_ar'] ?? '').toString(),
      nameEn: (map['name_en'] ?? '').toString(),
      shortDescAr: map['short_desc_ar']?.toString(),
      shortDescEn: map['short_desc_en']?.toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      address: (location['address'] ?? '').toString(),
      lat: _asDouble(location['lat']),
      lng: _asDouble(location['lng']),
      sortOrder: _asInt(map['sort_order']),
      isActive: map['is_active'] is bool ? map['is_active'] as bool : true,
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
      subCategories: subs,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
