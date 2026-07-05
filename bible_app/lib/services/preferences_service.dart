import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service for managing user preferences and settings
class PreferencesService {
  static const String _themeModeKey = 'theme_mode';
  
  static PreferencesService? _instance;
  static PreferencesService get instance {
    _instance ??= PreferencesService._();
    return _instance!;
  }
  
  PreferencesService._();
  
  SharedPreferences? _prefs;
  
  /// Initialize the preferences service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get the saved theme mode
  /// Returns null if not set (defaults to system)
  ThemeMode? getThemeMode() {
    if (_prefs == null) return null;
    
    final themeModeString = _prefs!.getString(_themeModeKey);
    if (themeModeString == null) return null;
    
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  /// Save the theme mode preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_prefs == null) return;
    
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        modeString = 'system';
        break;
    }
    
    await _prefs!.setString(_themeModeKey, modeString);
  }
}
