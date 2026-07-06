import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Word data from TAGNT (Translators Amalgamated Greek NT)
class TAGNTWord {
  final String greek;         // Greek text with accents (Βίβλος)
  final String translit;      // Transliteration (Biblos)
  final String gloss;         // English gloss ([The] book)
  final String? strongs;      // Strong's number (G0976)
  final String morphology;    // Morphology code (N-NSF)

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
      gloss: json['gloss'] as String,
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
  static final TAGNTRepository instance = TAGNTRepository._();
  TAGNTRepository._();

  final Map<String, Map<String, Map<String, List<TAGNTWord>>>> _cache = {};

  /// Get TAGNT word data for a specific verse
  /// 
  /// Returns null if the book doesn't have TAGNT data (e.g., for OT books)
  Future<List<TAGNTWord>?> getVerse(
    String bookId,
    int chapter,
    int verse,
  ) async {
    print('🔍 TAGNT: getVerse called for $bookId $chapter:$verse');
    
    // Check if this is an NT book (TAGNT only has NT)
    if (!_hasTAGNTData(bookId)) {
      print('❌ TAGNT: $bookId is not an NT book');
      return null;
    }

    print('✅ TAGNT: $bookId is an NT book');

    // Load book if not cached
    if (!_cache.containsKey(bookId)) {
      print('📖 TAGNT: Book not in cache, loading...');
      await _loadBook(bookId);
    } else {
      print('✅ TAGNT: Book already in cache');
    }

    // Return verse data
    final bookData = _cache[bookId];
    if (bookData == null || bookData.isEmpty) {
      print('❌ TAGNT: Book data is null or empty');
      return null;
    }

    print('✅ TAGNT: Found book data with ${bookData.length} chapters');

    final chapterData = bookData[chapter.toString()];
    if (chapterData == null) {
      print('❌ TAGNT: Chapter $chapter not found');
      return null;
    }

    print('✅ TAGNT: Found chapter data with ${chapterData.length} verses');

    final verseWords = chapterData[verse.toString()];
    if (verseWords == null) {
      print('❌ TAGNT: Verse $verse not found');
      return null;
    }

    print('✅ TAGNT: Found ${verseWords.length} words for verse');
    return verseWords;
  }

  /// Check if a book has TAGNT data (NT only)
  bool _hasTAGNTData(String bookId) {
    // Map book IDs to their TAGNT file prefixes
    const bookToTagnt = {
      'Matt': 'MATT', 'Mark': 'MARK', 'Luke': 'LUKE', 'John': 'JOHN',
      'Acts': 'ACTS', 'Rom': 'ROM', '1Cor': '1CO', '2Cor': '2CO',
      'Gal': 'GAL', 'Eph': 'EPH', 'Phil': 'PHIL', 'Col': 'COL',
      '1Thess': '1TH', '2Thess': '2TH', '1Tim': '1TI', '2Tim': '2TI',
      'Titus': 'TITUS', 'Phlm': 'PHLM', 'Heb': 'HEB', 'Jas': 'JAS',
      '1Pet': '1PE', '2Pet': '2PE', '1John': '1JN', '2John': '2JN',
      '3John': '3JN', 'Jude': 'JUDE', 'Rev': 'REV'
    };
    return bookToTagnt.containsKey(bookId);
  }

  /// Load a book's TAGNT data from assets
  Future<void> _loadBook(String bookId) async {
    print('📖 TAGNT: Loading book $bookId...');
    try {
      // Map book ID to TAGNT filename prefix
      const bookToTagnt = {
        'Matt': 'MATT', 'Mark': 'MARK', 'Luke': 'LUKE', 'John': 'JOHN',
        'Acts': 'ACTS', 'Rom': 'ROM', '1Cor': '1CO', '2Cor': '2CO',
        'Gal': 'GAL', 'Eph': 'EPH', 'Phil': 'PHIL', 'Col': 'COL',
        '1Thess': '1TH', '2Thess': '2TH', '1Tim': '1TI', '2Tim': '2TI',
        'Titus': 'TITUS', 'Phlm': 'PHLM', 'Heb': 'HEB', 'Jas': 'JAS',
        '1Pet': '1PE', '2Pet': '2PE', '1John': '1JN', '2John': '2JN',
        '3John': '3JN', 'Jude': 'JUDE', 'Rev': 'REV'
      };
      
      final tagntBookId = bookToTagnt[bookId];
      if (tagntBookId == null) {
        print('❌ TAGNT: Unknown book ID: $bookId');
        _cache[bookId] = {};
        return;
      }
      
      final assetPath = 'packages/bible_core/assets/data/greek/${tagntBookId}_tagnt.json';
      print('📖 TAGNT: Asset path: $assetPath');
      final jsonString = await rootBundle.loadString(assetPath);
      print('📖 TAGNT: Loaded ${jsonString.length} bytes');
      final Map<String, dynamic> bookJson = json.decode(jsonString);
      print('📖 TAGNT: Decoded ${bookJson.length} chapters');

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
              .map((wordJson) => TAGNTWord.fromJson(wordJson as Map<String, dynamic>))
              .toList();
        }
      }

      _cache[bookId] = bookData;
      print('✅ TAGNT: Successfully loaded $bookId');
    } catch (e) {
      print('❌ TAGNT: Error loading $bookId: $e');
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
