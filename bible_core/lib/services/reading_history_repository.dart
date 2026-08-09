import '../models/history_entry.dart';
import '../models/passage_reference.dart';

/// Abstract repository for persisting and querying reading history entries.
abstract class ReadingHistoryRepository {
  /// Add or update a history entry for a visited passage.
  Future<void> addVisit({
    required PassageReference reference,
    String? sourceId,
  });

  /// Get all history entries (newest first).
  Future<List<HistoryEntry>> getHistory();

  /// Get history entries grouped by local calendar day (newest days first).
  Future<Map<DateTime, List<HistoryEntry>>> getGroupedHistory();

  /// Clear all history entries.
  Future<void> clearHistory();

  /// Delete a single history entry by ID.
  Future<void> deleteEntry(String id);
}
