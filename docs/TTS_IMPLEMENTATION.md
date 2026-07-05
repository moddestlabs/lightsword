# Text-to-Speech (TTS) Implementation

## Overview

LIGHTSWORD now includes full Text-to-Speech support with automatic language detection for **Hebrew**, **Greek**, and **English**. The TTS system can read Bible verses aloud using the native TTS engines on each platform.

## Features

### ✅ Multi-Language Support
- **Hebrew (עברית)** - Modern Israeli pronunciation with niqqud support
- **Greek (Ελληνικά)** - Modern Greek pronunciation (not ancient Koine)
- **English** - Multiple variants (US, UK, Australia, etc.)

### ✅ Automatic Language Detection
The system automatically detects the language of the text being read by analyzing character ranges:
- Hebrew: Unicode range U+0590 to U+05FF
- Greek: Unicode ranges U+0370 to U+03FF and U+1F00 to U+1FFF (polytonic)
- English: Default for Latin characters

### ✅ Full Playback Controls
- **Play/Pause** - Start and pause reading
- **Stop** - Stop reading and reset
- **Continuous Reading** - Automatically reads through all verses in a chapter
- **Visual Feedback** - Shows current language and playback state

### ✅ Customizable Settings
- **Speech Rate** - Adjust reading speed (10% to 100%)
- **Speech Pitch** - Adjust voice pitch (0.5 to 2.0)
- **Volume** - Control playback volume (0% to 100%)

## Architecture

### Core Components

1. **`TtsEngine` (Abstract Interface)**
   - Location: `bible_core/lib/tts/tts_engine.dart`
   - Platform-agnostic interface
   - Defines methods: `speak()`, `stop()`, `pause()`, `setRate()`, `setPitch()`, `setVolume()`

2. **`FlutterTtsEngine` (Concrete Implementation)**
   - Location: `bible_app/lib/platform/tts/flutter_tts_engine.dart`
   - Uses `flutter_tts` package
   - Wraps platform-specific TTS engines:
     - iOS/macOS: AVSpeechSynthesizer
     - Android: Android TTS
     - Web: Web Speech API
     - Linux: eSpeak/other

3. **`LanguageDetector` (Utility)**
   - Location: `bible_app/lib/platform/tts/language_detector.dart`
   - Detects Hebrew, Greek, or English from text content
   - Returns ISO language codes: `he-IL`, `el-GR`, `en-US`

4. **`TtsService` (State Management)**
   - Location: `bible_app/lib/services/tts_service.dart`
   - Singleton service using `ChangeNotifier`
   - Manages playback state and verse queue
   - Coordinates language detection and TTS engine

5. **`TtsControlWidget` (UI Component)**
   - Location: `bible_app/lib/ui/widgets/tts_control_widget.dart`
   - Floating control panel
   - Shows current language and playback controls

## Usage

### In the Reader Screen

1. **Start Reading**: Tap the volume icon (🔊) in the app bar
2. **Playback Controls**: A floating control panel appears at the bottom
3. **Stop/Pause**: Use the controls in the floating panel
4. **Automatic Progression**: Verses are read sequentially with proper pauses

### In Settings

Navigate to **Settings → Text-to-Speech** to:
- Adjust speech rate (reading speed)
- Adjust speech pitch (voice tone)
- Adjust volume
- View available TTS languages on your device
- Test TTS with sample texts in Hebrew, Greek, and English

### Programmatic Usage

```dart
import 'package:bible_app/services/tts_service.dart';

final tts = TtsService.instance;

// Speak a single text (language auto-detected)
await tts.speak('Ἐν ἀρχῇ ἦν ὁ λόγος');

// Read multiple verses
await tts.readVerses(verses, startIndex: 0);

// Control playback
await tts.togglePlayPause();
await tts.stop();

// Adjust settings
await tts.setRate(0.7);  // 70% speed
await tts.setPitch(1.2); // Higher pitch
```

## Platform-Specific Notes

### iOS/macOS
- High-quality voices for Hebrew and Greek typically available
- Best pronunciation of Hebrew niqqud
- Voice quality depends on system settings

