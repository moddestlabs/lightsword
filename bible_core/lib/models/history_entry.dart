import 'package:meta/meta.dart';
import 'passage_reference.dart';

/// A record of a visited passage in reading history
@immutable
class HistoryEntry {
  final String id;
  final PassageReference reference;
  final DateTime timestamp;
  final String? sourceId;

  const HistoryEntry({
    required this.id,
    required this.reference,
    required this.timestamp,
    this.sourceId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': reference.bookId,
        'chapter': reference.chapter,
        'startVerse': reference.startVerse,
        'endVerse': reference.endVerse,
        'timestamp': timestamp.toIso8601String(),
        if (sourceId != null) 'sourceId': sourceId,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      reference: PassageReference(
        bookId: json['bookId'] as String,
        chapter: json['chapter'] as int,
        startVerse: json['startVerse'] as int?,
        endVerse: json['endVerse'] as int?,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sourceId: json['sourceId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reference == other.reference &&
          timestamp == other.timestamp &&
          sourceId == other.sourceId;

  @override
  int get hashCode => Object.hash(id, reference, timestamp, sourceId);
}

/// Normalizes date to midnight local time for per-day grouping.
DateTime normalizeDateToDay(DateTime dt) {
  final local = dt.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Helper function to group history entries by local calendar day (newest days first).
Map<DateTime, List<HistoryEntry>> groupEntriesByDay(
    List<HistoryEntry> entries) {
  final Map<DateTime, List<HistoryEntry>> grouped = {};
  final sorted = List<HistoryEntry>.from(entries)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  for (final entry in sorted) {
    final dayKey = normalizeDateToDay(entry.timestamp);
    grouped.putIfAbsent(dayKey, () => []).add(entry);
  }
  return grouped;
}
