/// Abstract text-to-speech engine interface
/// Platform-specific implementations in bible_app
typedef TtsProgressHandler = void Function(
  String text,
  int start,
  int end,
  String word,
);

abstract class TtsEngine {
  /// Speak the given text
  /// Returns true if speech started successfully, false otherwise
  Future<bool> speak(String text, {String? languageCode, TtsVoice? voice});

  /// Stop current speech
  Future<void> stop();

  /// Pause current speech
  Future<void> pause();

  /// Resume paused speech
  Future<void> resume();

  /// Get available languages/voices
  Future<List<TtsLanguage>> availableLanguages();

  /// Get available voices, optionally filtered by language code.
  Future<List<TtsVoice>> availableVoices({String? languageCode});

  /// Receive progress updates from the active utterance when supported.
  void setProgressHandler(TtsProgressHandler handler);

  /// Set speech rate (0.0 to 1.0, default 0.5)
  Future<void> setRate(double rate);

  /// Set speech pitch (0.0 to 1.0, default 0.5)
  Future<void> setPitch(double pitch);

  /// Set speech volume (0.0 to 1.0, default 1.0)
  Future<void> setVolume(double volume);

  /// Whether TTS is currently speaking
  Future<bool> get isSpeaking;
}

/// Represents a TTS language/voice
class TtsLanguage {
  final String code;
  final String name;
  final List<String>? voices;

  const TtsLanguage({
    required this.code,
    required this.name,
    this.voices,
  });

  @override
  String toString() => '$name ($code)';
}

class TtsVoice {
  final String id;
  final String name;
  final String locale;

  const TtsVoice({
    required this.id,
    required this.name,
    required this.locale,
  });

  String get label => '$name ($locale)';

  @override
  String toString() => label;
}
