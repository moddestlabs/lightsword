import 'dart:convert';

import '../repository.dart';
import '../../packs/pack_manifest.dart';
import '../../packs/pack_reader.dart';

import 'gloss_text.dart';

/// Word data from TAGNT (Translators Amalgamated Greek NT)
class TAGNTWord {
  final String greek; // Greek text with accents (Βίβλος)
  final String translit; // Transliteration (Biblos)
  final String gloss; // English gloss ([The] book)
  final String? strongs; // Strong's number (G0976)
  final String morphology; // Morphology code (N-NSF)

  TAGNTWord({
    required this.greek,
    required this.translit,
    required this.gloss,
    this.strongs,
    required this.morphology,
  });

  factory TAGNTWord.fromJson(Map<String, dynamic> json) {
    return TAGNTWord(
      greek: json['greek'] as String,
      translit: json['translit'] as String,
      gloss: normalizeGlossToken(json['gloss'] as String),
      strongs: json['strongs'] as String?,
      morphology: json['morphology'] as String,
    );
  }
}

/// Repository for accessing TAGNT Greek New Testament data
///
/// Provides enhanced Greek text with transliteration, glosses,
/// and morphological analysis for all New Testament books.
class TAGNTRepository {
  factory TAGNTRepository(
    DataSource dataSource, {
    String assetBasePath = 'packages/bible_core/assets/data/greek',
  }) {
    return TAGNTRepository.fromPackReader(
      DataSourcePackReader(
        dataSource: dataSource,
        packBasePaths: {PackIds.originalLanguageNt: assetBasePath},
      ),
    );
  }

  TAGNTRepository.fromPackReader(
    this._packReader, {
    this.packId = PackIds.originalLanguageNt,
  });

  final PackReader _packReader;
  final String packId;

  final Map<String, Map<String, Map<String, List<TAGNTWord>>>> _cache = {};

  /// Get TAGNT word data for a specific verse
  ///
  /// Returns null if the book doesn't have TAGNT data (e.g., for OT books)
  Future<List<TAGNTWord>?> getVerse(
    String bookId,
    int chapter,
    int verse,
  ) async {
    // Check if this is an NT book (TAGNT only has NT)
    if (!_hasTAGNTData(bookId)) {
      return null;
    }

    // Load book if not cached
    if (!_cache.containsKey(bookId)) {
      await _loadBook(bookId);
    }

    // Return verse data
    final bookData = _cache[bookId];
    if (bookData == null || bookData.isEmpty) {
      return null;
    }

    final chapterData = bookData[chapter.toString()];
    if (chapterData == null) {
      return null;
    }

    final verseWords = chapterData[verse.toString()];
    if (verseWords == null) {
      return null;
    }

    return verseWords;
  }

  Future<Map<String, List<TAGNTWord>>?> getChapter(
    String bookId,
    int chapter,
  ) async {
    if (!_hasTAGNTData(bookId)) {
      return null;
    }

    if (!_cache.containsKey(bookId)) {
      await _loadBook(bookId);
    }

    final bookData = _cache[bookId];
    if (bookData == null || bookData.isEmpty) {
      return null;
    }

    return bookData[chapter.toString()];
  }

  /// Check if a book has TAGNT data (NT only)
  bool _hasTAGNTData(String bookId) {
    return _bookToTagnt.containsKey(bookId);
  }

  /// Load a book's TAGNT data from assets
  Future<void> _loadBook(String bookId) async {
    try {
      final tagntBookId = _bookToTagnt[bookId];
      if (tagntBookId == null) {
        _cache[bookId] = {};
        return;
      }

      final jsonString = await _packReader.loadText(
        packId,
        '${tagntBookId}_tagnt.json',
      );
      final Map<String, dynamic> bookJson = json.decode(jsonString);

      // Convert JSON structure to typed data
      final Map<String, Map<String, List<TAGNTWord>>> bookData = {};

      for (final chapterEntry in bookJson.entries) {
        final chapterNum = chapterEntry.key;
        final chapterData = chapterEntry.value as Map<String, dynamic>;

        bookData[chapterNum] = {};

        for (final verseEntry in chapterData.entries) {
          final verseNum = verseEntry.key;
          final verseData = verseEntry.value as List<dynamic>;

          bookData[chapterNum]![verseNum] = verseData
              .map(
                (wordJson) =>
                    TAGNTWord.fromJson(wordJson as Map<String, dynamic>),
              )
              .toList();
        }
      }

      _cache[bookId] = bookData;
    } catch (e) {
      _cache[bookId] = {};
    }
  }

  /// Clear the cache (useful for testing or memory management)
  void clearCache() {
    _cache.clear();
  }

  /// Check if a book is loaded in cache
  bool isBookCached(String bookId) {
    return _cache.containsKey(bookId);
  }
}

const Map<String, String> _bookToTagnt = {
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
