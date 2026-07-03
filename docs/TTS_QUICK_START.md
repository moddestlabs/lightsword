# TTS Quick Start Guide

## What Was Implemented

Your Dabar Bible app now has full Text-to-Speech (TTS) support with automatic language detection for Hebrew, Greek, and English!

## Key Features

✅ **Automatic Language Detection** - Detects Hebrew, Greek, or English and switches TTS voices automatically  
✅ **Multi-Language Support** - Hebrew (עברית), Greek (Ελληνικά), English  
✅ **Reading Controls** - Play, pause, stop with visual feedback  
✅ **Customizable Settings** - Adjust speed, pitch, and volume  
✅ **Continuous Chapter Reading** - Read all verses in a chapter sequentially  

## How to Use

### Reading Bible Text

1. Open the **Reader Screen** (navigate to any Bible chapter)
2. Tap the **volume icon (🔊)** in the top-right corner
3. The app will automatically:
   - Detect the language (Hebrew/Greek/English)
   - Start reading from verse 1
   - Show floating controls at the bottom

### Controls

- **Play/Pause** - Tap the play/pause button in floating controls
- **Stop** - Tap the stop button to end reading
- **Language Indicator** - Shows detected language (Hebrew/Greek/English)

### Settings

Navigate to **Settings → Text-to-Speech** to:
- **Adjust Speech Rate** - Slider from 10% to 100% speed
- **Adjust Pitch** - Slider from 0.5 to 2.0
- **Adjust Volume** - Slider from 0% to 100%
- **View Available Languages** - See what TTS voices are installed
- **Test TTS** - Hear samples in all three languages

## Demo Page

A demo page was created at `lib/ui/screens/tts_demo_page.dart` that showcases:
- Sample texts in Hebrew, Greek, and English
- Automatic language detection
- Sequential reading
- Interactive examples

To add it to your app navigation, you can link to it from the home screen or settings.

## Files Created

```
bible_app/lib/
├── platform/tts/
│   ├── flutter_tts_engine.dart       # TTS engine implementation
│   └── language_detector.dart        # Language detection utility
├── services/
│   └── tts_service.dart              # TTS service with state management
└── ui/
    ├── screens/
    │   └── tts_demo_page.dart        # Demo page (optional)
    └── widgets/
        └── tts_control_widget.dart   # Floating TTS controls

docs/
└── TTS_IMPLEMENTATION.md             # Full documentation
```

## Important Notes

### Language Pronunciation

- **Hebrew**: Uses **modern Israeli pronunciation**, not Biblical Hebrew
  - Example: שָׁלוֹם = "Shalom" (modern 'o' sound)
  
- **Greek**: Uses **modern Greek pronunciation**, not Koine/Ancient
  - Example: η, ει, οι, υ all sound like "ee" (iotacism)
  - β sounds like "v" not "b"

For authentic ancient pronunciation, TTS is not recommended. Consider pre-recorded audio or specialized pronunciation apps.

### Platform Differences

- **iOS/macOS**: Best quality voices, excellent Hebrew/Greek support
- **Android**: Voice quality varies, may need language pack downloads
- **Web**: Uses Web Speech API, browser-dependent
- **Linux**: Uses eSpeak, may need additional voice packages

### Voice Availability

Not all devices have Hebrew and Greek voices installed by default. Users can:
- **iOS**: Settings → Accessibility → Spoken Content → Voices
- **Android**: Settings → Language & Input → Text-to-Speech → Download languages
- **Web**: Depends on browser, some voices require internet

## Testing

### Quick Test
```dart
// In your app or Dart console:
import 'package:bible_app/services/tts_service.dart';

final tts = TtsService.instance;
await tts.initialize();

// Test Hebrew
await tts.speak('שָׁלוֹם');

// Test Greek
await tts.speak('Χαῖρε');

// Test English
await tts.speak('Hello, world!');
```

### Test in the App

1. **Navigate to Settings** → Text-to-Speech → Test TTS
2. **Open Reader** → John 1 (Greek) → Tap volume icon
3. **Open Reader** → Genesis 1 (Hebrew) → Tap volume icon

## Next Steps

To enhance TTS further, consider:
- [ ] Word-by-word highlighting during reading
- [ ] Persistent settings (save user preferences)
- [ ] Voice selection per language
- [ ] Background audio support
- [ ] Better completion detection (use TTS callbacks)
- [ ] Audio focus management

## Troubleshooting

**No sound?**
- Check device volume
- Check app permissions (some platforms require microphone/audio permissions)
- Verify voices are installed (see Settings → TTS → Available Languages)

**Wrong pronunciation?**
- This is expected for ancient languages (using modern pronunciation)
- Check if correct language is detected (visible in floating controls)

**TTS not available for Hebrew/Greek?**
- Download language packs from device settings
- Some platforms have limited language support

---

Enjoy your new TTS-powered Bible reading experience! 📖🔊