### Android
- Voice availability varies by device and Android version
- Users may need to download additional language packs
- Check Settings → Language & Input → Text-to-Speech

### Web
- Uses Web Speech API
- Browser support varies:
  - Chrome/Edge: Good support
  - Firefox: Limited language support
  - Safari: Good quality voices
- Requires internet connection for some voices

### Linux
- Uses eSpeak or other installed TTS engines
- Hebrew/Greek support depends on installed voices
- May require additional voice packages:
  ```bash
  sudo apt-get install espeak-ng-data
  ```

## Language Pronunciation Notes

### Hebrew (עברית)
- Uses **Modern Israeli Hebrew** pronunciation
- Supports niqqud (vowel points) and cantillation marks
- **NOT** reconstructed Biblical Hebrew pronunciation
- Examples:
  - תּוֹרָה pronounced "Torah" (not "Towrah")
  - שָׁלוֹם pronounced "Shalom" (with modern 'o' sound)

### Greek (Ελληνικά)
- Uses **Modern Greek** pronunciation
- **NOT** Koine/Ancient Greek pronunciation
- Differences include:
  - η, ει, οι, υ all pronounced as "ee" (iotacism)
  - β pronounced as "v" (not "b")
  - γ before ε/ι pronounced as "y"
- Example: Ἐν ἀρχῇ → "En arhee" (modern) vs "En arkhay" (ancient)

### For Authentic Ancient Pronunciation
If you need authentic Koine Greek or Biblical Hebrew pronunciation:
1. Consider recording custom audio
2. Use specialized pronunciation apps
3. TTS is optimized for modern language speakers, not historical accuracy

## Known Limitations

1. **No Resume Function**: Most platforms don't support true pause/resume
   - Workaround: Re-reads from the current verse when "resumed"

2. **Sequential Reading**: Currently reads verse-by-verse with fixed delays
   - Future enhancement: Use TTS completion callbacks for smoother flow

3. **Voice Quality Varies**: Depends on platform and installed voices
   - iOS/macOS typically have the best quality
   - Some platforms may lack Hebrew/Greek voices entirely

4. **Language Detection**: Based on character ranges, not content analysis
   - Mixed-language text defaults to the dominant script
   - Transliterated text (e.g., "Logos") read as English

## Testing

### Quick Test
1. Open Settings
2. Scroll to Text-to-Speech section
3. Tap "Test TTS"
4. Listen to samples in English, Hebrew, and Greek

### Manual Test with Real Text
1. Navigate to Genesis 1 (Hebrew text)
2. Tap the volume icon
3. Verify Hebrew is auto-detected and pronounced correctly
4. Navigate to John 1 (Greek text)
5. Verify Greek is auto-detected and pronounced correctly

## Future Enhancements

- [ ] Word-by-word highlighting during playback
- [ ] Variable speed during playback (without stopping)
- [ ] Voice selection per language
- [ ] Pronunciation corrections/customizations
- [ ] Persistent settings storage
- [ ] Background audio support
- [ ] Audio focus management (pause on interruption)
- [ ] Better async control using TTS callbacks

## Dependencies

- `flutter_tts: ^4.0.0` - Cross-platform TTS wrapper

## Files Created/Modified

**New Files:**
- `bible_app/lib/platform/tts/flutter_tts_engine.dart`
- `bible_app/lib/platform/tts/language_detector.dart`
- `bible_app/lib/services/tts_service.dart`
- `bible_app/lib/ui/widgets/tts_control_widget.dart`

**Modified Files:**
- `bible_app/pubspec.yaml` - Added flutter_tts dependency
- `bible_app/lib/main.dart` - Initialize TTS service on startup
- `bible_app/lib/ui/screens/reader_screen.dart` - Added TTS button and controls
- `bible_app/lib/ui/screens/settings_screen.dart` - Added TTS settings panel

---

**Note**: This implementation prioritizes simplicity and cross-platform compatibility. For production use in an app store release, consider adding error handling, permission checks, and audio session management.
