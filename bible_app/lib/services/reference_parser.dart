import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_app/ui/models/view_mode.dart';

/// Result of parsing a reference string
class ParsedReference {
  final PassageReference reference;
  final ViewMode? viewMode;

  const ParsedReference({
    required this.reference,
    this.viewMode,
  });
}

/// Parser for Bible reference strings from URLs
class ReferenceParser {
  /// Book ID normalization map (case-insensitive)
  /// Maps user input abbreviations to actual book IDs used in the Bible data
  static final Map<String, String> _bookAbbreviations = {
    // Old Testament
    'gen': 'Gen',
    'genesis': 'Gen',
    'exo': 'Exod',
    'exod': 'Exod',
    'exodus': 'Exod',
    'lev': 'Lev',
    'leviticus': 'Lev',
    'num': 'Num',
    'numbers': 'Num',
    'deu': 'Deut',
    'deut': 'Deut',
    'deuteronomy': 'Deut',
    'jos': 'Josh',
    'josh': 'Josh',
    'joshua': 'Josh',
    'jdg': 'Judg',
    'judg': 'Judg',
    'judges': 'Judg',
    'rut': 'Ruth',
    'ruth': 'Ruth',
    '1sa': '1Sam',
    '1sam': '1Sam',
    '1samuel': '1Sam',
    '2sa': '2Sam',
    '2sam': '2Sam',
    '2samuel': '2Sam',
    '1ki': '1Kgs',
    '1kgs': '1Kgs',
    '1kings': '1Kgs',
    '2ki': '2Kgs',
    '2kgs': '2Kgs',
    '2kings': '2Kgs',
    '1ch': '1Chr',
    '1chr': '1Chr',
    '1chronicles': '1Chr',
    '2ch': '2Chr',
    '2chr': '2Chr',
    '2chronicles': '2Chr',
    'ezr': 'Ezra',
    'ezra': 'Ezra',
    'neh': 'Neh',
    'nehemiah': 'Neh',
    'est': 'Esth',
    'esth': 'Esth',
    'esther': 'Esth',
    'job': 'Job',
    'psa': 'Ps',
    'ps': 'Ps',
    'psalm': 'Ps',
    'psalms': 'Ps',
    'pro': 'Prov',
    'prov': 'Prov',
    'proverbs': 'Prov',
    'ecc': 'Eccl',
    'eccl': 'Eccl',
    'ecclesiastes': 'Eccl',
    'sng': 'Song',
    'song': 'Song',
    'songofsolomon': 'Song',
    'isa': 'Isa',
    'isaiah': 'Isa',
    'jer': 'Jer',
    'jeremiah': 'Jer',
    'lam': 'Lam',
    'lamentations': 'Lam',
    'ezk': 'Ezek',
    'ezek': 'Ezek',
    'ezekiel': 'Ezek',
    'dan': 'Dan',
    'daniel': 'Dan',
    'hos': 'Hos',
    'hosea': 'Hos',
    'jol': 'Joel',
    'joel': 'Joel',
    'amo': 'Amos',
    'amos': 'Amos',
    'oba': 'Obad',
    'obad': 'Obad',
    'obadiah': 'Obad',
    'jon': 'Jonah',
    'jonah': 'Jonah',
    'mic': 'Mic',
    'micah': 'Mic',
    'nam': 'Nah',
    'nah': 'Nah',
    'nahum': 'Nah',
    'hab': 'Hab',
    'habakkuk': 'Hab',
    'zep': 'Zeph',
    'zeph': 'Zeph',
    'zephaniah': 'Zeph',
    'hag': 'Hag',
    'haggai': 'Hag',
    'zec': 'Zech',
    'zech': 'Zech',
    'zechariah': 'Zech',
    'mal': 'Mal',
    'malachi': 'Mal',
    
    // New Testament
    'mat': 'Matt',
    'matt': 'Matt',
    'matthew': 'Matt',
    'mrk': 'Mark',
    'mark': 'Mark',
    'luk': 'Luke',
    'luke': 'Luke',
    'jhn': 'John',
    'john': 'John',
    'act': 'Acts',
    'acts': 'Acts',
    'rom': 'Rom',
    'romans': 'Rom',
    '1co': '1Cor',
    '1cor': '1Cor',
    '1corinthians': '1Cor',
    '2co': '2Cor',
    '2cor': '2Cor',
    '2corinthians': '2Cor',
    'gal': 'Gal',
    'galatians': 'Gal',
    'eph': 'Eph',
    'ephesians': 'Eph',
    'php': 'Phil',
    'phil': 'Phil',
    'philippians': 'Phil',
    'col': 'Col',
    'colossians': 'Col',
    '1th': '1Thess',
    '1thess': '1Thess',
    '1thessalonians': '1Thess',
    '2th': '2Thess',
    '2thess': '2Thess',
    '2thessalonians': '2Thess',
    '1ti': '1Tim',
    '1tim': '1Tim',
    '1timothy': '1Tim',
    '2ti': '2Tim',
    '2tim': '2Tim',
    '2timothy': '2Tim',
    'tit': 'Titus',
    'titus': 'Titus',
    'phm': 'Phlm',
    'phlm': 'Phlm',
    'philemon': 'Phlm',
    'heb': 'Heb',
    'hebrews': 'Heb',
    'jas': 'Jas',
    'james': 'Jas',
    '1pe': '1Pet',
    '1pet': '1Pet',
    '1peter': '1Pet',
    '2pe': '2Pet',
    '2pet': '2Pet',
    '2peter': '2Pet',
    '1jn': '1John',
    '1john': '1John',
    '2jn': '2John',
    '2john': '2John',
    '3jn': '3John',
    '3john': '3John',
    'jud': 'Jude',
    'jude': 'Jude',
    'rev': 'Rev',
    'revelation': 'Rev',
  };

