import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:bible_core/models/strongs_entry.dart';

/// Lookup Strong's Concordance entries
class StrongsLookup {
  static StrongsLookup? _instance;
  Map<String, StrongsEntry>? _hebrewLexicon;
  Map<String, StrongsEntry>? _greekLexicon;
  bool _isLoading = false;
  
  /// Get singleton instance
  static StrongsLookup get instance {
    _instance ??= StrongsLookup._();
    return _instance!;
  }
  
  StrongsLookup._();
  
  /// Load lexicon data from assets
  Future<void> load() async {
    if (_hebrewLexicon != null && _greekLexicon != null) {
      return; // Already loaded
    }
    
    if (_isLoading) {
      // Wait for existing load to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    _isLoading = true;
    
    try {
      // Load Hebrew lexicon
      final hebrewJson = await rootBundle.loadString(
        'packages/bible_core/assets/data/lexicon/strongs_hebrew.json',
      );
      final hebrewData = json.decode(hebrewJson) as Map<String, dynamic>;
      _hebrewLexicon = {};
      for (final entry in hebrewData.entries) {
        _hebrewLexicon![entry.key] = _parseEntry(entry.value as Map<String, dynamic>);
      }
      
      // Load Greek lexicon
      final greekJson = await rootBundle.loadString(
        'packages/bible_core/assets/data/lexicon/strongs_greek.json',
      );
      final greekData = json.decode(greekJson) as Map<String, dynamic>;
      _greekLexicon = {};
      for (final entry in greekData.entries) {
        _greekLexicon![entry.key] = _parseEntry(entry.value as Map<String, dynamic>);
      }
    } finally {
      _isLoading = false;
    }
  }
  
  StrongsEntry _parseEntry(Map<String, dynamic> data) {
    return StrongsEntry(
      number: data['number'] as String,
      language: data['language'] == 'hebrew' ? Language.hebrew : Language.greek,
      lemma: data['lemma'] as String? ?? '',
      transliteration: data['transliteration'] as String?,
      morphology: data['morphology'] as String?,
      shortDefinition: data['gloss'] as String? ?? '',
      longDefinition: data['definition'] as String?,
    );
  }
  
  /// Get a Strong's entry by number (e.g., "H1234" or "G5678")
  Future<StrongsEntry?> getEntry(String number) async {
    await load();
    
    if (number.startsWith('H')) {
      return _hebrewLexicon?[number];
    } else if (number.startsWith('G')) {
      return _greekLexicon?[number];
    }
    return null;
  }
  
  /// Search Strong's entries by gloss or lemma
  Future<List<StrongsEntry>> search(String query) async {
    await load();
    
    final results = <StrongsEntry>[];
    final lowerQuery = query.toLowerCase();
    
    // Search Hebrew
    _hebrewLexicon?.values.forEach((entry) {
      if (entry.shortDefinition.toLowerCase().contains(lowerQuery) ||
          entry.lemma.contains(query)) {
        results.add(entry);
      }
    });
    
    // Search Greek
    _greekLexicon?.values.forEach((entry) {
      if (entry.shortDefinition.toLowerCase().contains(lowerQuery) ||
          entry.lemma.contains(query)) {
        results.add(entry);
      }
    });
    
    return results;
  }
  
  /// Check if lexicons are loaded
  bool get isLoaded => _hebrewLexicon != null && _greekLexicon != null;
  
  /// Get total entry count
  int get entryCount => 
    (_hebrewLexicon?.length ?? 0) + (_greekLexicon?.length ?? 0);
}
