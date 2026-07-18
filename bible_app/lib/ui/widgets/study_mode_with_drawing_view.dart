import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/state/chapter_view_controller.dart';
import 'package:bible_app/ui/widgets/drawing_painter.dart';
import 'package:bible_app/ui/widgets/drawing_canvas.dart';
import 'package:bible_app/ui/widgets/drawing_toolbar.dart';

/// Enhanced study mode view with vector drawing support
///
/// This example shows how to integrate the drawing system into
/// the existing study mode. It wraps the study content with a
/// DrawingCanvas and overlays drawings using DrawingPainter.
class StudyModeWithDrawingView extends StatefulWidget {
  final ChapterViewController controller;

  const StudyModeWithDrawingView({
    super.key,
    required this.controller,
  });

  @override
  State<StudyModeWithDrawingView> createState() =>
      _StudyModeWithDrawingViewState();
}

class _StudyModeWithDrawingViewState extends State<StudyModeWithDrawingView> {
  final TtsService _ttsService = TtsService.instance;

  // Drawing state
  bool _isDrawingMode = false;
  DrawingToolSettings _toolSettings = const DrawingToolSettings();
  List<Drawing> _drawings = [];

  // Verse position tracking for content anchoring
  final Map<int, GlobalKey> _verseKeys = {};
  final Map<int, Rect> _versePositions = {};
  final GlobalKey _contentStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ttsService.addListener(_handleTtsChanged);
    _loadDrawings();
    _initializeVerseKeys();

