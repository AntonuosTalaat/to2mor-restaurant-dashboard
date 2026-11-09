import 'package:cloud_firestore/cloud_firestore.dart';

class ExtraModel {
  final List<ItemExtra> extras;

  final String restaurantId;
  final DateTime updatedAt;

  ExtraModel({
    required this.extras,
    required this.restaurantId,
    required this.updatedAt,
  });

  factory ExtraModel.fromMap(Map<String, dynamic> map) {
    return ExtraModel(
      // ✅ صح - بتعمل parse لكل extra
      extras:
          (map['extras'] as List<dynamic>? ?? [])
              .map((e) => ItemExtra.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
      restaurantId: map['restaurantId'] ?? '',
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'extras': extras.map((e) => e.toMap()).toList(),
      'restaurantId': restaurantId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ExtraModel copyWith({
    List<ItemExtra>? extras,
    String? restaurantId,
    DateTime? updatedAt,
  }) {
    return ExtraModel(
      extras: extras ?? this.extras,
      restaurantId: restaurantId ?? this.restaurantId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ItemExtra {
  final String id;
  final String name;
  final double price;
  final double? discountPercent;
  final String? img;

  ItemExtra({
    required this.id,
    required this.name,
    required this.price,
    this.discountPercent,
    this.img,
  });

  double get discountedPrice {
    if (discountPercent != null && discountPercent! > 0) {
      return price * (1 - discountPercent! / 100);
    }
    return price;
  }

  bool get hasDiscount => discountPercent != null && discountPercent! > 0;

  factory ItemExtra.fromMap(Map<String, dynamic> data) {
    return ItemExtra(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      price:
          (data['price'] is int)
              ? (data['price'] as int).toDouble()
              : (data['price'] ?? 0.0).toDouble(),
      discountPercent:
          data['discountPercent'] != null
              ? ((data['discountPercent'] is int)
                  ? (data['discountPercent'] as int).toDouble()
                  : (data['discountPercent'] ?? 0.0).toDouble())
              : null,
      img: data['img'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (img != null) 'img': img,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemExtra &&
        other.id == id &&
        other.name == name &&
        other.price == price;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ price.hashCode;
}
