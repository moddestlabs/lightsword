import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_core/bible_core.dart';

/// Local implementation of ReadingHistoryRepository backed by SharedPreferences
class LocalReadingHistoryService implements ReadingHistoryRepository {
  static const String _historyKey = 'reading_history_entries';
  static const int _maxEntries = 500;

  static LocalReadingHistoryService? _instance;
  static LocalReadingHistoryService get instance {
    _instance ??= LocalReadingHistoryService._();
    return _instance!;
  }

  LocalReadingHistoryService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> addVisit({
    required PassageReference reference,
    String? sourceId,
  }) async {
    final prefs = await _getPrefs();
    final history = await getHistory();
    final now = DateTime.now();

    // Check for debouncing / deduplication with most recent entry
    if (history.isNotEmpty) {
      final latest = history.first;
      final isSamePassage = latest.reference == reference;
      final timeDiff = now.difference(latest.timestamp);

      // If visited same passage within 5 minutes, update timestamp instead of duplicating
      if (isSamePassage && timeDiff.inMinutes < 5) {
        final updatedEntry = HistoryEntry(
          id: latest.id,
          reference: reference,
          timestamp: now,
          sourceId: sourceId ?? latest.sourceId,
        );
        history[0] = updatedEntry;
        await _saveHistory(prefs, history);
        return;
      }
    }

    final newEntry = HistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      reference: reference,
      timestamp: now,
      sourceId: sourceId,
    );

    history.insert(0, newEntry);

    if (history.length > _maxEntries) {
      history.removeRange(_maxEntries, history.length);
    }

    await _saveHistory(prefs, history);
  }

  @override
  Future<List<HistoryEntry>> getHistory() async {
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(_historyKey);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(rawJson);
      return jsonList
          .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to decode reading history: $e');
      return [];
    }
  }

  @override
  Future<Map<DateTime, List<HistoryEntry>>> getGroupedHistory() async {
    final history = await getHistory();
    return groupEntriesByDay(history);
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_historyKey);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final prefs = await _getPrefs();
    final history = await getHistory();
    history.removeWhere((entry) => entry.id == id);
    await _saveHistory(prefs, history);
  }

  Future<void> _saveHistory(
    SharedPreferences prefs,
    List<HistoryEntry> history,
  ) async {

    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }
}
