import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import '../../../../Services/firebase_storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  /// Get current logged in Firebase user
  User? get currentUser => _auth.currentUser;

  /// 🆕 تسجيل مطعم جديد مع صورة مرفوعة مسبقاً (أسرع!)
  Future<Restaurant> registerRestaurant({
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
    double totalRating = 0.0,
    int ratingCount = 0,
    double averageRating = 0.0,
    double wallet = 0.0,
  }) async {
    try {
      // 1. إنشاء حساب Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. رفع الشعار إلى Firebase Storage
      final imageUrl = await _storageService.uploadLogoImage(
        imageBytes,
        imageFileName,
        restaurantId: cred.user!.uid,
      );

      // 3. إنشاء كائن المطعم
      final restaurant = Restaurant(
        id: cred.user!.uid,
        ownerId: cred.user!.uid,
        ownerName: ownerName,
        resturantName: restaurantName,
        email: email,
        address: address,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: null,
        orderTimeFinish: '20m',
        menu: [],
        latitude: latitude,
        longitude: longitude,
        totalRating: totalRating,
        averageRating: averageRating,
        ratingCount: ratingCount,
        wallet: wallet,
        accountStatus: 'pending',
        openStatus: 'closed',
        restaurantType: restaurantType,
      );

      // 4. حفظ في Firestore
      await _firestore
          .collection('restaurants')
          .doc(restaurant.id)
          .set(restaurant.toMap());

      return restaurant;
    } catch (e) {
      // تنظيف الحساب إذا فشل إنشاء المطعم
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (deleteError) {
          print(
            'Failed to delete user after restaurant creation failure: $deleteError',
          );
        }
      }
      rethrow;
    }
  }

  /// Check if user is currently logged in
  Future<bool> isUserLoggedIn() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // التحقق من أن المستخدم لم يتم حذف حسابه أو إبطاله
        await user.reload();
        return FirebaseAuth.instance.currentUser != null;
      }
      return false;
    } catch (e) {
      print('❌ [AuthService] Error checking login status: $e');
      return false;
    }
  }

  /// Sign in with email & password
  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get restaurant data for logged-in user
  Future<Restaurant?> getCurrentRestaurant() async {
    if (currentUser == null) return null;

    try {
      final doc =
          await _firestore
              .collection('restaurants')
              .doc(currentUser!.uid)
              .get();
      if (!doc.exists) return null;
      return Restaurant.fromMap(doc.id, doc.data()!);
    } catch (e) {
      print('Error getting current restaurant: $e');
      return null;
    }
  }

  /// Update restaurant info (including image)
  Future<void> updateRestaurantInfo({
    required String restaurantId,
    String? ownerName,
    String? restaurantName,
    String? address,
    dynamic imageFile,
    String? imageFileName,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    // Update text fields
    if (ownerName != null) updates['ownerName'] = ownerName;
    if (restaurantName != null) updates['resturantName'] = restaurantName;
    if (address != null) updates['address'] = address;

    // Handle image upload if provided
    if (imageFile != null) {
      String imageUrl = '';

      final folderPath = 'restaurants/$restaurantId/logo';
      if (imageFile is Uint8List) {
        imageUrl = await _storageService.uploadImageBytes(
          imageFile,
          imageFileName ??
              'restaurant_logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folderPath: folderPath,
        );
      } else {
        imageUrl = await _storageService.uploadImage(
          imageFile,
          folderPath: folderPath,
        );
      }

      updates['imageUrl'] = imageUrl;
    }

    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .update(updates);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Get current user stream for listening to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<bool> updateRestaurantOpenStatus(String id, String newStatus) async {
    try {
      await _firestore.collection('restaurants').doc(id).update({
        'openStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateRestaurantLocation({
    required String restaurantId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error updating restaurant location: $e');
      rethrow;
    }
  }
}
