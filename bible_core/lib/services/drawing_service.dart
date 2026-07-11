import 'package:bible_core/models/drawing.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/data/repository.dart';

/// Service for managing drawings with content-anchored positioning
class DrawingService {
  final UserContentRepository _repository;

  DrawingService(this._repository);

  /// Get all drawings for a specific passage
  Future<List<Drawing>> getDrawings(PassageReference reference) async {
    return await _repository.getDrawings(reference);
  }

  /// Get all drawings for a chapter
  Future<List<Drawing>> getChapterDrawings(String bookId, int chapter) async {
    return await _repository.getDrawings(
      PassageReference(bookId: bookId, chapter: chapter),
    );
  }

  /// Add a new drawing
  Future<void> addDrawing(Drawing drawing) async {
    await _repository.saveDrawing(drawing);
  }

  /// Update an existing drawing
  Future<void> updateDrawing(Drawing drawing) async {
    final updated = drawing.copyWith(
      modifiedAt: DateTime.now(),
      version: drawing.version + 1,
    );
    await _repository.saveDrawing(updated);
  }

  /// Delete a drawing
  Future<void> deleteDrawing(String id) async {
    await _repository.deleteDrawing(id);
  }

  /// Get all public drawings for a passage (for community sharing)
  Future<List<Drawing>> getPublicDrawings(PassageReference reference) async {
    final allDrawings = await getDrawings(reference);
    return allDrawings.where((d) => d.isPublic).toList();
  }

  /// Share a drawing publicly
  Future<void> shareDrawing(String drawingId, bool isPublic) async {
    // Implementation depends on repository capabilities
    // This would update the isPublic flag
  }
}
