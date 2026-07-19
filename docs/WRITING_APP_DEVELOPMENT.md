# LightSword Write Development Plan

**Status:** Draft development reference  
**Audience:** Contributors planning or implementing the writing companion app  
**Proposed app URL:** `https://write.lightsword.app`

## 1. Product thesis

LightSword Write is a focused writing companion for sermons, lessons, Bible
studies, devotionals, and other Scripture-centered content. It should feel like
a real writing workspace first, not a note widget attached to a reader. The app
should help users move from passage study to structured teaching material while
staying connected to LightSword's biblical data, references, and future sync
contracts.

The useful distinction is:

- **LightSword** is the reading and study surface.
- **LightSword Write** is the composition, organization, and publishing surface.
- **Future companion apps** such as atlas, ages, and media tools
  can provide insertable research blocks, visuals, and export targets. See the
  [LightSword Ages plan](AGES.md) for the proposed ages companion.

The writing app can begin as a separate repository and deployment target under
`write.lightsword.app`, but it should not become an island. It should consume
the same shared route contracts, reference parser, pack manifest vocabulary, and
eventually the same user-content sync model.

## 2. Why this should be a companion app

Sermon and content writing is user-content heavy: drafts, outlines, notes,
exports, media, revisions, and probably collaboration or account-backed sync
later. Keeping it outside the main reader protects LightSword's lean core while
still allowing a deeper workflow for users who need it.

Compared with atlas or timeline companions, Write has less need for large
read-only datasets at first, but it has more need for durable user data. That
means the first implementation should bias toward local-first persistence,
portable exports, and stable document schemas before adding cloud features.

## 3. Target users and jobs

Primary users:

- Pastors preparing sermons and teaching series.
- Bible study leaders building weekly lessons.
- Writers creating devotionals, articles, or study guides.
- Students organizing exegetical notes into a finished document.

Core jobs:

- Capture research from LightSword into a draft without losing references.
- Build a sermon or lesson outline from a passage, theme, or series plan.
- Quote Scripture with translation attribution and durable passage links.
- Keep notes, observations, illustrations, applications, and sources organized.
- Export or publish content in formats useful for preaching, teaching, and
  sharing.

## 4. MVP scope

The first version should prove the writing workflow and ecosystem connection
without depending on a full cloud backend.

### 4.1 MVP features

- Local document library with search, tags, and basic filtering.
- Rich text or structured Markdown editor with headings, lists, block quotes,
  footnotes, and Scripture blocks.
- Sermon/lesson outline mode with movable sections.
- Passage insertion from a normalized Bible reference.
- Deep links back to LightSword passages and original-language word studies.
- Export to Markdown, HTML, PDF, and plain text.
- Import/export of a portable JSON document package for backup and migration.
- Browser PWA deployment at `write.lightsword.app`.

### 4.2 Deliberately out of scope for MVP

- Real-time collaboration.
- AI-generated sermon writing.
- Full slide deck creation.
- Public hosting of published sermons.
- Account-backed sync, unless the broader LightSword sync contract is ready.
- A custom Bible text licensing strategy beyond existing allowed sources.

## 5. Recommended initial architecture

Start as an independent Flutter app if the goal is to share code and platform
patterns with the existing LightSword apps. A web-first Flutter PWA is a good
starting point because the proposed domain is web-native, while Flutter keeps a
path open for desktop and tablet apps later.

Suggested repository layout:

```text
write.lightsword.app/
  README.md
  docs/
    ARCHITECTURE.md
    DOCUMENT_FORMAT.md
    ROUTES.md
  write_app/
    pubspec.yaml
    lib/
      main.dart
      editor/
      library/
      documents/
      scripture/
      export/
      platform/
      state/
    test/
    web/
```

If this app eventually joins the current monorepo, it can live beside
`bible_app` and `bible_core` as `write_app`. If it starts as a separate repo,
it should depend on shared packages by Git reference or published internal
packages once those boundaries are stable.

## 6. Shared LightSword contracts

The writing app should reuse or track these ecosystem contracts:

| Contract | Needed for Write | Notes |
|---|---|---|
| Reference parsing | Yes | Normalize user-entered references like `John 3:16-18`. |
| Route builder/parser | Yes | Create durable links to passages, words, notes, and documents. |
| Pack manifests | Later | Useful for Bible text, lexicons, media, or research packs. |
| User-content model | Yes | Write documents should share sync/versioning ideas with notes/highlights. |
| Platform storage | Yes | Local-first storage should align with shared app storage decisions. |

The app should not import LightSword's reader UI. It should consume portable
domain code from `bible_core` or future shared packages.

## 7. Document model

Use a stable document schema from the beginning. The editor implementation can
change, but saved documents should remain portable.

Suggested top-level model:

```json
{
  "schemaVersion": 1,
  "id": "doc_...",
  "kind": "sermon",
  "title": "The Good Shepherd",
  "subtitle": "John 10:1-18",
  "status": "draft",
  "createdAt": "2026-07-19T00:00:00Z",
  "updatedAt": "2026-07-19T00:00:00Z",
  "primaryPassages": ["john.10.1-18"],
  "tags": ["john", "christology"],
  "seriesId": null,
  "blocks": [],
  "sources": [],
  "sync": {
    "version": 1,
    "deleted": false
  }
}
```

