import 'dart:convert';
import 'package:bible_core/models/highlight.dart';
import 'package:bible_core/models/arc.dart';
import 'package:bible_core/models/study_note.dart';
import 'package:bible_core/models/drawing.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/services/user_content_repository.dart';

/// Local storage implementation of UserContentRepository
/// Uses in-memory storage for now; will be backed by SQLite in the Flutter app
class LocalUserContentRepository implements UserContentRepository {
  // In-memory storage (for pure Dart testing)
  // In the Flutter app, this will be replaced with sqflite Database
  final Map<String, Highlight> _highlights = {};
  final Map<String, Arc> _arcs = {};
  final Map<String, StudyNote> _notes = {};
  final Map<String, Drawing> _drawings = {};

  @override
  bool get isSyncAvailable => false; // Local only

  // === Highlight Operations ===

  @override
  Future<void> saveHighlight(Highlight highlight) async {
    _highlights[highlight.id] = highlight;
  }

  @override
  Future<void> deleteHighlight(String id) async {
    final highlight = _highlights[id];
    if (highlight != null) {
      // Soft delete
      _highlights[id] = highlight.copyWith(
        isDeleted: true,
        modifiedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<Highlight>> getHighlights(PassageReference reference) async {
    return _highlights.values
        .where((h) =>
            !h.isDeleted &&
            h.reference.bookId == reference.bookId &&
            h.reference.chapter == reference.chapter)
        .toList();
  }

  @override
  Future<List<Highlight>> getAllHighlights() async {
    return _highlights.values.where((h) => !h.isDeleted).toList();
  }

  @override
  Future<Highlight?> getHighlight(String id) async {
    final highlight = _highlights[id];
    return highlight?.isDeleted == false ? highlight : null;
  }

  // === Arc Operations ===

  @override
  Future<void> saveArc(Arc arc) async {
    _arcs[arc.id] = arc;
  }

  @override
  Future<void> deleteArc(String id) async {
    final arc = _arcs[id];
    if (arc != null) {
      // Soft delete
      _arcs[id] = arc.copyWith(
        isDeleted: true,
        modifiedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<Arc>> getArcs(PassageReference reference) async {
    return _arcs.values
        .where((a) =>
            !a.isDeleted &&
            a.reference.bookId == reference.bookId &&
            a.reference.chapter == reference.chapter)
        .toList();
  }

  @override
  Future<List<Arc>> getAllArcs() async {
    return _arcs.values.where((a) => !a.isDeleted).toList();
  }

  @override
  Future<Arc?> getArc(String id) async {
    final arc = _arcs[id];
    return arc?.isDeleted == false ? arc : null;
  }

  // === Study Note Operations ===

  @override
  Future<void> saveNote(StudyNote note) async {
    _notes[note.id] = note;
  }

  @override
  Future<void> deleteNote(String id) async {
    final note = _notes[id];
    if (note != null) {
      // Soft delete
      _notes[id] = note.copyWith(
        isDeleted: true,
        modifiedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<StudyNote>> getNotes(PassageReference reference) async {
    return _notes.values
        .where((n) =>
            !n.isDeleted &&
            n.reference.bookId == reference.bookId &&
            n.reference.chapter == reference.chapter)
        .toList();
  }

  @override
  Future<List<StudyNote>> getAllNotes() async {
    return _notes.values.where((n) => !n.isDeleted).toList();
  }

  @override
  Future<List<StudyNote>> getNotesByTag(String tag) async {
    return _notes.values
        .where((n) => !n.isDeleted && n.tags.contains(tag))
        .toList();
  }

  @override
  Future<StudyNote?> getNote(String id) async {
    final note = _notes[id];
    return note?.isDeleted == false ? note : null;
  }

  // === Drawing Operations ===

  @override
  Future<void> saveDrawing(Drawing drawing) async {
    _drawings[drawing.id] = drawing;
  }

  @override
  Future<void> deleteDrawing(String id) async {
    final drawing = _drawings[id];
    if (drawing != null) {
      // Soft delete
      _drawings[id] = drawing.copyWith(
        isDeleted: true,
        modifiedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<Drawing>> getDrawings(PassageReference reference) async {
    return _drawings.values
        .where((d) =>
            !d.isDeleted &&
            d.reference.bookId == reference.bookId &&
            d.reference.chapter == reference.chapter)
        .toList();
  }

  @override
  Future<List<Drawing>> getAllDrawings() async {
    return _drawings.values.where((d) => !d.isDeleted).toList();
  }

  @override
  Future<Drawing?> getDrawing(String id) async {
    final drawing = _drawings[id];
    return drawing?.isDeleted == false ? drawing : null;
  }

  // === Sync Operations ===

  @override
  Future<SyncStatus> sync() async {
    // No cloud sync for local repository
    return const SyncStatus(
      success: true,
      message: 'Local only - no sync available',
    );
  }

  @override
  Future<void> importSharedContent(String contentJson) async {
    final data = jsonDecode(contentJson) as Map<String, dynamic>;

    // Import highlights
    if (data['highlights'] != null) {
      final highlights = (data['highlights'] as List)
          .map((json) => Highlight.fromJson(json as Map<String, dynamic>))
          .toList();
      for (final highlight in highlights) {
        await saveHighlight(highlight);
      }
    }

    // Import arcs
    if (data['arcs'] != null) {
      final arcs = (data['arcs'] as List)
          .map((json) => Arc.fromJson(json as Map<String, dynamic>))
          .toList();
      for (final arc in arcs) {
        await saveArc(arc);
      }
    }

    // Import notes
    if (data['notes'] != null) {
      final notes = (data['notes'] as List)
          .map((json) => StudyNote.fromJson(json as Map<String, dynamic>))
          .toList();
      for (final note in notes) {
        await saveNote(note);
      }
    }

    // Import drawings
    if (data['drawings'] != null) {
      final drawings = (data['drawings'] as List)
          .map((json) => Drawing.fromJson(json as Map<String, dynamic>))
          .toList();
      for (final drawing in drawings) {
        await saveDrawing(drawing);
      }
    }
  }

  @override
  Future<String> exportContent(List<String> entityIds) async {
    final highlights = <Map<String, dynamic>>[];
    final arcs = <Map<String, dynamic>>[];
    final notes = <Map<String, dynamic>>[];
    final drawings = <Map<String, dynamic>>[];

    for (final id in entityIds) {
      final highlight = _highlights[id];
      if (highlight != null && !highlight.isDeleted) {
        highlights.add(highlight.toJson());
      }

      final arc = _arcs[id];
      if (arc != null && !arc.isDeleted) {
        arcs.add(arc.toJson());
      }

      final note = _notes[id];
      if (note != null && !note.isDeleted) {
        notes.add(note.toJson());
      }

      final drawing = _drawings[id];
      if (drawing != null && !drawing.isDeleted) {
        drawings.add(drawing.toJson());
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