    // Calculate verse positions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateVersePositions();
        setState(() {}); // Trigger rebuild with positions
      }
    });
  }

  @override
  void dispose() {
    _ttsService.removeListener(_handleTtsChanged);
    super.dispose();
  }

  void _handleTtsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadDrawings() async {
    final drawings = await widget.controller.repository.getDrawings(
      PassageReference(
        bookId: widget.controller.state.chapter.bookId,
        chapter: widget.controller.state.chapter.number,
      ),
    );
    setState(() {
      _drawings = drawings;
    });
  }

  void _initializeVerseKeys() {
    for (var verse in widget.controller.state.chapter.verses) {
      _verseKeys[verse.number] = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final settings = state.studySettings;

    return Scaffold(
      body: DrawingCanvas(
        enabled: _isDrawingMode,
        settings: _toolSettings,
        onStrokeCompleted: _handleStrokeCompleted,
        child: Stack(
          key: _contentStackKey,
          children: [
            // Original study content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildVerseWidgets(state),
              ),
            ),

            // Drawing overlay
            if (_drawings.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: DrawingPainter(
                    drawings: _drawings,
                    versePositions: _calculateVersePositions(),
                    currentTextSize: settings.textSize,
                    viewportSize: MediaQuery.of(context).size,
                  ),
                ),
              ),
          ],
        ),
      ),

      // Drawing toolbar
      bottomNavigationBar: DrawingToolbar(
        settings: _toolSettings,
        onSettingsChanged: (settings) {
          setState(() => _toolSettings = settings);
        },
        isDrawingMode: _isDrawingMode,
        onToggleDrawingMode: () {
          setState(() => _isDrawingMode = !_isDrawingMode);
        },
        onUndo: _drawings.isNotEmpty ? _undoLastDrawing : null,
        onClear: _drawings.isNotEmpty ? _clearAllDrawings : null,
      ),
    );
  }

  /// Build verse widgets with GlobalKeys for position tracking
  List<Widget> _buildVerseWidgets(ChapterViewState state) {
    final widgets = <Widget>[];

    for (var verse in state.chapter.verses) {
      widgets.add(
        Container(
          key: _verseKeys[verse.number],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: state.studySettings.textSize,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                children: [
                  if (state.showVerseNumbers)
                    TextSpan(
                      text: '${verse.number} ',
                      style: TextStyle(
                        fontSize: state.studySettings.textSize * 0.7,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ..._buildVerseTextSpans(verse),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<InlineSpan> _buildVerseTextSpans(Verse verse) {
    final progress = _ttsService.progressState;
    final isActiveVerse = _ttsService.currentVerseNumber == verse.number &&
        progress != null &&
        progress.contentType == TtsContentType.translation &&
        progress.verseNumber == verse.number;
    if (!isActiveVerse) {
      return [TextSpan(text: verse.text)];
    }

    final highlightStart = progress.startOffset.clamp(0, verse.text.length);
    final highlightEnd = progress.endOffset.clamp(0, verse.text.length);
    if (highlightStart >= highlightEnd) {
      return [TextSpan(text: verse.text)];
    }

    final colorScheme = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    if (highlightStart > 0) {
      spans.add(TextSpan(text: verse.text.substring(0, highlightStart)));
    }
    spans.add(
      TextSpan(
        text: verse.text.substring(highlightStart, highlightEnd),
        style: TextStyle(
          backgroundColor: colorScheme.tertiaryContainer,
          color: colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (highlightEnd < verse.text.length) {
      spans.add(TextSpan(text: verse.text.substring(highlightEnd)));
    }
    return spans;
  }

  /// Calculate current positions of verses in the layout
  Map<int, Rect> _calculateVersePositions() {
    // Schedule position calculation after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stackContext = _contentStackKey.currentContext;
      final stackBox = stackContext?.findRenderObject() as RenderBox?;
      if (stackBox == null) {
        return;
      }

      bool positionsChanged = false;

      for (var entry in _verseKeys.entries) {
        final key = entry.value;
        final verseNumber = entry.key;

        final context = key.currentContext;
        if (context != null) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final position = box.localToGlobal(
            Offset.zero,
            ancestor: stackBox,
          );

          final newRect = Rect.fromLTWH(
            position.dx,
            position.dy,
            box.size.width,
            box.size.height,
          );

          if (_versePositions[verseNumber] != newRect) {
            _versePositions[verseNumber] = newRect;
            positionsChanged = true;
          }
        }
      }

      // Trigger rebuild if positions changed and we have drawings
      if (positionsChanged && _drawings.isNotEmpty && mounted) {
        setState(() {});
      }
    });

    return _versePositions;
  }

  /// Handle completion of a drawing stroke
  Future<void> _handleStrokeCompleted(
    DrawingStroke stroke,
    Offset localStartPosition,
  ) async {
    // Determine which verse the drawing is anchored to
    final anchorVerse = _findAnchorVerse(localStartPosition);
    if (anchorVerse == null) return;

    // Determine the zone (margin or overlay)
    final zone = _determineZone(localStartPosition, anchorVerse);

    // Calculate anchor offset relative to verse
    final anchorOffset = _calculateAnchorOffset(
      localStartPosition,
      anchorVerse,
      zone,
    );

    // Create drawing entity
    final drawing = Drawing.create(
      reference: PassageReference(
        bookId: widget.controller.state.chapter.bookId,
        chapter: widget.controller.state.chapter.number,
        startVerse: anchorVerse,
      ),
      zone: zone,
      strokes: [stroke],
      anchorOffset: DrawingOffset(anchorOffset.dx, anchorOffset.dy),
      baseTextSize: widget.controller.state.studySettings.textSize,
      colorValue: _toolSettings.color.toARGB32(),
      strokeWidth: _toolSettings.strokeWidth,
    );

    // Save to repository
    await widget.controller.repository.saveDrawing(drawing);

    // Update UI
    setState(() {
      _drawings.add(drawing);
    });
  }

  /// Find which verse the stroke should be anchored to
  int? _findAnchorVerse(Offset startPosition) {
    // Get the Y position
    final startY = startPosition.dy;

    // Find the verse whose bounding box contains this Y position
    int? closestVerse;
    double closestDistance = double.infinity;

    for (var entry in _versePositions.entries) {
      final verseNumber = entry.key;
      final rect = entry.value;

      if (rect.top <= startY && rect.bottom >= startY) {
        return verseNumber; // Direct hit
      }

      // Find closest verse if no direct hit
      final distance = (rect.center.dy - startY).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestVerse = verseNumber;
      }
    }

    return closestVerse;
  }

  /// Determine which zone the stroke belongs to
  DrawingZone _determineZone(Offset startPosition, int verseNumber) {
    final verseRect = _versePositions[verseNumber];
    if (verseRect == null) return DrawingZone.contentOverlay;

    if (startPosition.dx < verseRect.left) {
      return DrawingZone.leftMargin;
    }

    if (startPosition.dx > verseRect.right) {
      return DrawingZone.rightMargin;
    }

    return DrawingZone.contentOverlay;
  }

  /// Calculate anchor offset relative to verse position
  Offset _calculateAnchorOffset(
    Offset startPosition,
    int verseNumber,
    DrawingZone zone,
  ) {
    final verseRect = _versePositions[verseNumber];
    if (verseRect == null) return Offset.zero;

    final viewportWidth = _contentStackKey.currentContext?.size?.width ??
        MediaQuery.of(context).size.width;

    late final double relativeX;

    switch (zone) {
      case DrawingZone.leftMargin:
        final leftMarginWidth = verseRect.left;
        relativeX =
            leftMarginWidth > 0 ? startPosition.dx / leftMarginWidth : 0.0;
        break;
      case DrawingZone.rightMargin:
        final rightMarginWidth = viewportWidth - verseRect.right;
        relativeX = rightMarginWidth > 0
            ? (startPosition.dx - verseRect.right) / rightMarginWidth
            : 0.0;
        break;
      case DrawingZone.contentOverlay:
        relativeX = verseRect.width > 0
            ? (startPosition.dx - verseRect.left) / verseRect.width
            : 0.0;
        break;
    }

    // Calculate relative position within the verse area
    final relativeY = (startPosition.dy - verseRect.top) / verseRect.height;

    return Offset(
      relativeX.clamp(0.0, 1.0),
      relativeY.clamp(0.0, 1.0),
    );
  }

  /// Undo the last drawing
  Future<void> _undoLastDrawing() async {
    if (_drawings.isEmpty) return;

    final lastDrawing = _drawings.last;
    await widget.controller.repository.deleteDrawing(lastDrawing.id);

    setState(() {
      _drawings.removeLast();
    });
  }

  /// Clear all drawings
  Future<void> _clearAllDrawings() async {
    for (var drawing in _drawings) {
      await widget.controller.repository.deleteDrawing(drawing.id);
    }

    setState(() {
      _drawings.clear();
    });
  }
}
