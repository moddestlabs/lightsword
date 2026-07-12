import 'package:bible_app/platform/storage/flutter_asset_data_source.dart';
import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/tagnt_repository.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:bible_core/data/sources/gloss_text.dart';
import 'package:bible_core/data/sources/usfm_lazy_repository.dart';
import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/models/verse.dart';

class OriginalLanguageBibleRepository implements BibleRepository {
  OriginalLanguageBibleRepository()
      : _metadataRepository = UsfmLazyRepository(
          FlutterAssetDataSource(),
          'assets/data/usfm/bsb',
        );

  final BibleRepository _metadataRepository;

  @override
  Future<List<Book>> getBooks() {
    return _metadataRepository.getBooks();
  }

  @override
  Future<Book?> getBook(String bookId) {
    return _metadataRepository.getBook(bookId);
  }

  @override
  Future<List<Verse>> getVerses(PassageReference reference) async {
    final verses = await _loadChapter(reference.bookId, reference.chapter);
    if (reference.startVerse == null) {
      return verses;
    }

    return verses.where((verse) {
      return verse.number >= reference.startVerse! &&
          verse.number <= (reference.endVerse ?? reference.startVerse!);
    }).toList();
  }

  @override
  Future<Verse?> getVerse(String bookId, int chapter, int verse) async {
    final verses = await getVerses(
      PassageReference(
        bookId: bookId,
        chapter: chapter,
        startVerse: verse,
        endVerse: verse,
      ),
    );
    return verses.isEmpty ? null : verses.first;
  }

  @override
  Future<List<Verse>> search(String query) {
    throw UnimplementedError(
      'Search is not yet implemented for the original language repository.',
    );
  }

  Future<List<Verse>> _loadChapter(String bookId, int chapter) async {
    final tahotChapter = await TAHOTRepository.instance.getChapter(bookId, chapter);
    if (tahotChapter != null) {
      return _buildFromTAHOT(bookId, chapter, tahotChapter);
    }

    final tagntChapter = await TAGNTRepository.instance.getChapter(bookId, chapter);
    if (tagntChapter != null) {
      return _buildFromTAGNT(bookId, chapter, tagntChapter);
    }

    return const [];
  }

  List<Verse> _buildFromTAHOT(
    String bookId,
    int chapter,
    Map<String, List<TAHOTWord>> chapterData,
  ) {
    final verseNumbers = chapterData.keys.map(int.parse).toList()..sort();

    return verseNumbers.map((verseNumber) {
      final words = chapterData['$verseNumber'] ?? const <TAHOTWord>[];
      return Verse(
        bookId: bookId,
        chapter: chapter,
        number: verseNumber,
        text: _composeGloss(words.map((word) => word.gloss)),
        notes: _composeOriginal(words.map((word) => word.hebrew)),
      );
    }).toList(growable: false);
  }

  List<Verse> _buildFromTAGNT(
    String bookId,
    int chapter,
    Map<String, List<TAGNTWord>> chapterData,
  ) {
    final verseNumbers = chapterData.keys.map(int.parse).toList()..sort();

    return verseNumbers.map((verseNumber) {
      final words = chapterData['$verseNumber'] ?? const <TAGNTWord>[];
      return Verse(
        bookId: bookId,
        chapter: chapter,
        number: verseNumber,
        text: _composeGloss(words.map((word) => word.gloss)),
        notes: _composeOriginal(words.map((word) => word.greek)),
      );
    }).toList(growable: false);
  }

  String _composeGloss(Iterable<String> glosses) {
    return composeGlossText(glosses);
  }

  String _composeOriginal(Iterable<String> originals) {
    return originals
        .map((word) => word.replaceAll('/', '').replaceAll('\\', '').trim())
        .where((word) => word.isNotEmpty)
        .join(' ');
  }
}