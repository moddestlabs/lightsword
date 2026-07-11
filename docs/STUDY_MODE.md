# Study Mode Architecture

## Overview

The study mode feature adds powerful annotation capabilities to Lightsword, including:
- **Three reading modes**: Verse-by-verse, Interlinear, and Study
- **Highlights**: Color-coded text highlighting with 8 predefined colors
- **Arcs**: Syntactic/semantic relationship diagrams connecting words
- **Notes**: Rich study notes with tags and attachments
- **Cloud-ready**: Built for future synchronization and sharing

## Architecture

### Core Components

#### 1. Data Models (`bible_core/lib/models/`)

**SyncableEntity** - Base class for all user content
```dart
abstract class SyncableEntity {
  final String id;              // UUID for global uniqueness
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? userId;         // For multi-user scenarios
  final bool isDeleted;         // Soft deletes for sync
  final int version;            // Optimistic locking
  final String syncStatus;      // 'local', 'synced', 'pending', 'conflict'
}
```

**Highlight** - Text highlighting
- Color-coded emphasis on verse ranges
- Optional notes attached to highlights
- Word-level precision (wordStart/wordEnd)
- Public/private sharing flags

**Arc** - Syntactic/semantic arcs
- Connect words to show relationships
- Types: subject, verb, object, modifier, clause, etc.
- Styles: curved, straight, above, below
- Color-coded with optional labels

**StudyNote** - Study notes
- Markdown or plain text content
- Tag-based organization
- Links to highlights and arcs
- Passage-level or verse-level

#### 2. Repository Layer (`bible_core/lib/services/`)

**UserContentRepository** - Abstract interface
```dart
abstract class UserContentRepository {
  // CRUD for highlights, arcs, notes
  Future<void> saveHighlight(Highlight highlight);
  Future<List<Highlight>> getHighlights(PassageReference ref);
  
  // Sync and sharing
  Future<SyncStatus> sync();
  Future<void> importSharedContent(String json);
  Future<String> exportContent(List<String> ids);
}
```

**LocalUserContentRepository** - In-memory implementation
- Current: In-memory storage for testing
- Future: SQLite backend with sqflite package
- Implements soft deletes for sync compatibility

#### 3. State Management (`bible_app/lib/state/`)

**ChapterViewController** - Manages all chapter views
```dart
class ChapterViewController extends ChangeNotifier {
  ChapterViewState state;
  
  // Mode switching
  void switchMode(ReadingMode mode);
  
  // User content operations
  Future<void> addHighlight(Highlight h);
  Future<void> addArc(Arc a);
  Future<void> addNote(StudyNote n);
  
  // Export/import
  Future<String> exportContent(List<String> ids);
  Future<void> importContent(String json);
}
```

**ReadingMode** enum
- `verse` - Traditional verse-by-verse
- `interlinear` - Word-by-word with Hebrew/Greek
- `study` - Paragraph form with annotations

#### 4. UI Widgets (`bible_app/lib/ui/widgets/`)

**VerseReadingView** - Traditional reading
- One verse per line
- Optional verse numbers
- Simple highlight display

**InterlinearChapterView** - Already exists
- Word-by-word original languages
- Morphology and glosses

**StudyModeView** - Advanced study features
- Paragraph or verse-per-line layout
- Interactive text selection
- Floating toolbar for annotations
- Arc visualization overlay
- Notes section below text

**ArcPainter** - Custom painter for arcs
- Bezier curves connecting words
- Arrow heads indicating direction
- Labels for arc types
- Multiple visual styles

**StudyToolbar** - Selection toolbar
- Highlight (with color picker)
- Arc (with type picker)
- Note (with editor dialog)
- Copy and Share (optional)

## Usage

### Basic Setup

```dart
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/state/chapter_view_controller.dart';
import 'package:bible_app/ui/widgets/verse_reading_view.dart';
import 'package:bible_app/ui/widgets/study_mode_view.dart';

// Create repository
final repository = LocalUserContentRepository();

// Create controller
final controller = ChapterViewController(repository, chapter);

// Build UI
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      switch (controller.state.mode) {
        case ReadingMode.verse:
          return VerseReadingView(controller: controller);
        case ReadingMode.interlinear:
          return InterlinearChapterView(controller: controller);
        case ReadingMode.study:
          return StudyModeView(controller: controller);
      }
    },
  );
}
```

### Adding Highlights

