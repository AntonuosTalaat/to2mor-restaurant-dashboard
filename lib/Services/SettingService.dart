import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/SettingModel.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'settings';
  static const String _documentId = 'systemFlags';

  /// Get the autoAssignToBranches setting from Firestore
  Future<bool> getAutoAssignToBranches() async {
    try {
      final doc = await _firestore.collection('settings').doc('systemFlags').get();

      if (doc.exists) {
        final data = doc.data();
        return data?['autoAssignToBranches'] as bool? ?? false;
      }

      return false; // Default value if document doesn't exist
    } catch (e) {
      print('❌ Error getting autoAssignToBranches setting');
      return false; // Default value on error
    }
  }

  /// Helper method to determine isMainCompany based on autoAssign setting
  Future<bool> getIsMainCompany() async {
    final autoAssignToBranches = await getAutoAssignToBranches();
    // When autoAssignToBranches is true, return isMainCompany == false
    return !autoAssignToBranches;
  }

  DocumentReference get _docRef =>
      _firestore.collection(_collectionName).doc(_documentId);

  /// ✅ جلب الإعدادات كـ Stream (مناسب للـ Provider)
  Stream<SettingModel?> getSettingsStream() {
    return _docRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return SettingModel.fromMap(
          snapshot.data() as Map<String, dynamic>,
          snapshot.id,
        );
      }
      return null;
    });
  }

  /// ✅ جلب الإعدادات مرة واحدة
  Future<SettingModel?> getSettings() async {
    try {
      final snapshot = await _docRef.get();
      if (snapshot.exists) {
        return SettingModel.fromMap(
          snapshot.data() as Map<String, dynamic>,
          snapshot.id,
        );
      }
      return null;
    } catch (e) {
      print("Error getting settings");
      return null;
    }
  }
}