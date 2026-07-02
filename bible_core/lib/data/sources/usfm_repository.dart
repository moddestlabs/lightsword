import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/usfm_parser.dart';

/// BibleRepository implementation using USFM files.
class UsfmRepository implements BibleRepository {
  final DataSource _dataSource;
  final String _modulePath;
  List<Book>? _cachedBooks;
  List<Verse>? _cachedVerses;

  UsfmRepository(this._dataSource, this._modulePath);

  /// List of all 66 USFM book files (in canonical order).
  static const List<String> _bookFiles = [
    '02-GENengbsb.usfm', '03-EXOengbsb.usfm', '04-LEVengbsb.usfm', '05-NUMengbsb.usfm',
    '06-DEUengbsb.usfm', '07-JOSengbsb.usfm', '08-JDGengbsb.usfm', '09-RUTengbsb.usfm',
    '10-1SAengbsb.usfm', '11-2SAengbsb.usfm', '12-1KIengbsb.usfm', '13-2KIengbsb.usfm',
    '14-1CHengbsb.usfm', '15-2CHengbsb.usfm', '16-EZRengbsb.usfm', '17-NEHengbsb.usfm',
    '18-ESTengbsb.usfm', '19-JOBengbsb.usfm', '20-PSAengbsb.usfm', '21-PROengbsb.usfm',
    '22-ECCengbsb.usfm', '23-SNGengbsb.usfm', '24-ISAengbsb.usfm', '25-JERengbsb.usfm',
    '26-LAMengbsb.usfm', '27-EZKengbsb.usfm', '28-DANengbsb.usfm', '29-HOSengbsb.usfm',
    '30-JOLengbsb.usfm', '31-AMOengbsb.usfm', '32-OBAengbsb.usfm', '33-JONengbsb.usfm',
    '34-MICengbsb.usfm', '35-NAMengbsb.usfm', '36-HABengbsb.usfm', '37-ZEPengbsb.usfm',
    '38-HAGengbsb.usfm', '39-ZECengbsb.usfm', '40-MALengbsb.usfm', '70-MATengbsb.usfm',
    '71-MRKengbsb.usfm', '72-LUKengbsb.usfm', '73-JHNengbsb.usfm', '74-ACTengbsb.usfm',
    '75-ROMengbsb.usfm', '76-1COengbsb.usfm', '77-2COengbsb.usfm', '78-GALengbsb.usfm',
    '79-EPHengbsb.usfm', '80-PHPengbsb.usfm', '81-COLengbsb.usfm', '82-1THengbsb.usfm',
    '83-2THengbsb.usfm', '84-1TIengbsb.usfm', '85-2TIengbsb.usfm', '86-TITengbsb.usfm',
    '87-PHMengbsb.usfm', '88-HEBengbsb.usfm', '89-JASengbsb.usfm', '90-1PEengbsb.usfm',
    '91-2PEengbsb.usfm', '92-1JNengbsb.usfm', '93-2JNengbsb.usfm', '94-3JNengbsb.usfm',
    '95-JUDengbsb.usfm', '96-REVengbsb.usfm',
  ];

  /// Load and parse all USFM files.
  Future<void> _loadData() async {
    if (_cachedVerses != null) return;

    final allVerses = <Verse>[];

    try {
      print('UsfmRepository: Loading USFM files from $_modulePath');
      // Load each book file
      for (final filename in _bookFiles) {
        try {
          print('  Loading $filename...');
          final content = await _dataSource.loadAsset('$_modulePath/$filename');
          final verses = UsfmParser.parseVerses(content);
          print('    Parsed ${verses.length} verses');
          allVerses.addAll(verses);
        } catch (e) {
          print('    Failed to load $filename: $e');
          // Skip files that don't exist or fail to load
          continue;
        }
      }

      print('UsfmRepository: Total verses loaded: ${allVerses.length}');
      _cachedVerses = allVerses;
      
      // Extract unique books from verses
      final bookSet = <String>{};
      for (final verse in allVerses) {
        bookSet.add(verse.bookId);
      }
      
      // Create minimal book list (can be expanded later)
      _cachedBooks = bookSet.map((id) => Book(
        id: id,
        name: id, // TODO: Add proper book names
        abbreviation: id,
        testament: _isOldTestament(id) ? Testament.old : Testament.new_,
        chapterCount: 0, // TODO: Calculate from verses
        order: 0,
      )).toList();
      
    } catch (e) {
      throw Exception('Failed to load USFM Bible data: $e');
    }
  }

  bool _isOldTestament(String bookId) {
    const ntBooks = [
      'Matt', 'Mark', 'Luke', 'John', 'Acts', 'Rom', '1Cor', '2Cor', 'Gal',
      'Eph', 'Phil', 'Col', '1Thess', '2Thess', '1Tim', '2Tim', 'Titus',
      'Phlm', 'Heb', 'Jas', '1Pet', '2Pet', '1John', '2John', '3John', 'Jude', 'Rev'
    ];
    return !ntBooks.contains(bookId);
  }

  @override
  Future<List<Book>> getBooks() async {
    await _loadData();
    return _cachedBooks ?? [];
  }

  @override
  Future<Book?> getBook(String bookId) async {
    await _loadData();
    try {
      return _cachedBooks?.firstWhere((b) => b.id == bookId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Verse>> getVerses(PassageReference reference) async {
    await _loadData();

    return _cachedVerses?.where((v) {
      if (v.bookId != reference.bookId) return false;
      if (v.chapter != reference.chapter) return false;

      if (reference.startVerse == null) return true;

      return v.number >= reference.startVerse! &&
             v.number <= (reference.endVerse ?? reference.startVerse!);
    }).toList() ?? [];
  }

  @override
  Future<Verse?> getVerse(String bookId, int chapter, int verse) async {
    await _loadData();

    try {
      return _cachedVerses?.firstWhere(
        (v) => v.bookId == bookId && v.chapter == chapter && v.number == verse,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Verse>> search(String query) async {
    await _loadData();

    final lowerQuery = query.toLowerCase();
    return _cachedVerses?.where((v) =>
      v.text.toLowerCase().contains(lowerQuery),
    ).toList() ?? [];
  }
}
