import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// Provider for managing app theme mode
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final PreferencesService _prefsService = PreferencesService.instance;
  
  ThemeMode get themeMode => _themeMode;
  
  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    final savedMode = _prefsService.getThemeMode();
    if (savedMode != null) {
      _themeMode = savedMode;
      notifyListeners();
    }
  }
  
  /// Set the theme mode and persist the preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _prefsService.setThemeMode(mode);
    notifyListeners();
  }
  
  /// Check if currently using dark theme based on context
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    
    // System mode - check platform brightness
    final brightness = MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark;
  }
}
