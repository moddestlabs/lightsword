import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/usfm_parser.dart';

/// Optimized BibleRepository that loads USFM files on-demand
class UsfmLazyRepository implements BibleRepository {
  final DataSource _dataSource;
  final String _modulePath;
  
  // Cache loaded books/chapters
  final Map<String, List<Verse>> _chapterCache = {};
  List<Book>? _bookMetadata;

  UsfmLazyRepository(this._dataSource, this._modulePath);

  /// Book metadata with chapter counts (static, no file loading needed)
  static final List<Book> _allBooks = [
    Book(id: 'Gen', name: 'Genesis', abbreviation: 'Gen', testament: Testament.old, chapterCount: 50, order: 1),
    Book(id: 'Exod', name: 'Exodus', abbreviation: 'Exod', testament: Testament.old, chapterCount: 40, order: 2),
    Book(id: 'Lev', name: 'Leviticus', abbreviation: 'Lev', testament: Testament.old, chapterCount: 27, order: 3),
    Book(id: 'Num', name: 'Numbers', abbreviation: 'Num', testament: Testament.old, chapterCount: 36, order: 4),
    Book(id: 'Deut', name: 'Deuteronomy', abbreviation: 'Deut', testament: Testament.old, chapterCount: 34, order: 5),
    Book(id: 'Josh', name: 'Joshua', abbreviation: 'Josh', testament: Testament.old, chapterCount: 24, order: 6),
    Book(id: 'Judg', name: 'Judges', abbreviation: 'Judg', testament: Testament.old, chapterCount: 21, order: 7),
    Book(id: 'Ruth', name: 'Ruth', abbreviation: 'Ruth', testament: Testament.old, chapterCount: 4, order: 8),
    Book(id: '1Sam', name: '1 Samuel', abbreviation: '1Sam', testament: Testament.old, chapterCount: 31, order: 9),
    Book(id: '2Sam', name: '2 Samuel', abbreviation: '2Sam', testament: Testament.old, chapterCount: 24, order: 10),
    Book(id: '1Kgs', name: '1 Kings', abbreviation: '1Kgs', testament: Testament.old, chapterCount: 22, order: 11),
    Book(id: '2Kgs', name: '2 Kings', abbreviation: '2Kgs', testament: Testament.old, chapterCount: 25, order: 12),
    Book(id: '1Chr', name: '1 Chronicles', abbreviation: '1Chr', testament: Testament.old, chapterCount: 29, order: 13),
    Book(id: '2Chr', name: '2 Chronicles', abbreviation: '2Chr', testament: Testament.old, chapterCount: 36, order: 14),
    Book(id: 'Ezra', name: 'Ezra', abbreviation: 'Ezra', testament: Testament.old, chapterCount: 10, order: 15),
    Book(id: 'Neh', name: 'Nehemiah', abbreviation: 'Neh', testament: Testament.old, chapterCount: 13, order: 16),
    Book(id: 'Esth', name: 'Esther', abbreviation: 'Esth', testament: Testament.old, chapterCount: 10, order: 17),
    Book(id: 'Job', name: 'Job', abbreviation: 'Job', testament: Testament.old, chapterCount: 42, order: 18),
    Book(id: 'Ps', name: 'Psalms', abbreviation: 'Ps', testament: Testament.old, chapterCount: 150, order: 19),
    Book(id: 'Prov', name: 'Proverbs', abbreviation: 'Prov', testament: Testament.old, chapterCount: 31, order: 20),
    Book(id: 'Eccl', name: 'Ecclesiastes', abbreviation: 'Eccl', testament: Testament.old, chapterCount: 12, order: 21),
    Book(id: 'Song', name: 'Song of Solomon', abbreviation: 'Song', testament: Testament.old, chapterCount: 8, order: 22),
    Book(id: 'Isa', name: 'Isaiah', abbreviation: 'Isa', testament: Testament.old, chapterCount: 66, order: 23),
    Book(id: 'Jer', name: 'Jeremiah', abbreviation: 'Jer', testament: Testament.old, chapterCount: 52, order: 24),
    Book(id: 'Lam', name: 'Lamentations', abbreviation: 'Lam', testament: Testament.old, chapterCount: 5, order: 25),
    Book(id: 'Ezek', name: 'Ezekiel', abbreviation: 'Ezek', testament: Testament.old, chapterCount: 48, order: 26),
    Book(id: 'Dan', name: 'Daniel', abbreviation: 'Dan', testament: Testament.old, chapterCount: 12, order: 27),
    Book(id: 'Hos', name: 'Hosea', abbreviation: 'Hos', testament: Testament.old, chapterCount: 14, order: 28),
    Book(id: 'Joel', name: 'Joel', abbreviation: 'Joel', testament: Testament.old, chapterCount: 3, order: 29),
    Book(id: 'Amos', name: 'Amos', abbreviation: 'Amos', testament: Testament.old, chapterCount: 9, order: 30),
    Book(id: 'Obad', name: 'Obadiah', abbreviation: 'Obad', testament: Testament.old, chapterCount: 1, order: 31),
    Book(id: 'Jonah', name: 'Jonah', abbreviation: 'Jonah', testament: Testament.old, chapterCount: 4, order: 32),
    Book(id: 'Mic', name: 'Micah', abbreviation: 'Mic', testament: Testament.old, chapterCount: 7, order: 33),
    Book(id: 'Nah', name: 'Nahum', abbreviation: 'Nah', testament: Testament.old, chapterCount: 3, order: 34),
    Book(id: 'Hab', name: 'Habakkuk', abbreviation: 'Hab', testament: Testament.old, chapterCount: 3, order: 35),
    Book(id: 'Zeph', name: 'Zephaniah', abbreviation: 'Zeph', testament: Testament.old, chapterCount: 3, order: 36),
    Book(id: 'Hag', name: 'Haggai', abbreviation: 'Hag', testament: Testament.old, chapterCount: 2, order: 37),
    Book(id: 'Zech', name: 'Zechariah', abbreviation: 'Zech', testament: Testament.old, chapterCount: 14, order: 38),
    Book(id: 'Mal', name: 'Malachi', abbreviation: 'Mal', testament: Testament.old, chapterCount: 4, order: 39),
    // New Testament
    Book(id: 'Matt', name: 'Matthew', abbreviation: 'Matt', testament: Testament.new_, chapterCount: 28, order: 40),
    Book(id: 'Mark', name: 'Mark', abbreviation: 'Mark', testament: Testament.new_, chapterCount: 16, order: 41),
    Book(id: 'Luke', name: 'Luke', abbreviation: 'Luke', testament: Testament.new_, chapterCount: 24, order: 42),
    Book(id: 'John', name: 'John', abbreviation: 'John', testament: Testament.new_, chapterCount: 21, order: 43),
    Book(id: 'Acts', name: 'Acts', abbreviation: 'Acts', testament: Testament.new_, chapterCount: 28, order: 44),
    Book(id: 'Rom', name: 'Romans', abbreviation: 'Rom', testament: Testament.new_, chapterCount: 16, order: 45),
    Book(id: '1Cor', name: '1 Corinthians', abbreviation: '1Cor', testament: Testament.new_, chapterCount: 16, order: 46),
    Book(id: '2Cor', name: '2 Corinthians', abbreviation: '2Cor', testament: Testament.new_, chapterCount: 13, order: 47),
    Book(id: 'Gal', name: 'Galatians', abbreviation: 'Gal', testament: Testament.new_, chapterCount: 6, order: 48),
    Book(id: 'Eph', name: 'Ephesians', abbreviation: 'Eph', testament: Testament.new_, chapterCount: 6, order: 49),
    Book(id: 'Phil', name: 'Philippians', abbreviation: 'Phil', testament: Testament.new_, chapterCount: 4, order: 50),
    Book(id: 'Col', name: 'Colossians', abbreviation: 'Col', testament: Testament.new_, chapterCount: 4, order: 51),
    Book(id: '1Thess', name: '1 Thessalonians', abbreviation: '1Thess', testament: Testament.new_, chapterCount: 5, order: 52),
    Book(id: '2Thess', name: '2 Thessalonians', abbreviation: '2Thess', testament: Testament.new_, chapterCount: 3, order: 53),
    Book(id: '1Tim', name: '1 Timothy', abbreviation: '1Tim', testament: Testament.new_, chapterCount: 6, order: 54),
    Book(id: '2Tim', name: '2 Timothy', abbreviation: '2Tim', testament: Testament.new_, chapterCount: 4, order: 55),
    Book(id: 'Titus', name: 'Titus', abbreviation: 'Titus', testament: Testament.new_, chapterCount: 3, order: 56),
    Book(id: 'Phlm', name: 'Philemon', abbreviation: 'Phlm', testament: Testament.new_, chapterCount: 1, order: 57),
    Book(id: 'Heb', name: 'Hebrews', abbreviation: 'Heb', testament: Testament.new_, chapterCount: 13, order: 58),
    Book(id: 'Jas', name: 'James', abbreviation: 'Jas', testament: Testament.new_, chapterCount: 5, order: 59),
    Book(id: '1Pet', name: '1 Peter', abbreviation: '1Pet', testament: Testament.new_, chapterCount: 5, order: 60),
    Book(id: '2Pet', name: '2 Peter', abbreviation: '2Pet', testament: Testament.new_, chapterCount: 3, order: 61),
    Book(id: '1John', name: '1 John', abbreviation: '1John', testament: Testament.new_, chapterCount: 5, order: 62),
    Book(id: '2John', name: '2 John', abbreviation: '2John', testament: Testament.new_, chapterCount: 1, order: 63),
    Book(id: '3John', name: '3 John', abbreviation: '3John', testament: Testament.new_, chapterCount: 1, order: 64),
    Book(id: 'Jude', name: 'Jude', abbreviation: 'Jude', testament: Testament.new_, chapterCount: 1, order: 65),
    Book(id: 'Rev', name: 'Revelation', abbreviation: 'Rev', testament: Testament.new_, chapterCount: 22, order: 66),
  ];

