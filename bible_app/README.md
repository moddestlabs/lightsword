# LightSword Bible App

Flutter UI for the LightSword Bible study application.

## Dependencies

- `bible_core` - Local path dependency to the pure Dart package containing all business logic
- Flutter SDK

## Structure

- `lib/main.dart` - App entry point
- `lib/ui/` - UI screens and widgets
- `lib/platform/` - Platform-specific implementations (TTS, storage)
- `lib/state/` - State management (to be chosen)

## Running

```bash
flutter run
```

### For web (GitHub Pages deployment):

```bash
flutter build web --base-href /
```

Output will be in `build/web/` ready for deployment.
