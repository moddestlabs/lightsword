import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/word.dart';

/// Parser for USFM (Unified Standard Format Markers) Bible files.
/// 
/// USFM is a simpler, more readable format than OSIS. Example:
/// ```
/// \id GEN - Berean Study Bible
/// \c 1
/// \v 1 \w In|strong="H8064"\w* \w the|strong="H1254"\w* beginning...
/// ```
class UsfmParser {
  /// Maps USFM book codes to our internal book IDs.
  static const Map<String, String> _bookCodeMap = {
    'GEN': 'Gen', 'EXO': 'Exod', 'LEV': 'Lev', 'NUM': 'Num', 'DEU': 'Deut',
    'JOS': 'Josh', 'JDG': 'Judg', 'RUT': 'Ruth', '1SA': '1Sam', '2SA': '2Sam',
    '1KI': '1Kgs', '2KI': '2Kgs', '1CH': '1Chr', '2CH': '2Chr', 'EZR': 'Ezra',
    'NEH': 'Neh', 'EST': 'Esth', 'JOB': 'Job', 'PSA': 'Ps', 'PRO': 'Prov',
    'ECC': 'Eccl', 'SNG': 'Song', 'ISA': 'Isa', 'JER': 'Jer', 'LAM': 'Lam',
    'EZK': 'Ezek', 'DAN': 'Dan', 'HOS': 'Hos', 'JOL': 'Joel', 'AMO': 'Amos',
    'OBA': 'Obad', 'JON': 'Jonah', 'MIC': 'Mic', 'NAM': 'Nah', 'HAB': 'Hab',
    'ZEP': 'Zeph', 'HAG': 'Hag', 'ZEC': 'Zech', 'MAL': 'Mal',
    'MAT': 'Matt', 'MRK': 'Mark', 'LUK': 'Luke', 'JHN': 'John', 'ACT': 'Acts',
    'ROM': 'Rom', '1CO': '1Cor', '2CO': '2Cor', 'GAL': 'Gal', 'EPH': 'Eph',
    'PHP': 'Phil', 'COL': 'Col', '1TH': '1Thess', '2TH': '2Thess', '1TI': '1Tim',
    '2TI': '2Tim', 'TIT': 'Titus', 'PHM': 'Phlm', 'HEB': 'Heb', 'JAS': 'Jas',
    '1PE': '1Pet', '2PE': '2Pet', '1JN': '1John', '2JN': '2John', '3JN': '3John',
    'JUD': 'Jude', 'REV': 'Rev',
  };

