import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bible_core/tts/tts_engine.dart';

/// Flutter TTS implementation using flutter_tts package
/// Supports Hebrew (he-IL), Greek (el-GR), and English (en-US)
class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  Function()? _onComplete;
  Function(String)? _onError;
  
  FlutterTtsEngine() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Set default parameters
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    
    // Check available languages on initialization
    try {
      final languages = await _flutterTts.getLanguages;
      print('🔊 TTS Engine initialized');
      print('🔊 Available languages: $languages');
      
      // Check specifically for Hebrew and Greek
      if (languages != null) {
        final langList = languages as List;
        final hasHebrew = langList.any((l) => l.toString().startsWith('he'));
        final hasGreek = langList.any((l) => l.toString().startsWith('el'));
        print('🔊 Hebrew support: $hasHebrew');
        print('🔊 Greek support: $hasGreek');
      }
    } catch (e) {
      print('🔊 Error checking languages: $e');
    }
    
    // Setup callbacks
    _flutterTts.setStartHandler(() {
      print('🔊 TTS Started');
      _isSpeaking = true;
    });
    
    _flutterTts.setCompletionHandler(() {
      print('🔊 TTS Completed');
      _isSpeaking = false;
      _onComplete?.call();
    });
    
    _flutterTts.setCancelHandler(() {
      print('🔊 TTS Cancelled');
      _isSpeaking = false;
    });
    
    _flutterTts.setErrorHandler((msg) {
      print('🔊 TTS Error Handler: $msg');
      _isSpeaking = false;
      _onError?.call(msg);
    });
  }
  
  /// Set callback for when speech completes
  void setCompletionHandler(Function() handler) {
    _onComplete = handler;
  }
  
  /// Set callback for errors
  void setErrorHandler(Function(String) handler) {
    _onError = handler;
  }

  @override
  Future<bool> speak(String text, {String? languageCode}) async {
    try {
      // Get available voices to check what's actually available
      final voices = await _flutterTts.getVoices;
      
      if (languageCode != null) {
        debugPrint('🔊 Setting TTS language to: $languageCode');
        final result = await _flutterTts.setLanguage(languageCode);
        debugPrint('🔊 setLanguage result: $result');
        
        // Check if we have a voice for this language
        bool hasVoice = false;
        if (voices != null) {
          final voicesList = voices as List;
          hasVoice = voicesList.any((v) {
            final voiceMap = v as Map;
            final lang = voiceMap['locale']?.toString() ?? voiceMap['language']?.toString() ?? '';
            return lang.startsWith(languageCode.substring(0, 2));
          });
          debugPrint('🔊 Voice available for $languageCode: $hasVoice');
          
          if (!hasVoice) {
            debugPrint('⚠️ No voice available for $languageCode.');
            return false; // Indicate failure
          }
        }
      }
      
      debugPrint('🔊 Calling TTS speak with text length: ${text.length}');
      final speakResult = await _flutterTts.speak(text);
      debugPrint('🔊 speak() result: $speakResult');
      
      if (speakResult == null || speakResult == 0) {
        debugPrint('⚠️ TTS speak() returned $speakResult - voice not available');
        return false;
      }
      
      return true; // Success
    } catch (e) {
      debugPrint('🔊 TTS Error: $e');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  @override
  Future<void> pause() async {
    await _flutterTts.pause();
  }

  @override
  Future<void> resume() async {
    // Note: flutter_tts doesn't have a built-in resume, 
    // so we'll rely on the app to re-call speak() if needed
  }

  @override
  Future<List<TtsLanguage>> availableLanguages() async {
    final languages = await _flutterTts.getLanguages;
    
    print('🔊 Available TTS languages: $languages');
    
    if (languages == null) return [];
    
    // Convert to our TtsLanguage model
    return (languages as List).map((lang) {
      final langStr = lang.toString();
      return TtsLanguage(
        code: langStr,
        name: _languageCodeToName(langStr),
      );
    }).toList();
  }

  @override
  Future<void> setRate(double rate) async {
    // flutter_tts expects rate typically between 0.0 and 1.0
    // but some platforms support higher values
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  @override
  Future<bool> get isSpeaking async => _isSpeaking;

  /// Convert language code to human-readable name
  String _languageCodeToName(String code) {
    final names = {
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'en-AU': 'English (Australia)',
      'he-IL': 'Hebrew (עברית)',
      'el-GR': 'Greek (Ελληνικά)',
      'es-ES': 'Spanish',
      'fr-FR': 'French',
      'de-DE': 'German',
      'it-IT': 'Italian',
      'pt-BR': 'Portuguese (Brazil)',
      'ru-RU': 'Russian',
      'ar-SA': 'Arabic',
      'zh-CN': 'Chinese (Simplified)',
      'ja-JP': 'Japanese',
      'ko-KR': 'Korean',
    };
    
    return names[code] ?? code;
  }
}
