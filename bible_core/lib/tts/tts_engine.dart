/// Abstract text-to-speech engine interface
/// Platform-specific implementations in bible_app
abstract class TtsEngine {
  /// Speak the given text
  /// Returns true if speech started successfully, false otherwise
  Future<bool> speak(String text, {String? languageCode});
  
  /// Stop current speech
  Future<void> stop();
  
  /// Pause current speech
  Future<void> pause();
  
  /// Resume paused speech
  Future<void> resume();
  
  /// Get available languages/voices
  Future<List<TtsLanguage>> availableLanguages();
  
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
