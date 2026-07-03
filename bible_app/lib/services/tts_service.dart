import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bible_core/tts/tts_engine.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_app/platform/tts/flutter_tts_engine.dart';
import 'package:bible_app/platform/tts/language_detector.dart';

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
  
  List<Verse> _currentVerses = [];
  int _currentVerseIndex = 0;
  String? _detectedLanguage;
  bool _stopRequested = false;
  
  // Callback for showing user notifications
  Function(String message)? onShowNotification;
  
  TtsService._internal() {
    // Set up completion handler for sequential verse reading
    _engine.setCompletionHandler(_onSpeechComplete);
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
  String? get detectedLanguage => _detectedLanguage;
  
  /// Initialize the TTS engine with saved settings
  Future<void> initialize() async {
    await _engine.setRate(_rate);
    await _engine.setPitch(_pitch);
    await _engine.setVolume(_volume);
  }
  
  /// Speak a single text with auto-detected language
  Future<void> speak(String text, {String? transliteration, bool showNotification = false}) async {
    if (text.isEmpty) return;
    
    debugPrint('🔊 TTS speak called with text length: ${text.length}');
    debugPrint('🔊 Text preview: ${text.substring(0, text.length > 50 ? 50 : text.length)}');
    
    final languageCode = LanguageDetector.detect(text);
    _detectedLanguage = languageCode;
    
    debugPrint('🔊 Detected language: $languageCode');
    
    await _engine.stop();
    
    // Try speaking in the detected language
    final success = await _engine.speak(text, languageCode: languageCode);
    
    // If Hebrew/Greek failed and we have transliteration, try that instead
    if (!success && transliteration != null && (languageCode == 'he-IL' || languageCode == 'el-GR')) {
      debugPrint('⚠️ Original language failed, using transliteration');
      _detectedLanguage = 'en-US (transliterated from $languageCode)';
      
      final langName = languageCode == 'he-IL' ? 'Hebrew' : 'Greek';
      onShowNotification?.call(
        'No $langName voice found. Reading transliteration instead.\n'
        'Install $langName language pack in your system settings for native pronunciation.'
      );
      
      await _engine.speak(transliteration, languageCode: 'en-US');
    } else if (!success) {
      // Failed without transliteration available
      final langName = LanguageDetector.getLanguageName(languageCode);
      onShowNotification?.call(
        'No $langName voice available. Please install language packs in your system settings.'
      );
    }
    
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();
  }
  
  /// Read a list of verses sequentially
  Future<void> readVerses(List<Verse> verses, {int startIndex = 0}) async {
    if (verses.isEmpty) return;
    
    _currentVerses = verses;
    _currentVerseIndex = startIndex;
    _stopRequested = false;
    
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
    
    final languageCode = LanguageDetector.detect(verse.text);
    _detectedLanguage = languageCode;
    
    await _engine.speak(text, languageCode: languageCode);
    
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();
  }
  
  /// Called when TTS completes speaking
  void _onSpeechComplete() {
    if (_stopRequested || _currentVerses.isEmpty) {
      return;
    }
    
    // Move to next verse
    _currentVerseIndex++;
    
    if (_currentVerseIndex < _currentVerses.length) {
      // Continue with next verse
      _readCurrentVerse();
    } else {
      // All verses completed
      stop();
    }
  }
  
  /// Stop reading
  Future<void> stop() async {
    _stopRequested = true;
    await _engine.stop();
    _isPlaying = false;
    _isPaused = false;
    _currentVerses = [];
    _currentVerseIndex = 0;
    _detectedLanguage = null;
    notifyListeners();
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
}
