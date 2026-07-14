enum SyntaxRelationKind {
  clause,
  predicate,
  subject,
  object,
  modifier,
  referent,
  head,
  apposition,
  parallel,
  unknown,
}

extension SyntaxRelationKindJson on SyntaxRelationKind {
  static SyntaxRelationKind fromJsonValue(String? value) {
    switch (value) {
      case 'clause':
        return SyntaxRelationKind.clause;
      case 'predicate':
        return SyntaxRelationKind.predicate;
      case 'subject':
        return SyntaxRelationKind.subject;
      case 'object':
        return SyntaxRelationKind.object;
      case 'modifier':
        return SyntaxRelationKind.modifier;
      case 'referent':
        return SyntaxRelationKind.referent;
      case 'head':
        return SyntaxRelationKind.head;
      case 'apposition':
        return SyntaxRelationKind.apposition;
      case 'parallel':
        return SyntaxRelationKind.parallel;
      default:
        return SyntaxRelationKind.unknown;
    }
  }
}

class SyntaxArcData {
  final int fromWordIndex;
  final int toWordIndex;
  final SyntaxRelationKind kind;
  final String? label;

  const SyntaxArcData({
    required this.fromWordIndex,
    required this.toWordIndex,
    required this.kind,
    this.label,
  });

  factory SyntaxArcData.fromJson(Map<String, dynamic> json) {
    return SyntaxArcData(
      fromWordIndex: json['fromWordIndex'] as int,
      toWordIndex: json['toWordIndex'] as int,
      kind: SyntaxRelationKindJson.fromJsonValue(json['kind'] as String?),
      label: json['label'] as String?,
    );
  }
}

class SyntaxSpanData {
  final int fromWordIndex;
  final int startWordIndex;
  final int endWordIndex;
  final SyntaxRelationKind kind;
  final String? label;

  const SyntaxSpanData({
    required this.fromWordIndex,
    required this.startWordIndex,
    required this.endWordIndex,
    required this.kind,
    this.label,
  });

  factory SyntaxSpanData.fromJson(Map<String, dynamic> json) {
    return SyntaxSpanData(
      fromWordIndex: json['fromWordIndex'] as int,
      startWordIndex: json['startWordIndex'] as int,
      endWordIndex: json['endWordIndex'] as int,
      kind: SyntaxRelationKindJson.fromJsonValue(json['kind'] as String?),
      label: json['label'] as String?,
    );
  }
}

class SyntaxWordAnnotation {
  final int wordIndex;
  final String? tokenId;
  final String? tokenText;
  final String? role;
  final int? headWordIndex;
  final int? referentWordIndex;
  final int? referentSpanStartWordIndex;
  final int? referentSpanEndWordIndex;

  const SyntaxWordAnnotation({
    required this.wordIndex,
    this.tokenId,
    this.tokenText,
    this.role,
    this.headWordIndex,
    this.referentWordIndex,
    this.referentSpanStartWordIndex,
    this.referentSpanEndWordIndex,
  });

  factory SyntaxWordAnnotation.fromJson(Map<String, dynamic> json) {
    return SyntaxWordAnnotation(
      wordIndex: json['wordIndex'] as int,
      tokenId: json['tokenId'] as String?,
      tokenText: json['tokenText'] as String?,
      role: json['role'] as String?,
      headWordIndex: json['headWordIndex'] as int?,
      referentWordIndex: json['referentWordIndex'] as int?,
      referentSpanStartWordIndex: json['referentSpanStartWordIndex'] as int?,
      referentSpanEndWordIndex: json['referentSpanEndWordIndex'] as int?,
    );
  }
}

class SyntaxVerseData {
  final String bookId;
  final int chapter;
  final int verse;
  final List<SyntaxWordAnnotation> words;
  final List<SyntaxArcData> arcs;
  final List<SyntaxSpanData> spans;

  const SyntaxVerseData({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.words,
    required this.arcs,
    required this.spans,
  });

  factory SyntaxVerseData.fromJson(
    String bookId,
    int chapter,
    int verse,
    Map<String, dynamic> json,
  ) {
    final wordsJson = json['words'] as List<dynamic>? ?? const <dynamic>[];
    final arcsJson = json['arcs'] as List<dynamic>? ?? const <dynamic>[];
    final spansJson = json['spans'] as List<dynamic>? ?? const <dynamic>[];
    return SyntaxVerseData(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      words: wordsJson
          .whereType<Map<String, dynamic>>()
          .map(SyntaxWordAnnotation.fromJson)
          .toList(growable: false),
      arcs: arcsJson
          .whereType<Map<String, dynamic>>()
          .map(SyntaxArcData.fromJson)
          .toList(growable: false),
        spans: spansJson
          .whereType<Map<String, dynamic>>()
          .map(SyntaxSpanData.fromJson)
          .toList(growable: false),
    );
  }

  SyntaxWordAnnotation? annotationForWord(int wordIndex) {
    for (final word in words) {
      if (word.wordIndex == wordIndex) {
        return word;
      }
    }
    return null;
  }
}

Map<String, SyntaxVerseData> decodeSyntaxBook(
  String bookId,
  Map<String, dynamic> bookJson,
) {
  final decoded = <String, SyntaxVerseData>{};

  for (final chapterEntry in bookJson.entries) {
    final chapter = int.tryParse(chapterEntry.key);
    final chapterData = chapterEntry.value;
    if (chapter == null || chapterData is! Map<String, dynamic>) {
      continue;
    }

    for (final verseEntry in chapterData.entries) {
      final verse = int.tryParse(verseEntry.key);
      final verseData = verseEntry.value;
      if (verse == null || verseData is! Map<String, dynamic>) {
        continue;
      }

      decoded['$chapter:$verse'] = SyntaxVerseData.fromJson(
        bookId,
        chapter,
        verse,
        verseData,
      );
    }
  }

  return decoded;
}