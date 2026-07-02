import 'dart:typed_data';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/passage_reference.dart';

/// Abstract data source interface for loading Bible text data
/// Platform-specific implementations in bible_app
abstract class DataSource {
  /// Load a text asset by path
  Future<String> loadAsset(String path);
  
  /// Load a binary asset by path
  Future<Uint8List> loadBytes(String path);
  
  /// Check if an asset exists
  Future<bool> assetExists(String path);
}

/// Repository for accessing Bible text data
abstract class BibleRepository {
  /// Get all available books
  Future<List<Book>> getBooks();
  
  /// Get a specific book by ID
  Future<Book?> getBook(String bookId);
  
  /// Get verses for a passage reference
  Future<List<Verse>> getVerses(PassageReference reference);
  
  /// Get a single verse
  Future<Verse?> getVerse(String bookId, int chapter, int verse);
  
  /// Search for text across all verses
  Future<List<Verse>> search(String query);
}
