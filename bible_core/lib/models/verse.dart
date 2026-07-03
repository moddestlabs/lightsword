import 'package:meta/meta.dart';
import 'package:bible_core/models/word.dart';

/// Represents a single verse with its text and metadata
@immutable
class Verse {
  final String bookId;
  final int chapter;
  final int number;
  final String text;
  final String? notes;
  final List<Word>? words; // Interlinear word-by-word data

  const Verse({
    required this.bookId,
    required this.chapter,
    required this.number,
    required this.text,
    this.notes,
    this.words,
  });

  String get reference => '$bookId $chapter:$number';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Verse &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          chapter == other.chapter &&
          number == other.number;

  @override
  int get hashCode => Object.hash(bookId, chapter, number);

  @override
  String toString() => '$reference - ${text.substring(0, text.length > 50 ? 50 : text.length)}...';
}
