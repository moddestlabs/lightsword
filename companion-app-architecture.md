# LightSword Companion App Architecture

**Status:** Design reference
**Audience:** Claude (or any contributor) implementing companion apps and cross-app communication for the LightSword ecosystem

## 1. Vision

LightSword stays a lean core Bible reading/study app. Broader Logos-style
features (maps, genealogy, timelines, sermon writing, etc.) live in separate
companion apps under the Moddest Labs umbrella. Users install only what they
need. Companion apps should feel connected to LightSword — deep-linking into
specific content, and reusing shared offline data packs — without LightSword
itself carrying that weight.

## 1.1 Feasibility summary

This architecture is feasible and matches the current repo direction, but it
requires treating LightSword's core as a stable ecosystem contract rather than
only an internal app package. The existing `bible_core`/`bible_app` split is the
right starting point: companion apps can share models, parsers, reference
normalization, morphology parsing, syntax data structures, and pack metadata
without inheriting LightSword's reader UI.

The main implementation risk is that some current "core" readers still load
Flutter assets directly and expose singleton repositories. That works for the
main Flutter app, but companion apps need the same APIs to read from different
backends: bundled assets, native shared directories, App Group containers,
web service-worker caches, web IndexedDB, or a shared web storage hub. Before
shipping companion apps, the core should move from asset-bound repositories to
repository factories backed by injectable data/pack providers.

Recommended posture:

- Keep LightSword lean by moving Logos-like feature UIs into separate apps.
- Keep `bible_core` lean but more formal: domain models, reference parsing,
  data schemas, pack manifests, and reader/query interfaces only.
- Put platform storage, app links, installation state, and PWA/cache mechanics
  in app-level packages, not in `bible_core`.
- Treat every companion app as an independent Flutter app that depends on the
  shared core package plus one shared platform bridge package.

## 1.2 Current implementation changes likely needed

The current codebase is close, but several changes would make the companion
model durable:

- Remove Flutter dependencies from `bible_core`. Today several core files use
  `rootBundle`, and some user-content models import Flutter UI types such as
  `Color`/`Offset`. Move those concerns to adapters or represent them with
  portable primitives in core.
- Refactor TAHOT, TAGNT, syntax, Hebrew text, and Strong's repositories to
  accept a `DataSource` or `PackReader` instead of calling `rootBundle`
  directly. The app can still pass a Flutter asset implementation for bundled
  data.
- Replace global singletons like `TAHOTRepository.instance` with constructors
  or factories. Singletons make it difficult for LightSword, maps, genealogy,
  and sermon tools to point at different pack locations or test fixtures.
- Split "resource identity" from "resource storage". For example, `TAHOT` is a
  logical pack ID; whether it lives in assets, a native shared directory, an
  App Group container, IndexedDB, or the hub iframe should be decided by a
  provider chain.
- Add a versioned pack manifest and schema before building the first companion
  app. At minimum: pack ID, semantic version, schema version, license/source,
  content type, language, canonical book coverage, file hashes, byte size, and
  dependency list.
- Define a canonical route spec as a small shared library, not just prose. Apps
  should call the same route builder/parser for `passage`, `word`, `strongs`,
  `lemma`, `location`, `timeline`, `person`, and `note` links.
- Keep the web hub iframe as an optimization, not the only path. Each app still
  needs a local per-origin cache fallback because iframe storage can be blocked
  by browser settings, CSP, or extensions.

## 1.3 Suggested package boundaries

Long term, the repo could evolve toward these packages:

| Package | Responsibility | Depends on Flutter? |
|---|---|---|
| `bible_core` | Portable models, references, parsers, morphology, syntax models, repository interfaces | No |
| `lightsword_packs` | Pack manifest/schema, pack reader interfaces, SQLite/JSON readers, integrity checks | No, if possible |
| `lightsword_platform` | App Groups, desktop shared paths, web IndexedDB/hub bridge, app-link registration helpers | Yes |
| `bible_app` | Main LightSword reader UI and study mode | Yes |
| Companion apps | Maps, timelines, genealogy, sermon tools, atlas, media, etc. | Yes |

This keeps the commercial-feature surface outside the main reader while still
giving every app the same data vocabulary and navigation rules.

## 1.4 Companion app candidates

Good first companions are the ones that reuse existing data and need only a
small number of new entities:

1. **Bible Atlas / Maps** — entities: place, region, route, event-location;
   links from passages and people. High user value, moderate data work.
2. **Ages** — entities: age/era, person, relationship, event, prophecy,
   date/date range, passage. High Logos-like feel with a lean core impact, and
  stronger as one combined app because genealogies, timelines, events, people,
  and prophecies share the same data model. See [LightSword Ages Development Plan](docs/AGES.md).
3. **Sermon / Teaching Workspace** — mostly user content, notes, outlines,
   exports, and passage links. This should probably depend on a future sync
   contract rather than ship first.
4. **Media / Slides** — depends on sermon workspace and licensing decisions;
   likely later.

The first companion should probably be Atlas or Ages because both prove deep
links, shared packs, route contracts, and lightweight cross-app workflows
without requiring cloud sync first.

## 1.5 Minimal viable implementation path

1. Write the route spec and implement a shared route parser/builder.
2. Refactor one existing data family, preferably syntax or TAHOT, to load via
   an injected `DataSource`/`PackReader` instead of `rootBundle`.
