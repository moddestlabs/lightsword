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
    // Only OT books have Hebrew text
    final otBooks = [
      'GEN', 'EXO', 'LEV', 'NUM', 'DEU', 'JOS', 'JDG', 'RUT',
      '1SA', '2SA', '1KI', '2KI', '1CH', '2CH', 'EZR', 'NEH', 'EST',
      'JOB', 'PSA', 'PRO', 'ECC', 'SNG', 'ISA', 'JER', 'LAM', 'EZK', 'DAN',
      'HOS', 'JOL', 'AMO', 'OBA', 'JON', 'MIC', 'NAM', 'HAB', 'ZEP', 'HAG', 'ZEC', 'MAL'
    ];
    
    if (!otBooks.contains(bookId)) {
      return null; // NT book, no Hebrew text
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
      final jsonString = await rootBundle.loadString(
        'packages/bible_core/assets/data/hebrew/${bookId}_hebrew.json',
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
    final otBooks = [
      'GEN', 'EXO', 'LEV', 'NUM', 'DEU', 'JOS', 'JDG', 'RUT',
      '1SA', '2SA', '1KI', '2KI', '1CH', '2CH', 'EZR', 'NEH', 'EST',
      'JOB', 'PSA', 'PRO', 'ECC', 'SNG', 'ISA', 'JER', 'LAM', 'EZK', 'DAN',
      'HOS', 'JOL', 'AMO', 'OBA', 'JON', 'MIC', 'NAM', 'HAB', 'ZEP', 'HAG', 'ZEC', 'MAL'
    ];
    return otBooks.contains(bookId);
  }
}
