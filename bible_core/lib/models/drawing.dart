import 'dart:convert';

import 'package:meta/meta.dart';

import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_core/models/syncable_entity.dart';

/// Portable 2D coordinate for drawing data.
@immutable
class DrawingOffset {
  final double dx;
  final double dy;

  const DrawingOffset(this.dx, this.dy);

  static const zero = DrawingOffset(0, 0);
}

/// Zone where a drawing is positioned
enum DrawingZone {
  leftMargin,
  rightMargin,
  contentOverlay;

  String get value {
    switch (this) {
      case DrawingZone.leftMargin:
        return 'left_margin';
      case DrawingZone.rightMargin:
        return 'right_margin';
      case DrawingZone.contentOverlay:
        return 'content_overlay';
    }
  }

  static DrawingZone fromString(String value) {
    switch (value) {
      case 'left_margin':
        return DrawingZone.leftMargin;
      case 'right_margin':
        return DrawingZone.rightMargin;
      case 'content_overlay':
        return DrawingZone.contentOverlay;
      default:
        return DrawingZone.contentOverlay;
    }
  }
}

/// Style of stroke rendering
enum StrokeStyle {
  pen,
  highlighter,
  pencil;

  String get value {
    switch (this) {
      case StrokeStyle.pen:
        return 'pen';
      case StrokeStyle.highlighter:
        return 'highlighter';
      case StrokeStyle.pencil:
        return 'pencil';
    }
  }

  static StrokeStyle fromString(String value) {
    switch (value) {
      case 'pen':
        return StrokeStyle.pen;
      case 'highlighter':
        return StrokeStyle.highlighter;
      case 'pencil':
        return StrokeStyle.pencil;
      default:
        return StrokeStyle.pen;
    }
  }
}

/// A single point in a drawing stroke
@immutable
class DrawingPoint {
  /// Position relative to anchor (normalized coordinates 0.0 - 1.0)
  final DrawingOffset position;

  /// Pressure sensitivity (0.0 - 1.0) for stylus support
  final double pressure;

  /// Stylus tilt in X direction (-1.0 to 1.0)
  final double tiltX;

  /// Stylus tilt in Y direction (-1.0 to 1.0)
  final double tiltY;

