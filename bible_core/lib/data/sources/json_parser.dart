import 'dart:convert';
import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';

/// Parses Bible data from JSON format
class JsonBibleParser {
  /// Parse complete Bible JSON
  static BibleData parse(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    final String translation = data['translation'] as String;
    final List<dynamic> booksJson = data['books'] as List<dynamic>;
    
    final books = <Book>[];
    final verses = <Verse>[];
    
    for (int i = 0; i < booksJson.length; i++) {
      final bookJson = booksJson[i] as Map<String, dynamic>;
      final bookId = bookJson['id'] as String;
      final bookName = bookJson['name'] as String;
      final testament = bookJson['testament'] as String;
      final List<dynamic> chaptersJson = bookJson['chapters'] as List<dynamic>;
      
      final book = Book(
        id: bookId,
        name: bookName,
        abbreviation: bookId.substring(0, 3).toUpperCase(),
        testament: testament == 'OT' ? Testament.old : Testament.new_,
        chapterCount: chaptersJson.length,
        order: i + 1,
      );
      books.add(book);
      
      // Parse verses
      for (final chapterJson in chaptersJson) {
        final chapterNum = chapterJson['number'] as int;
        final List<dynamic> versesJson = chapterJson['verses'] as List<dynamic>;
        
        for (final verseJson in versesJson) {
          final verseNum = verseJson['number'] as int;
          final verseText = verseJson['text'] as String;
          
          verses.add(Verse(
            bookId: bookId,
            chapter: chapterNum,
            number: verseNum,
            text: verseText,
          ),);
        }
      }
    }
    
    return BibleData(
      translation: translation,
      books: books,
      verses: verses,
    );
  }
}

/// Parsed Bible data
class BibleData {
  final String translation;
  final List<Book> books;
  final List<Verse> verses;
  
  const BibleData({
    required this.translation,
    required this.books,
    required this.verses,
  });
}
