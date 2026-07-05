# LIGHTSWORD — Project Plan

## Vision

A free, open-source, fully offline-capable Bible study application inspired by Bible Bento, eSword, and the SWORD Project — but built with a modern cross-platform stack (Dart + Flutter) and distributed first as a static, no-install web build via GitHub Pages, with native iOS/Android/desktop builds to follow.

No internet required after initial asset download. No ads, no tracking, no account.

## Core Requirements

1. **Advanced Hebrew and Greek functionality** — interlinear display, word-for-word concordance, morphological parsing (part of speech, tense, mood, voice, case, number, gender), Strong's numbers, lexicon lookups, etymology where available.
2. **Text-to-speech** — read any displayed text aloud, in any language the underlying TTS engine on the platform supports, including correct handling of Hebrew/Greek pronunciation where feasible.
3. **Open data only** — all biblical texts, lexicons, morphology, and concordance data must come from open-source/open-data sources with licenses compatible with free redistribution. No proprietary or licensed-restricted module content.

## Explicitly Out of Scope (for this phase)

- **No CLI/terminal client.** A terminal version may be pursued later as a *separate* project, likely in **Nim** (chosen for substantially smaller compiled binary size vs. Dart AOT), consuming the same open data formats independently. It will not share a codebase with this project. Do not design around future CLI reuse — keep this repo Flutter/Dart-only and unencumbered by that concern.
- No backend server, sync service, or account system in this phase.
- No commercial/licensed translations or commentary sets.

## Architecture

### Principle: separate the core logic from the UI shell

Even without a CLI target, this separation still matters: it keeps business logic testable, keeps the data layer swappable, and keeps the Flutter layer "dumb" (rendering only). Two packages in one repo (a Dart monorepo via a workspace, or simple path-based local packages):

```
/bible_core/              <- pure Dart package, NO Flutter dependency
  lib/
    models/                  Verse, Book, Chapter, Word, MorphologyTag, LexiconEntry, StrongsEntry
    data/
      sources/                parsers/loaders for chosen open text formats (see "Data Sources" below)
      repository.dart         BibleRepository: load, query, navigate texts
    concordance/
      index.dart               word-for-word concordance index (build + query)
      search.dart               full text + lemma + Strong's-number search
    lexicon/
      strongs.dart              Strong's number -> definition lookups
      morphology.dart           morphology code -> human-readable parsing
    tts/
      tts_engine.dart           abstract interface (speak, stop, listVoices, setRate, etc.)
    services/
      bookmark_service.dart
      notes_service.dart
      reading_plan_service.dart

/bible_app/                <- Flutter app (iOS, Android, macOS, Windows, Linux, Web)
  lib/
    main.dart
    ui/                       screens, widgets
    platform/
      tts/                     FlutterTtsEngine implementing bible_core's TtsEngine
      storage/                 platform storage adapters (see "Platform-Specific Concerns")
    state/                     app state management (provider/riverpod/bloc — TBD)
  web/                        Flutter web target — this is what gets built and pushed to GitHub Pages
  assets/                     bundled open-data text/lexicon files (or pointers to downloadable asset packs)
```

`bible_app` depends on `bible_core` as a local path dependency. `bible_core` has zero awareness of Flutter — it only deals with models, parsing, indexing, and abstract interfaces.

### Why this still matters without a CLI

