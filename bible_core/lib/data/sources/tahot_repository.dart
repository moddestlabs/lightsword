import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Word data from TAHOT (Translators Amalgamated Hebrew OT)
class TAHOTWord {
  final String hebrew;        // Vocalized Hebrew text (בְּ/רֵאשִׁ֖ית)
  final String translit;      // Transliteration (be./re.Shit)
  final String gloss;         // English gloss (in/ beginning)
  final String? strongs;      // Strong's number (H7225G)
  final String morphology;    // Morphology code (HR/Ncfsa)

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
      gloss: json['gloss'] as String,
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
  static final TAHOTRepository instance = TAHOTRepository._();
  TAHOTRepository._();

  final Map<String, Map<String, Map<String, List<TAHOTWord>>>> _cache = {};

  /// Get TAHOT word data for a specific verse
  /// 
  /// Returns null if the book doesn't have TAHOT data (e.g., for NT books)
  Future<List<TAHOTWord>?> getVerse(
    String bookId,
    int chapter,
    int verse,
  ) async {
    print('🔍 TAHOT: getVerse called for $bookId $chapter:$verse');
    
    // Check if this is an OT book (TAHOT only has OT)
    if (!_hasTAHOTData(bookId)) {
      print('❌ TAHOT: $bookId is not an OT book');
      return null;
    }

    print('✅ TAHOT: $bookId is an OT book');

    // Load book if not cached
    if (!_cache.containsKey(bookId)) {
      print('📖 TAHOT: Book not in cache, loading...');
      await _loadBook(bookId);
    } else {
      print('✅ TAHOT: Book already in cache');
    }

    // Return verse data
    final bookData = _cache[bookId];
    if (bookData == null || bookData.isEmpty) {
      print('❌ TAHOT: Book data is null or empty');
      return null;
    }

    print('✅ TAHOT: Found book data with ${bookData.length} chapters');

    final chapterData = bookData[chapter.toString()];
    if (chapterData == null) {
      print('❌ TAHOT: Chapter $chapter not found');
      return null;
    }

    print('✅ TAHOT: Found chapter data with ${chapterData.length} verses');

    final verseWords = chapterData[verse.toString()];
    if (verseWords == null) {
      print('❌ TAHOT: Verse $verse not found');
      return null;
    }

    print('✅ TAHOT: Found ${verseWords.length} words for verse');
    return verseWords;
  }

  /// Check if a book has TAHOT data (OT only)
  bool _hasTAHOTData(String bookId) {
    // TAHOT only covers the 39 OT books
    const otBooks = [
      'GEN', 'EXO', 'LEV', 'NUM', 'DEU',
      'JOS', 'JDG', 'RUT', '1SA', '2SA',
      '1KI', '2KI', '1CH', '2CH', 'EZR',
      'NEH', 'EST', 'JOB', 'PSA', 'PRO',
      'ECC', 'SNG', 'ISA', 'JER', 'LAM',
      'EZE', 'DAN', 'HOS', 'JOE', 'AMO',
      'OBA', 'JON', 'MIC', 'NAH', 'HAB',
      'ZEP', 'HAG', 'ZEC', 'MAL'
    ];
    return otBooks.contains(bookId.toUpperCase());
  }

  /// Load a book's TAHOT data from assets
  Future<void> _loadBook(String bookId) async {
    print('📖 TAHOT: Loading book $bookId...');
    try {
      // Convert to uppercase to match asset filenames (GEN_tahot.json, etc.)
      final upperBookId = bookId.toUpperCase();
      final assetPath = 'packages/bible_core/assets/data/tahot/${upperBookId}_tahot.json';
      print('📖 TAHOT: Asset path: $assetPath');
      final jsonString = await rootBundle.loadString(assetPath);
      print('📖 TAHOT: Loaded ${jsonString.length} bytes');
      final Map<String, dynamic> bookJson = json.decode(jsonString);
      print('📖 TAHOT: Decoded ${bookJson.length} chapters');

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
              .map((wordJson) => TAHOTWord.fromJson(wordJson as Map<String, dynamic>))
              .toList();
        }
      }

      _cache[bookId] = bookData;
    } catch (e) {
      print('Error loading TAHOT data for $bookId: $e');
      // Cache an empty map so we don't keep retrying
      _cache[bookId] = {};
    }
  }

  /// Clear the cache (useful for testing)
  void clearCache() {
    _cache.clear();
  }
}
