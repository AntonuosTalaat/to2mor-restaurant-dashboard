import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';

class RestaurantService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RestaurantService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String get _restaurantId => _auth.currentUser!.uid;

  /// Update order completion time
  Future<void> updateOrderTimeFinish(String newTime) async {
    try {
      await _firestore.collection('restaurants').doc(_restaurantId).update({
        'orderTimeFinish': newTime,
      });
    } catch (e) {
      throw Exception('Failed to update order time: ${e.toString()}');
    }
  }

  /// Fetch complete restaurant data
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
}
