import 'package:flutter/foundation.dart';
import 'package:bible_core/bible_core.dart';

/// Reading modes available in the app
enum ReadingMode {
  verse,       // One verse per line (traditional)
  interlinear, // Word-by-word with original languages
  study,       // Paragraph form with highlights/arcs/notes
  drawing,     // Study mode with vector drawing tools
}

extension ReadingModeExtension on ReadingMode {
  String get displayName {
    switch (this) {
      case ReadingMode.verse:
        return 'Verse';
      case ReadingMode.interlinear:
        return 'Interlinear';
      case ReadingMode.study:
        return 'Study';
      case ReadingMode.drawing:
        return 'Drawing';
    }
  }

  String get description {
    switch (this) {
      case ReadingMode.verse:
        return 'Traditional verse-by-verse reading';
      case ReadingMode.interlinear:
        return 'Word-by-word with Hebrew/Greek';
      case ReadingMode.study:
        return 'Study mode with highlights and arcs';
      case ReadingMode.drawing:
        return 'Freehand drawing with study features';
    }
  }
}

/// Settings specific to study mode
class StudyModeSettings {
  final bool showArcs;
  final bool showHighlights;
  final bool showNotes;
  final ArcStyle arcDisplayStyle;
  final double textSize;
  final bool paragraphMode;

  const StudyModeSettings({
    this.showArcs = true,
    this.showHighlights = true,
    this.showNotes = true,
    this.arcDisplayStyle = ArcStyle.curved,
    this.textSize = 16.0,
    this.paragraphMode = true,
  });

  StudyModeSettings copyWith({
    bool? showArcs,
    bool? showHighlights,
    bool? showNotes,
    ArcStyle? arcDisplayStyle,
    double? textSize,
    bool? paragraphMode,
  }) {
    return StudyModeSettings(
      showArcs: showArcs ?? this.showArcs,
      showHighlights: showHighlights ?? this.showHighlights,
      showNotes: showNotes ?? this.showNotes,
      arcDisplayStyle: arcDisplayStyle ?? this.arcDisplayStyle,
      textSize: textSize ?? this.textSize,
      paragraphMode: paragraphMode ?? this.paragraphMode,
    );
  }
}

/// State for chapter view across all modes
@immutable
class ChapterViewState {
  final Chapter chapter;
  final ReadingMode mode;
  final bool showVerseNumbers;
  final List<Highlight> highlights;
  final List<Arc> arcs;
  final List<StudyNote> notes;
  final List<Drawing> drawings;
  final StudyModeSettings studySettings;
  final bool isLoading;

  const ChapterViewState({
    required this.chapter,
    this.mode = ReadingMode.verse,
    this.showVerseNumbers = true,
    this.highlights = const [],
    this.arcs = const [],
    this.notes = const [],
    this.drawings = const [],
    this.studySettings = const StudyModeSettings(),
    this.isLoading = false,
  });

  ChapterViewState copyWith({
    Chapter? chapter,
    ReadingMode? mode,
    bool? showVerseNumbers,
    List<Highlight>? highlights,
    List<Arc>? arcs,
    List<StudyNote>? notes,
    List<Drawing>? drawings,
    StudyModeSettings? studySettings,
    bool? isLoading,
  }) {
    return ChapterViewState(
      chapter: chapter ?? this.chapter,
      mode: mode ?? this.mode,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
      highlights: highlights ?? this.highlights,
      arcs: arcs ?? this.arcs,
      notes: notes ?? this.notes,
      drawings: drawings ?? this.drawings,
      studySettings: studySettings ?? this.studySettings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller for chapter view that manages reading modes and user content
class ChapterViewController extends ChangeNotifier {
  final UserContentRepository _contentRepo;
  ChapterViewState _state;

  ChapterViewController(
    this._contentRepo,
    Chapter chapter,
  ) : _state = ChapterViewState(chapter: chapter) {
    _loadUserContent();
  }

  ChapterViewState get state => _state;

  /// Expose repository for direct access when needed
  UserContentRepository get repository => _contentRepo;

  /// Load highlights, arcs, and notes for the current chapter
  Future<void> _loadUserContent() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final ref = PassageReference(
        bookId: _state.chapter.bookId,
        chapter: _state.chapter.number,
      );

      final highlights = await _contentRepo.getHighlights(ref);
      final arcs = await _contentRepo.getArcs(ref);
      final notes = await _contentRepo.getNotes(ref);
      final drawings = await _contentRepo.getDrawings(ref);

      _state = _state.copyWith(
        highlights: highlights,
        arcs: arcs,
        notes: notes,
        drawings: drawings,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      rethrow;
    }
  }

  /// Switch to a different reading mode
  void switchMode(ReadingMode mode) {
    _state = _state.copyWith(mode: mode);
    notifyListeners();
  }

  /// Toggle verse numbers visibility
  void toggleVerseNumbers() {
    _state = _state.copyWith(showVerseNumbers: !_state.showVerseNumbers);
    notifyListeners();
  }

  /// Update study mode settings
  void updateStudySettings(StudyModeSettings settings) {
    _state = _state.copyWith(studySettings: settings);
    notifyListeners();
  }

  // === Highlight Operations ===

  Future<void> addHighlight(Highlight highlight) async {
    await _contentRepo.saveHighlight(highlight);
    await _loadUserContent();
  }

  Future<void> updateHighlight(Highlight highlight) async {
    final updated = highlight.copyWith(modifiedAt: DateTime.now());
    await _contentRepo.saveHighlight(updated);
    await _loadUserContent();
  }

  Future<void> deleteHighlight(String id) async {
    await _contentRepo.deleteHighlight(id);
    await _loadUserContent();
  }

  // === Arc Operations ===

  Future<void> addArc(Arc arc) async {
    await _contentRepo.saveArc(arc);
    await _loadUserContent();
  }

  Future<void> updateArc(Arc arc) async {
    final updated = arc.copyWith(modifiedAt: DateTime.now());
    await _contentRepo.saveArc(updated);
    await _loadUserContent();
  }

  Future<void> deleteArc(String id) async {
    await _contentRepo.deleteArc(id);
    await _loadUserContent();
  }

  // === Note Operations ===

  Future<void> addNote(StudyNote note) async {
    await _contentRepo.saveNote(note);
    await _loadUserContent();
  }

  Future<void> updateNote(StudyNote note) async {
    final updated = note.copyWith(modifiedAt: DateTime.now());
    await _contentRepo.saveNote(updated);
    await _loadUserContent();
  }

  Future<void> deleteNote(String id) async {
    await _contentRepo.deleteNote(id);
    await _loadUserContent();
  }

  // === Drawing Operations ===

  Future<void> addDrawing(Drawing drawing) async {
    await _contentRepo.saveDrawing(drawing);
    await _loadUserContent();
  }

  Future<void> updateDrawing(Drawing drawing) async {
    final updated = drawing.copyWith(modifiedAt: DateTime.now());
    await _contentRepo.saveDrawing(updated);
    await _loadUserContent();
  }

  Future<void> deleteDrawing(String id) async {
    await _contentRepo.deleteDrawing(id);
    await _loadUserContent();
  }

  // === Export/Import ===

  Future<String> exportContent(List<String> entityIds) async {
    return await _contentRepo.exportContent(entityIds);
  }

  Future<void> importContent(String contentJson) async {
    await _contentRepo.importSharedContent(contentJson);
    await _loadUserContent();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
