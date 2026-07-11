import 'dart:convert';

enum ChapterViewTextDirection {
  auto,
  ltr,
  rtl,
}

extension ChapterViewTextDirectionJson on ChapterViewTextDirection {
  String get jsonValue {
    switch (this) {
      case ChapterViewTextDirection.auto:
        return 'auto';
      case ChapterViewTextDirection.ltr:
        return 'ltr';
      case ChapterViewTextDirection.rtl:
        return 'rtl';
    }
  }

  static ChapterViewTextDirection fromJsonValue(String? value) {
    switch (value) {
      case 'ltr':
        return ChapterViewTextDirection.ltr;
      case 'rtl':
        return ChapterViewTextDirection.rtl;
      case 'auto':
      default:
        return ChapterViewTextDirection.auto;
    }
  }
}

class ChapterViewDefinition {
  final String id;
  final String name;
  final bool isBuiltIn;
  final bool showVerseNumbers;
  final bool lineByLine;
  final bool showOriginalLanguage;
  final bool showTranslation;
  final bool showGloss;
  final ChapterViewTextDirection originalLanguageTextDirection;

  const ChapterViewDefinition({
    required this.id,
    required this.name,
    this.isBuiltIn = false,
    this.showVerseNumbers = true,
    this.lineByLine = true,
    this.showOriginalLanguage = false,
    this.showTranslation = true,
    this.showGloss = false,
    this.originalLanguageTextDirection = ChapterViewTextDirection.auto,
  });

  static const ChapterViewDefinition paragraphView = ChapterViewDefinition(
    id: 'paragraph',
    name: 'Paragraph',
    isBuiltIn: true,
    showVerseNumbers: true,
    lineByLine: false,
    showOriginalLanguage: false,
    showTranslation: true,
    showGloss: false,
  );

  static const ChapterViewDefinition lineByLineView = ChapterViewDefinition(
    id: 'line_by_line',
    name: 'Line by Line',
    isBuiltIn: true,
    showVerseNumbers: true,
    lineByLine: true,
    showOriginalLanguage: false,
    showTranslation: true,
    showGloss: false,
  );

  static const ChapterViewDefinition interlinearView = ChapterViewDefinition(
    id: 'interlinear',
    name: 'Interlinear',
    isBuiltIn: true,
    showVerseNumbers: true,
    lineByLine: true,
    showOriginalLanguage: true,
    showTranslation: true,
    showGloss: true,
    originalLanguageTextDirection: ChapterViewTextDirection.auto,
  );

  static const List<ChapterViewDefinition> defaults = [
    paragraphView,
    lineByLineView,
    interlinearView,
  ];

  ChapterViewDefinition copyWith({
    String? id,
    String? name,
    bool? isBuiltIn,
    bool? showVerseNumbers,
    bool? lineByLine,
    bool? showOriginalLanguage,
    bool? showTranslation,
    bool? showGloss,
    ChapterViewTextDirection? originalLanguageTextDirection,
  }) {
    return ChapterViewDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
      lineByLine: lineByLine ?? this.lineByLine,
      showOriginalLanguage: showOriginalLanguage ?? this.showOriginalLanguage,
      showTranslation: showTranslation ?? this.showTranslation,
      showGloss: showGloss ?? this.showGloss,
      originalLanguageTextDirection:
          originalLanguageTextDirection ?? this.originalLanguageTextDirection,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isBuiltIn': isBuiltIn,
      'showVerseNumbers': showVerseNumbers,
      'lineByLine': lineByLine,
      'showOriginalLanguage': showOriginalLanguage,
      'showTranslation': showTranslation,
      'showGloss': showGloss,
      'originalLanguageTextDirection': originalLanguageTextDirection.jsonValue,
    };
  }

  factory ChapterViewDefinition.fromJson(Map<String, dynamic> json) {
    return ChapterViewDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      showVerseNumbers: json['showVerseNumbers'] as bool? ?? true,
      lineByLine: json['lineByLine'] as bool? ?? true,
      showOriginalLanguage: json['showOriginalLanguage'] as bool? ?? false,
      showTranslation: json['showTranslation'] as bool? ?? true,
      showGloss: json['showGloss'] as bool? ?? false,
      originalLanguageTextDirection:
          ChapterViewTextDirectionJson.fromJsonValue(
        json['originalLanguageTextDirection'] as String?,
      ),
    );
  }

  static String encodeList(List<ChapterViewDefinition> views) {
    return jsonEncode(views.map((view) => view.toJson()).toList());
  }

  static List<ChapterViewDefinition> decodeList(String? encodedViews) {
    if (encodedViews == null || encodedViews.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(encodedViews);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ChapterViewDefinition.fromJson)
        .toList();
  }
}