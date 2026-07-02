import 'package:xml/xml.dart';
import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/word.dart';

/// Parser for OSIS (Open Scripture Information Standard) XML format
class OsisParser {
  /// Map OSIS book names to internal book IDs
  static final Map<String, String> _osisBookMap = {
    'Gen': 'genesis',
    'Exod': 'exodus',
    'Lev': 'leviticus',
    'Num': 'numbers',
    'Deut': 'deuteronomy',
    'Josh': 'joshua',
    'Judg': 'judges',
    'Ruth': 'ruth',
    '1Sam': '1samuel',
    '2Sam': '2samuel',
    '1Kgs': '1kings',
    '2Kgs': '2kings',
    '1Chr': '1chronicles',
    '2Chr': '2chronicles',
    'Ezra': 'ezra',
    'Neh': 'nehemiah',
    'Esth': 'esther',
    'Job': 'job',
    'Ps': 'psalms',
    'Prov': 'proverbs',
    'Eccl': 'ecclesiastes',
    'Song': 'songofsolomon',
    'Isa': 'isaiah',
    'Jer': 'jeremiah',
    'Lam': 'lamentations',
    'Ezek': 'ezekiel',
    'Dan': 'daniel',
    'Hos': 'hosea',
    'Joel': 'joel',
    'Amos': 'amos',
    'Obad': 'obadiah',
    'Jonah': 'jonah',
    'Mic': 'micah',
    'Nah': 'nahum',
    'Hab': 'habakkuk',
    'Zeph': 'zephaniah',
    'Hag': 'haggai',
    'Zech': 'zechariah',
    'Mal': 'malachi',
    'Matt': 'matthew',
    'Mark': 'mark',
    'Luke': 'luke',
    'John': 'john',
    'Acts': 'acts',
    'Rom': 'romans',
    '1Cor': '1corinthians',
    '2Cor': '2corinthians',
    'Gal': 'galatians',
    'Eph': 'ephesians',
    'Phil': 'philippians',
    'Col': 'colossians',
    '1Thess': '1thessalonians',
    '2Thess': '2thessalonians',
    '1Tim': '1timothy',
    '2Tim': '2timothy',
    'Titus': 'titus',
    'Phlm': 'philemon',
    'Heb': 'hebrews',
    'Jas': 'james',
    '1Pet': '1peter',
    '2Pet': '2peter',
    '1John': '1john',
    '2John': '2john',
    '3John': '3john',
    'Jude': 'jude',
    'Rev': 'revelation',
  };

  /// Parse OSIS XML and extract all verses
  /// Returns a list of verses with book/chapter/verse references
  static List<Verse> parseVerses(String osisXml) {
    final document = XmlDocument.parse(osisXml);
    final verses = <Verse>[];

    // Find all <verse> elements
    final verseElements = document.findAllElements('verse');
    
    for (final verseElement in verseElements) {
      final verse = _parseVerseElement(verseElement);
      if (verse != null) {
        verses.add(verse);
      }
    }

    return verses;
  }

  /// Parse a single <verse> element
  static Verse? _parseVerseElement(XmlElement element) {
    // Get osisID attribute (e.g., "Gen.1.1" or "Matt.1.1-Matt.1.2")
    final osisId = element.getAttribute('osisID');
    if (osisId == null) return null;

    // Parse osisID to extract book/chapter/verse
    final parts = osisId.split('.');
    if (parts.length < 3) return null;

    final osisBookName = parts[0];
    final bookId = _osisBookMap[osisBookName];
    if (bookId == null) return null;

    final chapter = int.tryParse(parts[1]);
    if (chapter == null) return null;

    // Handle verse ranges (e.g., "1-2")
    final versePart = parts[2].split('-')[0]; // Take first verse in range
    final verseNum = int.tryParse(versePart);
    if (verseNum == null) return null;

    // Extract text content (ignore markup for now)
    final text = _extractText(element);

    return Verse(
      bookId: bookId,
      chapter: chapter,
      number: verseNum,
      text: text.trim(),
    );
  }

  /// Extract plain text from XML element, stripping tags
  static String _extractText(XmlElement element) {
    final buffer = StringBuffer();

    for (final node in element.children) {
      if (node is XmlText) {
        buffer.write(node.value);
      } else if (node is XmlElement) {
        // Recursively extract text from child elements
        buffer.write(_extractText(node));
      }
    }

    return buffer.toString();
  }

  /// Parse Strong's numbers and morphology from <w> elements
  /// Returns a list of Word objects for interlinear display
  static List<Word> parseWords(XmlElement verseElement) {
    final words = <Word>[];
    final wordElements = verseElement.findElements('w');
    
    int position = 0;
    for (final wordElement in wordElements) {
      final text = wordElement.innerText;
      
      // Parse lemma (Strong's number)
      final lemma = wordElement.getAttribute('lemma');
      String? strongsNumber;
      if (lemma != null && lemma.contains('strong:')) {
        // Extract Strong's number (e.g., "strong:H07225" -> "H07225")
        strongsNumber = lemma.split('strong:').last.split(' ').first;
      }
      
      // Parse morphology
      final morph = wordElement.getAttribute('morph');
      MorphologyTag? morphology;
      if (morph != null) {
        morphology = MorphologyTag(rawCode: morph);
      }
      
      words.add(Word(
        text: text,
        strongsNumber: strongsNumber,
        morphology: morphology,
        position: position++,
      ),);
    }
    
    return words;
  }

  /// Parse book metadata from OSIS XML
  static List<Book> parseBooks(String osisXml) {
    final document = XmlDocument.parse(osisXml);
    final books = <Book>[];
    
    // Find all <div type="book"> elements
    final bookElements = document.findAllElements('div').where(
      (e) => e.getAttribute('type') == 'book',
    );
    
    int order = 0;
    for (final bookElement in bookElements) {
      final book = _parseBookElement(bookElement, order++);
      if (book != null) {
        books.add(book);
      }
    }
    
    return books;
  }

  /// Parse a single book element
  static Book? _parseBookElement(XmlElement element, int order) {
    final osisId = element.getAttribute('osisID');
    if (osisId == null) return null;

    final bookId = _osisBookMap[osisId];
    if (bookId == null) return null;

    // Count chapters
    final chapters = element.findAllElements('chapter').length;

    // Determine testament
    final testament = _isOldTestament(osisId) ? Testament.old : Testament.new_;

    // Get book name (use display name if available, otherwise derive from ID)
    final titleElement = element.findElements('title').firstOrNull;
    final name = titleElement?.innerText ?? _deriveBookName(bookId);

    return Book(
      id: bookId,
      name: name,
      abbreviation: osisId,
      testament: testament,
      chapterCount: chapters,
      order: order,
    );
  }

  /// Check if a book is in the Old Testament
  static bool _isOldTestament(String osisBookName) {
    const ntBooks = {
      'Matt', 'Mark', 'Luke', 'John', 'Acts', 'Rom', '1Cor', '2Cor',
      'Gal', 'Eph', 'Phil', 'Col', '1Thess', '2Thess', '1Tim', '2Tim',
      'Titus', 'Phlm', 'Heb', 'Jas', '1Pet', '2Pet', '1John', '2John',
      '3John', 'Jude', 'Rev',
    };
    return !ntBooks.contains(osisBookName);
  }

  /// Derive human-readable book name from book ID
  static String _deriveBookName(String bookId) {
    // Convert "1samuel" -> "1 Samuel", "songofsolomon" -> "Song of Solomon"
    final capitalized = bookId[0].toUpperCase() + bookId.substring(1);
    return capitalized
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('of', 'of ');
  }
}
