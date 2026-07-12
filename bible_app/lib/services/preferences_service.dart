import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:bible_app/ui/models/chapter_view_definition.dart';

/// Service for managing user preferences and settings
class PreferencesService {
  static const String _themeModeKey = 'theme_mode';
  static const String _appearancePaletteKey = 'appearance_palette';
  static const String _lastBookIdKey = 'last_book_id';
  static const String _lastChapterKey = 'last_chapter';
  static const String _lastStartVerseKey = 'last_start_verse';
  static const String _lastEndVerseKey = 'last_end_verse';
  static const String _customChapterViewsKey = 'custom_chapter_views';
  static const String _selectedChapterViewIdKey = 'selected_chapter_view_id';
  static const String _selectedTextSourceKey = 'selected_text_source';
  static const String _selectedTtsVoiceEnglishKey =
      'selected_tts_voice_english';
  static const String _selectedTtsVoiceHebrewKey = 'selected_tts_voice_hebrew';
  static const String _selectedTtsVoiceGreekKey = 'selected_tts_voice_greek';

  static PreferencesService? _instance;
  static PreferencesService get instance {
    _instance ??= PreferencesService._();
    return _instance!;
  }

  PreferencesService._();

  SharedPreferences? _prefs;

  /// Initialize the preferences service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the saved theme mode
  /// Returns null if not set (defaults to system)
  ThemeMode? getThemeMode() {
    if (_prefs == null) return null;

    final themeModeString = _prefs!.getString(_themeModeKey);
    if (themeModeString == null) return null;

    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Save the theme mode preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_prefs == null) return;

    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }

    await _prefs!.setString(_themeModeKey, modeString);
  }

  /// Get the saved appearance palette id.
  /// Returns null if not set.
  String? getAppearancePalette() {
    if (_prefs == null) return null;
    return _prefs!.getString(_appearancePaletteKey);
  }

  /// Save the appearance palette id.
  Future<void> setAppearancePalette(String paletteId) async {
    if (_prefs == null) return;
    await _prefs!.setString(_appearancePaletteKey, paletteId);
  }

  String? getLastBookId() {
    if (_prefs == null) return null;
    return _prefs!.getString(_lastBookIdKey);
  }

  int? getLastChapter() {
    if (_prefs == null) return null;
    return _prefs!.getInt(_lastChapterKey);
  }

  int? getLastStartVerse() {
    if (_prefs == null) return null;
    return _prefs!.getInt(_lastStartVerseKey);
  }

  int? getLastEndVerse() {
    if (_prefs == null) return null;
    return _prefs!.getInt(_lastEndVerseKey);
  }

  Future<void> setLastReadingLocation({
    required String bookId,
    required int chapter,
    int? startVerse,
    int? endVerse,
  }) async {
    if (_prefs == null) return;

    await _prefs!.setString(_lastBookIdKey, bookId);
    await _prefs!.setInt(_lastChapterKey, chapter);

    if (startVerse == null) {
      await _prefs!.remove(_lastStartVerseKey);
    } else {
      await _prefs!.setInt(_lastStartVerseKey, startVerse);
    }

    if (endVerse == null) {
      await _prefs!.remove(_lastEndVerseKey);
    } else {
      await _prefs!.setInt(_lastEndVerseKey, endVerse);
    }
  }

  /// Get all saved custom chapter views.
  List<ChapterViewDefinition> getCustomChapterViews() {
    if (_prefs == null) return const [];

    return ChapterViewDefinition.decodeList(
      _prefs!.getString(_customChapterViewsKey),
    );
  }

  /// Save custom chapter views.
  Future<void> setCustomChapterViews(List<ChapterViewDefinition> views) async {
    if (_prefs == null) return;

    await _prefs!.setString(
      _customChapterViewsKey,
      ChapterViewDefinition.encodeList(views),
    );
  }

  /// Get the selected chapter view id.
  String? getSelectedChapterViewId() {
    if (_prefs == null) return null;
    return _prefs!.getString(_selectedChapterViewIdKey);
  }

  /// Save the selected chapter view id.
  Future<void> setSelectedChapterViewId(String viewId) async {
    if (_prefs == null) return;
    await _prefs!.setString(_selectedChapterViewIdKey, viewId);
  }

  String? getSelectedTextSource() {
    if (_prefs == null) return null;
    return _prefs!.getString(_selectedTextSourceKey);
  }

  Future<void> setSelectedTextSource(String sourceId) async {
    if (_prefs == null) return;
    await _prefs!.setString(_selectedTextSourceKey, sourceId);
  }

  String? getSelectedTtsVoiceId(String languageFamily) {
    if (_prefs == null) return null;
    return _prefs!.getString(_ttsVoiceKeyFor(languageFamily));
  }

  Future<void> setSelectedTtsVoiceId(
    String languageFamily,
    String? voiceId,
  ) async {
    if (_prefs == null) return;

    final key = _ttsVoiceKeyFor(languageFamily);
    if (voiceId == null || voiceId.isEmpty) {
      await _prefs!.remove(key);
      return;
    }

    await _prefs!.setString(key, voiceId);
  }

  String _ttsVoiceKeyFor(String languageFamily) {
    switch (languageFamily) {
      case 'he':
        return _selectedTtsVoiceHebrewKey;
      case 'el':
        return _selectedTtsVoiceGreekKey;
      case 'en':
      default:
        return _selectedTtsVoiceEnglishKey;
    }
  }
}
