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
  TtsProgressHandler? _onProgress;

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

    _flutterTts.setProgressHandler((text, start, end, word) {
      _onProgress?.call(text, start, end, word);
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
  void setProgressHandler(TtsProgressHandler handler) {
    _onProgress = handler;
  }

  @override
  Future<bool> speak(String text,
      {String? languageCode, TtsVoice? voice}) async {
    try {
      if (languageCode != null) {
        debugPrint('🔊 Setting TTS language to: $languageCode');
        final result = await _flutterTts.setLanguage(languageCode);
        debugPrint('🔊 setLanguage result: $result');

        // Check if language was rejected (result is 0 on some platforms when unsupported)
        // However, many platforms return 1 even when the voice isn't great
        // So we'll be optimistic and try to speak anyway
        if (result == 0) {
          debugPrint(
              '⚠️ setLanguage returned 0 for $languageCode - language may not be supported');
          // Check if we have any voices for this language
          final voices = await _flutterTts.getVoices;
          if (voices != null) {
            final voicesList = voices as List;
            final hasVoice = voicesList.any((v) {
              final voiceMap = v as Map;
              final lang = voiceMap['locale']?.toString() ??
                  voiceMap['language']?.toString() ??
                  '';
              return lang.startsWith(languageCode.substring(0, 2));
            });

            if (!hasVoice) {
              debugPrint('⚠️ No voice available for $languageCode.');
              return false; // Definitely no voice
            }
          }
        }
      }

      if (voice != null) {
        debugPrint('🔊 Setting TTS voice to: ${voice.label}');
        await _flutterTts.setVoice({
          'name': voice.name,
          'locale': voice.locale,
          'identifier': voice.id,
        });
      }

      debugPrint('🔊 Calling TTS speak with text length: ${text.length}');
      final speakResult = await _flutterTts.speak(text);
      debugPrint('🔊 speak() result: $speakResult');

      // On many platforms, speak() returns 1 for success, but on some platforms
      // it may return 0 or null even when it's working. The completion/error
      // handlers are more reliable, so we'll assume success unless there's a clear error.
      // We only return false if the result is explicitly indicating an error state.

      return true; // Assume success - failures will be caught by error handler
    } catch (e) {
      debugPrint('🔊 TTS Error: $e');
      _onError?.call(e.toString());
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
    final voices = await availableVoices();

    print('🔊 Available TTS languages: $languages');

    if (languages == null) return [];

    // Convert to our TtsLanguage model
    return (languages as List).map((lang) {
      final langStr = lang.toString();
      return TtsLanguage(
        code: langStr,
        name: _languageCodeToName(langStr),
        voices: voices
            .where((voice) => _matchesLanguageCode(voice.locale, langStr))
            .map((voice) => voice.name)
            .toList(),
      );
    }).toList();
  }

  @override
  Future<List<TtsVoice>> availableVoices({String? languageCode}) async {
    final rawVoices = await _flutterTts.getVoices;
    if (rawVoices == null) {
      return const [];
    }

    final voices = <TtsVoice>[];
    for (final item in rawVoices as List) {
      if (item is! Map) {
        continue;
      }

      final locale =
          item['locale']?.toString() ?? item['language']?.toString() ?? '';
      final name =
          item['name']?.toString() ?? item['identifier']?.toString() ?? locale;
      if (locale.isEmpty || name.isEmpty) {
        continue;
      }

      final voice = TtsVoice(
        id: _voiceIdFromMap(item),
        name: name,
        locale: locale,
      );
      if (languageCode == null || _matchesLanguageCode(locale, languageCode)) {
        voices.add(voice);
      }
    }

    voices.sort((a, b) {
      final localeCompare = a.locale.compareTo(b.locale);
      if (localeCompare != 0) {
        return localeCompare;
      }
      return a.name.compareTo(b.name);
    });

    return voices;
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

  bool _matchesLanguageCode(String locale, String languageCode) {
    if (locale == languageCode) {
      return true;
    }

    final localePrefix = locale.split(RegExp('[-_]')).first.toLowerCase();
    final codePrefix = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    return localePrefix == codePrefix;
  }

  String _voiceIdFromMap(Map<dynamic, dynamic> voiceMap) {
    final identifier = voiceMap['identifier']?.toString();
    if (identifier != null && identifier.isNotEmpty) {
      return identifier;
    }

    final name = voiceMap['name']?.toString() ?? 'voice';
    final locale = voiceMap['locale']?.toString() ??
        voiceMap['language']?.toString() ??
        'unknown';
    return '$locale::$name';
  }
}
