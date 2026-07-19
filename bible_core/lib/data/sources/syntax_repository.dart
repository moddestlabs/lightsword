import 'dart:convert';

import '../repository.dart';
import '../../models/syntax_data.dart';
import '../../packs/pack_manifest.dart';
import '../../packs/pack_reader.dart';

/// Repository for compact, app-specific syntax data derived from Macula.
///
/// The expected asset shape is book-scoped JSON:
/// {
///   "2": {
///     "8": {
///       "words": [...],
///       "arcs": [...]
///     }
///   }
/// }
class SyntaxRepository {
  factory SyntaxRepository(
    DataSource dataSource, {
    String assetBasePath = 'packages/bible_core/assets/data/syntax',
  }) {
    return SyntaxRepository.fromPackReader(
      DataSourcePackReader(
        dataSource: dataSource,
        packBasePaths: {PackIds.maculaSyntax: assetBasePath},
      ),
    );
  }

  SyntaxRepository.fromPackReader(
    this._packReader, {
    this.packId = PackIds.maculaSyntax,
  });

  final PackReader _packReader;
  final String packId;

  final Map<String, Map<String, SyntaxVerseData>> _cache = {};

  Future<SyntaxVerseData?> getVerse(
    String bookId,
    int chapter,
    int verse,
  ) async {
    if (!_bookToSyntaxPrefix.containsKey(bookId)) {
      return null;
    }

    if (!_cache.containsKey(bookId)) {
      await _loadBook(bookId);
    }

    return _cache[bookId]?['$chapter:$verse'];
  }

  Future<void> _loadBook(String bookId) async {
    final prefix = _bookToSyntaxPrefix[bookId];
    if (prefix == null) {
      _cache[bookId] = const {};
      return;
    }

    try {
      final jsonString = await _packReader.loadText(
        packId,
        '${prefix}_syntax.json',
      );
      final bookJson = json.decode(jsonString);
      if (bookJson is! Map<String, dynamic>) {
        _cache[bookId] = const {};
        return;
      }
      _cache[bookId] = decodeSyntaxBook(bookId, bookJson);
    } catch (_) {
      _cache[bookId] = const {};
    }
  }

  void clearCache() {
    _cache.clear();
  }
}

const Map<String, String> _bookToSyntaxPrefix = {
  'Gen': 'GEN',
  'Exod': 'EXO',
  'Lev': 'LEV',
  'Num': 'NUM',
  'Deut': 'DEU',
  'Josh': 'JOS',
  'Judg': 'JDG',
  'Ruth': 'RUT',
  '1Sam': '1SA',
  '2Sam': '2SA',
  '1Kgs': '1KI',
  '2Kgs': '2KI',
  '1Chr': '1CH',
  '2Chr': '2CH',
  'Ezra': 'EZR',
  'Neh': 'NEH',
  'Esth': 'EST',
  'Job': 'JOB',
  'Ps': 'PSA',
  'Prov': 'PRO',
  'Eccl': 'ECC',
  'Song': 'SNG',
  'Isa': 'ISA',
  'Jer': 'JER',
  'Lam': 'LAM',
  'Ezek': 'EZE',
  'Dan': 'DAN',
  'Hos': 'HOS',
  'Joel': 'JOE',
  'Amos': 'AMO',
  'Obad': 'OBA',
  'Jonah': 'JON',
  'Mic': 'MIC',
  'Nah': 'NAH',
  'Hab': 'HAB',
  'Zeph': 'ZEP',
  'Hag': 'HAG',
  'Zech': 'ZEC',
  'Mal': 'MAL',
  'Matt': 'MATT',
  'Mark': 'MARK',
  'Luke': 'LUKE',
  'John': 'JOHN',
  'Acts': 'ACTS',
  'Rom': 'ROM',
  '1Cor': '1CO',
  '2Cor': '2CO',
  'Gal': 'GAL',
  'Eph': 'EPH',
  'Phil': 'PHIL',
  'Col': 'COL',
  '1Thess': '1TH',
  '2Thess': '2TH',
  '1Tim': '1TI',
  '2Tim': '2TI',
  'Titus': 'TITUS',
  'Phlm': 'PHLM',
  'Heb': 'HEB',
  'Jas': 'JAS',
  '1Pet': '1PE',
  '2Pet': '2PE',
  '1John': '1JN',
  '2John': '2JN',
  '3John': '3JN',
  'Jude': 'JUDE',
  'Rev': 'REV',
};
