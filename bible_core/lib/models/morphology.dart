import 'word.dart' show MorphologyTag;

/// Parse morphology codes into human-readable MorphologyTag
class MorphologyParser {
  /// Parse a morphology code string into a MorphologyTag
  /// Format depends on source (e.g., Robinson, STEPBible, OSHB)
  static MorphologyTag? parse(String code) {
    // TODO: Implement parsers for common morphology code formats
    // - Robinson codes (Greek NT)
    // - STEPBible codes
    // - OSHB codes (Hebrew)
    return MorphologyTag(rawCode: code);
  }

  /// Convert a MorphologyTag to human-readable description
  static String describe(MorphologyTag tag) {
    final parts = <String>[];
    
    if (tag.partOfSpeech != null) parts.add(tag.partOfSpeech!);
    if (tag.tense != null) parts.add(tag.tense!);
    if (tag.voice != null) parts.add(tag.voice!);
    if (tag.mood != null) parts.add(tag.mood!);
    if (tag.person != null) parts.add('${tag.person!} person');
    if (tag.gender != null) parts.add(tag.gender!);
    if (tag.number != null) parts.add(tag.number!);
    if (tag.case_ != null) parts.add(tag.case_!);
    if (tag.state != null) parts.add(tag.state!);

    return parts.isEmpty ? tag.rawCode : parts.join(', ');
  }
}
