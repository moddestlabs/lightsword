import 'package:meta/meta.dart';
import 'verse.dart';

/// Represents a chapter within a book
@immutable
class Chapter {
  final String bookId;
  final int number;
  final int verseCount;
  final List<Verse> verses;

  const Chapter({
    required this.bookId,
    required this.number,
    required this.verseCount,
    this.verses = const [],
  });

  Chapter copyWith({
    String? bookId,
    int? number,
    int? verseCount,
    List<Verse>? verses,
  }) {
    return Chapter(
      bookId: bookId ?? this.bookId,
      number: number ?? this.number,
      verseCount: verseCount ?? this.verseCount,
      verses: verses ?? this.verses,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          number == other.number;

  @override
  int get hashCode => Object.hash(bookId, number);

  @override
  String toString() => '$bookId $number';
}
