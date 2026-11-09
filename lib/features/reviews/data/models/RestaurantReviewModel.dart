class RestaurantReview {
  final String? id;
  final DateTime createdAt;
  final String? deliveryComment;
  final String deliveryId;
  final String deliveryName;
  final double deliveryRating;
  final String orderId;
  final String? restaurantComment;
  final String restaurantId;
  final String restaurantName;
  final double restaurantRating;
  final DateTime? updatedAt;
  final String userId;
  final String userName;

  RestaurantReview({
    this.id,
    required this.createdAt,
    this.deliveryComment,
    required this.deliveryId,
    required this.deliveryName,
    required this.deliveryRating,
    required this.orderId,
    this.restaurantComment,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantRating,
    this.updatedAt,
    required this.userId,
    required this.userName,
  });

  factory RestaurantReview.fromMap(Map<String, dynamic> map, String id) {
    return RestaurantReview(
      id: id,
      createdAt: (map['createdAt'] is String)
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt']?.toDate() ?? DateTime.now()),
      deliveryComment: map['deliveryComment'],
      deliveryId: map['deliveryId'] ?? '',
      deliveryName: map['deliveryName'] ?? '',
      deliveryRating: (map['deliveryRating'] ?? 0).toDouble(),
      orderId: map['orderId'] ?? '',
      restaurantComment: map['restaurantComment'],
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      restaurantRating: (map['restaurantRating'] ?? 0).toDouble(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is String)
          ? DateTime.parse(map['updatedAt'])
          : map['updatedAt']?.toDate()
          : null,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'deliveryComment': deliveryComment,
      'deliveryId': deliveryId,
      'deliveryName': deliveryName,
      'deliveryRating': deliveryRating,
      'orderId': orderId,
      'restaurantComment': restaurantComment,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantRating': restaurantRating,
      'updatedAt': updatedAt?.toIso8601String(),
      'userId': userId,
      'userName': userName,
    };
  }

  RestaurantReview copyWith({
    String? id,
    DateTime? createdAt,
    String? deliveryComment,
    String? deliveryId,
    String? deliveryName,
    double? deliveryRating,
    String? orderId,
    String? restaurantComment,
    String? restaurantId,
    String? restaurantName,
    double? restaurantRating,
    DateTime? updatedAt,
    String? userId,
    String? userName,
  }) {
    return RestaurantReview(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      deliveryComment: deliveryComment ?? this.deliveryComment,
      deliveryId: deliveryId ?? this.deliveryId,
      deliveryName: deliveryName ?? this.deliveryName,
      deliveryRating: deliveryRating ?? this.deliveryRating,
      orderId: orderId ?? this.orderId,
      restaurantComment: restaurantComment ?? this.restaurantComment,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantRating: restaurantRating ?? this.restaurantRating,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }

  // Helper getters
  bool get hasComments {
    return (restaurantComment != null && restaurantComment!.isNotEmpty) ||
        (deliveryComment != null && deliveryComment!.isNotEmpty);
  }

  double get overallRating {
    return (restaurantRating + deliveryRating) / 2;
  }

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get shortOrderId {
    return orderId.length > 8 ? orderId.substring(0, 8) : orderId;
  }
}