# LIGHTSWORD

Cross-platform and fully offline-capable Bible study application built on advanced language functionality but focused on usability. The goal is to provide an extremely easy and intuitive but powerful study tool with markup, cross-reference and language capabilities.

**Tech Stack:** Dart + Flutter (iOS, Android, Web, macOS, Windows, Linux)  

See it live: https://moddestlabs.github.io/lightsword/

## Design

LIGHTSWORD is inspired by Bible Bento, eSword, and the SWORD Project, but built with modern cross-platform technology. Bible Bento served as the main inspiration behind the UI/UX while the longstanding SWORD Project and eSword help inform the more complex features. We want to provide the easiest possible entry point and still pave way for advanced language study meanwhile ensuring it's all totally usable on mobile.

See [PLAN.md](PLAN.md) for full product vision and roadmap.

### Features

LIGHTSWORD features:
- **Advanced Hebrew and Greek**: Interlinear display, morphological parsing, Strong's numbers, lexicon lookups.
- **Text-to-speech**: Read any displayed text aloud, including Hebrew and Greek.
- **Open data first**: All core Bible texts and lexicons from freely redistributable sources.
- **Offline-first**: No internet required after initial asset download.
- **No ads, no tracking, no account.**

### Views

LIGHTSWORD is built around the concept of customizable Views to Bible content.

We start with just 2 core Views:
- Paragraph: language gloss or translation in typical, paragraph form.
- Interlinear: original language + language gloss + translation, each on separate line.

Create editable copies of core Views or create new Views from scratch to configure layout and structure for easy study as well as for copy-and-paste and TTS (Text-to-Speech) reading. Need to copy Scripture text in specific formats like "Jhn 3:16 For God so loved the world..."? Create a View showing Bible text line-by-line with Book (abbreviated), Chapter and Verse on each line. Wanna just sit and listen to Scripture being read aloud? Create a View showing text without verse numbers and untick the line-by-line option.

## Repository Structure

```
/bible_core/        Pure Dart package (business logic, no Flutter)
/bible_app/         Flutter UI (all platforms)
/docs/              Architecture and data license documentation
/.github/workflows/ CI/CD for GitHub Pages deployment
```

### bible_core (Pure Dart)

Contains all domain models, data parsing, concordance indexing, and business services.  
**No Flutter dependency** — can be unit-tested with `dart test`.

Key abstractions:
- `BibleRepository` — Data access for verses, books, chapters
- `TtsEngine` — Abstract text-to-speech interface
- `DataSource` — Platform-agnostic asset loading
- Services for bookmarks, notes, reading plans

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

### bible_app (Flutter)

Flutter UI consuming `bible_core` via local path dependency.  
Supports iOS, Android, macOS, Windows, Linux, and **Web** (GitHub Pages).

**PWA Support:** Full Progressive Web App implementation with offline support, installability, and platform-specific optimizations. See [docs/PWA_QUICK_START.md](docs/PWA_QUICK_START.md) for details.

## Quick Start

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK 3.0+

### Run Locally

```bash
# Get dependencies for both packages
cd bible_core && flutter pub get && cd ..
cd bible_app && flutter pub get && cd ..

# Run tests
cd bible_core && dart test && cd ..

# Run app (choose platform)
cd bible_app
flutter run              # Interactive platform selector
flutter run -d chrome    # Web
flutter run -d macos     # macOS
```

### Build for Web (GitHub Pages)

```bash
cd bible_app
flutter build web --release --base-href /lightsword/
```

Output: `bible_app/build/web/`

GitHub Actions automatically builds and deploys to Pages on push to `main`.

## License

MIT License — see [LICENSE](LICENSE) for details.

All Bible texts and lexicons used will be from open-source/public-domain sources with compatible licenses (documented in [docs/DATA_LICENSES.md](docs/DATA_LICENSES.md)).