3. Define the first pack manifest format using the current JSON files, even if
   SQLite comes later.
4. Implement a native/web provider chain: shared pack location first, bundled
   asset fallback second, network/download fallback third.
5. Build one small companion proof of concept that can open a passage link from
   LightSword and read one shared pack.
6. Only then decide whether the pack payload should remain JSON or move to
   SQLite. SQLite is attractive for large Logos-like datasets, but proving the
   provider contract first is cheaper and lower risk.

Implementation has started with the original-language repositories: TAHOT and
TAGNT now support constructor-injected data sources, while the main Flutter app
continues to pass its existing asset-backed data source. The next best target is
syntax data, because it is already optional, pack-like, and directly relevant to
Logos-style study features.

Target platforms: iOS, desktop (macOS/Windows/Linux via Flutter), and web
(GitHub Pages, `*.LightSword.app` subdomains).

Two distinct problems to solve for every platform:

1. **Navigation handoff** — jump from one app to specific content in another
   (e.g. a verse reference opens the map app centered on that location).
2. **Shared data** — offline data packs (e.g. the TAHOT Hebrew dataset)
   downloaded once should be usable by every app that needs them, not
   redownloaded per app.

## 2. Navigation handoff

| Platform | Mechanism |
|---|---|
| iOS | Custom URL scheme (`LightSword://passage/john/3/16`) + Universal Links (`https://LightSword.app/passage/john/3/16`) for web fallback |
| Desktop | Custom URL scheme registered per-OS (macOS: `CFBundleURLTypes`; Windows: registry at install time; Linux: `.desktop` MIME handler) |
| Web | Plain URLs with hash or path routing (`https://maps.LightSword.app/#/location/jerusalem`) — no scheme registration needed, works across subdomains natively |

Notes:
- Declare all schemes we query via `canOpenURL` in `LSApplicationQueriesSchemes` (iOS cap: 50 entries).
- Flutter: `app_links` package for receiving deep links on mobile/desktop.
- Design one **URL/route scheme spec** shared across all apps and platforms
  so a "passage" or "location" link means the same thing everywhere (see
  §4).

## 3. Shared data packs

### 3.1 iOS — App Groups

- All Moddest Labs apps share an App Group entitlement.
- Packs are downloaded into the shared container via
  `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` —
  actual shared filesystem, not just key-value storage.
- Any app in the group reads the same files directly. No redownload, no IPC.
- Caveat: deleting the app that owns the App Group may or may not clean up
  the shared container depending on whether sibling apps remain installed —
  test this so a companion app doesn't silently lose access.

### 3.2 Desktop — shared filesystem location

- Use a shared app-data path outside any single app's sandboxed directory:
  - macOS: `~/Library/Application Support/ModdestLabs/packs/`
  - Windows: `%APPDATA%\ModdestLabs\packs\`
  - Linux: `~/.local/share/moddestlabs/packs/`
- All apps read/write via `path_provider` plus a shared constant for the
  subpath.

### 3.3 Web — same-site subdomains

Companion web apps live on `*.LightSword.app` subdomains (e.g.
`maps.LightSword.app`, `ages.LightSword.app`). These are separate
**origins** (no automatic `localStorage`/`IndexedDB` sharing) but the same
**site**, which matters:

- Browser anti-tracking protections (Chrome storage partitioning, Safari
  ITP) key off cross-*site* behavior, not cross-*origin* — same-site
  subdomains are treated as trusted in ways arbitrary third-party domains
  are not. This makes a shared-storage pattern durable here.

**Primary pattern — hub iframe:**

- A quiet page at `data.LightSword.app` (or similar) is embedded as a
  hidden iframe by each companion app.
- The hub owns the actual `IndexedDB` storage for downloaded packs.
- Companions talk to it via `postMessage` RPC: `getPack('TAHOT')`,
  `hasPack('TAHOT')`, `savePack('TAHOT', blob)`.
- Verify `event.origin` against a `*.LightSword.app` pattern on both sides.

**Fallback — per-origin caching:**

- Every companion must also be able to fetch and cache its own copy of a
  pack directly into its own `IndexedDB` if the hub iframe is unreachable
  (ad blockers, embed restrictions, etc.).
- This is not just a web quirk-hedge — treat it as the baseline
  implementation, with the hub as an optimization layered on top.

## 4. Pack format spec

Since up to 4 runtimes (iOS, desktop, web, eventually Android) need to read
the same pack, the pack format is a contract, not an implementation detail
of LightSword.

- [ ] Define a versioned schema for pack contents (SQLite recommended:
      queryable, mmap-friendly, no need to load the whole dataset into
      memory).
- [ ] Document the schema in this repo (separate file, e.g.
      `pack-format-spec.md`) before any companion app starts implementing
      its own reader.
- [ ] Version the format explicitly (e.g. a `pack_version` field) so future
      schema changes don't silently break older companion apps.
- [ ] First concrete pack to spec: TAHOT (Hebrew text/tagging dataset).

## 5. Open questions / to decide

- Exact App Group identifier and which apps are members.
- Final route/URL scheme naming convention (§2) — needs a canonical list
  before the first companion app ships.
- Whether the web hub iframe is a single shared page for all pack types, or
  split per pack.
- Android equivalent for App Groups (likely a `ContentProvider` exposed by
  LightSword, or shared scoped-storage directory) — not yet designed.
