import 'package:bible_core/models/highlight.dart';
import 'package:bible_core/models/arc.dart';
import 'package:bible_core/models/study_note.dart';
import 'package:bible_core/models/drawing.dart';
import 'package:bible_core/models/passage_reference.dart';

/// Status of sync operations
class SyncStatus {
  final bool success;
  final String? message;
  final int itemsSynced;
  final List<String> conflicts;

  const SyncStatus({
    required this.success,
    this.message,
    this.itemsSynced = 0,
    this.conflicts = const [],
  });
}

/// Repository for user-generated content (highlights, arcs, notes)
/// Both local and cloud implementations should implement this interface
abstract class UserContentRepository {
  // === Highlight Operations ===
  
  /// Save or update a highlight
  Future<void> saveHighlight(Highlight highlight);
  
  /// Delete a highlight by ID
  Future<void> deleteHighlight(String id);
  
  /// Get all highlights for a specific passage
  Future<List<Highlight>> getHighlights(PassageReference reference);
  
  /// Get all highlights across all passages
  Future<List<Highlight>> getAllHighlights();
  
  /// Get a specific highlight by ID
  Future<Highlight?> getHighlight(String id);

  // === Arc Operations ===
  
  /// Save or update an arc
  Future<void> saveArc(Arc arc);
  
  /// Delete an arc by ID
  Future<void> deleteArc(String id);
  
  /// Get all arcs for a specific passage
  Future<List<Arc>> getArcs(PassageReference reference);
  
  /// Get all arcs across all passages
  Future<List<Arc>> getAllArcs();
  
  /// Get a specific arc by ID
  Future<Arc?> getArc(String id);

  // === Study Note Operations ===
  
  /// Save or update a study note
  Future<void> saveNote(StudyNote note);
  
  /// Delete a study note by ID
  Future<void> deleteNote(String id);
  
  /// Get all notes for a specific passage
  Future<List<StudyNote>> getNotes(PassageReference reference);
  
  /// Get all notes across all passages
  Future<List<StudyNote>> getAllNotes();
  
  /// Get notes by tag
  Future<List<StudyNote>> getNotesByTag(String tag);
  
  /// Get a specific note by ID
  Future<StudyNote?> getNote(String id);

  // === Drawing Operations ===
  
  /// Save or update a drawing
  Future<void> saveDrawing(Drawing drawing);
  
  /// Delete a drawing by ID
  Future<void> deleteDrawing(String id);
  
  /// Get all drawings for a specific passage
  Future<List<Drawing>> getDrawings(PassageReference reference);
  
  /// Get all drawings across all passages
  Future<List<Drawing>> getAllDrawings();
  
  /// Get a specific drawing by ID
  Future<Drawing?> getDrawing(String id);

  // === Sync Operations (for future cloud implementation) ===
  
  /// Sync local changes with cloud (if available)
  Future<SyncStatus> sync();
  
  /// Import shared content from JSON
  Future<void> importSharedContent(String contentJson);
  
  /// Export content as JSON for sharing
  Future<String> exportContent(List<String> entityIds);
  
  /// Check if cloud sync is available
  bool get isSyncAvailable;
}
