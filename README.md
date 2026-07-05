# LIGHTSWORD

A free, open-source, fully offline-capable Bible study application with advanced Hebrew and Greek functionality.

**Status:** Early development (v0.1.0)  
**Tech Stack:** Dart + Flutter (iOS, Android, Web, macOS, Windows, Linux)  
**Web Demo:** Coming soon (GitHub Pages)

## Vision

LIGHTSWORD is inspired by Bible Bento, eSword, and the SWORD Project, but built with modern cross-platform technology and focused on:

1. **Advanced Hebrew and Greek** — Interlinear display, morphological parsing, Strong's numbers, lexicon lookups
2. **Text-to-speech** — Read any displayed text aloud, including Hebrew and Greek
3. **Open data only** — All Bible texts and lexicons from freely redistributable sources
4. **Offline-first** — No internet required after initial asset download
5. **No ads, no tracking, no account**

See [PLAN.md](PLAN.md) for full product vision and roadmap.

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

## Current Status (Milestone 0: Bootstrap)

✅ Monorepo structure with `bible_core` + `bible_app`  
✅ Core domain models (Book, Verse, Word, MorphologyTag, etc.)  
✅ Abstract interfaces (BibleRepository, TtsEngine, DataSource)  
✅ **Full PWA implementation** with offline support, installability, and TTS detection
✅ Basic Flutter UI scaffold with Reader, Study, Library, Settings screens  
✅ GitHub Actions workflow for web deployment  

⏳ **Next:** Implement data loading, choose open Bible text sources, add passage picker

## Roadmap

See [PLAN.md](PLAN.md) for full details.

**Phase 1:** Web prototype via GitHub Pages  
**Phase 2:** Native mobile and desktop builds  
**Phase 3:** Advanced study features (interlinear, concordance, TTS)

## Documentation

- [PLAN.md](PLAN.md) — Full product vision and technical direction
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Codebase structure and design
- [docs/DATA_LICENSES.md](docs/DATA_LICENSES.md) — Open Bible data sources and licenses

## Contributing

Contributions welcome! This project is in early development.

Open questions to help with:
- Best open-source Hebrew/Greek Bible datasets
- State management library choice (Provider/Riverpod/Bloc)
- Hebrew/Greek TTS quality testing across platforms

## License

MIT License — see [LICENSE](LICENSE) for details.

All Bible texts and lexicons used will be from open-source/public-domain sources with compatible licenses (documented in [docs/DATA_LICENSES.md](docs/DATA_LICENSES.md)).