  /// Parses a USFM file and returns a list of verses.
  static List<Verse> parseVerses(String usfmContent) {
    final verses = <Verse>[];
    final lines = usfmContent.split('\n');
    
    String? bookCode;
    String? bookId;
    int currentChapter = 0;
    int? currentVerseNumber;
    final verseContentBuffer = StringBuffer();
    
    void finalizeVerse() {
      if (currentVerseNumber != null && bookId != null && currentChapter > 0) {
        final verseContent = verseContentBuffer.toString().trim();
        
        // Extract plain text (remove USFM markers)
        final text = _extractPlainText(verseContent);
        
        // Extract word-level data with Strong's numbers
        final words = parseWords(verseContent);
        
        if (text.isNotEmpty) {
          verses.add(Verse(
            bookId: bookId,
            chapter: currentChapter,
            number: currentVerseNumber!,
            text: text,
            words: words.isNotEmpty ? words : null,
          ));
        }
        
        currentVerseNumber = null;
        verseContentBuffer.clear();
      }
    }
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Extract book ID from \id marker
      if (trimmed.startsWith(r'\id ')) {
        finalizeVerse();
        bookCode = trimmed.substring(4, 7).toUpperCase();
        bookId = _bookCodeMap[bookCode];
        continue;
      }
      
      // Extract chapter number from \c marker
      if (trimmed.startsWith(r'\c ')) {
        finalizeVerse();
        final match = RegExp(r'\\c\s+(\d+)').firstMatch(trimmed);
        if (match != null) {
          currentChapter = int.parse(match.group(1)!);
        }
        continue;
      }
      
      // Extract verse from \v marker
      if (trimmed.startsWith(r'\v ')) {
        // Finalize previous verse before starting new one
        finalizeVerse();
        
        final match = RegExp(r'\\v\s+(\d+)(.*)').firstMatch(trimmed);
        if (match != null && bookId != null && currentChapter > 0) {
          currentVerseNumber = int.parse(match.group(1)!);
          final contentOnSameLine = match.group(2)!.trim();
          if (contentOnSameLine.isNotEmpty) {
            verseContentBuffer.write(contentOnSameLine);
            verseContentBuffer.write(' ');
          }
        }
        continue;
      }
      
      // If we're currently in a verse, append continuation lines
      // (poetry lines like \q1, \q2, or any other content)
      if (currentVerseNumber != null) {
        // Skip structural markers that shouldn't be part of verse content
        if (trimmed.startsWith(r'\s') || // section headings
            trimmed.startsWith(r'\ms') || // major section headings
            trimmed.startsWith(r'\mr') || // major section references
            trimmed.startsWith(r'\r') || // parallel references
            trimmed.startsWith(r'\b') || // blank line markers
            trimmed.startsWith(r'\m') || // margin paragraphs
            trimmed.startsWith(r'\h') || // running header
            trimmed.startsWith(r'\toc') || // table of contents
            trimmed.startsWith(r'\mt')) { // main title
          continue;
        }
        
        // For poetry lines and other content, remove the marker and keep the text
        var content = trimmed;
        // Remove poetry markers (\q1, \q2, etc.) and paragraph markers (\p)
        content = content.replaceAll(RegExp(r'^\\q\d*\s*'), '');
        content = content.replaceAll(RegExp(r'^\\p\s*'), '');
        
        if (content.isNotEmpty) {
          verseContentBuffer.write(content);
          verseContentBuffer.write(' ');
        }
      }
    }
    
    // Finalize the last verse
    finalizeVerse();
    
    return verses;
  }
  
  /// Extracts plain text from USFM content, removing markers and footnotes.
  static String _extractPlainText(String usfmText) {
    var text = usfmText;
    
    // Remove footnotes: \f + \fr 1:1 \ft note text\f*
    // Footnotes can span multiple lines, use non-greedy match
    text = text.replaceAll(RegExp(r'\\f\s*\+.*?\\f\*', dotAll: true), '');
    
    // Remove word markers with Strong's: \w text|strong="H1234"\w*
    text = text.replaceAllMapped(
      RegExp(r'\\w\s*([^|\\]+)(?:\|[^\\]*)?\\w\*'),
      (match) => match.group(1)!,
    );
    
    // Remove other formatting markers
    text = text.replaceAll(RegExp(r'\\[a-z]+\d*\*?'), '');
    
    // Clean up extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }
  
  /// Extracts words with Strong's numbers from a verse.
  /// 
  /// This will be used for interlinear features in the future.
  static List<Word> parseWords(String usfmText) {
    final words = <Word>[];
    var position = 0;
    
    final wordPattern = RegExp(r'\\w\s*([^|\\]+)(?:\|strong="([^"]+)")?\\w\*');
    
    for (final match in wordPattern.allMatches(usfmText)) {
      final text = match.group(1)!.trim();
      final strongsCode = match.group(2);
      
      if (text.isNotEmpty) {
        words.add(Word(
          text: text,
          strongsNumber: strongsCode,
          position: position++,
        ));
      }
    }
    
    return words;
  }
  
  /// Parses book metadata from USFM content.
  static List<Book> parseBooks(List<String> usfmFiles) {
    // For now, return standard 66 books
    // TODO: Extract actual book list from USFM files
    return [];
  }
}
