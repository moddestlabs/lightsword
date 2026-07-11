# Drawing Feature Quick Start

## Overview
This guide shows how to add the vector drawing feature to your Bible app's Study Mode.

## Architecture

### Models
- **Drawing**: Main entity representing a collection of strokes anchored to Bible content
- **DrawingStroke**: A single continuous pen/pencil/highlighter stroke
- **DrawingPoint**: Individual point in a stroke with position and pressure data
- **DrawingZone**: Enum for margin vs overlay positioning

### Widgets
- **DrawingCanvas**: Interactive gesture detection for creating strokes
- **DrawingPainter**: CustomPainter that renders vector drawings
- **DrawingToolbar**: Tool selection UI (pen, highlighter, colors, etc.)

### Services
- **DrawingService**: Business logic for managing drawings
- **UserContentRepository**: Extended with drawing CRUD operations

## Integration Example

### Step 1: Update Study Mode View

Wrap your study mode content with DrawingCanvas:

```dart
class _StudyModeViewState extends State<StudyModeView> {
  bool _isDrawingMode = false;
  DrawingToolSettings _toolSettings = const DrawingToolSettings();
  List<Drawing> _drawings = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DrawingCanvas(
        enabled: _isDrawingMode,
        settings: _toolSettings,
        onStrokeCompleted: _handleStrokeCompleted,
        child: Stack(
          children: [
            // Original study mode content
            _buildStudyContent(),
            
            // Drawing overlay
            if (_drawings.isNotEmpty)
              CustomPaint(
                painter: DrawingPainter(
                  drawings: _drawings,
                  versePositions: _calculateVersePositions(),
                  currentTextSize: widget.controller.state.studySettings.textSize,
                  viewportSize: MediaQuery.of(context).size,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: DrawingToolbar(
        settings: _toolSettings,
        onSettingsChanged: (settings) {
          setState(() => _toolSettings = settings);
        },
        isDrawingMode: _isDrawingMode,
        onToggleDrawingMode: () {
          setState(() => _isDrawingMode = !_isDrawingMode);
        },
      ),
    );
  }
}
```

### Step 2: Handle Stroke Completion

```dart
void _handleStrokeCompleted(DrawingStroke stroke) async {
  // Determine anchor verse (e.g., first visible verse)
  final anchorVerse = _getAnchorVerse();
  
  // Create drawing entity
  final drawing = Drawing.create(
    reference: PassageReference(
      bookId: widget.controller.state.chapter.bookId,
      chapter: widget.controller.state.chapter.number,
      startVerse: anchorVerse,
    ),
    zone: _determineZone(stroke),
    strokes: [stroke],
    anchorOffset: _calculateAnchorOffset(stroke),
    baseTextSize: widget.controller.state.studySettings.textSize,
    color: _toolSettings.color,
    strokeWidth: _toolSettings.strokeWidth,
  );
  
  // Save to repository
  await widget.controller.addDrawing(drawing);
  
  // Update UI
  setState(() {
    _drawings.add(drawing);
  });
}
```

### Step 3: Calculate Verse Positions

For content anchoring to work, you need to track verse positions:

```dart
Map<int, Rect> _calculateVersePositions() {
  final positions = <int, Rect>{};
  
  // Use GlobalKey to get RenderBox for each verse
  for (var verse in widget.controller.state.chapter.verses) {
    final key = _verseKeys[verse.number];
    if (key?.currentContext != null) {
      final RenderBox box = key!.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      positions[verse.number] = Rect.fromLTWH(
        position.dx,
        position.dy,
        box.size.width,
        box.size.height,
      );
    }
  }
  
  return positions;
}
```

### Step 4: Extend ChapterViewController

Add drawing methods to your controller:

```dart
class ChapterViewController extends ChangeNotifier {
  final DrawingService _drawingService;
  
  Future<void> addDrawing(Drawing drawing) async {
    await _drawingService.addDrawing(drawing);
    await _reloadDrawings();
    notifyListeners();
  }
  
  Future<void> deleteDrawing(String id) async {
    await _drawingService.deleteDrawing(id);
    await _reloadDrawings();
    notifyListeners();
  }
  
  Future<void> _reloadDrawings() async {
    final drawings = await _drawingService.getChapterDrawings(
      _state.chapter.bookId,
      _state.chapter.number,
    );
    _state = _state.copyWith(drawings: drawings);
  }
}
```

### Step 5: Add to ChapterViewState

```dart
@immutable
class ChapterViewState {
  final Chapter chapter;
  final ReadingMode mode;
  final List<Highlight> highlights;
  final List<Arc> arcs;
  final List<StudyNote> notes;
  final List<Drawing> drawings;  // Add this
  final StudyModeSettings studySettings;
  
  // ... rest of implementation
}
```

## Database Setup

Add the drawings table to your local database:

```sql
CREATE TABLE IF NOT EXISTS drawings (
  id TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  user_id TEXT,
  is_deleted INTEGER DEFAULT 0,
  version INTEGER DEFAULT 1,
  sync_status TEXT DEFAULT 'local',
  book_id TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_start INTEGER,
  verse_end INTEGER,
  anchor_word_index INTEGER,
  zone TEXT NOT NULL,
  anchor_offset_x REAL NOT NULL,
  anchor_offset_y REAL NOT NULL,
  base_text_size REAL NOT NULL,
  color INTEGER NOT NULL,
  stroke_width REAL NOT NULL,
  strokes_json TEXT NOT NULL,
  is_public INTEGER DEFAULT 0,
  shared_from_user_id TEXT
);

CREATE INDEX idx_drawings_reference ON drawings(book_id, chapter, verse_start);
CREATE INDEX idx_drawings_user ON drawings(user_id);
```

## Repository Implementation

Implement drawing methods in LocalUserContentRepository:

```dart
@override
Future<void> saveDrawing(Drawing drawing) async {
  final db = await _database;
  await db.insert(
    'drawings',
    drawing.toJson(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

@override
Future<void> deleteDrawing(String id) async {
  final db = await _database;
  await db.delete(
    'drawings',
    where: 'id = ?',
    whereArgs: [id],
  );
}

@override
Future<List<Drawing>> getDrawings(PassageReference reference) async {
  final db = await _database;
  final maps = await db.query(
    'drawings',
    where: 'book_id = ? AND chapter = ? AND is_deleted = 0',
    whereArgs: [reference.bookId, reference.chapter],
  );
  return maps.map((map) => Drawing.fromJson(map)).toList();
}
```

## Advanced Features

### Margin Configuration

Add settings for margin width:

```dart
class StudyModeSettings {
  final bool showMargins;
  final double marginWidth;  // 0.1 to 0.3 (10% to 30%)
  final bool lockMargins;    // Prevent accidental drawing over content
  
  // ... rest of implementation
}
```

### Undo/Redo

Implement stroke history:

```dart
class DrawingHistory {
  final List<Drawing> _history = [];
  int _currentIndex = -1;
  
  void addDrawing(Drawing drawing) {
    // Remove any "future" history
    _history.removeRange(_currentIndex + 1, _history.length);
    _history.add(drawing);
    _currentIndex++;
  }
  
  Drawing? undo() {
    if (_currentIndex > 0) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return null;
  }
  
  Drawing? redo() {
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return null;
  }
}
```

### Shape Tools

Add preset shapes (lines, arrows, boxes):