  const DrawingPoint({
    required this.position,
    this.pressure = 1.0,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'p': pressure,
      'tx': tiltX,
      'ty': tiltY,
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      position: DrawingOffset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      pressure: (json['p'] as num?)?.toDouble() ?? 1.0,
      tiltX: (json['tx'] as num?)?.toDouble() ?? 0.0,
      tiltY: (json['ty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// A continuous stroke in a drawing
@immutable
class DrawingStroke {
  /// Points that make up this stroke
  final List<DrawingPoint> points;

  /// Color of this stroke as an ARGB integer.
  final int colorValue;

  /// Width of the stroke
  final double width;

  /// Visual style of the stroke
  final StrokeStyle style;

  const DrawingStroke({
    required this.points,
    required this.colorValue,
    required this.width,
    this.style = StrokeStyle.pen,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'color': colorValue,
      'width': width,
      'style': style.value,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      colorValue: json['color'] as int,
      width: (json['width'] as num).toDouble(),
      style: StrokeStyle.fromString(json['style'] as String? ?? 'pen'),
    );
  }
}

/// A vector-based drawing anchored to Bible content
@immutable
class Drawing extends SyncableEntity {
  /// Reference to the passage this drawing is anchored to
  final PassageReference reference;

  /// Optional word index within the verse to anchor to
  final int? anchorWordIndex;

  /// Zone where this drawing is positioned
  final DrawingZone zone;

  /// Collection of strokes that make up this drawing
  final List<DrawingStroke> strokes;

  /// Anchor offset as percentage of viewport (0.0 - 1.0)
  final DrawingOffset anchorOffset;

  /// Base text size when drawing was created (for scaling)
  final double baseTextSize;

  /// Default color for the drawing as an ARGB integer.
  final int colorValue;

  /// Default stroke width (strokes can override)
  final double strokeWidth;

  /// Whether this drawing is shared publicly
  final bool isPublic;

  /// User ID who shared this (if imported from community)
  final String? sharedFromUserId;

  const Drawing({
    required super.id,
    required super.createdAt,
    required super.modifiedAt,
    super.userId,
    super.isDeleted,
    super.version,
    super.syncStatus,
    required this.reference,
    this.anchorWordIndex,
    required this.zone,
    required this.strokes,
    required this.anchorOffset,
    required this.baseTextSize,
    required this.colorValue,
    required this.strokeWidth,
    this.isPublic = false,
    this.sharedFromUserId,
  });

  factory Drawing.create({
    required PassageReference reference,
    int? anchorWordIndex,
    required DrawingZone zone,
    required List<DrawingStroke> strokes,
    required DrawingOffset anchorOffset,
    required double baseTextSize,
    int colorValue = 0xFF000000,
    double strokeWidth = 2.0,
    String? userId,
  }) {
    final now = DateTime.now();
    return Drawing(
      id: SyncableEntity.generateId(),
      createdAt: now,
      modifiedAt: now,
      userId: userId,
      reference: reference,
      anchorWordIndex: anchorWordIndex,
      zone: zone,
      strokes: strokes,
      anchorOffset: anchorOffset,
      baseTextSize: baseTextSize,
      colorValue: colorValue,
      strokeWidth: strokeWidth,
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
      'anchor_word_index': anchorWordIndex,
      'zone': zone.value,
      'anchor_offset_x': anchorOffset.dx,
      'anchor_offset_y': anchorOffset.dy,
      'base_text_size': baseTextSize,
      'color': colorValue,
      'stroke_width': strokeWidth,
      'strokes_json': jsonEncode(strokes.map((s) => s.toJson()).toList()),
      'is_public': isPublic ? 1 : 0,
      'shared_from_user_id': sharedFromUserId,
    };
  }

  factory Drawing.fromJson(Map<String, dynamic> json) {
    final strokesJson = jsonDecode(json['strokes_json'] as String) as List;
    return Drawing(
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
        startVerse: json['verse_start'] as int? ?? 0,
        endVerse: json['verse_end'] as int?,
      ),
      anchorWordIndex: json['anchor_word_index'] as int?,
      zone: DrawingZone.fromString(json['zone'] as String),
      strokes: strokesJson
          .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      anchorOffset: DrawingOffset(
        (json['anchor_offset_x'] as num).toDouble(),
        (json['anchor_offset_y'] as num).toDouble(),
      ),
      baseTextSize: (json['base_text_size'] as num).toDouble(),
      colorValue: json['color'] as int,
      strokeWidth: (json['stroke_width'] as num).toDouble(),
      isPublic: (json['is_public'] as int?) == 1,
      sharedFromUserId: json['shared_from_user_id'] as String?,
    );
  }

  Drawing copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? userId,
    bool? isDeleted,
    int? version,
    String? syncStatus,
    PassageReference? reference,
    int? anchorWordIndex,
    DrawingZone? zone,
    List<DrawingStroke>? strokes,
    DrawingOffset? anchorOffset,
    double? baseTextSize,
    int? colorValue,
    double? strokeWidth,
    bool? isPublic,
    String? sharedFromUserId,
  }) {
    return Drawing(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      reference: reference ?? this.reference,
      anchorWordIndex: anchorWordIndex ?? this.anchorWordIndex,
      zone: zone ?? this.zone,
      strokes: strokes ?? this.strokes,
      anchorOffset: anchorOffset ?? this.anchorOffset,
      baseTextSize: baseTextSize ?? this.baseTextSize,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isPublic: isPublic ?? this.isPublic,
      sharedFromUserId: sharedFromUserId ?? this.sharedFromUserId,
    );
  }
}
