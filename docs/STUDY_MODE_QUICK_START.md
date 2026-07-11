# Study Mode Quick Start Guide

## Overview

You've implemented a complete study mode architecture with three reading modes and powerful annotation capabilities. This guide will help you get started using the new features.

## Quick Start

### 1. Display a Chapter with All Three Modes

```dart
import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/ui/widgets/chapter_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<Chapter>(
          future: loadChapter('GEN', 1),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return ChapterView(chapter: snapshot.data!);
          },
        ),
      ),
    );
  }
  
  Future<Chapter> loadChapter(String bookId, int chapterNum) async {
    // Your existing chapter loading logic
  }
}
```

### 2. Switch Between Reading Modes

The `ChapterView` widget provides a mode selector in the app bar:
- **Verse Mode** - Traditional verse-by-verse reading
- **Interlinear Mode** - Word-by-word with Hebrew/Greek
- **Study Mode** - Paragraph form with annotations

Users can switch modes via the view module icon in the app bar.

### 3. Add Highlights (Study Mode)

In study mode, users can:
1. Select text
2. Tap the "Highlight" button in the floating toolbar
3. Choose a color from the color picker
4. The highlight is automatically saved

Programmatically:
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
  note: 'Important passage',
);

await controller.addHighlight(highlight);
```

### 4. Add Arcs (Study Mode)

To show syntactic relationships:
1. Select text spanning two words
2. Tap the "Arc" button
3. Choose an arc type (subject, verb, object, etc.)
4. Choose a color

Programmatically:
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
  toWordIndex: 3,
  type: ArcType.subject,
  color: Colors.blue,
  label: 'Subject',
  style: ArcStyle.curved,
);

await controller.addArc(arc);
```

### 5. Add Study Notes

```dart
final note = StudyNote.create(
  reference: PassageReference(
    bookId: 'GEN',
    chapterStart: 1,
    chapterEnd: 1,
  ),
  content: 'Genesis 1 describes the six days of creation...',
  tags: ['creation', 'theology', 'beginnings'],
);

await controller.addNote(note);
```

## Available Colors

### Highlight Colors
- Yellow (#FFEB3B) - General emphasis
- Green (#4CAF50) - Promises
- Blue (#2196F3) - Commands
- Orange (#FF9800) - Warnings
- Purple (#9C27B0) - Prophecy
- Pink (#E91E63) - Love/Grace
- Red (#F44336) - Important
- Cyan (#00BCD4) - Water themes

## Arc Types

- **Subject** - The doer of the action
- **Verb** - The action itself
- **Direct Object** - Receives the action
- **Indirect Object** - To whom/for whom
- **Modifier** - Describes or modifies
- **Prepositional Phrase** - Location, time, manner
- **Clause** - Dependent or independent clauses
- **Comparison** - Similes, metaphors
- **Contrast** - Opposition or difference
- **Cause** - Reason or cause
- **Effect** - Result or consequence
- **Custom** - User-defined relationships

## Export and Import

### Export Content
```dart
final ids = [highlight1.id, arc1.id, note1.id];
final json = await controller.exportContent(ids);
// Save to file or share
```

### Import Content
```dart
final json = '...'; // Load from file or clipboard
await controller.importContent(json);
```

## Customization

### Study Mode Settings
```dart
controller.updateStudySettings(
  StudyModeSettings(
    showArcs: true,
    showHighlights: true,
    showNotes: true,
    arcDisplayStyle: ArcStyle.curved,
    textSize: 18.0,
    paragraphMode: true,
  ),
);
```

### Custom Color Schemes
Add your own colors to `HighlightColors`:
```dart
class HighlightColors {
  static const myCustomColor = Color(0xFF123456);
  static const List<Color> all = [
    yellow, green, blue, orange, purple, pink, red, cyan,
    myCustomColor,  // Add custom colors here
  ];
}
```

## Next Steps: Adding SQLite Backend

Currently, the app uses in-memory storage. To add persistence:

### 1. Add sqflite Dependency
```yaml
# bible_app/pubspec.yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3
```

### 2. Create Database Helper
```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }
  
  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'lightsword.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create highlights table
    await db.execute('''
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
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
    
    // Create arcs table
    await db.execute('''
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
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
    
    // Create study_notes table
    await db.execute('''
      CREATE TABLE study_notes (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse_start INTEGER,
        verse_end INTEGER,
        content TEXT NOT NULL,
        tags TEXT,
        attached_highlight_ids TEXT,
        attached_arc_ids TEXT,
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
  }
}
```

### 3. Update LocalUserContentRepository

Replace the in-memory maps with SQLite operations:
```dart
class LocalUserContentRepository implements UserContentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  @override
  Future<void> saveHighlight(Highlight highlight) async {
    final db = await _dbHelper.database;
    await db.insert(
      'highlights',
      highlight.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  @override
  Future<List<Highlight>> getHighlights(PassageReference reference) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'highlights',
      where: 'book_id = ? AND chapter = ? AND is_deleted = 0',
      whereArgs: [reference.bookId, reference.chapterStart],
    );
    return maps.map((m) => Highlight.fromJson(m)).toList();
  }
  
  // Implement other methods similarly
}
```

## Troubleshooting

### Text Selection Not Working
- Ensure you're using `SelectableText.rich` in study mode
- Check that the text widget has focus

### Arcs Not Displaying
- Verify `showArcs` is true in study settings
- Check that arc geometry is being calculated
- Ensure CustomPaint is wrapping the text widget

### Highlights Not Persisting
- Confirm you're using the SQLite implementation
- Check database file location and permissions
- Verify `saveHighlight` is being called

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│          ChapterView Widget             │
│  ┌─────────────────────────────────┐   │
│  │   ChapterViewController          │   │
│  │  - switchMode()                  │   │
│  │  - addHighlight()                │   │
│  │  - addArc()                      │   │
│  │  - addNote()                     │   │
│  └──────────────┬──────────────────┘   │
└─────────────────┼───────────────────────┘
                  │
      ┌───────────┼───────────┐
      │           │           │
      ▼           ▼           ▼
┌──────────┐ ┌─────────┐ ┌──────────┐
│  Verse   │ │Interlin.│ │  Study   │
│   Mode   │ │  Mode   │ │   Mode   │
└──────────┘ └─────────┘ └────┬─────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
            ┌──────────────┐      ┌─────────────┐
            │  ArcPainter  │      │StudyToolbar │
            └──────────────┘      └─────────────┘
                    │
                    ▼
        ┌──────────────────────┐
        │ UserContentRepository│
        │  - LocalRepository   │
        │  - CloudRepository   │
        └──────────────────────┘
```

## Additional Resources

- [STUDY_MODE.md](./STUDY_MODE.md) - Complete architecture documentation
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Overall app architecture
- Flutter CustomPaint: https://api.flutter.dev/flutter/widgets/CustomPaint-class.html
- Sqflite: https://pub.dev/packages/sqflite
