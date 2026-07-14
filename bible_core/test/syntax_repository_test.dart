import 'package:bible_core/models/syntax_data.dart';
import 'package:test/test.dart';

void main() {
  group('decodeSyntaxBook', () {
    test('decodes compact verse syntax data keyed by chapter and verse', () {
      final decoded = decodeSyntaxBook('Eph', {
        '2': {
          '8': {
            'words': [
              {
                'wordIndex': 0,
                'tokenId': 't0',
                'tokenText': 'this',
                'role': 'demonstrative',
                'referentWordIndex': 5,
                'referentSpanStartWordIndex': 1,
                'referentSpanEndWordIndex': 5,
              },
            ],
            'arcs': [
              {
                'fromWordIndex': 0,
                'toWordIndex': 5,
                'kind': 'referent',
                'label': 'this -> clause',
              },
            ],
            'spans': [
              {
                'fromWordIndex': 0,
                'startWordIndex': 1,
                'endWordIndex': 5,
                'kind': 'referent',
                'label': 'referent clause',
              },
            ],
          },
        },
      });

      final verse = decoded['2:8'];

      expect(verse, isNotNull);
      expect(verse!.bookId, 'Eph');
      expect(verse.chapter, 2);
      expect(verse.verse, 8);
      expect(verse.words, hasLength(1));
      expect(verse.words.first.referentWordIndex, 5);
      expect(verse.words.first.tokenText, 'this');
      expect(verse.words.first.referentSpanStartWordIndex, 1);
      expect(verse.words.first.referentSpanEndWordIndex, 5);
      expect(verse.arcs, hasLength(1));
      expect(verse.arcs.first.kind, SyntaxRelationKind.referent);
      expect(verse.spans, hasLength(1));
      expect(verse.spans.first.startWordIndex, 1);
      expect(verse.spans.first.endWordIndex, 5);
      expect(verse.annotationForWord(0)?.tokenId, 't0');
    });
  });
}