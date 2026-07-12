import 'package:bible_core/data/sources/gloss_text.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes representative TAHOT and TAGNT gloss markup', () {
    expect(normalizeGlossToken('<obj.>'), isEmpty);
    expect(normalizeGlossToken('[the] book'), 'the book');
    expect(normalizeGlossToken('<to>/ why?'), 'why?');
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