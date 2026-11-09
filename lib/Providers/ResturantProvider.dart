import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import '../Services/ResturantService.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantService _restaurantService;

  Restaurant? _restaurant;
  Restaurant? get restaurant => _restaurant;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  RestaurantProvider(this._restaurantService);

  Future<void> fetchRestaurantData() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      _restaurant = await _restaurantService.getRestaurantData();
    } catch (e) {
      _lastError = 'Failed to load restaurant data: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? get orderTimeFinish => _restaurant?.orderTimeFinish;

  Future<void> updateOrderTimeFinish(String time) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _restaurantService.updateOrderTimeFinish(time);
      await fetchRestaurantData();
    } catch (e) {
      _lastError = 'Failed to update order time: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double get wallet => _restaurant?.wallet ?? 0.0;
  String get formattedTotalEarnings =>
      _restaurant?.formattedTotalEarnings ?? '0 جنيه';
  DateTime? get lastwalletUpdate => _restaurant?.lastwalletUpdate;
  String get formattedLastEarningsUpdate =>
      _restaurant?.formattedLastEarningsUpdate ?? 'لم يتم التحديث';

  Stream<DocumentSnapshot> getEarningsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(userId)
        .snapshots();
  }

  void setupEarningsListener() {
    getEarningsStream().listen(
      (snapshot) {
        if (!snapshot.exists || _restaurant == null) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final updatedWallet = (data['wallet'] as num?)?.toDouble() ?? 0.0;
        final updatedLastUpdate =
            data['lastEarningsUpdate'] != null
                ? (data['lastEarningsUpdate'] as Timestamp).toDate()
                : null;

        if (_restaurant!.wallet != updatedWallet ||
            _restaurant!.lastwalletUpdate != updatedLastUpdate) {
          _restaurant = _restaurant!.copyWith(
            wallet: updatedWallet,
            lastwalletUpdate: updatedLastUpdate,
          );
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('Error listening to earnings updates: $error');
      },
    );
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
