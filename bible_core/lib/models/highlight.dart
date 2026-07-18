import 'package:meta/meta.dart';

import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/models/syncable_entity.dart';

/// A text highlight applied to a range of words in a verse
@immutable
class Highlight extends SyncableEntity {
  /// Reference to the passage
  final PassageReference reference;

  /// Starting word index within the verse
  final int wordStart;

  /// Ending word index within the verse (exclusive)
  final int wordEnd;

  /// Highlight color as an ARGB integer.
  final int colorValue;

  /// Optional note attached to the highlight
  final String? note;

  /// Whether this highlight is shared publicly
  final bool isPublic;

  /// User ID who shared this (if imported from community)
  final String? sharedFromUserId;

  const Highlight({
    required super.id,
    required super.createdAt,
    required super.modifiedAt,
    super.userId,
    super.isDeleted,
    super.version,
    super.syncStatus,
    required this.reference,
    required this.wordStart,
    required this.wordEnd,
    required this.colorValue,
    this.note,
    this.isPublic = false,
    this.sharedFromUserId,
  });

  factory Highlight.create({
    required PassageReference reference,
    required int wordStart,
    required int wordEnd,
    required int colorValue,
    String? note,
    String? userId,
  }) {
    final now = DateTime.now();
    return Highlight(
      id: SyncableEntity.generateId(),
      createdAt: now,
      modifiedAt: now,
      userId: userId,
      reference: reference,
      wordStart: wordStart,
      wordEnd: wordEnd,
      colorValue: colorValue,
      note: note,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.millisecondsSinceEpoch,
      'modified_at': modifiedAt.millisecondsSinceEpoch,
      'user_id': userId,
      'is_deleted': isDeleted ? 1 : 0,
      'version': version,
      'sync_status': syncStatus,
      'book_id': reference.bookId,
      'chapter': reference.chapter,
      'verse_start': reference.startVerse ?? 0,
      'verse_end': reference.endVerse ?? reference.startVerse ?? 0,
      'word_start': wordStart,
      'word_end': wordEnd,
      'color': colorValue,
      'note': note,
      'is_public': isPublic ? 1 : 0,
      'shared_from_user_id': sharedFromUserId,
    };
  }

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      modifiedAt:
          DateTime.fromMillisecondsSinceEpoch(json['modified_at'] as int),
      userId: json['user_id'] as String?,
      isDeleted: (json['is_deleted'] as int) == 1,
      version: json['version'] as int,
      syncStatus: json['sync_status'] as String,
      reference: PassageReference(
        bookId: json['book_id'] as String,
        chapter: json['chapter'] as int,
        startVerse: json['verse_start'] as int,
        endVerse: json['verse_end'] as int,
      ),
      wordStart: json['word_start'] as int,
      wordEnd: json['word_end'] as int,
      colorValue: json['color'] as int,
      note: json['note'] as String?,
      isPublic: (json['is_public'] as int) == 1,
      sharedFromUserId: json['shared_from_user_id'] as String?,
    );
  }

  Highlight copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? userId,
    bool? isDeleted,
    int? version,
    String? syncStatus,
    PassageReference? reference,
    int? wordStart,
    int? wordEnd,
    int? colorValue,
    String? note,
    bool? isPublic,
    String? sharedFromUserId,
  }) {
    return Highlight(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      reference: reference ?? this.reference,
      wordStart: wordStart ?? this.wordStart,
      wordEnd: wordEnd ?? this.wordEnd,
      colorValue: colorValue ?? this.colorValue,
      note: note ?? this.note,
      isPublic: isPublic ?? this.isPublic,
      sharedFromUserId: sharedFromUserId ?? this.sharedFromUserId,
    );
  }
}
