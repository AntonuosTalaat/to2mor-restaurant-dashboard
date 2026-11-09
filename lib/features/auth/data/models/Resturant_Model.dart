import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';

class Restaurant {
  final String id;
  final String ownerId;
  final String ownerName;
  final String resturantName;
  final String email;
  final String address;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String orderTimeFinish;
  final List<ItemModel> menu;
  final double latitude;
  final double longitude;
  final double wallet;
  final DateTime? lastwalletUpdate;
  final double totalRating;
  final int ratingCount;
  final double averageRating;
  final String accountStatus;
  final String openStatus;
  final String restaurantType;

  Restaurant({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.resturantName,
    required this.email,
    required this.address,
    required this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    required this.orderTimeFinish,
    required this.menu,
    required this.latitude,
    required this.longitude,
    required this.wallet,
    this.lastwalletUpdate,
    required this.totalRating,
    required this.ratingCount,
    required this.averageRating,
    required this.accountStatus,
    required this.openStatus,
    required this.restaurantType,
  });

  factory Restaurant.fromMap(String id, Map<String, dynamic> data) {
    List<ItemModel> menuItems = [];
    bool needsUpdate = false; // ✅ Flag to track if we need to update Firestore

    if (data['menu'] != null) {
      final menuList = data['menu'] as List;
      for (int i = 0; i < menuList.length; i++) {
        final itemData = menuList[i] as Map<String, dynamic>;

        String itemId = itemData['id'] ?? '';
        if (itemId.isEmpty) {
          // ✅ Generate unique ID for old items
          itemId = FirebaseFirestore.instance.collection('temp').doc().id;
          needsUpdate = true; // Mark that we need to update
        }

        menuItems.add(
          ItemModel.fromMap({...itemData, 'id': itemId}, id: itemId),
        );
      }
    }

    // ✅ Auto-fix old items in background (optional but recommended)
    if (needsUpdate) {
      _autoFixMenuIds(id, menuItems);
    }

    return Restaurant(
      id: id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      resturantName: data['resturantName'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      accountStatus: data['accountStatus'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      orderTimeFinish: data['orderTimeFinish'] ?? '20m',
      totalRating: (data['totalRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      menu: menuItems,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      wallet: (data['wallet'] as num?)?.toDouble() ?? 0.0,
      lastwalletUpdate:
          data['lastEarningsUpdate'] != null
              ? (data['lastEarningsUpdate'] as Timestamp).toDate()
              : null,
      openStatus: data['openStatus'] ?? 'closed',
      restaurantType: data['restaurantType'] ?? 'food',
    );
  }

  // ✅ Helper method to fix IDs in Firestore automatically
  static Future<void> _autoFixMenuIds(
    String restaurantId,
    List<ItemModel> menuItems,
  ) async {
    try {
      final updatedMenu = menuItems.map((item) => item.toMap()).toList();
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .update({'menu': updatedMenu});
      print('✅ Auto-fixed menu IDs for restaurant: $restaurantId');
    } catch (e) {
      print('⚠️ Failed to auto-fix menu IDs: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'resturantName': resturantName,
      'email': email,
      'address': address,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'orderTimeFinish': orderTimeFinish,
      'menu': menu.map((item) => item.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'wallet': wallet,
      'totalRating': totalRating,
      'ratingCount': ratingCount,
      'averageRating': averageRating,
      'accountStatus': accountStatus,
      'lastEarningsUpdate':
          lastwalletUpdate != null
              ? Timestamp.fromDate(lastwalletUpdate!)
              : null,
      'openStatus': openStatus,
      'restaurantType': restaurantType,
    };
  }

  Restaurant copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? resturantName,
    String? email,
    String? address,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? orderTimeFinish,
    List<ItemModel>? menu,
    double? latitude,
    double? longitude,
    double? wallet,
    DateTime? lastwalletUpdate,
    double? totalRating,
    int? ratingCount,
    double? averageRating,
    String? accountStatus,
    String? openStatus,
    String? restaurantType,
  }) {
    return Restaurant(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      resturantName: resturantName ?? this.resturantName,
      email: email ?? this.email,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderTimeFinish: orderTimeFinish ?? this.orderTimeFinish,
      menu: menu ?? this.menu,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      wallet: wallet ?? this.wallet,
      lastwalletUpdate: lastwalletUpdate ?? this.lastwalletUpdate,
      totalRating: totalRating ?? this.totalRating,
      ratingCount: ratingCount ?? this.ratingCount,
      averageRating: averageRating ?? this.averageRating,
      accountStatus: accountStatus ?? this.accountStatus,
      openStatus: openStatus ?? this.openStatus,
      restaurantType: restaurantType ?? this.restaurantType,
    );
  }

  String get formattedTotalEarnings => '${wallet.toStringAsFixed(0)} جنيه';

  String get formattedLastEarningsUpdate {
    if (lastwalletUpdate == null) return 'لم يتم التحديث';

    final now = DateTime.now();
    final difference = now.difference(lastwalletUpdate!);

    if (difference.inMinutes < 1) {
      return 'منذ لحظات';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${lastwalletUpdate!.day}/${lastwalletUpdate!.month}/${lastwalletUpdate!.year}';
    }
  }

  bool get isOpen => openStatus == 'open';
  String get statusLabel => isOpen ? 'فاتح' : 'قافل';

  String get typeLabel {
    switch (restaurantType) {
      case 'food':
        return 'مطعم';
      case 'supermarket':
        return 'سوبرماركت';
      case 'pharmacy':
        return 'صيدلية';
      case 'mart':
        return 'مارت';
      default:
        return 'غير محدد';
    }
  }
}
