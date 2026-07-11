import 'package:meta/meta.dart';

/// Base class for all user-generated content that can be synced
@immutable
abstract class SyncableEntity {
  /// Globally unique identifier (UUID)
  final String id;

  /// When this entity was created
  final DateTime createdAt;

  /// When this entity was last modified
  final DateTime modifiedAt;

  /// User ID for multi-user scenarios (optional for now)
  final String? userId;

  /// Soft delete flag for sync compatibility
  final bool isDeleted;

  /// Version number for optimistic locking and conflict resolution
  final int version;

  /// Sync status: 'local', 'synced', 'pending', 'conflict'
  final String syncStatus;

  const SyncableEntity({
    required this.id,
    required this.createdAt,
    required this.modifiedAt,
    this.userId,
    this.isDeleted = false,
    this.version = 1,
    this.syncStatus = 'local',
  });

  /// Convert to JSON for persistence and sharing
  Map<String, dynamic> toJson();

  /// Generate a new UUID for entities
  static String generateId() {
    // Simple UUID-like generator using timestamp and random
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecondsSinceEpoch % 100000).toString();
    return '$timestamp-$random';
  }
}
