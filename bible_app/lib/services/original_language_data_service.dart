import 'package:bible_core/bible_core.dart'
    show SyntaxRepository, SyntaxVerseData;
import 'package:bible_core/data/sources/tagnt_repository.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:bible_core/models/syntax_data.dart';

import '../platform/storage/bundled_pack_reader.dart';
import '../ui/models/interlinear_word.dart';

class OriginalLanguageVerseContent {
  final List<InterlinearWord> words;
  final SyntaxVerseData? syntax;

  const OriginalLanguageVerseContent({
    required this.words,
    this.syntax,
  });
}

/// Centralized original-language loader so syntax-capable sources can be added
/// without rewriting every reader widget.
class OriginalLanguageDataService {
  static final OriginalLanguageDataService instance =
      OriginalLanguageDataService._();
  static final BundledPackReader _bundledPackReader = BundledPackReader();

  OriginalLanguageDataService._();

  final TAHOTRepository _tahotRepository =
      TAHOTRepository.fromPackReader(_bundledPackReader);
  final TAGNTRepository _tagntRepository =
      TAGNTRepository.fromPackReader(_bundledPackReader);
  final SyntaxRepository _syntaxRepository =
      SyntaxRepository.fromPackReader(_bundledPackReader);

  Future<OriginalLanguageVerseContent> loadVerse(
    String bookId,
    int chapter,
    int verseNumber, {
    bool includeSyntax = false,
  }) async {
    final tahot = await _tahotRepository.getVerse(
      bookId,
      chapter,
      verseNumber,
    );
    if (tahot != null) {
      final words =
          tahot.map(InterlinearWord.fromTAHOT).toList(growable: false);
      final syntax = includeSyntax
          ? await _syntaxRepository.getVerse(bookId, chapter, verseNumber)
          : null;
      return OriginalLanguageVerseContent(
        words: words,
        syntax: _realignSyntaxToWords(words, syntax),
      );
    }

    final tagnt = await _tagntRepository.getVerse(
      bookId,
      chapter,
      verseNumber,
    );
    if (tagnt != null) {
      final words =
          tagnt.map(InterlinearWord.fromTAGNT).toList(growable: false);
      final syntax = includeSyntax
          ? await _syntaxRepository.getVerse(bookId, chapter, verseNumber)
          : null;
      return OriginalLanguageVerseContent(
        words: words,
        syntax: _realignSyntaxToWords(words, syntax),
      );
    }

    final syntax = includeSyntax
        ? await _syntaxRepository.getVerse(bookId, chapter, verseNumber)
        : null;
    return OriginalLanguageVerseContent(
      words: const <InterlinearWord>[],
      syntax: syntax,
    );
  }

  SyntaxVerseData? _realignSyntaxToWords(
    List<InterlinearWord> words,
    SyntaxVerseData? syntax,
  ) {
    if (syntax == null || words.isEmpty || syntax.words.isEmpty) {
      return syntax;
    }

    final mappedIndices = <int, int>{};
    var searchStart = 0;
    for (final annotation in syntax.words) {
      final tokenText = _normalizeToken(annotation.tokenText);
      if (tokenText == null || tokenText.isEmpty) {
        continue;
      }

      final matchIndex = _findMatchingWordIndex(words, tokenText, searchStart);
      if (matchIndex != null) {
        mappedIndices[annotation.wordIndex] = matchIndex;
        searchStart = matchIndex + 1;
      }
    }

    if (mappedIndices.isEmpty) {
      return syntax;
    }

    int? mapIndex(int? sourceIndex) {
      if (sourceIndex == null) {
        return null;
      }
      return mappedIndices[sourceIndex];
    }

    final remappedWords = syntax.words.map((annotation) {
      return SyntaxWordAnnotation(
        wordIndex: mapIndex(annotation.wordIndex) ?? annotation.wordIndex,
        tokenId: annotation.tokenId,
        tokenText: annotation.tokenText,
        role: annotation.role,
        headWordIndex: mapIndex(annotation.headWordIndex),
        referentWordIndex: mapIndex(annotation.referentWordIndex),
        referentSpanStartWordIndex:
            mapIndex(annotation.referentSpanStartWordIndex),
        referentSpanEndWordIndex: mapIndex(annotation.referentSpanEndWordIndex),
      );
    }).toList(growable: false);

    final remappedArcs = syntax.arcs.map((arc) {
      return SyntaxArcData(
        fromWordIndex: mapIndex(arc.fromWordIndex) ?? arc.fromWordIndex,
        toWordIndex: mapIndex(arc.toWordIndex) ?? arc.toWordIndex,
        kind: arc.kind,
        label: arc.label,
      );
    }).toList(growable: false);

    final remappedSpans = syntax.spans.map((span) {
      return SyntaxSpanData(
        fromWordIndex: mapIndex(span.fromWordIndex) ?? span.fromWordIndex,
        startWordIndex: mapIndex(span.startWordIndex) ?? span.startWordIndex,
        endWordIndex: mapIndex(span.endWordIndex) ?? span.endWordIndex,
        kind: span.kind,
        label: span.label,
      );
    }).toList(growable: false);

    return SyntaxVerseData(
      bookId: syntax.bookId,
      chapter: syntax.chapter,
      verse: syntax.verse,
      words: remappedWords,
      arcs: remappedArcs,
      spans: remappedSpans,
    );
  }

  int? _findMatchingWordIndex(
    List<InterlinearWord> words,
    String tokenText,
    int searchStart,
  ) {
    for (var index = searchStart; index < words.length; index++) {
      final wordText = _normalizeToken(words[index].displayOriginalText);
      if (wordText == tokenText) {
        return index;
      }
    }
    for (var index = 0; index < searchStart && index < words.length; index++) {
      final wordText = _normalizeToken(words[index].displayOriginalText);
      if (wordText == tokenText) {
        return index;
      }
    }
    return null;
  }

  String? _normalizeToken(String? value) {
    if (value == null) {
      return null;
    }
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      if (_isCombiningMark(rune)) {
        continue;
      }
      final char = String.fromCharCode(rune);
      if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(char)) {
        buffer.write(char);
      }
    }
    final normalized = buffer.toString();
    return normalized.isEmpty ? null : normalized;
  }

  bool _isCombiningMark(int rune) {
    return (rune >= 0x0300 && rune <= 0x036F) ||
        (rune >= 0x1AB0 && rune <= 0x1AFF) ||
        (rune >= 0x1DC0 && rune <= 0x1DFF) ||
        (rune >= 0x20D0 && rune <= 0x20FF) ||
        (rune >= 0xFE20 && rune <= 0xFE2F);
  }
}
