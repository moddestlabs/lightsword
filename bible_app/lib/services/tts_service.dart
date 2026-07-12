import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bible_core/tts/tts_engine.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_app/platform/tts/flutter_tts_engine.dart';
import 'package:bible_app/platform/tts/language_detector.dart';
import 'package:bible_app/services/preferences_service.dart';

/// Service for managing text-to-speech functionality
/// Handles reading verses with automatic language detection
class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._internal();
  static TtsService get instance => _instance;

  final FlutterTtsEngine _engine = FlutterTtsEngine();

  bool _isPlaying = false;
  bool _isPaused = false;
  double _rate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  final Map<String, List<TtsVoice>> _voicesByLanguageFamily = {
    'en': const [],
    'he': const [],
    'el': const [],
  };
  final Map<String, TtsVoice?> _selectedVoices = {
    'en': null,
    'he': null,
    'el': null,
  };

  List<Verse> _currentVerses = [];
  int _currentVerseIndex = 0;
  int? _currentStandaloneVerseNumber;
  String? _detectedLanguage;
  bool _stopRequested = false;
  bool _isSequencePlayback = false;
  int _currentUtterancePrefixLength = 0;
  TtsProgressState? _progressState;

  // Callback for showing user notifications
  Function(String message)? onShowNotification;

  TtsService._internal() {
    // Set up completion handler for sequential verse reading
    _engine.setCompletionHandler(_onSpeechComplete);
    _engine.setProgressHandler(_onSpeechProgress);
    _engine.setErrorHandler((error) {
      debugPrint('TTS Error: $error');
      _onSpeechComplete(); // Continue to next verse on error
    });
  }

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;
  int get currentVerseIndex => _currentVerseIndex;
  int? get currentVerseNumber {
    if (_isSequencePlayback &&
        _currentVerseIndex >= 0 &&
        _currentVerseIndex < _currentVerses.length) {
      return _currentVerses[_currentVerseIndex].number;
    }
    return _currentStandaloneVerseNumber;
  }

  String? get detectedLanguage => _detectedLanguage;
  TtsProgressState? get progressState => _progressState;
  List<TtsVoice> get englishVoices =>
      List.unmodifiable(_voicesByLanguageFamily['en']!);
  List<TtsVoice> get hebrewVoices =>
      List.unmodifiable(_voicesByLanguageFamily['he']!);
  List<TtsVoice> get greekVoices =>
      List.unmodifiable(_voicesByLanguageFamily['el']!);
  TtsVoice? get selectedEnglishVoice => _selectedVoices['en'];
  TtsVoice? get selectedHebrewVoice => _selectedVoices['he'];
  TtsVoice? get selectedGreekVoice => _selectedVoices['el'];

  /// Initialize the TTS engine with saved settings
  Future<void> initialize() async {
    await _engine.setRate(_rate);
    await _engine.setPitch(_pitch);
    await _engine.setVolume(_volume);
    await refreshAvailableVoices();
  }

  /// Speak a single text with auto-detected language
  Future<void> speak(
    String text, {
    int? verseNumber,
    String? transliteration,
    bool showNotification = false,
  }) async {
    if (text.isEmpty) return;

    debugPrint('🔊 TTS speak called with text length: ${text.length}');
    debugPrint(
        '🔊 Text preview: ${text.substring(0, text.length > 50 ? 50 : text.length)}');

    final languageCode = LanguageDetector.detect(text);
    _detectedLanguage = languageCode;

    debugPrint('🔊 Detected language: $languageCode');

    await _engine.stop();
    _stopRequested = false;
    _isSequencePlayback = false;
    _currentVerses = [];
    _currentVerseIndex = 0;
    _currentStandaloneVerseNumber = verseNumber;
    _currentUtterancePrefixLength = 0;
    _progressState = null;

    // For Hebrew/Greek, check if voice is actually available before trying
    bool shouldTryNativeVoice = true;
    final selectedVoice = _voiceForLanguageCode(languageCode);
    if (languageCode == 'he-IL' || languageCode == 'el-GR') {
      final availableVoices = getAvailableVoicesForLanguage(languageCode);
      final hasVoice = availableVoices.isNotEmpty;

      debugPrint('🔊 Native voice available for $languageCode: $hasVoice');

      if (!hasVoice && transliteration != null) {
        // No native voice available, use transliteration directly
        shouldTryNativeVoice = false;
        debugPrint('🔊 No native voice found, using transliteration directly');
        _detectedLanguage = 'en-US (transliterated from $languageCode)';

        final langName = languageCode == 'he-IL' ? 'Hebrew' : 'Greek';
        onShowNotification?.call(
            'No $langName voice found. Reading transliteration instead.\n'
            'Install $langName language pack in your system settings for native pronunciation.');

        await _engine.speak(
          transliteration,
          languageCode: 'en-US',
          voice: _voiceForLanguageCode('en-US'),
        );
      } else if (!hasVoice) {
        // No native voice and no transliteration
        final langName = LanguageDetector.getLanguageName(languageCode);
        onShowNotification?.call(
          'No $langName voice available. Please install language packs in your system settings.',
        );
        return;
      }
    }

    // Try speaking in the detected language if we should
    if (shouldTryNativeVoice) {
      final success = await _engine.speak(
        text,
        languageCode: languageCode,
        voice: selectedVoice,
      );

      if (!success) {
        // This should rarely happen now, but handle it just in case
        debugPrint('⚠️ speak() returned false unexpectedly');
        if (transliteration != null &&
            (languageCode == 'he-IL' || languageCode == 'el-GR')) {
          _detectedLanguage = 'en-US (transliterated from $languageCode)';
          await _engine.speak(
            transliteration,
            languageCode: 'en-US',
            voice: _voiceForLanguageCode('en-US'),
          );
        }
      }
    }

    _isPlaying = true;
    _isPaused = false;
    notifyListeners();
  }

  /// Read a list of verses sequentially
  Future<void> readVerses(List<Verse> verses, {int startIndex = 0}) async {
    if (verses.isEmpty) return;

    await _engine.stop();
    _currentVerses = verses;
    _currentVerseIndex = startIndex;
    _currentStandaloneVerseNumber = null;
    _stopRequested = false;
    _isSequencePlayback = true;
    _progressState = null;

    await _readCurrentVerse();
  }

  /// Read the current verse in the sequence
  Future<void> _readCurrentVerse() async {
    if (_stopRequested || _currentVerseIndex >= _currentVerses.length) {
      // Finished reading all verses
      await stop();
      return;
    }

    final verse = _currentVerses[_currentVerseIndex];
    final text = '${verse.number}. ${verse.text}';
    _currentUtterancePrefixLength = '${verse.number}. '.length;
    _progressState = null;

    final languageCode = LanguageDetector.detect(verse.text);
    _detectedLanguage = languageCode;

    await _engine.speak(
      text,
      languageCode: languageCode,
      voice: _voiceForLanguageCode(languageCode),
    );

    _isPlaying = true;
    _isPaused = false;
    notifyListeners();
  }

  /// Called when TTS completes speaking
  void _onSpeechComplete() {
    if (_stopRequested) {
      return;
    }

    if (!_isSequencePlayback || _currentVerses.isEmpty) {
      _finishPlaybackState();
      return;
    }

    // Move to next verse
    _currentVerseIndex++;

    if (_currentVerseIndex < _currentVerses.length) {
      // Continue with next verse
      _readCurrentVerse();
    } else {
      // All verses completed. Clear UI state immediately so the overlay hides
      // even if the platform stop call lags behind the completion callback.
      _finishPlaybackState();
    }
  }

  void _finishPlaybackState() {
    _stopRequested = true;
    _isPlaying = false;
    _isPaused = false;
    _isSequencePlayback = false;
    _currentVerses = [];
    _currentVerseIndex = 0;
    _currentStandaloneVerseNumber = null;
    _currentUtterancePrefixLength = 0;
    _detectedLanguage = null;
    _progressState = null;
    notifyListeners();
  }

  void _onSpeechProgress(String text, int start, int end, String word) {
    if (_stopRequested) {
      return;
    }

    final verseNumber = currentVerseNumber;
    final fullText = _isSequencePlayback &&
            _currentVerseIndex >= 0 &&
            _currentVerseIndex < _currentVerses.length
        ? _currentVerses[_currentVerseIndex].text
        : text;

    final normalizedStart =
        (start - _currentUtterancePrefixLength).clamp(0, fullText.length);
    final normalizedEnd =
        (end - _currentUtterancePrefixLength).clamp(0, fullText.length);

    if (normalizedEnd <= 0 || normalizedStart >= normalizedEnd) {
      return;
    }

    final nextState = TtsProgressState(
      verseNumber: verseNumber,
      text: fullText,
      startOffset: normalizedStart,
      endOffset: normalizedEnd,
      word: word,
    );

    if (_progressState == nextState) {
      return;
    }

    _progressState = nextState;
    notifyListeners();
  }

  /// Stop reading
  Future<void> stop() async {
    final wasActive = _isPlaying || _isPaused || _currentVerses.isNotEmpty;
    _finishPlaybackState();
    await _engine.stop();
    if (!wasActive) {
      notifyListeners();
    }
  }

  /// Pause reading (not fully supported by all platforms)
  Future<void> pause() async {
    await _engine.pause();
    _isPaused = true;
    _isPlaying = false;
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else if (_isPaused && _currentVerses.isNotEmpty) {
      // Resume reading from current position
      await _readCurrentVerse();
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 1.0);
    await _engine.setRate(_rate);
    notifyListeners();
  }

  /// Set speech pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _engine.setPitch(_pitch);
    notifyListeners();
  }

  /// Set speech volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _engine.setVolume(_volume);
    notifyListeners();
  }

  /// Get available languages
  Future<List<TtsLanguage>> getAvailableLanguages() async {
    return await _engine.availableLanguages();
  }

  Future<void> refreshAvailableVoices() async {
    final voices = await _engine.availableVoices();

    _voicesByLanguageFamily['en'] = _filterVoices(voices, 'en');
    _voicesByLanguageFamily['he'] = _filterVoices(voices, 'he');
    _voicesByLanguageFamily['el'] = _filterVoices(voices, 'el');

    for (final languageFamily in _voicesByLanguageFamily.keys) {
      final savedVoiceId =
          PreferencesService.instance.getSelectedTtsVoiceId(languageFamily);
      final matchingVoice = _voicesByLanguageFamily[languageFamily]!
          .where((voice) => voice.id == savedVoiceId)
          .cast<TtsVoice?>()
          .firstWhere((voice) => voice != null, orElse: () => null);
      _selectedVoices[languageFamily] = matchingVoice;
    }

    notifyListeners();
  }

  List<TtsVoice> getAvailableVoicesForLanguage(String languageCode) {
    return List.unmodifiable(
        _voicesByLanguageFamily[_languageFamilyFor(languageCode)] ?? const []);
  }

  TtsVoice? getSelectedVoiceForLanguage(String languageCode) {
    return _voiceForLanguageCode(languageCode);
  }

  Future<void> selectVoiceForLanguage(
      String languageCode, TtsVoice? voice) async {
    final languageFamily = _languageFamilyFor(languageCode);
    _selectedVoices[languageFamily] = voice;
    await PreferencesService.instance
        .setSelectedTtsVoiceId(languageFamily, voice?.id);
    notifyListeners();
  }

  /// Get current language display name
  String getCurrentLanguageName() {
    if (_detectedLanguage == null) return 'Auto';
    if (_detectedLanguage!.contains('transliterated')) {
      // Extract the original language from format like "en-US (transliterated from he-IL)"
      if (_detectedLanguage!.contains('he-IL')) {
        return 'Hebrew (transliterated)';
      } else if (_detectedLanguage!.contains('el-GR')) {
        return 'Greek (transliterated)';
      }
      return 'Transliterated';
    }
    return LanguageDetector.getLanguageName(_detectedLanguage!);
  }

  List<TtsVoice> _filterVoices(List<TtsVoice> voices, String languageFamily) {
    return voices.where((voice) {
      final voiceFamily = _languageFamilyFor(voice.locale);
      return voiceFamily == languageFamily;
    }).toList();
  }

  String _languageFamilyFor(String languageCode) {
    final normalized = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    switch (normalized) {
      case 'he':
        return 'he';
      case 'el':
        return 'el';
      case 'en':
      default:
        return 'en';
    }
  }

  TtsVoice? _voiceForLanguageCode(String languageCode) {
    return _selectedVoices[_languageFamilyFor(languageCode)];
  }
}

class TtsProgressState {
  final int? verseNumber;
  final String text;
  final int startOffset;
  final int endOffset;
  final String word;

  const TtsProgressState({
    required this.verseNumber,
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.word,
  });

  @override
  bool operator ==(Object other) {
    return other is TtsProgressState &&
        other.verseNumber == verseNumber &&
        other.text == text &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.word == word;
  }

  @override
  int get hashCode => Object.hash(
        verseNumber,
        text,
        startOffset,
        endOffset,
        word,
      );
}
