import 'package:meta/meta.dart';

/// Strong's Concordance entry
@immutable
class StrongsEntry {
  final String number;
  final Language language;
  final String lemma;
  final String? transliteration;
  final String? morphology;
  final String shortDefinition;
  final String? longDefinition;

  const StrongsEntry({
    required this.number,
    required this.language,
    required this.lemma,
    this.transliteration,
    this.morphology,
    required this.shortDefinition,
    this.longDefinition,
  });

  @override
  String toString() => '$number ($lemma): $shortDefinition';
}

enum Language {
  hebrew,
  greek,
}
