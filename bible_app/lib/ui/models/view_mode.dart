/// Display mode for Bible text viewing
enum ViewMode {
  /// Standard verse-by-verse reading view
  standard,
  
  /// Interlinear view with original language text and morphology
  interlinear,
  
  /// Paragraph mode with continuous text
  paragraph,

  /// Markup study mode with highlights and notes
  markup,

  /// Study mode
  study,

  /// Drawing mode
  drawing,
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
      case ViewMode.markup:
      case ViewMode.study:
        return 'Markup';
      case ViewMode.drawing:
        return 'Drawing';
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
      case ViewMode.markup:
      case ViewMode.study:
        return '✏️';
      case ViewMode.drawing:
        return '🎨';
    }
  }
  
  /// Whether this mode is currently implemented
  bool get isImplemented {
    switch (this) {
      case ViewMode.standard:
      case ViewMode.interlinear:
      case ViewMode.markup:
      case ViewMode.study:
      case ViewMode.drawing:
        return true;
      case ViewMode.paragraph:
        return false;
    }
  }
}
