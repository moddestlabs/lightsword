import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:bible_core/data/sources/tagnt_repository.dart';

/// Unified word data interface for both Hebrew and Greek interlinear display
class InterlinearWord {
  final String originalText;  // Hebrew or Greek text
  final String translit;
  final String gloss;
  final String? strongs;
  final String morphology;
  final bool isHebrew;

  InterlinearWord({
    required this.originalText,
    required this.translit,
    required this.gloss,
    this.strongs,
    required this.morphology,
    required this.isHebrew,
  });

  String get displayOriginalText {
    return originalText.replaceAll('/', '').replaceAll('\\', '');
  }

  factory InterlinearWord.fromTAHOT(TAHOTWord word) {
    return InterlinearWord(
      originalText: word.hebrew,
      translit: word.translit,
      gloss: word.gloss,
      strongs: word.strongs,
      morphology: word.morphology,
      isHebrew: true,
    );
  }

  factory InterlinearWord.fromTAGNT(TAGNTWord word) {
    return InterlinearWord(
      originalText: word.greek,
      translit: word.translit,
      gloss: word.gloss,
      strongs: word.strongs,
      morphology: word.morphology,
      isHebrew: false,
    );
  }
}
