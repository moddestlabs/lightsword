import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/json_parser.dart';

/// In-memory implementation of BibleRepository using JSON data
class JsonBibleRepository implements BibleRepository {
  final DataSource _dataSource;
  BibleData? _cachedData;
  
  JsonBibleRepository(this._dataSource);
  
  /// Load and cache the Bible data
  Future<BibleData> _loadData() async {
    if (_cachedData != null) return _cachedData!;
    
    final jsonString = await _dataSource.loadAsset('data/web_sample.json');
    _cachedData = JsonBibleParser.parse(jsonString);
    return _cachedData!;
  }
  
  @override
  Future<List<Book>> getBooks() async {
    final data = await _loadData();
    return data.books;
  }
  
  @override
  Future<Book?> getBook(String bookId) async {
    final data = await _loadData();
    try {
      return data.books.firstWhere((b) => b.id == bookId);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<Verse>> getVerses(PassageReference reference) async {
    final data = await _loadData();
    
    return data.verses.where((v) {
      if (v.bookId != reference.bookId) return false;
      if (v.chapter != reference.chapter) return false;
      
      if (reference.startVerse == null) return true;
      
      return v.number >= reference.startVerse! &&
             v.number <= (reference.endVerse ?? reference.startVerse!);
    }).toList();
  }
  
  @override
  Future<Verse?> getVerse(String bookId, int chapter, int verse) async {
    final data = await _loadData();
    
    try {
      return data.verses.firstWhere(
        (v) => v.bookId == bookId && v.chapter == chapter && v.number == verse,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<Verse>> search(String query) async {
    final data = await _loadData();
    final lowerQuery = query.toLowerCase();
    
    return data.verses
        .where((v) => v.text.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
