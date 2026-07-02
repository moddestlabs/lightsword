import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/sword/osis_parser.dart';
import 'package:bible_core/data/sources/sword/module_config.dart';

/// BibleRepository implementation using SWORD modules
class SwordRepository implements BibleRepository {
  final DataSource _dataSource;
  final String _modulePath;
  SwordModuleConfig? _config;
  List<Book>? _cachedBooks;
  List<Verse>? _cachedVerses;

  SwordRepository(this._dataSource, this._modulePath);

  /// Load and parse the SWORD module configuration
  Future<SwordModuleConfig> _loadConfig() async {
    if (_config != null) return _config!;

    try {
      final confContent = await _dataSource.loadAsset('$_modulePath.conf');
      _config = SwordModuleConfig.parse(confContent);
      return _config!;
    } catch (e) {
      throw Exception('Failed to load SWORD module config: $e');
    }
  }

  /// Load and parse all module data
  Future<void> _loadData() async {
    if (_cachedVerses != null) return;

    final config = await _loadConfig();

    // For now, only support OSIS format
    if (config.sourceType != SourceType.osis) {
      throw UnsupportedError(
        'Only OSIS format is currently supported. Module uses ${config.sourceType}',
      );
    }

    // TODO: Handle compressed modules
    if (config.compression != CompressionType.none) {
      throw UnsupportedError(
        'Compressed modules not yet supported. Module uses ${config.compression}',
      );
    }

    try {
      // Load the OSIS XML file
      final osisXml = await _dataSource.loadAsset(config.dataPath);
      
      // Parse verses and books
      _cachedVerses = OsisParser.parseVerses(osisXml);
      _cachedBooks = OsisParser.parseBooks(osisXml);
    } catch (e) {
      throw Exception('Failed to parse SWORD module data: $e');
    }
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