```dart
final highlight = Highlight.create(
  reference: PassageReference(
    bookId: 'GEN',
    chapterStart: 1,
    chapterEnd: 1,
    verseStart: 1,
    verseEnd: 1,
  ),
  wordStart: 0,
  wordEnd: 5,
  color: HighlightColors.yellow,
  note: 'Beginning of creation',
);

await controller.addHighlight(highlight);
```

### Adding Arcs

```dart
final arc = Arc.create(
  reference: PassageReference(
    bookId: 'GEN',
    chapterStart: 1,
    chapterEnd: 1,
    verseStart: 1,
    verseEnd: 1,
  ),
  fromWordIndex: 0,
  toWordIndex: 2,
  type: ArcType.subject,
  color: Colors.blue,
  label: 'Subject',
);

await controller.addArc(arc);
```

### Adding Notes

```dart
final note = StudyNote.create(
  reference: PassageReference(
    bookId: 'GEN',
    chapterStart: 1,
    chapterEnd: 1,
  ),
  content: 'Genesis 1 describes the creation week...',
  tags: ['creation', 'theology'],
);

await controller.addNote(note);
```

## Database Schema (Future SQLite Implementation)

```sql
CREATE TABLE highlights (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_start INTEGER NOT NULL,
  verse_end INTEGER NOT NULL,
  word_start INTEGER NOT NULL,
  word_end INTEGER NOT NULL,
  color INTEGER NOT NULL,
  note TEXT,
  is_public INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  is_deleted INTEGER DEFAULT 0,
  version INTEGER DEFAULT 1,
  sync_status TEXT DEFAULT 'local'
);

CREATE TABLE arcs (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  from_word_index INTEGER NOT NULL,
  to_word_index INTEGER NOT NULL,
  arc_type TEXT NOT NULL,
  color INTEGER NOT NULL,
  label TEXT,
  style TEXT NOT NULL,
  is_public INTEGER DEFAULT 0,
  metadata TEXT,
  created_at INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  is_deleted INTEGER DEFAULT 0,
  version INTEGER DEFAULT 1,
  sync_status TEXT DEFAULT 'local'
);

CREATE TABLE study_notes (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_start INTEGER,
  verse_end INTEGER,
  content TEXT NOT NULL,
  tags TEXT,
  is_public INTEGER DEFAULT 0,
  attached_highlight_ids TEXT,
  attached_arc_ids TEXT,
  created_at INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  is_deleted INTEGER DEFAULT 0,
  version INTEGER DEFAULT 1,
  sync_status TEXT DEFAULT 'local'
);
```

## Future Enhancements

### Phase 2: SQLite Backend
- Implement persistent storage with sqflite
- Add database migrations
- Implement indexing for fast queries

### Phase 3: Cloud Sync
- Implement CloudUserContentRepository
- Two-way sync with conflict resolution
- Use timestamps and version numbers for merging

### Phase 4: Community Sharing
- Public content repository
- Search and discover community annotations
- Subscribe to authors
- Import/export content packages

### Phase 5: Advanced Features
- Multi-word highlighting based on actual word positions
- Calculate arc geometry from text layout
- Collaborative annotations
- Version history and rollback
- Export to various formats (PDF, Markdown, etc.)

## Color Palette

Predefined highlight colors:
- Yellow (#FFEB3B) - General emphasis
- Green (#4CAF50) - Promises, growth
- Blue (#2196F3) - Commands, teaching
- Orange (#FF9800) - Warnings, caution
- Purple (#9C27B0) - Prophecy, royal
- Pink (#E91E63) - Love, grace
- Red (#F44336) - Important, judgment
- Cyan (#00BCD4) - Water, cleansing

## Arc Types

Predefined syntactic/semantic relationships:
- Subject
- Verb
- Direct Object
- Indirect Object
- Modifier
- Prepositional Phrase
- Clause
- Comparison
- Contrast
- Cause
- Effect
- Custom

## Testing

### Unit Tests (bible_core)
```bash
cd bible_core
dart test
```

### Widget Tests (bible_app)
```bash
cd bible_app
flutter test
```

## Performance Considerations

1. **Lazy Loading**: Load content only for visible chapters
2. **Pagination**: Limit query results for large datasets
3. **Caching**: Cache frequently accessed content
4. **Debouncing**: Debounce save operations on rapid edits
5. **Arc Rendering**: Calculate geometry only when needed
6. **Background Sync**: Sync in background thread

## Accessibility

- Semantic labels for screen readers
- High contrast mode support
- Keyboard navigation
- Voice control compatibility
- Adjustable text size

## Security

- No PII stored without consent
- Optional encryption for local data
- HTTPS-only for cloud sync
- OAuth for authentication
- Rate limiting on API endpoints
