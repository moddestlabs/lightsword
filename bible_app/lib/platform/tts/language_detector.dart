/// Language detection utility for determining the primary language of text
/// Supports Hebrew, Greek, and English
class LanguageDetector {
  /// Detect the primary language of the given text
  /// Returns ISO language code: 'he-IL', 'el-GR', or 'en-US'
  static String detect(String text) {
    if (text.isEmpty) return 'en-US';
    
    // Count characters by script
    int hebrewCount = 0;
    int greekCount = 0;
    int latinCount = 0;
    
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      
      // Hebrew (including niqqud and cantillation marks)
      // U+0590 to U+05FF - Hebrew block
      if (codeUnit >= 0x0590 && codeUnit <= 0x05FF) {
        hebrewCount++;
      }
      // Greek
      // U+0370 to U+03FF - Greek and Coptic
      // U+1F00 to U+1FFF - Greek Extended (polytonic diacritics)
      else if ((codeUnit >= 0x0370 && codeUnit <= 0x03FF) ||
               (codeUnit >= 0x1F00 && codeUnit <= 0x1FFF)) {
        greekCount++;
      }
      // Latin/English
      // U+0041 to U+005A - Uppercase A-Z
      // U+0061 to U+007A - Lowercase a-z
      else if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
               (codeUnit >= 0x0061 && codeUnit <= 0x007A)) {
        latinCount++;
      }
    }
    
    // Determine dominant language
    if (hebrewCount > greekCount && hebrewCount > latinCount) {
      return 'he-IL';
    } else if (greekCount > hebrewCount && greekCount > latinCount) {
      return 'el-GR';
    } else {
      return 'en-US';
    }
  }
  
  /// Check if text contains Hebrew characters
  static bool containsHebrew(String text) {
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (codeUnit >= 0x0590 && codeUnit <= 0x05FF) {
        return true;
      }
    }
    return false;
  }
  
  /// Check if text contains Greek characters
  static bool containsGreek(String text) {
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if ((codeUnit >= 0x0370 && codeUnit <= 0x03FF) ||
          (codeUnit >= 0x1F00 && codeUnit <= 0x1FFF)) {
        return true;
      }
    }
    return false;
  }
  
  /// Get human-readable language name from code
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'he-IL':
        return 'Hebrew';
      case 'el-GR':
        return 'Greek';
      case 'en-US':
        return 'English';
      default:
        return languageCode;
    }
  }
}
