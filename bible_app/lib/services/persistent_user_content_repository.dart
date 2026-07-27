import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_core/bible_core.dart';

/// Persistent user content repository backed by SharedPreferences
class PersistentUserContentRepository implements UserContentRepository {
  final Map<String, Highlight> _highlights = {};
  final Map<String, Arc> _arcs = {};
  final Map<String, StudyNote> _notes = {};
  final Map<String, Drawing> _drawings = {};
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final highlightsJson = prefs.getString('user_highlights');
      if (highlightsJson != null) {
        final List<dynamic> list = jsonDecode(highlightsJson);
        for (var item in list) {
          final h = Highlight.fromJson(item as Map<String, dynamic>);
          _highlights[h.id] = h;
        }
      }
      final notesJson = prefs.getString('user_notes');
      if (notesJson != null) {
        final List<dynamic> list = jsonDecode(notesJson);
        for (var item in list) {
          final n = StudyNote.fromJson(item as Map<String, dynamic>);
          _notes[n.id] = n;
        }
      }
    } catch (_) {}
    _isInitialized = true;
  }

  Future<void> _persistHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _highlights.values.map((h) => h.toJson()).toList();
      await prefs.setString('user_highlights', jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _persistNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _notes.values.map((n) => n.toJson()).toList();
      await prefs.setString('user_notes', jsonEncode(list));
    } catch (_) {}
  }

  @override
  bool get isSyncAvailable => false;

  @override
  Future<SyncStatus> sync() async {
    return const SyncStatus(success: true, message: 'Local storage');
  }

  @override
  Future<void> saveHighlight(Highlight highlight) async {
    await init();
    _highlights[highlight.id] = highlight;
    await _persistHighlights();
  }

  @override
  Future<void> deleteHighlight(String id) async {
    await init();
    final highlight = _highlights[id];
    if (highlight != null) {
      _highlights[id] = highlight.copyWith(
        isDeleted: true,
        modifiedAt: DateTime.now(),
      );
      await _persistHighlights();
    }
  }

  @override
  Future<List<Highlight>> getHighlights(PassageReference reference) async {
    await init();
    return _highlights.values
        .where(
          (h) =>
              !h.isDeleted &&
              h.reference.bookId == reference.bookId &&
              h.reference.chapter == reference.chapter,
        )
        .toList();
  }

  @override
  Future<List<Highlight>> getAllHighlights() async {
    await init();
    return _highlights.values.where((h) => !h.isDeleted).toList();
  }

  @override
  Future<Highlight?> getHighlight(String id) async {
    await init();
    final highlight = _highlights[id];
    return highlight?.isDeleted == false ? highlight : null;
  }

  // === Arc Operations ===
  @override
  Future<void> saveArc(Arc arc) async {
    await init();
    _arcs[arc.id] = arc;
  }

  @override
  Future<void> deleteArc(String id) async {
    await init();
    final arc = _arcs[id];
    if (arc != null) {
      _arcs[id] = arc.copyWith(isDeleted: true, modifiedAt: DateTime.now());
    }
  }

  @override
  Future<List<Arc>> getArcs(PassageReference reference) async {
    await init();
    return _arcs.values
        .where(
          (a) =>
              !a.isDeleted &&
              a.reference.bookId == reference.bookId &&
              a.reference.chapter == reference.chapter,
        )
        .toList();
  }

  @override
  Future<List<Arc>> getAllArcs() async {
    await init();
    return _arcs.values.where((a) => !a.isDeleted).toList();
  }

  @override
  Future<Arc?> getArc(String id) async {
    await init();
    final arc = _arcs[id];
    return arc?.isDeleted == false ? arc : null;
  }

  // === Note Operations ===
  @override
  Future<void> saveNote(StudyNote note) async {
    await init();
    _notes[note.id] = note;
    await _persistNotes();
  }

  @override
  Future<void> deleteNote(String id) async {
    await init();
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isDeleted: true, modifiedAt: DateTime.now());
      await _persistNotes();
    }
  }

  @override
  Future<List<StudyNote>> getNotes(PassageReference reference) async {
    await init();
    return _notes.values
        .where(
          (n) =>
              !n.isDeleted &&
              n.reference.bookId == reference.bookId &&
              n.reference.chapter == reference.chapter,
        )
        .toList();
  }

  @override
  Future<List<StudyNote>> getNotesByTag(String tag) async {
    await init();
    return _notes.values
        .where((n) => !n.isDeleted && n.tags.contains(tag))
        .toList();
  }

  @override
  Future<List<StudyNote>> getAllNotes() async {
    await init();
    return _notes.values.where((n) => !n.isDeleted).toList();
  }

  @override
  Future<StudyNote?> getNote(String id) async {
    await init();
    final note = _notes[id];
    return note?.isDeleted == false ? note : null;
  }

  // === Drawing Operations ===
  @override
  Future<void> saveDrawing(Drawing drawing) async {
    await init();
    _drawings[drawing.id] = drawing;
  }

  @override
  Future<void> deleteDrawing(String id) async {
    await init();
    final drawing = _drawings[id];
    if (drawing != null) {
      _drawings[id] =
          drawing.copyWith(isDeleted: true, modifiedAt: DateTime.now());
    }
  }

  @override
  Future<List<Drawing>> getDrawings(PassageReference reference) async {
    await init();
    return _drawings.values
        .where(
          (d) =>
              !d.isDeleted &&
              d.reference.bookId == reference.bookId &&
              d.reference.chapter == reference.chapter,
        )
        .toList();
  }

  @override
  Future<List<Drawing>> getAllDrawings() async {
    await init();
    return _drawings.values.where((d) => !d.isDeleted).toList();
  }

  @override
  Future<Drawing?> getDrawing(String id) async {
    await init();
    final drawing = _drawings[id];
    return drawing?.isDeleted == false ? drawing : null;
  }

  // === Import / Export Operations ===
  @override
  Future<void> importSharedContent(String contentJson) async {
    await init();
    final data = jsonDecode(contentJson) as Map<String, dynamic>;

    if (data['highlights'] != null) {
      final highlights = (data['highlights'] as List)
          .map((json) => Highlight.fromJson(json as Map<String, dynamic>))
          .toList();
      for (final highlight in highlights) {
        await saveHighlight(highlight);
      }
    }

    if (data['notes'] != null) {
      final notes = (data['notes'] as List)
          .map((json) => StudyNote.fromJson(json as Map<String, dynamic>))
          .toList();
      for (final note in notes) {
        await saveNote(note);
      }
    }
  }

  @override
  Future<String> exportContent(List<String> entityIds) async {
    await init();
    final highlights = <Map<String, dynamic>>[];
    final arcs = <Map<String, dynamic>>[];
    final notes = <Map<String, dynamic>>[];
    final drawings = <Map<String, dynamic>>[];

    for (final id in entityIds) {
      final highlight = _highlights[id];
      if (highlight != null && !highlight.isDeleted) {
        highlights.add(highlight.toJson());
      }
      final note = _notes[id];
      if (note != null && !note.isDeleted) {
        notes.add(note.toJson());
      }
    }

    return jsonEncode({
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'highlights': highlights,
      'arcs': arcs,
      'notes': notes,
      'drawings': drawings,
    });
  }
}
