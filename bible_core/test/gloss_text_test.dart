import 'package:bible_core/data/sources/gloss_text.dart';
import 'package:bible_core/data/sources/tagnt_repository.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes representative TAHOT and TAGNT gloss markup', () {
    final tahotWord = TAHOTWord.fromJson({
      'hebrew': 'אֶת',
      'translit': "'et",
      'gloss': '<obj.>',
      'strongs': 'H0853',
      'morphology': 'HTo',
    });

    final tagntWord = TAGNTWord.fromJson({
      'greek': 'βίβλος',
      'translit': 'biblos',
      'gloss': '[the] book',
      'strongs': 'G0976',
      'morphology': 'N-NSF',
    });

    final indirectArticle = TAHOTWord.fromJson({
      'hebrew': 'למה',
      'translit': 'lamah',
      'gloss': '<to>/ why?',
      'strongs': 'H9005',
      'morphology': 'HR/Pi',
    });

    expect(tahotWord.gloss, isEmpty);
    expect(tagntWord.gloss, 'the book');
    expect(indirectArticle.gloss, 'why?');
  });

  test('composes cleaner English gloss text', () {
    expect(
      composeGlossText([
        'in/ beginning',
        '[the] law',
        'there-',
        '-fore',
        '<obj.>',
        'justice',
        '.',
      ]),
      'in beginning the law therefore justice.',
    );

    expect(
      composeGlossText([
        'the/ righteous [person]',
        'found [me];',
      ]),
      'the righteous person found me;',
    );
  });
}