import 'package:meta/meta.dart';

import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/models/syncable_entity.dart';

/// Types of syntactic or semantic relationships that can be represented by arcs
enum ArcType {
  subject,
  verb,
  directObject,
  indirectObject,
  modifier,
  prepositionalPhrase,
  clause,
  comparison,
  contrast,
  cause,
  effect,
  custom;

  String get displayName {
    switch (this) {
      case ArcType.subject:
        return 'Subject';
      case ArcType.verb:
        return 'Verb';
      case ArcType.directObject:
        return 'Direct Object';
      case ArcType.indirectObject:
        return 'Indirect Object';
      case ArcType.modifier:
        return 'Modifier';
      case ArcType.prepositionalPhrase:
        return 'Prepositional Phrase';
      case ArcType.clause:
        return 'Clause';
      case ArcType.comparison:
        return 'Comparison';
      case ArcType.contrast:
        return 'Contrast';
      case ArcType.cause:
        return 'Cause';
      case ArcType.effect:
        return 'Effect';
      case ArcType.custom:
        return 'Custom';
    }
  }
}

/// Visual style for drawing arcs
enum ArcStyle {
  above,
  below,
  straight,
  curved;

  String get displayName {
    switch (this) {
      case ArcStyle.above:
        return 'Above Text';
      case ArcStyle.below:
        return 'Below Text';
      case ArcStyle.straight:
        return 'Straight Line';
      case ArcStyle.curved:
        return 'Curved Line';
    }
  }
}

/// An arc connecting words to show syntactic or semantic relationships
@immutable
class Arc extends SyncableEntity {
  /// Reference to the passage
  final PassageReference reference;

  /// Starting word index within the verse
  final int fromWordIndex;

  /// Ending word index within the verse
  final int toWordIndex;

  /// Type of relationship this arc represents
  final ArcType type;

  /// Arc color as an ARGB integer.
  final int colorValue;

  /// Optional label to display on the arc
  final String? label;

  /// Visual style for drawing the arc
  final ArcStyle style;

  /// Whether this arc is shared publicly
  final bool isPublic;

  /// User ID who shared this (if imported from community)
  final String? sharedFromUserId;

  /// Extensible metadata for future features
  final Map<String, dynamic>? metadata;

  const Arc({
    required super.id,
    required super.createdAt,
    required super.modifiedAt,
    super.userId,
    super.isDeleted,
    super.version,
    super.syncStatus,
    required this.reference,
    required this.fromWordIndex,
    required this.toWordIndex,
    required this.type,
    required this.colorValue,
    this.label,
    this.style = ArcStyle.curved,
    this.isPublic = false,
    this.sharedFromUserId,
    this.metadata,
  });

  factory Arc.create({
    required PassageReference reference,
    required int fromWordIndex,
    required int toWordIndex,
    required ArcType type,
    required int colorValue,
    String? label,
    ArcStyle style = ArcStyle.curved,
    String? userId,
  }) {
    final now = DateTime.now();
    return Arc(
      id: SyncableEntity.generateId(),
      createdAt: now,
      modifiedAt: now,
      userId: userId,
      reference: reference,
      fromWordIndex: fromWordIndex,
      toWordIndex: toWordIndex,
      type: type,
      colorValue: colorValue,
      label: label,
      style: style,
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
      'verse': reference.startVerse ?? 0,
      'from_word_index': fromWordIndex,
      'to_word_index': toWordIndex,
      'arc_type': type.name,
      'color': colorValue,
      'label': label,
      'style': style.name,
      'is_public': isPublic ? 1 : 0,
      'shared_from_user_id': sharedFromUserId,
      'metadata': metadata,
    };
  }

  factory Arc.fromJson(Map<String, dynamic> json) {
    return Arc(
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
        startVerse: json['verse'] as int,
        endVerse: json['verse'] as int,
      ),
      fromWordIndex: json['from_word_index'] as int,
      toWordIndex: json['to_word_index'] as int,
      type: ArcType.values.firstWhere(
        (e) => e.name == json['arc_type'],
        orElse: () => ArcType.custom,
      ),
      colorValue: json['color'] as int,
      label: json['label'] as String?,
      style: ArcStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => ArcStyle.curved,
      ),
      isPublic: (json['is_public'] as int) == 1,
      sharedFromUserId: json['shared_from_user_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Arc copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? userId,
    bool? isDeleted,
    int? version,
    String? syncStatus,
    PassageReference? reference,
    int? fromWordIndex,
    int? toWordIndex,
    ArcType? type,
    int? colorValue,
    String? label,
    ArcStyle? style,
    bool? isPublic,
    String? sharedFromUserId,
    Map<String, dynamic>? metadata,
  }) {
    return Arc(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      reference: reference ?? this.reference,
      fromWordIndex: fromWordIndex ?? this.fromWordIndex,
      toWordIndex: toWordIndex ?? this.toWordIndex,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      label: label ?? this.label,
      style: style ?? this.style,
      isPublic: isPublic ?? this.isPublic,
      sharedFromUserId: sharedFromUserId ?? this.sharedFromUserId,
      metadata: metadata ?? this.metadata,
    );
  }
}