  /// Map bookId to USFM filename
  String _getFilename(String bookId) {
    final fileMap = {
      'Gen': '02-GENengbsb.usfm', 'Exod': '03-EXOengbsb.usfm', 'Lev': '04-LEVengbsb.usfm',
      'Num': '05-NUMengbsb.usfm', 'Deut': '06-DEUengbsb.usfm', 'Josh': '07-JOSengbsb.usfm',
      'Judg': '08-JDGengbsb.usfm', 'Ruth': '09-RUTengbsb.usfm', '1Sam': '10-1SAengbsb.usfm',
      '2Sam': '11-2SAengbsb.usfm', '1Kgs': '12-1KIengbsb.usfm', '2Kgs': '13-2KIengbsb.usfm',
      '1Chr': '14-1CHengbsb.usfm', '2Chr': '15-2CHengbsb.usfm', 'Ezra': '16-EZRengbsb.usfm',
      'Neh': '17-NEHengbsb.usfm', 'Esth': '18-ESTengbsb.usfm', 'Job': '19-JOBengbsb.usfm',
      'Ps': '20-PSAengbsb.usfm', 'Prov': '21-PROengbsb.usfm', 'Eccl': '22-ECCengbsb.usfm',
      'Song': '23-SNGengbsb.usfm', 'Isa': '24-ISAengbsb.usfm', 'Jer': '25-JERengbsb.usfm',
      'Lam': '26-LAMengbsb.usfm', 'Ezek': '27-EZKengbsb.usfm', 'Dan': '28-DANengbsb.usfm',
      'Hos': '29-HOSengbsb.usfm', 'Joel': '30-JOLengbsb.usfm', 'Amos': '31-AMOengbsb.usfm',
      'Obad': '32-OBAengbsb.usfm', 'Jonah': '33-JONengbsb.usfm', 'Mic': '34-MICengbsb.usfm',
      'Nah': '35-NAMengbsb.usfm', 'Hab': '36-HABengbsb.usfm', 'Zeph': '37-ZEPengbsb.usfm',
      'Hag': '38-HAGengbsb.usfm', 'Zech': '39-ZECengbsb.usfm', 'Mal': '40-MALengbsb.usfm',
      'Matt': '70-MATengbsb.usfm', 'Mark': '71-MRKengbsb.usfm', 'Luke': '72-LUKengbsb.usfm',
      'John': '73-JHNengbsb.usfm', 'Acts': '74-ACTengbsb.usfm', 'Rom': '75-ROMengbsb.usfm',
      '1Cor': '76-1COengbsb.usfm', '2Cor': '77-2COengbsb.usfm', 'Gal': '78-GALengbsb.usfm',
      'Eph': '79-EPHengbsb.usfm', 'Phil': '80-PHPengbsb.usfm', 'Col': '81-COLengbsb.usfm',
      '1Thess': '82-1THengbsb.usfm', '2Thess': '83-2THengbsb.usfm', '1Tim': '84-1TIengbsb.usfm',
      '2Tim': '85-2TIengbsb.usfm', 'Titus': '86-TITengbsb.usfm', 'Phlm': '87-PHMengbsb.usfm',
      'Heb': '88-HEBengbsb.usfm', 'Jas': '89-JASengbsb.usfm', '1Pet': '90-1PEengbsb.usfm',
      '2Pet': '91-2PEengbsb.usfm', '1John': '92-1JNengbsb.usfm', '2John': '93-2JNengbsb.usfm',
      '3John': '94-3JNengbsb.usfm', 'Jude': '95-JUDengbsb.usfm', 'Rev': '96-REVengbsb.usfm',
    };
    return fileMap[bookId] ?? '';
  }