Suggested block types:

- `heading`
- `paragraph`
- `outline_item`
- `scripture_quote`
- `observation`
- `interpretation`
- `application`
- `illustration`
- `quote`
- `source_note`
- `callout`

Scripture quote blocks should store both the human-readable display text and a
normalized reference key. That keeps exports stable while preserving deep-link
behavior.

## 8. Editor strategy

There are two reasonable paths:

1. **Structured Markdown first**  
   Faster to implement, easy to export, easy to diff, and friendly to plain-text
   backups. Add typed blocks by storing metadata beside Markdown.

2. **Block editor first**  
   Better long-term UX for sermon sections, Scripture blocks, research cards,
   and drag-and-drop organization. More work up front and more schema risk.

Recommendation: start with a structured document model and render it as an
outline-aware editor. Export Markdown as a first-class format, but avoid making
raw Markdown the only source of truth if the app is expected to support sermons,
slides, and research blocks later.

## 9. Storage and sync posture

For MVP, use local-first storage:

- Web: IndexedDB.
- Desktop/mobile later: app documents directory or shared Moddest Labs storage.
- Export/import: zipped JSON package with optional Markdown and assets.

Every document should have stable IDs, timestamps, version numbers, and soft
delete metadata from the beginning. This keeps the path open for future sync
without committing to a backend before the product shape is proven.

Possible sync phases:

1. Local-only documents plus manual export/import.
2. Private cloud backup per user.
3. Cross-device sync.
4. Collaboration and shared libraries.

## 10. Deep links and routes

The writing app should support incoming and outgoing links.

Incoming routes:

- `/new?passage=john.10.1-18`
- `/document/{documentId}`
- `/series/{seriesId}`
- `/search?q=resurrection`

Outgoing LightSword routes:

- Passage: `https://lightsword.app/passage/john/10/1-18`
- Strong's: `https://lightsword.app/strongs/G4166`
- Lemma: `https://lightsword.app/lemma/poimen`
- Note or user content: final format depends on the shared route spec.

The final route names should be implemented through a shared parser/builder so
both apps generate the same URLs.

## 11. Export targets

Initial exports:

- Markdown for backup, editing, and portability.
- HTML for web publishing or copying into CMS tools.
- PDF for printing and preaching notes.
- Plain text for quick sharing.
- JSON package for round-tripping back into LightSword Write.

Later exports:

- Slides or sermon presentation package.
- DOCX, if users need church-office workflows.
- Static sermon page publishing.
- Podcast or transcript metadata.

## 12. Design direction

The app should feel like a quiet professional writing desk for biblical work:
calm, legible, fast, and organized. Avoid making the first screen a marketing
page. The primary screen should be the document library or active editor.

Core surfaces:

- Left library/sidebar for documents, series, tags, and search.
- Center editor with strong typography and generous line length control.
- Right research/reference panel for passages, notes, lexical details, and
  source material.
- Outline rail for sermon structure and fast navigation.

## 13. Development phases

### Phase 0 - Repo and contracts

- Create the `write.lightsword.app` repository.
- Scaffold a Flutter web app.
- Add architecture and document-format docs.
- Decide how the app consumes `bible_core` or extracted shared packages.
- Implement reference normalization and route helpers.

### Phase 1 - Local writing MVP

- Document library.
- Local persistence.
- Structured editor.
- Passage insertion.
- Markdown/HTML/plain-text export.
- JSON import/export package.

### Phase 2 - LightSword integration

- Open Write from a LightSword passage.
- Open LightSword from a document Scripture block.
- Reuse shared pack or reference providers where appropriate.
- Add research panel backed by LightSword data APIs.

### Phase 3 - Sermon workflow depth

- Series planning.
- Preaching mode or speaker notes.
- Source library.
- PDF export polish.
- Optional slide handoff.

### Phase 4 - Sync and publishing

- Account-backed backup.
- Cross-device sync.
- Shared document libraries.
- Public or private publishing workflows.

## 14. Technical decisions to make early

- Separate repo versus monorepo package.
- Flutter editor package choice, or custom editor surface.
- Canonical saved document format.
- Whether Scripture quote text is stored, regenerated, or both.
- Initial Bible translation/source strategy for quoted text.
- IndexedDB schema and migration strategy.
- Export rendering engine for PDF.
- Whether Write owns sermon-specific sync or waits for ecosystem sync.

## 15. Open questions

- Should the app be named **LightSword Write**, **LightSword Sermon Studio**,
  or something broader?
- Is the first target pastor sermons, small-group lessons, or general biblical
  writing?
- Should documents be passage-first, topic-first, or flexible?
- Should the app support offline Bible text insertion in MVP, or require opening
  LightSword for Bible lookup?
- What export format matters most to the first real users?
- Should slide generation be part of this app or a later media companion?

## 16. Recommended next step

Create a separate `write.lightsword.app` repository with a small Flutter PWA and
commit only three product commitments at first:

1. A local document library.
2. A stable document schema.
3. Passage-aware writing blocks that deep-link back to LightSword.

That proves the product direction while preserving room for richer sermon,
lesson, publishing, and sync workflows later.