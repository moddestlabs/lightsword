import 'dart:convert';

import 'package:bible_core/services/bookmark_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBookmarkService implements BookmarkService {
  static const String _storageKey = 'bookmarks';

  static LocalBookmarkService? _instance;
  static LocalBookmarkService get instance {
    _instance ??= LocalBookmarkService._();
    return _instance!;
  }

  LocalBookmarkService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _preferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    final bookmarks = await getBookmarks();
    final updated = [
      ...bookmarks.where(
        (existing) =>
            existing.bookId != bookmark.bookId ||
            existing.chapter != bookmark.chapter ||
            existing.verse != bookmark.verse,
      ),
      bookmark,
    ];
    await _saveBookmarks(updated);
  }

  @override
  Future<List<Bookmark>> getBookmarks() async {
    final prefs = await _preferences();
    final encoded = prefs.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_bookmarkFromJson)
        .toList();
  }

  @override
  Future<bool> isBookmarked(String bookId, int chapter, int verse) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any(
      (bookmark) =>
          bookmark.bookId == bookId &&
          bookmark.chapter == chapter &&
          bookmark.verse == verse,
    );
  }

  @override
  Future<void> removeBookmark(String id) async {
    final bookmarks = await getBookmarks();
    await _saveBookmarks(
      bookmarks.where((bookmark) => bookmark.id != id).toList(),
    );
  }

  Future<void> _saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await _preferences();
    final encoded = jsonEncode(
      bookmarks.map(_bookmarkToJson).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Map<String, dynamic> _bookmarkToJson(Bookmark bookmark) {
    return {
      'id': bookmark.id,
      'bookId': bookmark.bookId,
      'chapter': bookmark.chapter,
      'verse': bookmark.verse,
      'createdAt': bookmark.createdAt.toIso8601String(),
      'note': bookmark.note,
    };
  }

  Bookmark _bookmarkFromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}