  /// Load verses for a specific book (lazy load)
  Future<List<Verse>> _loadBook(String bookId) async {
    final filename = _getFilename(bookId);
    if (filename.isEmpty) {
      throw Exception('Unknown book: $bookId');
    }

    try {
      final content = await _dataSource.loadAsset('$_modulePath/$filename');
      final verses = UsfmParser.parseVerses(content);
      return verses;
    } catch (e) {
      throw Exception('Failed to load $bookId: $e');
    }
  }

  @override
  Future<List<Book>> getBooks() async {
    return _allBooks;
  }

  @override
  Future<Book?> getBook(String bookId) async {
    try {
      return _allBooks.firstWhere((b) => b.id == bookId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Verse>> getVerses(PassageReference reference) async {
    final cacheKey = '${reference.bookId}_${reference.chapter}';
    
    // Check cache first
    if (_chapterCache.containsKey(cacheKey)) {
      return _filterVerses(_chapterCache[cacheKey]!, reference);
    }

    // Load the entire book (chapters are not separate files)
    final bookVerses = await _loadBook(reference.bookId);
    
    // Cache verses by chapter for future use
    final chapterMap = <int, List<Verse>>{};
    for (final verse in bookVerses) {
      chapterMap.putIfAbsent(verse.chapter, () => []).add(verse);
    }
    
    for (final entry in chapterMap.entries) {
      _chapterCache['${reference.bookId}_${entry.key}'] = entry.value;
    }

    // Return requested verses
    return _filterVerses(bookVerses, reference);
  }

  List<Verse> _filterVerses(List<Verse> verses, PassageReference reference) {
    return verses.where((v) {
      if (v.bookId != reference.bookId) return false;
      if (v.chapter != reference.chapter) return false;

      if (reference.startVerse == null) return true;

      return v.number >= reference.startVerse! &&
             v.number <= (reference.endVerse ?? reference.startVerse!);
    }).toList();
  }

  @override
  Future<Verse?> getVerse(String bookId, int chapter, int verse) async {
    final verses = await getVerses(PassageReference(
      bookId: bookId,
      chapter: chapter,
      startVerse: verse,
      endVerse: verse,
    ));
    return verses.isNotEmpty ? verses.first : null;
  }

  @override
  Future<List<Verse>> search(String query) async {
    // For search, we'd need to load all books, or implement indexed search
    // For now, keep it simple
    throw UnimplementedError('Search not yet implemented for lazy repository');
  }
}
