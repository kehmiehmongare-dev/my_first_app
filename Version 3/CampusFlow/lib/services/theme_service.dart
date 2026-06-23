import 'package:flutter/material.dart';
import 'package:campus_flow/services/preferences_service.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final PreferencesService _prefs = PreferencesService();

  // ✅ Get current theme mode
  Future<ThemeMode> getThemeMode() async {
    final mode = _prefs.getThemeMode();
    switch (mode) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  // ✅ Save theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    int value;
    switch (mode) {
      case ThemeMode.light:
        value = 0;
        break;
      case ThemeMode.dark:
        value = 1;
        break;
      case ThemeMode.system:
        value = 2;
        break;
    }
    await _prefs.setThemeMode(value);
  }
}
