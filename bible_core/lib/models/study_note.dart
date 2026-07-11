import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/models/syncable_entity.dart';

/// A user's study note attached to a passage
@immutable
class StudyNote extends SyncableEntity {
  /// Reference to the passage
  final PassageReference reference;

  /// Note content (can be plain text or markdown)
  final String content;

  /// Tags for organization and search
  final List<String> tags;

  /// Whether this note is shared publicly
  final bool isPublic;

  /// IDs of highlights referenced in this note
  final List<String> attachedHighlightIds;

  /// IDs of arcs referenced in this note
  final List<String> attachedArcIds;

  const StudyNote({
    required super.id,
    required super.createdAt,
    required super.modifiedAt,
    super.userId,
    super.isDeleted,
    super.version,
    super.syncStatus,
    required this.reference,
    required this.content,
    this.tags = const [],
    this.isPublic = false,
    this.attachedHighlightIds = const [],
    this.attachedArcIds = const [],
  });

  factory StudyNote.create({
    required PassageReference reference,
    required String content,
    List<String> tags = const [],
    List<String> attachedHighlightIds = const [],
    List<String> attachedArcIds = const [],
    String? userId,
  }) {
    final now = DateTime.now();
    return StudyNote(
      id: SyncableEntity.generateId(),
      createdAt: now,
      modifiedAt: now,
      userId: userId,
      reference: reference,
      content: content,
      tags: tags,
      attachedHighlightIds: attachedHighlightIds,
      attachedArcIds: attachedArcIds,
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
      'verse_start': reference.startVerse,
      'verse_end': reference.endVerse,
      'content': content,
      'tags': jsonEncode(tags),
      'is_public': isPublic ? 1 : 0,
      'attached_highlight_ids': jsonEncode(attachedHighlightIds),
      'attached_arc_ids': jsonEncode(attachedArcIds),
    };
  }

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: json['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(json['modified_at'] as int),
      userId: json['user_id'] as String?,
      isDeleted: (json['is_deleted'] as int) == 1,
      version: json['version'] as int,
      syncStatus: json['sync_status'] as String,
      reference: PassageReference(
        bookId: json['book_id'] as String,
        chapter: json['chapter'] as int,
        startVerse: json['verse_start'] as int?,
        endVerse: json['verse_end'] as int?,
      ),
      content: json['content'] as String,
      tags: (jsonDecode(json['tags'] as String) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isPublic: (json['is_public'] as int) == 1,
      attachedHighlightIds:
          (jsonDecode(json['attached_highlight_ids'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      attachedArcIds:
          (jsonDecode(json['attached_arc_ids'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );
  }

  StudyNote copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? userId,
    bool? isDeleted,
    int? version,
    String? syncStatus,
    PassageReference? reference,
    String? content,
    List<String>? tags,
    bool? isPublic,
    List<String>? attachedHighlightIds,
    List<String>? attachedArcIds,
  }) {
    return StudyNote(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      reference: reference ?? this.reference,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      attachedHighlightIds: attachedHighlightIds ?? this.attachedHighlightIds,
      attachedArcIds: attachedArcIds ?? this.attachedArcIds,
    );
  }
}
