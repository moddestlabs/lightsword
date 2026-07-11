# Vector Drawing System

## Overview
This document describes the content-anchored vector drawing system that allows users to draw freehand sketches in their Bible that maintain positioning relative to text content even when text size changes.

## Key Concepts

### 1. Vector Storage (Not Bitmap)
All drawings are stored as vector paths (SVG-like bezier curves), not bitmaps. This ensures:
- Scalability without quality loss
- Small storage footprint
- Cross-platform compatibility
- Easy manipulation and editing

### 2. Content Anchoring
Unlike Pencil Bible (which uses fixed pixel positions), drawings are anchored to:
- **Verse references**: Which verse(s) the drawing relates to
- **Word positions**: Optional anchor to specific word indices
- **Relative positioning**: Offsets as percentages of container width/height

### 3. Drawing Zones
Three types of drawing areas:
1. **Left Margin**: Fixed width area (e.g., 20% of screen) for notes/sketches
2. **Right Margin**: Similar to left margin
3. **Content Overlay**: Drawings that appear over/around the actual text

### 4. Coordinate System
- **Anchor Point**: (verse, word) tuple that defines the logical anchor
- **Relative Offset**: (x%, y%) offset from anchor in viewport percentages
- **Path Points**: Vector coordinates relative to the anchor
- **Scale Factor**: Maintains consistent visual size across devices

## Data Model

### Drawing Entity
```dart
class Drawing extends SyncableEntity {
  final PassageReference reference;      // Verse anchor
  final int? anchorWordIndex;            // Optional word anchor
  final DrawingZone zone;                // Margin or overlay
  final List<DrawingStroke> strokes;     // Vector paths
  final Offset anchorOffset;             // Relative offset (0-1 range)
  final double baseTextSize;             // Text size when created
  final Color color;
  final double strokeWidth;
  final bool isPublic;
  final String? sharedFromUserId;
}
```

### DrawingStroke
```dart
class DrawingStroke {
  final List<DrawingPoint> points;
  final Color color;
  final double width;
  final StrokeStyle style;              // Pen, highlighter, pencil
}
```

### DrawingPoint
```dart
class DrawingPoint {
  final Offset position;                // Relative coordinates
  final double pressure;                // For stylus support
  final double tiltX;                   // For advanced stylus
  final double tiltY;
}
```

## Layout Engine

### Positioning Algorithm
When rendering a drawing:
1. **Find anchor verse** in the current layout
2. **Calculate anchor word position** if specified
3. **Apply relative offset** scaled to current viewport
4. **Scale path points** based on text size ratio
5. **Render vector paths** with CustomPaint

### Text Size Changes
When user changes text size:
1. Layout engine recalculates verse positions
2. Each drawing's anchor is located in new layout
3. Drawing is repositioned relative to new anchor
4. Path is scaled proportionally to text size change

### Margin Layout
Margins have fixed virtual width:
- Left margin: 0.0 to 0.2 (20% of viewport)
- Content area: 0.2 to 0.8 (60% of viewport)
- Right margin: 0.8 to 1.0 (20% of viewport)

User can adjust margin width in settings.

## User Interface

### Drawing Mode
Activated via toolbar button in Study Mode:
- Toggle between Read and Draw modes
- In Draw mode:
  - Tap-and-drag creates freehand strokes
  - Gestures confined to visible content
  - Real-time preview of stroke
  - Automatic saving on stroke completion

### Drawing Tools
Tool palette includes:
- **Pen**: Solid line (various colors)
- **Highlighter**: Semi-transparent wide stroke
- **Pencil**: Textured appearance
- **Eraser**: Remove strokes
- **Shapes**: Lines, arrows, circles, rectangles

### Margin Toggle
Settings option:
- Show/hide margins
- Adjust margin width (10-30%)
- Lock margins (prevent accidental drawing in content)

## Technical Implementation

### Flutter CustomPainter
```dart
class DrawingPainter extends CustomPainter {
  final List<Drawing> drawings;
  final Map<String, Rect> versePositions;  // Cached positions
  final double currentTextSize;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var drawing in drawings) {
      final anchor = _calculateAnchorPosition(drawing);
      _renderDrawing(canvas, drawing, anchor);
    }
  }
}
```

### Touch Input Handling
```dart
class DrawingCanvas extends StatefulWidget {
  // GestureDetector for touch/stylus input
  // Converts screen coordinates to relative coordinates
  // Batches points for performance
  // Smooths curves using Catmull-Rom splines
}
```

### Performance Optimizations
- **Spatial indexing**: Only render drawings in visible viewport
- **Path caching**: Cache rendered paths until text size changes
- **Culling**: Skip drawings outside scroll window
- **Batch rendering**: Combine multiple strokes into single paint call

## Storage & Sync

### Database Schema
```sql
CREATE TABLE drawings (
  id TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  user_id TEXT,
  is_deleted INTEGER DEFAULT 0,
  version INTEGER DEFAULT 1,
  sync_status TEXT,
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
```

### Sync Considerations
- Drawings sync like other user content (highlights, notes)
- Large drawings may need chunking
- Consider stroke simplification for sync efficiency
- Public drawings can be shared in community

## Migration Path

### Phase 1: Foundation (Week 1)
- [ ] Create Drawing, DrawingStroke, DrawingPoint models
- [ ] Add database tables and repository methods
- [ ] Implement basic DrawingPainter
- [ ] Add drawing mode toggle to Study Mode

### Phase 2: Drawing Tools (Week 2)
- [ ] Implement touch input handling
- [ ] Add pen, highlighter, pencil tools
- [ ] Create tool selection UI
- [ ] Add undo/redo functionality

### Phase 3: Content Anchoring (Week 3)
- [ ] Implement verse position tracking
- [ ] Add anchor calculation logic
- [ ] Handle text size scaling
- [ ] Test with various text sizes

### Phase 4: Margins & Polish (Week 4)
- [ ] Implement margin zones
- [ ] Add margin width settings
- [ ] Create drawing management UI (delete, edit)
- [ ] Performance optimizations

### Phase 5: Advanced Features (Future)
- [ ] Shape tools (lines, arrows, boxes)
- [ ] Eraser tool
- [ ] Layer management
- [ ] Public drawing sharing
- [ ] Import/export drawings

## Advantages Over Pencil Bible

1. **Scalability**: Drawings maintain quality at any text size
2. **Precise Positioning**: Always aligned with correct verse/word
3. **Cross-Platform**: Same drawings on mobile, tablet, desktop, web
4. **Efficient Storage**: Vector paths much smaller than bitmaps
5. **Editing**: Can modify, move, or delete individual strokes
6. **Sharing**: Easy to share drawings with community

## Example Use Cases

### Bible Teacher
- Draw arrows connecting related verses
- Highlight themes with colored regions
- Annotate in margins with theological notes
- Create visual study guides

### Student
- Mark up passages with color-coded highlights
- Draw connections between concepts
- Sketch illustrations of parables
- Create memory aids

### Personal Study
- Freeform journaling in margins
- Track reading patterns with marks
- Highlight favorite verses with decorations
- Create personalized study system
