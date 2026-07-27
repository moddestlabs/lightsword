import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// Provider for managing text font size and pinch-to-zoom settings across the app.
class FontSizeProvider extends ChangeNotifier {
  static const double minFontSize = 12.0;
  static const double maxFontSize = 36.0;
  static const double defaultFontSize = 18.0;

  double _fontSize = defaultFontSize;
  bool _pinchToZoomEnabled = true;
  String _fontFamily = 'Cardo';
  final PreferencesService _prefsService = PreferencesService.instance;

  double get fontSize => _fontSize;
  bool get pinchToZoomEnabled => _pinchToZoomEnabled;
  String get fontFamily => _fontFamily;

  /// Initialize font size and settings from saved preferences
  Future<void> initialize() async {
    _fontSize = _prefsService.getFontSize().clamp(minFontSize, maxFontSize);
    _pinchToZoomEnabled = _prefsService.getPinchToZoomEnabled();
    _fontFamily = _prefsService.getFontFamily();
    notifyListeners();
  }

  /// Set explicit font size and persist preference
  Future<void> setFontSize(double size) async {
    final clampedSize = double.parse(
      size.clamp(minFontSize, maxFontSize).toStringAsFixed(1),
    );
    if (_fontSize == clampedSize) return;

    _fontSize = clampedSize;
    await _prefsService.setFontSize(_fontSize);
    notifyListeners();
  }

  /// Set selected font family and persist preference
  Future<void> setFontFamily(String family) async {
    if (_fontFamily == family) return;

    _fontFamily = family;
    await _prefsService.setFontFamily(family);
    notifyListeners();
  }

  /// Set pinch to zoom toggle and persist preference
  Future<void> setPinchToZoomEnabled(bool enabled) async {
    if (_pinchToZoomEnabled == enabled) return;

    _pinchToZoomEnabled = enabled;
    await _prefsService.setPinchToZoomEnabled(enabled);
    notifyListeners();
  }

  /// Update font size during interactive pinch gesture without disk save on every frame
  void setFontSizeEphemeral(double size) {
    final clampedSize = double.parse(
      size.clamp(minFontSize, maxFontSize).toStringAsFixed(1),
    );
    if (_fontSize == clampedSize) return;

    _fontSize = clampedSize;
    notifyListeners();
  }

  /// Save current font size to disk (e.g. at end of pinch gesture)
  Future<void> commitFontSize() async {
    await _prefsService.setFontSize(_fontSize);
  }
}
