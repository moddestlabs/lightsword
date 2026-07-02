import 'dart:typed_data';
import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/sword/osis_parser.dart';
import 'package:bible_core/data/sources/sword/module_config.dart';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';

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
      final confContent = await _dataSource.loadAsset('data/$_modulePath.conf');
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

    try {
      String osisXml;
      
      // Handle compressed zText modules
      if (config.driver == ModuleDriver.zText && 
          config.compression != CompressionType.none) {
        osisXml = await _loadCompressedData(config);
      } else {
        // Load uncompressed OSIS XML file
        osisXml = await _dataSource.loadAsset(config.dataPath);
      }
      
      // Parse verses and books
      _cachedVerses = OsisParser.parseVerses(osisXml);
      _cachedBooks = OsisParser.parseBooks(osisXml);
    } catch (e) {
      throw Exception('Failed to parse SWORD module data: $e');
    }
  }

  /// Loads and decompresses a zText compressed module.
  /// 
  /// zText modules store data in separate files for OT and NT:
  /// - nt.bzv / ot.bzv: Verse index (locations in compressed data)
  /// - nt.bzz / ot.bzz: BZIP2 compressed text data
  /// - nt.bzs / ot.bzs: Book index (optional)
  Future<String> _loadCompressedData(SwordModuleConfig config) async {
    // Remove trailing slash and file extensions from dataPath
    var basePath = config.dataPath.replaceAll(RegExp(r'\.(xml|osis)$'), '');
    if (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }
    
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">');
    buffer.writeln('<osisText>');
    
    // Try to load both OT and NT
    for (final testament in ['ot', 'nt']) {
      try {
        final verses = await _loadTestament(basePath, testament);
        buffer.write(verses);
      } catch (e) {
        // Testament might not exist (e.g., NT-only module)
        continue;
      }
    }
    
    buffer.writeln('</osisText>');
    buffer.writeln('</osis>');
    
    return buffer.toString();
  }

  /// Loads and decompresses verses from one testament (OT or NT).
  Future<String> _loadTestament(String basePath, String testament) async {
    // Load compressed data (.bzz file contains multiple ZLIB blocks)
    final compressedData = await _dataSource.loadBytes('$basePath/$testament.bzz');
    
    // Try to load book index (.bzs) for proper block boundaries
    Uint8List? bookIndex;
    try {
      bookIndex = await _dataSource.loadBytes('$basePath/$testament.bzs');
    } catch (e) {
      // Book index might not exist, will use fallback method
      bookIndex = null;
    }
    
    // Decompress all blocks
    return ZTextReader.decompressAllBlocks(compressedData, bookIndex);
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
