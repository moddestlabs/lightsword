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
  static const double _defaultRate = 0.5;
  static const double _defaultPitch = 1.0;
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

  List<TtsUtterance> _currentUtterances = [];
  int _currentUtteranceIndex = 0;
  String? _detectedLanguage;
  String? _currentProfileKey;
  bool _stopRequested = false;
  TtsProgressState? _progressState;
  final Map<String, double> _ratesByProfile = {};
  final Map<String, double> _pitchesByProfile = {};

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
  double get rate => rateForLanguage('en-US');
  double get pitch => pitchForLanguage('en-US');
  double get volume => _volume;
  int get currentVerseIndex => _currentUtteranceIndex;
  int? get currentVerseNumber {
    if (_currentUtteranceIndex >= 0 &&
        _currentUtteranceIndex < _currentUtterances.length) {
      return _currentUtterances[_currentUtteranceIndex].verseNumber;
    }
    return null;
  }

  String? get detectedLanguage => _detectedLanguage;
  TtsProgressState? get progressState => _progressState;
  TtsContentType? get currentContentType {
    if (_currentUtteranceIndex >= 0 &&
        _currentUtteranceIndex < _currentUtterances.length) {
      return _currentUtterances[_currentUtteranceIndex].contentType;
    }
    return null;
  }

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
    await _engine.setRate(_defaultRate);
    await _engine.setPitch(_defaultPitch);
    await _engine.setVolume(_volume);
    await refreshAvailableVoices();
  }

  /// Speak a single text with auto-detected language
  Future<void> speak(
    String text, {
    int? verseNumber,
    String? transliteration,
    TtsContentType contentType = TtsContentType.translation,
    String? progressKey,
    bool showNotification = false,
  }) async {
    await readUtterances([
      TtsUtterance(
        text: text,
        verseNumber: verseNumber,
        contentType: contentType,
        progressKey: progressKey,
        transliteration: transliteration,
      ),
    ]);
  }

  /// Read a list of verses sequentially
  Future<void> readVerses(List<Verse> verses, {int startIndex = 0}) async {
    if (verses.isEmpty) return;

    final utterances = <TtsUtterance>[];
    for (final verse in verses.skip(startIndex)) {
      utterances.add(
        TtsUtterance(
          text: 'Verse ${verse.number}.',
          verseNumber: verse.number,
          contentType: TtsContentType.verseNumber,
          languageCode: 'en-US',
        ),
      );
      utterances.add(
        TtsUtterance(
          text: verse.text,
          verseNumber: verse.number,
          contentType: TtsContentType.translation,
        ),
      );
    }

    await readUtterances(utterances);
  }

  Future<void> readUtterances(List<TtsUtterance> utterances) async {
    if (utterances.isEmpty) {
      return;
    }

    await _engine.stop();
    _currentUtterances = utterances;
    _currentUtteranceIndex = 0;
    _stopRequested = false;
    _progressState = null;

    await _readCurrentUtterance();
  }

  /// Read the current utterance in the sequence
  Future<void> _readCurrentUtterance() async {
    if (_stopRequested || _currentUtteranceIndex >= _currentUtterances.length) {
      await stop();
      return;
    }

    final utterance = _currentUtterances[_currentUtteranceIndex];
    await _speakUtterance(utterance);
  }

  /// Called when TTS completes speaking
  void _onSpeechComplete() {
    if (_stopRequested) {
      return;
    }

    if (_currentUtterances.isEmpty) {
      _finishPlaybackState();
      return;
    }

    _currentUtteranceIndex++;

    if (_currentUtteranceIndex < _currentUtterances.length) {
      _readCurrentUtterance();
    } else {
      _finishPlaybackState();
    }
  }

  void _finishPlaybackState() {
    _stopRequested = true;
    _isPlaying = false;
    _isPaused = false;
    _currentUtterances = [];
    _currentUtteranceIndex = 0;
    _currentProfileKey = null;
    _detectedLanguage = null;
    _progressState = null;
    notifyListeners();
  }

  void _onSpeechProgress(String text, int start, int end, String word) {
    if (_stopRequested) {
      return;
    }

    if (_currentUtteranceIndex < 0 ||
        _currentUtteranceIndex >= _currentUtterances.length) {
      return;
    }

    final utterance = _currentUtterances[_currentUtteranceIndex];
    final fullText = utterance.progressText ?? utterance.text;

    final normalizedStart = start.clamp(0, fullText.length);
    final normalizedEnd = end.clamp(0, fullText.length);

    if (normalizedEnd <= 0 || normalizedStart >= normalizedEnd) {
      return;
    }

    final nextState = TtsProgressState(
      verseNumber: utterance.verseNumber,
      text: fullText,
      contentType: utterance.contentType,
      progressKey: utterance.progressKey,
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
    final wasActive = _isPlaying || _isPaused || _currentUtterances.isNotEmpty;
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
    } else if (_isPaused && _currentUtterances.isNotEmpty) {
      await _readCurrentUtterance();
    }
  }

  Future<void> _speakUtterance(TtsUtterance utterance) async {
    if (utterance.text.isEmpty) {
      _onSpeechComplete();
      return;
    }

    debugPrint(
      '🔊 TTS speak called with text length: ${utterance.text.length}',
    );
    debugPrint(
      '🔊 Text preview: ${utterance.text.substring(0, utterance.text.length > 50 ? 50 : utterance.text.length)}',
    );

    final languageCode =
        utterance.languageCode ?? LanguageDetector.detect(utterance.text);
    _detectedLanguage = languageCode;
    _currentProfileKey = _profileKeyForUtterance(utterance, languageCode);

    await _engine.setRate(_rateForProfileKey(_currentProfileKey!));
    await _engine.setPitch(_pitchForProfileKey(_currentProfileKey!));

    debugPrint('🔊 Detected language: $languageCode');

    _progressState = null;

    bool shouldTryNativeVoice = true;
    final selectedVoice = _voiceForLanguageCode(languageCode);
    if (languageCode == 'he-IL' || languageCode == 'el-GR') {
      final availableVoices = getAvailableVoicesForLanguage(languageCode);
      final hasVoice = availableVoices.isNotEmpty;

      debugPrint('🔊 Native voice available for $languageCode: $hasVoice');

      if (!hasVoice && utterance.transliteration != null) {
        shouldTryNativeVoice = false;
        debugPrint('🔊 No native voice found, using transliteration directly');
        _detectedLanguage = 'en-US (transliterated from $languageCode)';

        final langName = languageCode == 'he-IL' ? 'Hebrew' : 'Greek';
        onShowNotification?.call(
          'No $langName voice found. Reading transliteration instead.\n'
          'Install $langName language pack in your system settings for native pronunciation.',
        );

        await _engine.speak(
          utterance.transliteration!,
          languageCode: 'en-US',
          voice: _voiceForLanguageCode('en-US'),
        );
      } else if (!hasVoice) {
        final langName = LanguageDetector.getLanguageName(languageCode);
        onShowNotification?.call(
          'No $langName voice available. Please install language packs in your system settings.',
        );
        _onSpeechComplete();
        return;
      }
    }

    if (shouldTryNativeVoice) {
      final success = await _engine.speak(
        utterance.text,
        languageCode: languageCode,
        voice: selectedVoice,
      );

      if (!success) {
        debugPrint('⚠️ speak() returned false unexpectedly');
        if (utterance.transliteration != null &&
            (languageCode == 'he-IL' || languageCode == 'el-GR')) {
          _detectedLanguage = 'en-US (transliterated from $languageCode)';
          await _engine.speak(
            utterance.transliteration!,
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

  /// Set speech rate (0.0 to 1.0)
  Future<void> setRate(double rate) async {
    await setRateForLanguage('en-US', rate);
  }

  /// Set speech pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    await setPitchForLanguage('en-US', pitch);
  }

  double rateForLanguage(String languageCode) {
    return _rateForProfileKey(_profileKeyForLanguage(languageCode));
  }

  double pitchForLanguage(String languageCode) {
    return _pitchForProfileKey(_profileKeyForLanguage(languageCode));
  }

  Future<void> setRateForLanguage(String languageCode, double rate) async {
    final profileKey = _profileKeyForLanguage(languageCode);
    final normalizedRate = rate.clamp(0.0, 1.0);
    _ratesByProfile[profileKey] = normalizedRate;
    await PreferencesService.instance.setTtsRate(profileKey, normalizedRate);
    if (_currentProfileKey == profileKey) {
      await _engine.setRate(normalizedRate);
    }
    notifyListeners();
  }

  Future<void> setPitchForLanguage(String languageCode, double pitch) async {
    final profileKey = _profileKeyForLanguage(languageCode);
    final normalizedPitch = pitch.clamp(0.5, 2.0);
    _pitchesByProfile[profileKey] = normalizedPitch;
    await PreferencesService.instance.setTtsPitch(profileKey, normalizedPitch);
    if (_currentProfileKey == profileKey) {
      await _engine.setPitch(normalizedPitch);
    }
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
      _voicesByLanguageFamily[_languageFamilyFor(languageCode)] ?? const [],
    );
  }

  TtsVoice? getSelectedVoiceForLanguage(String languageCode) {
    return _voiceForLanguageCode(languageCode);
  }

  Future<void> selectVoiceForLanguage(
    String languageCode,
    TtsVoice? voice,
  ) async {
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

  String _profileKeyForUtterance(TtsUtterance utterance, String languageCode) {
    if (utterance.profileKey != null && utterance.profileKey!.isNotEmpty) {
      return utterance.profileKey!;
    }
    return _profileKeyForLanguage(languageCode);
  }

  String _profileKeyForLanguage(String languageCode) {
    final family = _languageFamilyFor(languageCode);
    final voice = _selectedVoices[family];
    if (voice != null) {
      return 'voice:${voice.id}';
    }
    return 'auto:$family';
  }

  double _rateForProfileKey(String profileKey) {
    return _ratesByProfile.putIfAbsent(
      profileKey,
      () => PreferencesService.instance.getTtsRate(profileKey) ?? _defaultRate,
    );
  }

  double _pitchForProfileKey(String profileKey) {
    return _pitchesByProfile.putIfAbsent(
      profileKey,
      () => PreferencesService.instance.getTtsPitch(profileKey) ?? _defaultPitch,
    );
  }
}

class TtsProgressState {
  final int? verseNumber;
  final String text;
  final TtsContentType contentType;
  final String? progressKey;
  final int startOffset;
  final int endOffset;
  final String word;

  const TtsProgressState({
    required this.verseNumber,
    required this.text,
    required this.contentType,
    this.progressKey,
    required this.startOffset,
    required this.endOffset,
    required this.word,
  });

  @override
  bool operator ==(Object other) {
    return other is TtsProgressState &&
        other.verseNumber == verseNumber &&
        other.text == text &&
        other.contentType == contentType &&
        other.progressKey == progressKey &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.word == word;
  }

  @override
  int get hashCode => Object.hash(
        verseNumber,
        text,
        contentType,
        progressKey,
        startOffset,
        endOffset,
        word,
      );
}

enum TtsContentType {
  verseNumber,
  originalLanguage,
  translation,
  gloss,
}

class TtsUtterance {
  final String text;
  final int? verseNumber;
  final TtsContentType contentType;
  final String? profileKey;
  final String? progressKey;
  final String? languageCode;
  final String? transliteration;
  final String? progressText;

  const TtsUtterance({
    required this.text,
    this.verseNumber,
    required this.contentType,
    this.profileKey,
    this.progressKey,
    this.languageCode,
    this.transliteration,
    this.progressText,
  });
}