```dart
enum DrawingShape {
  freehand,
  line,
  arrow,
  rectangle,
  circle,
}

DrawingStroke createShapeStroke(
  DrawingShape shape,
  Offset start,
  Offset end,
  DrawingToolSettings settings,
) {
  switch (shape) {
    case DrawingShape.line:
      return DrawingStroke(
        points: [
          DrawingPoint(position: start),
          DrawingPoint(position: end),
        ],
        color: settings.color,
        width: settings.strokeWidth,
        style: settings.style,
      );
    
    case DrawingShape.arrow:
      // Calculate arrowhead points
      final angle = atan2(end.dy - start.dy, end.dx - start.dx);
      final arrowSize = 10.0;
      final left = Offset(
        end.dx - arrowSize * cos(angle - pi / 6),
        end.dy - arrowSize * sin(angle - pi / 6),
      );
      final right = Offset(
        end.dx - arrowSize * cos(angle + pi / 6),
        end.dy - arrowSize * sin(angle + pi / 6),
      );
      
      return DrawingStroke(
        points: [
          DrawingPoint(position: start),
          DrawingPoint(position: end),
          DrawingPoint(position: left),
          DrawingPoint(position: end),
          DrawingPoint(position: right),
        ],
        color: settings.color,
        width: settings.strokeWidth,
        style: settings.style,
      );
    
    // ... other shapes
  }
}
```

## Testing

### Unit Tests

```dart
void main() {
  group('Drawing Model', () {
    test('serialization round-trip', () {
      final drawing = Drawing.create(
        reference: PassageReference(bookId: 'John', chapter: 3, startVerse: 16),
        zone: DrawingZone.leftMargin,
        strokes: [
          DrawingStroke(
            points: [
              DrawingPoint(position: Offset(0.1, 0.2)),
              DrawingPoint(position: Offset(0.3, 0.4)),
            ],
            color: Colors.red,
            width: 2.0,
          ),
        ],
        anchorOffset: Offset(0.5, 0.5),
        baseTextSize: 16.0,
      );
      
      final json = drawing.toJson();
      final restored = Drawing.fromJson(json);
      
      expect(restored.id, drawing.id);
      expect(restored.strokes.length, 1);
      expect(restored.strokes.first.points.length, 2);
    });
  });
}
```

### Integration Tests

```dart
void main() {
  testWidgets('Drawing mode creates strokes', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // Navigate to study mode
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();
    
    // Enter drawing mode
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    
    // Draw a stroke
    await tester.dragFrom(
      Offset(100, 100),
      Offset(200, 200),
    );
    await tester.pumpAndSettle();
    
    // Verify stroke was saved
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
```

## Performance Optimization

### Culling Off-Screen Drawings

```dart
List<Drawing> _getVisibleDrawings(ScrollController scrollController) {
  final viewport = Rect.fromLTWH(
    0,
    scrollController.offset,
    viewportSize.width,
    viewportSize.height,
  );
  
  return _drawings.where((drawing) {
    final versePos = versePositions[drawing.reference.startVerse];
    if (versePos == null) return false;
    return viewport.overlaps(versePos);
  }).toList();
}
```

### Path Caching

```dart
class CachedDrawingPainter extends CustomPainter {
  final Map<String, Path> _pathCache = {};
  double _lastTextSize = 0;
  
  @override
  void paint(Canvas canvas, Size size) {
    if (currentTextSize != _lastTextSize) {
      _pathCache.clear();
      _lastTextSize = currentTextSize;
    }
    
    for (var drawing in drawings) {
      final path = _pathCache.putIfAbsent(
        drawing.id,
        () => _buildPath(drawing),
      );
      canvas.drawPath(path, _getPaint(drawing));
    }
  }
}
```

## Next Steps

1. **Implement database schema** for drawings
2. **Add drawing methods** to LocalUserContentRepository
3. **Integrate DrawingCanvas** into Study Mode
4. **Add DrawingToolbar** UI
5. **Test with various text sizes** to verify anchoring
6. **Add undo/redo** functionality
7. **Implement shape tools** (optional)
8. **Add export/import** for sharing drawings

## Resources

- [DRAWING_SYSTEM.md](DRAWING_SYSTEM.md) - Detailed architecture
- [STUDY_MODE.md](STUDY_MODE.md) - Study mode overview
- Flutter CustomPainter: https://api.flutter.dev/flutter/rendering/CustomPainter-class.html
- Gesture Detection: https://api.flutter.dev/flutter/widgets/GestureDetector-class.html
