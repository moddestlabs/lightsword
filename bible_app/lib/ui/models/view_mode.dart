/// Display mode for Bible text viewing
enum ViewMode {
  /// Standard verse-by-verse reading view
  standard,
  
  /// Interlinear view with original language text and morphology
  interlinear,
  
  /// Paragraph mode with continuous text (future)
  paragraph,
  
  // Future modes:
  // - highlighted: verse sets with specific parts highlighted
  // - commentary: user commentary overlays
  // - parallel: side-by-side translations
}

extension ViewModeExtension on ViewMode {
  /// Display name for the view mode
  String get displayName {
    switch (this) {
      case ViewMode.standard:
        return 'Standard';
      case ViewMode.interlinear:
        return 'Interlinear';
      case ViewMode.paragraph:
        return 'Paragraph';
    }
  }
  
  /// Icon for the view mode
  String get icon {
    switch (this) {
      case ViewMode.standard:
        return '📖';
      case ViewMode.interlinear:
        return '🔤';
      case ViewMode.paragraph:
        return '📄';
    }
  }
  
  /// Whether this mode is currently implemented
  bool get isImplemented {
    switch (this) {
      case ViewMode.standard:
      case ViewMode.interlinear:
        return true;
      case ViewMode.paragraph:
        return false;
    }
  }
}
