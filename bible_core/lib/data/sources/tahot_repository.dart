import 'dart:convert';

import '../repository.dart';

import 'gloss_text.dart';

/// Word data from TAHOT (Translators Amalgamated Hebrew OT)
class TAHOTWord {
  final String hebrew; // Vocalized Hebrew text (בְּ/רֵאשִׁ֖ית)
  final String translit; // Transliteration (be./re.Shit)
  final String gloss; // English gloss (in/ beginning)
  final String? strongs; // Strong's number (H7225G)
  final String morphology; // Morphology code (HR/Ncfsa)

  TAHOTWord({
    required this.hebrew,
    required this.translit,
    required this.gloss,
    this.strongs,
    required this.morphology,
  });

  factory TAHOTWord.fromJson(Map<String, dynamic> json) {
    return TAHOTWord(
      hebrew: json['hebrew'] as String,
      translit: json['translit'] as String,
      gloss: normalizeGlossToken(json['gloss'] as String),
      strongs: json['strongs'] as String?,
      morphology: json['morphology'] as String,
    );
  }
}

/// Repository for accessing TAHOT Hebrew Bible data
///
/// Provides enhanced Hebrew text with vocalization, transliteration,
/// glosses, and morphological analysis for all Old Testament books.
class TAHOTRepository {
  TAHOTRepository(
    this._dataSource, {
    this.assetBasePath = 'packages/bible_core/assets/data/tahot',
  });

  final DataSource _dataSource;
  final String assetBasePath;

  final Map<String, Map<String, Map<String, List<TAHOTWord>>>> _cache = {};

  /// Get TAHOT word data for a specific verse
  ///
  /// Returns null if the book doesn't have TAHOT data (e.g., for NT books)
  Future<List<TAHOTWord>?> getVerse(
    String bookId,
    int chapter,
    int verse,
  ) async {
    // Check if this is an OT book (TAHOT only has OT)
    if (!_hasTAHOTData(bookId)) {
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

  Future<Map<String, List<TAHOTWord>>?> getChapter(
    String bookId,
    int chapter,
  ) async {
    if (!_hasTAHOTData(bookId)) {
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

  /// Check if a book has TAHOT data (OT only)
  bool _hasTAHOTData(String bookId) {
    // Map book IDs to their TAHOT file prefixes
    const bookToTahot = {
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
    };
    return bookToTahot.containsKey(bookId);
  }

  /// Load a book's TAHOT data from assets
  Future<void> _loadBook(String bookId) async {
    try {
      // Map book ID to TAHOT filename prefix
      const bookToTahot = {
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
      };

      final tahotBookId = bookToTahot[bookId];
      if (tahotBookId == null) {
        _cache[bookId] = {};
        return;
      }

      final assetPath = '$assetBasePath/${tahotBookId}_tahot.json';
      final jsonString = await _dataSource.loadAsset(assetPath);
      final Map<String, dynamic> bookJson = json.decode(jsonString);

      // Convert JSON structure to typed data
      final Map<String, Map<String, List<TAHOTWord>>> bookData = {};

      for (final chapterEntry in bookJson.entries) {
        final chapterNum = chapterEntry.key;
        final chapterData = chapterEntry.value as Map<String, dynamic>;

        bookData[chapterNum] = {};

        for (final verseEntry in chapterData.entries) {
          final verseNum = verseEntry.key;
          final wordsJson = verseEntry.value as List<dynamic>;

            bookData[chapterNum]![verseNum] = wordsJson
              .map(
              (wordJson) =>
                TAHOTWord.fromJson(wordJson as Map<String, dynamic>),
              )
              .toList();
        }
      }

      _cache[bookId] = bookData;
    } catch (e) {
      // Cache an empty map so we don't keep retrying
      _cache[bookId] = {};
    }
  }

  /// Clear the cache (useful for testing)
  void clearCache() {
    _cache.clear();
  }
}
