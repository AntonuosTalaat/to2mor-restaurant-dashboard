import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:restaurantdashboard/config/injection_container.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import 'package:restaurantdashboard/features/auth/data/datasources/AuthService.dart';
import 'package:restaurantdashboard/features/notifications/presentation/cubit/notification_cubit.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Restaurant? _restaurant;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasCheckedAuth = false; // للتأكد من أننا فحصنا المصادقة مرة واحدة

  Restaurant? get restaurant => _restaurant;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _restaurant != null;
  bool get hasCheckedAuth => _hasCheckedAuth;
  String? _lastError;
  String? get lastError => _lastError;
  // ✅ New getter to check if account is active
  bool get isAccountActive {
    if (_restaurant == null) return false;
    return _restaurant!.accountStatus.toLowerCase() == 'active';
  }

  // ✅ New getter to get account status
  String get accountStatus {
    if (_restaurant == null) return 'unknown';
    return _restaurant!.accountStatus;
  }

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    if (_hasCheckedAuth) return;

    _setLoading(true);
    try {
      final isAuthenticated = await _authService.isUserLoggedIn();

      if (isAuthenticated) {
        await loadCurrentRestaurant();
        await listenToRestaurantChanges();
      } else {
        _restaurant = null;
      }

      _errorMessage = null;
      _hasCheckedAuth = true;
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _errorMessage = e.toString();
      _restaurant = null;
      _hasCheckedAuth = true;
      Future.microtask(() => notifyListeners());
    } finally {
      _setLoading(false);
    }
  }

  /// Register restaurant account
  Future<void> registerRestaurant({
    required String ownerName,
    required String restaurantName,
    required String email,
    required String password,
    required String address,
    required Uint8List imageBytes,
    required String imageFileName,
    required double latitude,
    required double longitude,
    required String restaurantType,
    double? totalRating,
    int? ratingCount,
    double? averageRating,
    double? wallet,
  }) async {
    _setLoading(true);
    try {
      _restaurant = await _authService.registerRestaurant(
        ownerName: ownerName,
        restaurantName: restaurantName,
        email: email,
        password: password,
        address: address,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        latitude: latitude,
        longitude: longitude,
        wallet: wallet ?? 0.0,
        ratingCount: ratingCount ?? 0,
        averageRating: averageRating ?? 0.0,
        totalRating: totalRating ?? 0.0,
        restaurantType: restaurantType,
      );
      _errorMessage = null;
      _hasCheckedAuth = true; // تم التسجيل بنجاح
      notifyListeners();

      // Add a small delay to ensure Firestore consistency
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorMessage = e.toString();
      _restaurant = null;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.signIn(email, password);
      if (user != null) {
        await loadCurrentRestaurant();
      }
      _errorMessage = null;
      _hasCheckedAuth = true; // تم تسجيل الدخول بنجاح
    } catch (e) {
      _errorMessage = e.toString();
      _restaurant = null;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _restaurantSub?.cancel();
      _restaurantSub = null;
      try {
        await sl<NotificationCubit>().disposeForLogout();
      } catch (_) {}
      await _authService.signOut();
      _restaurant = null;
      _errorMessage = null;
      _hasCheckedAuth = false; // إعادة تعيين حالة الفحص
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  StreamSubscription? _restaurantSub;

  Future<void> listenToRestaurantChanges() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // cancel القديم لو موجود
    await _restaurantSub?.cancel();

    _restaurantSub = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            _restaurant = Restaurant.fromMap(snapshot.id, snapshot.data()!);
            notifyListeners(); // 🟢 يحدث الواجهة تلقائي
          }
        });
  }

  /// Load current restaurant data
  Future<void> loadCurrentRestaurant() async {
    try {
      _restaurant = await _authService.getCurrentRestaurant();
      if (_restaurant != null) {
        print('✅ [AuthProvider] Restaurant loaded');
        print('📊 [AuthProvider] Account status');
      } else {
        print('⚠️ [AuthProvider] No restaurant found for current user');
      }
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('❌ [AuthProvider] Load restaurant error');
      _errorMessage = e.toString();
      _restaurant = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Update restaurant info
  Future<void> updateRestaurantInfo({
    required String restaurantId,
    String? ownerName,
    String? restaurantName,
    String? address,
    dynamic imageFile,
    String? imageFileName,
  }) async {
    _setLoading(true);
    try {
      await _authService.updateRestaurantInfo(
        restaurantId: restaurantId,
        ownerName: ownerName,
        restaurantName: restaurantName,
        address: address,
        imageFile: imageFile,
        imageFileName: imageFileName,
      );

      // Refresh the restaurant data after update
      await loadCurrentRestaurant();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ New method to refresh account status specifically
  Future<bool> refreshAccountStatus() async {
    if (_restaurant == null) return false;

    try {
      await loadCurrentRestaurant();

      final newStatus = _restaurant?.accountStatus ?? '';

      return newStatus.toLowerCase() == 'active';
    } catch (e) {
      return false;
    }
  }

  // ✅ New method to check if user can access main app
  bool get canAccessMainApp {
    return isLoggedIn && isAccountActive;
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    Future.microtask(() => notifyListeners());
    _lastError = null;
    notifyListeners();
  }

  /// Reset auth check status
  void resetAuthCheck() {
    _hasCheckedAuth = false;
    Future.microtask(() => notifyListeners());
  }

  /// Check if restaurant is properly initialized
  bool get isRestaurantReady =>
      _restaurant != null && _restaurant!.id.isNotEmpty;

  Future<bool> updateOpenStatus(String newStatus) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final success = await _authService.updateRestaurantOpenStatus(
        userId,
        newStatus,
      );

      if (success && _restaurant != null) {
        // نعمل update للـ object عشان UI يتحدث
        _restaurant = Restaurant(
          id: _restaurant!.id,
          ownerId: _restaurant!.ownerId,
          ownerName: _restaurant!.ownerName,
          resturantName: _restaurant!.resturantName,
          email: _restaurant!.email,
          address: _restaurant!.address,
          imageUrl: _restaurant!.imageUrl,
          createdAt: _restaurant!.createdAt,
          updatedAt: DateTime.now(),
          orderTimeFinish: _restaurant!.orderTimeFinish,
          menu: _restaurant!.menu,
          latitude: _restaurant!.latitude,
          longitude: _restaurant!.longitude,
          wallet: _restaurant!.wallet,
          lastwalletUpdate: _restaurant!.lastwalletUpdate,
          totalRating: _restaurant!.totalRating,
          averageRating: _restaurant!.averageRating,
          ratingCount: _restaurant!.ratingCount,
          accountStatus: _restaurant!.accountStatus,
          restaurantType: _restaurant!.restaurantType,
          openStatus: newStatus, // ✅ تحديث الحالة
        );
        notifyListeners();
      }

      return success;
    } catch (e) {
      _lastError = 'Failed to update open status: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRestaurantLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_restaurant == null) {
      throw Exception('لا توجد بيانات للمطعم');
    }

    _setLoading(true);
    try {
      await _authService.updateRestaurantLocation(
        restaurantId: _restaurant!.id,
        latitude: latitude,
        longitude: longitude,
      );

      // Refresh the restaurant data after location update
      await loadCurrentRestaurant();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
