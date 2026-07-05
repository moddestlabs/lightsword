import 'dart:convert';
import 'package:flutter/services.dart';

/// Repository for accessing Hebrew Old Testament text (OSHB)
class HebrewTextRepository {
  static HebrewTextRepository? _instance;
  final Map<String, Map<int, Map<int, String>>> _cache = {};
  
  /// Get singleton instance
  static HebrewTextRepository get instance {
    _instance ??= HebrewTextRepository._();
    return _instance!;
  }
  
  HebrewTextRepository._();
  
  /// Get Hebrew text for a specific verse
  /// Returns null if not found or if book is NT (no Hebrew)
  Future<String?> getVerse(String bookId, int chapter, int verse) async {
    // Check if this book has Hebrew text
    if (!hasHebrewText(bookId)) {
      return null; // NT book or unknown, no Hebrew text
    }
    
    // Load book if not cached
    if (!_cache.containsKey(bookId)) {
      await _loadBook(bookId);
    }
    
    return _cache[bookId]?[chapter]?[verse];
  }
  
  /// Get Hebrew text for an entire chapter
  Future<Map<int, String>> getChapter(String bookId, int chapter) async {
    if (!_cache.containsKey(bookId)) {
      await _loadBook(bookId);
    }
    
    return _cache[bookId]?[chapter] ?? {};
  }
  
  Future<void> _loadBook(String bookId) async {
    try {
      // Map book ID to Hebrew filename prefix
      const bookToHebrew = {
        'Gen': 'GEN', 'Exod': 'EXO', 'Lev': 'LEV', 'Num': 'NUM', 'Deut': 'DEU',
        'Josh': 'JOS', 'Judg': 'JDG', 'Ruth': 'RUT', '1Sam': '1SA', '2Sam': '2SA',
        '1Kgs': '1KI', '2Kgs': '2KI', '1Chr': '1CH', '2Chr': '2CH', 'Ezra': 'EZR',
        'Neh': 'NEH', 'Esth': 'EST', 'Job': 'JOB', 'Ps': 'PSA', 'Prov': 'PRO',
        'Eccl': 'ECC', 'Song': 'SNG', 'Isa': 'ISA', 'Jer': 'JER', 'Lam': 'LAM',
        'Ezek': 'EZK', 'Dan': 'DAN', 'Hos': 'HOS', 'Joel': 'JOL', 'Amos': 'AMO',
        'Obad': 'OBA', 'Jonah': 'JON', 'Mic': 'MIC', 'Nah': 'NAM', 'Hab': 'HAB',
        'Zeph': 'ZEP', 'Hag': 'HAG', 'Zech': 'ZEC', 'Mal': 'MAL'
      };
      
      final hebrewBookId = bookToHebrew[bookId];
      if (hebrewBookId == null) {
        print('Error: Unknown book ID for Hebrew text: $bookId');
        _cache[bookId] = {};
        return;
      }
      
      final jsonString = await rootBundle.loadString(
        'packages/bible_core/assets/data/hebrew/${hebrewBookId}_hebrew.json',
      );
      
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      // Convert from JSON structure to nested maps
      final bookData = <int, Map<int, String>>{};
      for (final chapterEntry in data.entries) {
        final chapterNum = int.parse(chapterEntry.key);
        final verses = chapterEntry.value as Map<String, dynamic>;
        
        final verseMap = <int, String>{};
        for (final verseEntry in verses.entries) {
          final verseNum = int.parse(verseEntry.key);
          verseMap[verseNum] = verseEntry.value as String;
        }
        
        bookData[chapterNum] = verseMap;
      }
      
      _cache[bookId] = bookData;
    } catch (e) {
      print('Error loading Hebrew text for $bookId: $e');
      _cache[bookId] = {}; // Cache empty to avoid repeated attempts
    }
  }
  
  /// Check if Hebrew text is available for a book
  bool hasHebrewText(String bookId) {
    // Map book IDs to their Hebrew file prefixes
    const bookToHebrew = {
      'Gen': 'GEN', 'Exod': 'EXO', 'Lev': 'LEV', 'Num': 'NUM', 'Deut': 'DEU',
      'Josh': 'JOS', 'Judg': 'JDG', 'Ruth': 'RUT', '1Sam': '1SA', '2Sam': '2SA',
      '1Kgs': '1KI', '2Kgs': '2KI', '1Chr': '1CH', '2Chr': '2CH', 'Ezra': 'EZR',
      'Neh': 'NEH', 'Esth': 'EST', 'Job': 'JOB', 'Ps': 'PSA', 'Prov': 'PRO',
      'Eccl': 'ECC', 'Song': 'SNG', 'Isa': 'ISA', 'Jer': 'JER', 'Lam': 'LAM',
      'Ezek': 'EZK', 'Dan': 'DAN', 'Hos': 'HOS', 'Joel': 'JOL', 'Amos': 'AMO',
      'Obad': 'OBA', 'Jonah': 'JON', 'Mic': 'MIC', 'Nah': 'NAM', 'Hab': 'HAB',
      'Zeph': 'ZEP', 'Hag': 'HAG', 'Zech': 'ZEC', 'Mal': 'MAL'
    };
    return bookToHebrew.containsKey(bookId);
  }
}
