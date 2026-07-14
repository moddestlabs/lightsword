import 'package:bible_core/models/morphology.dart';
import 'package:test/test.dart';

void main() {
  group('MorphologyParser.parse', () {
    test('parses Greek noun gender and case', () {
      final tag = MorphologyParser.parse('N-NSF');

      expect(tag, isNotNull);
      expect(tag!.partOfSpeech, 'Noun');
      expect(tag.case_, 'Nominative');
      expect(tag.number, 'Singular');
      expect(tag.gender, 'Feminine');
    });

    test('parses Greek participle agreement fields', () {
      final tag = MorphologyParser.parse('V-PAP-NSM');

      expect(tag, isNotNull);
      expect(tag!.partOfSpeech, 'Verb');
      expect(tag.tense, 'Present');
      expect(tag.voice, 'Active');
      expect(tag.mood, 'Participle');
      expect(tag.case_, 'Nominative');
      expect(tag.number, 'Singular');
      expect(tag.gender, 'Masculine');
    });

    test('parses Hebrew noun gender and state', () {
      final tag = MorphologyParser.parse('HR/Ncfsa');

      expect(tag, isNotNull);
      expect(tag!.partOfSpeech, 'Noun');
      expect(tag.gender, 'Feminine');
      expect(tag.number, 'Singular');
      expect(tag.state, 'Absolute');
    });

    test('parses Hebrew verb person gender and number', () {
      final tag = MorphologyParser.parse('HV/Vqp3ms');

      expect(tag, isNotNull);
      expect(tag!.partOfSpeech, 'Verb');
      expect(tag.voice, 'Qal');
      expect(tag.tense, 'Perfect');
      expect(tag.person, '3');
      expect(tag.gender, 'Masculine');
      expect(tag.number, 'Singular');
    });

    test('recognizes Greek prepositions before single-letter pronoun fallback', () {
      final tag = MorphologyParser.parse('PREP');

      expect(tag, isNotNull);
      expect(tag!.partOfSpeech, 'Preposition');
    });

    test('builds compact human label for Greek morphology', () {
      final tag = MorphologyParser.parse('V-PAP-NSM');

      expect(tag, isNotNull);
      expect(
        MorphologyParser.describeCompact(tag!),
        'Verb Pres Active Ptcp Masc Sg Nom',
      );
    });

    test('builds compact human label for Hebrew morphology', () {
      final tag = MorphologyParser.parse('HR/Ncfsa');

      expect(tag, isNotNull);
      expect(
        MorphologyParser.describeCompact(tag!),
        'Noun Fem Sg Abs',
      );
    });
  });
}