- Logic in `bible_core` can be unit-tested with plain `dart test`, no widget/golden testing overhead.
- If a Nim terminal tool is built later, its author/maintainer (even if that's a future version of this same person) can independently study `bible_core`'s public API as a *reference* for expected behavior — without any code-sharing obligation.
- Keeps the Flutter layer thin: screens and widgets call `BibleRepository`/`ConcordanceIndex`/`TtsEngine`, nothing else. This avoids logic creeping into widgets, which becomes painful once interlinear rendering, search, and TTS all need to interact.

## Platform-Specific Concerns

These cannot live in `bible_core` and need an abstract interface in core + concrete implementation per platform in `bible_app`:

### Text-to-Speech
- Use `flutter_tts` (wraps AVSpeechSynthesizer on iOS/macOS, Android TTS, Web Speech API on web, eSpeak/other on Linux).
- Define `abstract class TtsEngine` in `bible_core` with methods like `speak(String text, {String? languageCode})`, `stop()`, `availableLanguages()`.
- Implement `FlutterTtsEngine` in `bible_app/lib/platform/tts/`.
- **Open question to flag in repo:** TTS quality/availability for Hebrew and Koine Greek varies wildly by platform and by installed system voices. Native pronunciation of Hebrew niqqud and Greek polytonic diacritics may require fallback to transliteration-based TTS or accepting degraded pronunciation. This needs early prototyping/spike before committing to a TTS approach.

### Storage / Data Loading
- Native targets (iOS, Android, macOS, Windows, Linux) can use `dart:io` File APIs or `sqflite`/`path_provider` for bundled or downloaded data.
- **Flutter Web cannot use `dart:io`.** Data must be bundled as static assets (JSON, or a web-compatible embedded DB like `sqlite3.wasm` via `sqlite3_flutter_libs`/drift-wasm) and fetched via HTTP from the same static host (GitHub Pages).
- Define an abstract `DataSource` in `bible_core` (e.g. `Future<String> loadAsset(String path)`), with a native file-based implementation and a web HTTP/asset-bundle implementation.
- Goal: identical data format across all platforms so `bible_core`'s parsing logic never needs to branch on platform.

### RTL & Diacritic Rendering
- Hebrew (RTL, niqqud/cantillation marks) and Greek (polytonic diacritics) text rendering is a known hard problem. Flutter's text layout generally handles RTL and combining characters reasonably well, but this needs visual verification early — before deep investment in the interlinear UI — to catch font rendering, line-breaking, and combining-mark issues per platform (especially Web, which has historically had more font/rendering quirks than native).

## Data Sources (open data only — no licensed/proprietary modules)

To be evaluated and finalized, but strong open candidates:

- **Open Scriptures Hebrew Bible (OSHB)** — Hebrew OT with full morphological tagging, openly licensed.
- **Berean Interlinear / Berean Greek Bible / Berean Study Bible** — fully open Greek NT interlinear with Strong's tagging, designed for open reuse.
- **STEPBible Data (Tyndale House)** — Hebrew/Greek tagged texts with lemma and morphology; verify exact license terms for redistribution before bundling.
- **SWORD Project module format** — large existing ecosystem of public-domain modules (texts, lexicons, dictionaries). Worth writing a SWORD module (OSIS/ThML-based) parser in `bible_core/lib/data/sources/` so the app can ingest the broader SWORD module ecosystem directly rather than only custom-curated files. This also keeps a future Nim CLI tool's data format compatible with this app's data, even without code sharing.
- **Strong's Concordance / Strong's Dictionary data** — multiple open-data JSON/XML packagings exist (verify license terms; the underlying Strong's content is generally public domain due to age, but specific digitizations may carry their own redistribution terms).

**Action item:** before writing the data layer, confirm and document the exact license for each chosen source directly in the repo (e.g. `/docs/DATA_LICENSES.md`), including attribution requirements, since this determines what can ship in a public GitHub Pages build and App Store submissions.

## Deployment Plan

1. **Phase 1 — Web prototype via GitHub Pages**
   - Build `bible_app` for web: `flutter build web --base-href /<repo-name>/`
   - Push `build/web` output to a `gh-pages` branch or `/docs` folder (whichever GitHub Pages config is used).
   - Goal: a shareable, installable-nothing link people can try immediately, no app store gatekeeping, fast iteration loop.
2. **Phase 2 — Native builds**
   - Once core feature set (interlinear, concordance, TTS, search) is stable on web, build and test iOS, Android, macOS, Windows, Linux targets from the same Flutter codebase.
   - App Store / Play Store submission follows once native builds are stable and data licensing is fully documented.
3. **(Separate, future, out of scope here) — Nim terminal client**
   - Independent project. May reuse the same open data sources/format (e.g. SWORD modules) for consistency, but will not share code with `bible_core`.

## Open Questions / Spikes to Resolve Early

- [ ] Pick state management approach for `bible_app` (Provider, Riverpod, Bloc, or plain `ChangeNotifier`) — keep `bible_core` agnostic either way.
- [ ] Spike: Hebrew/Greek TTS quality across iOS, Android, and Web Speech API — determine fallback strategy.
- [ ] Spike: Flutter Web rendering of Hebrew niqqud + Greek polytonic diacritics — verify before deep UI investment.
- [ ] Decide on-disk/asset data format: raw JSON, SQLite (via `drift` or `sqflite`), or direct SWORD module parsing.
- [ ] Write `bible_core` public API surface doc (key classes: `BibleRepository`, `ConcordanceIndex`, `LexiconLookup`, `TtsEngine`, `DataSource`) before first UI screen is built, so UI work has a stable contract to build against.
- [ ] Document data licenses per source in `/docs/DATA_LICENSES.md` before any public deployment.

## Suggested Repo Structure (top level)

```
/bible_core/
/bible_app/
/docs/
  DATA_LICENSES.md
  ARCHITECTURE.md   (can start as a copy of this document, expanded over time)
/.github/
  workflows/
    deploy-web.yml   (CI: build Flutter web, deploy to gh-pages on push to main)
README.md
```
