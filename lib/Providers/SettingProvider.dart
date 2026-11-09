import 'package:flutter/material.dart';
import '../Models/SettingModel.dart';
import '../Services/SettingService.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  SettingModel? _settings;
  bool _isLoading = false;
  bool _isListening = false;

  SettingModel? get settings => _settings;
  bool get isLoading => _isLoading;

  /// 🔹 تحميل الإعدادات مرة واحدة (initial fetch)
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _settingsService.getSettings();
    } catch (e) {
      print('❌ Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void listenToSettings() {
    if (_isListening) return; // لتجنب تكرار الـ Stream
    _isListening = true;

    _settingsService.getSettingsStream().listen((settingModel) {
      _settings = settingModel;
      notifyListeners();
    }, onError: (error) {
      print('❌ Error listening to settings stream');
    });
  }

  bool get autoAssignToBranches => _settings?.autoAssignToBranches ?? false;
  bool get isRestaurantSignupEnabled =>
      _settings?.isRestaurantSignupEnabled ?? true;
}
