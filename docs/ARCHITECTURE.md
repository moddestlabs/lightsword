# LightSword Architecture

## Overview

LightSword is structured as a **Dart monorepo** with two packages:

1. **bible_core** — Pure Dart package with no Flutter dependency
2. **bible_app** — Flutter UI consuming bible_core

This separation keeps business logic testable, UI-independent, and the data layer swappable.

## Package: bible_core

**Location:** `/bible_core/`  
**Purpose:** Core domain models, data parsing, concordance indexing, lexicon lookups, and business services.

### Structure

```
bible_core/
├── lib/
│   ├── bible_core.dart          # Public API exports
│   ├── models/                   # Domain models
│   │   ├── book.dart
│   │   ├── chapter.dart
│   │   ├── verse.dart
│   │   ├── word.dart             # Original language word with morphology
│   │   ├── morphology.dart       # MorphologyTag and parsing
│   │   ├── lexicon_entry.dart
│   │   ├── strongs_entry.dart
│   │   └── passage_reference.dart
│   ├── data/
│   │   ├── repository.dart       # BibleRepository + DataSource abstractions
│   │   └── sources/              # Parsers for open Bible formats (OSHB, SWORD, etc.)
│   ├── concordance/
│   │   ├── index.dart            # Word-for-word concordance index
│   │   └── search.dart           # Full-text + lemma + Strong's search
│   ├── lexicon/
│   │   ├── strongs.dart          # Strong's lookup
│   │   └── morphology.dart       # Morphology code parsing
│   ├── tts/
│   │   └── tts_engine.dart       # Abstract TTS interface
│   └── services/
│       ├── bookmark_service.dart
│       ├── notes_service.dart
│       └── reading_plan_service.dart
└── test/                         # Pure Dart unit tests (no Flutter)
```

### Key Abstractions

#### DataSource
Platform-agnostic interface for loading Bible text data:
```dart
abstract class DataSource {
  Future<String> loadAsset(String path);
  Future<bool> assetExists(String path);
}
```
- Native platforms: File I/O via `dart:io`
- Web: HTTP fetch from GitHub Pages static assets

#### BibleRepository
Main data access point:
```dart
abstract class BibleRepository {
  Future<List<Book>> getBooks();
  Future<List<Verse>> getVerses(PassageReference ref);
  Future<Verse?> getVerse(String bookId, int chapter, int verse);
  Future<List<Verse>> search(String query);
}
```

#### TtsEngine
Abstract text-to-speech interface:
```dart
abstract class TtsEngine {
  Future<void> speak(String text, {String? languageCode});
  Future<void> stop();
  Future<List<TtsLanguage>> availableLanguages();
  Future<void> setRate(double rate);
  // ...
}
```
Implemented in `bible_app` using `flutter_tts`.

### Testing

Run tests with:
```bash
cd bible_core
dart test
```

No Flutter needed for these tests — they're pure Dart unit tests.

---

## Package: bible_app

**Location:** `/bible_app/`  
**Purpose:** Flutter UI for iOS, Android, macOS, Windows, Linux, and Web.

### Structure

```
bible_app/
├── lib/
│   ├── main.dart
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── reader_screen.dart
│   │   │   ├── study_screen.dart
│   │   │   ├── library_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/              # Reusable UI components
│   ├── platform/
│   │   ├── tts/
│   │   │   └── flutter_tts_engine.dart  # TtsEngine impl using flutter_tts
│   │   └── storage/
│   │       ├── file_data_source.dart    # Native DataSource (dart:io)
│   │       └── web_data_source.dart     # Web DataSource (HTTP fetch)
│   └── state/                    # State management (Provider/Riverpod/Bloc TBD)
├── assets/                       # Bundled data files (or download links)
├── web/
│   ├── index.html
│   └── manifest.json
└── test/                         # Widget/integration tests
```

### State Management

**Open decision:** Choose one of:
- **Provider** (simple, recommended by Flutter team)
- **Riverpod** (more powerful, type-safe)
- **Bloc** (event-driven, verbose but explicit)

Keep `bible_core` agnostic — state management only touches the UI layer.

### Platform-Specific Implementations

#### TTS: FlutterTtsEngine
Wraps `flutter_tts` package, implements `TtsEngine` interface from `bible_core`.

**Known challenges:**
- Hebrew/Greek pronunciation quality varies by platform and installed voices
- May need fallback to transliteration or degraded pronunciation

#### Data Loading
- **Native:** Use `dart:io` File APIs or `path_provider`/`sqflite`
- **Web:** Fetch from GitHub Pages via HTTP (no `dart:io` available)

Both implement the same `DataSource` interface, so `bible_core` parsing logic never branches on platform.

---

## Data Flow

1. **App startup:** Load book list from `BibleRepository`
2. **User selects passage:** `BibleRepository.getVerses(reference)`
3. **Display verses:** UI renders via Flutter widgets
4. **User taps verse:** Show interlinear view (Word-level data with morphology)
5. **User taps TTS button:** `TtsEngine.speak(text, languageCode: 'he')` or `'grc'`
6. **User adds note:** `NotesService.addNote(note)`

---

## Deployment Targets

### Phase 1: Web (GitHub Pages)
```bash
cd bible_app
flutter build web --release --base-href /
```
Output: `bible_app/build/web/`  
Deploy: GitHub Actions uploads `bible_app/build/web/` to GitHub Pages (see `.github/workflows/deploy-web.yml`)

### Phase 2: Native
```bash
flutter build apk          # Android
flutter build ios          # iOS (requires macOS + Xcode)
flutter build macos        # macOS
flutter build windows      # Windows
flutter build linux        # Linux
```

---

## Design Principles

1. **Separation of concerns:** Business logic in `bible_core`, UI in `bible_app`
2. **Platform abstraction:** Use abstract interfaces (`DataSource`, `TtsEngine`) for platform-specific code
3. **Testability:** Core logic can be unit-tested without Flutter overhead
4. **Offline-first:** All Bible text and lexicon data should work offline after initial load
5. **Open data only:** No proprietary APIs or licensed content

---

## Future Nim CLI (Out of Scope for This Phase)

A separate terminal client may be built later in **Nim** (for smaller binary size). It will:
- Consume the same open data formats (e.g., SWORD modules)
- **Not share code** with `bible_core` (different language)
- Use `bible_core`'s public API as a **reference** for expected behavior

Do not design `bible_core` with CLI reuse in mind — keep it Flutter/Dart-focused.

---

## Open Questions

- [ ] State management library choice (Provider/Riverpod/Bloc)
- [ ] On-disk data format (raw JSON, SQLite via drift/sqflite, or SWORD modules)
- [ ] Hebrew/Greek TTS fallback strategy
- [ ] Flutter Web rendering quality for Hebrew niqqud + Greek polytonic diacritics