  /// Parse a reference string like "gen1.4", "john3.16", "rom8.1-10"
  /// Returns null if the reference is invalid
  static PassageReference? parse(String reference) {
    if (reference.isEmpty) return null;

    // Normalize: lowercase, remove spaces
    final normalized = reference.toLowerCase().replaceAll(' ', '');

    // Extract book, chapter, and verse(s)
    // Pattern: bookname + digit(s) + optional(.digit(s)) + optional(-digit(s))
    final regex = RegExp(r'^([a-z0-9]+?)(\d+)(?:\.(\d+)(?:-(\d+))?)?$');
    final match = regex.firstMatch(normalized);

    if (match == null) return null;

    final bookAbbrev = match.group(1)!;
    final chapterStr = match.group(2)!;
    final startVerseStr = match.group(3); // May be null
    final endVerseStr = match.group(4);   // May be null

    // Look up book ID
    final bookId = _bookAbbreviations[bookAbbrev];
    if (bookId == null) return null;

    final chapter = int.tryParse(chapterStr);
    if (chapter == null || chapter < 1) return null;

    int? startVerse;
    int? endVerse;

    if (startVerseStr != null) {
      startVerse = int.tryParse(startVerseStr);
      if (startVerse == null || startVerse < 1) return null;

      if (endVerseStr != null) {
        endVerse = int.tryParse(endVerseStr);
        if (endVerse == null || endVerse < startVerse) return null;
      }
    }

    return PassageReference(
      bookId: bookId,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }

  /// Parse with optional view mode parameter
  static ParsedReference? parseWithMode(String reference, String? modeStr) {
    final ref = parse(reference);
    if (ref == null) return null;

    ViewMode? viewMode;
    if (modeStr != null) {
      try {
        viewMode = ViewMode.values.firstWhere(
          (m) => m.name.toLowerCase() == modeStr.toLowerCase(),
        );
      } catch (_) {
        // Invalid mode, ignore
      }
    }

    return ParsedReference(
      reference: ref,
      viewMode: viewMode,
    );
  }

  /// Format a reference as a compact string (for generating URLs)
  static String format(PassageReference ref) {
    final bookAbbrev = _getAbbreviation(ref.bookId);
    final chapter = ref.chapter;

    if (ref.isChapter) {
      return '$bookAbbrev$chapter';
    } else if (ref.isSingleVerse) {
      return '$bookAbbrev$chapter.${ref.startVerse}';
    } else {
      return '$bookAbbrev$chapter.${ref.startVerse}-${ref.endVerse}';
    }
  }

  /// Get preferred abbreviation for a book ID
  static String _getAbbreviation(String bookId) {
    // Find the shortest abbreviation for this book
    final entries = _bookAbbreviations.entries
        .where((e) => e.value == bookId)
        .toList();
    
    if (entries.isEmpty) return bookId.toLowerCase();
    
    // Return the shortest abbreviation
    entries.sort((a, b) => a.key.length.compareTo(b.key.length));
    return entries.first.key;
  }
}
