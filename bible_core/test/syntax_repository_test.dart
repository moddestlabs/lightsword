import 'dart:io';
import 'dart:typed_data';

import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/syntax_repository.dart';
import 'package:bible_core/models/syntax_data.dart';
import 'package:test/test.dart';

class FileDataSource implements DataSource {
  const FileDataSource();

  @override
  Future<String> loadAsset(String path) {
    return File(path).readAsString();
  }

  @override
  Future<Uint8List> loadBytes(String path) {
    return File(path).readAsBytes();
  }

  @override
  Future<bool> assetExists(String path) {
    return File(path).exists();
  }
}

void main() {
  group('SyntaxRepository', () {
    test('loads syntax data through a DataSource', () async {
      final repository = SyntaxRepository(
        const FileDataSource(),
        assetBasePath: 'assets/data/syntax',
      );

      final verse = await repository.getVerse('Eph', 2, 8);

      expect(verse, isNotNull);
      expect(verse!.bookId, 'Eph');
      expect(verse.chapter, 2);
      expect(verse.verse, 8);
      expect(verse.words, isNotEmpty);
    });
  });

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
