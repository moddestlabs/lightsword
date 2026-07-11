import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

enum AppPalette {
  neutral(
    id: 'neutral',
    label: 'Neutral',
    description: 'Gray UI with restrained accents for content-first reading',
    icon: Icons.contrast,
    seedColor: Color(0xFF5F6368),
    contrastLevel: 0.0,
  ),
  sepia(
    id: 'sepia',
    label: 'Sepia',
    description: 'Warm brown accents similar to the current reading tone',
    icon: Icons.auto_awesome,
    seedColor: Color(0xFF8B4513),
    contrastLevel: 0.0,
  ),
  highContrast(
    id: 'high_contrast',
    label: 'High Contrast',
    description: 'Stronger foreground and accent separation for maximum legibility',
    icon: Icons.visibility,
    seedColor: Color(0xFF000000),
    contrastLevel: 1.0,
  );

  const AppPalette({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.seedColor,
    required this.contrastLevel,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color seedColor;
  final double contrastLevel;

  static AppPalette fromId(String? id) {
    return AppPalette.values.firstWhere(
      (palette) => palette.id == id,
      orElse: () => AppPalette.neutral,
    );
  }
}

/// Provider for managing app theme mode
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppPalette _palette = AppPalette.neutral;
  final PreferencesService _prefsService = PreferencesService.instance;
  
  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;
  Color get seedColor => _palette.seedColor;
  
  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    _themeMode = _prefsService.getThemeMode() ?? ThemeMode.system;
    _palette = AppPalette.fromId(_prefsService.getAppearancePalette());
    notifyListeners();
  }
  
  /// Set the theme mode and persist the preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _prefsService.setThemeMode(mode);
    notifyListeners();
  }

  /// Set the appearance palette and persist the preference.
  Future<void> setPalette(AppPalette palette) async {
    if (_palette == palette) return;

    _palette = palette;
    await _prefsService.setAppearancePalette(palette.id);
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
