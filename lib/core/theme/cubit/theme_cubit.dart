import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const _key = 'theme_mode';

  ThemeCubit()
      : super(const ThemeState(themeMode: ThemeMode.dark));

  // ── Load saved theme on app start ─────────
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    final mode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    emit(ThemeState(themeMode: mode));
  }

  // ── Toggle between light and dark ─────────
  Future<void> toggleTheme() async {
    final newMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    await _saveAndEmit(newMode);
  }

  // ── Set specific theme ────────────────────
  Future<void> setTheme(ThemeMode mode) async {
    await _saveAndEmit(mode);
  }

  Future<void> _saveAndEmit(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    emit(ThemeState(themeMode: mode));
  }
}