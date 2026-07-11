import 'package:flutter/material.dart';
import 'package:bible_core/models/drawing.dart';
import 'dart:ui' as ui;

/// Custom painter that renders vector drawings with content anchoring
class DrawingPainter extends CustomPainter {
  /// List of drawings to render
  final List<Drawing> drawings;

  /// Map of verse numbers to their bounding rectangles in the layout
  final Map<int, Rect> versePositions;

  /// Current text size for scaling calculations
  final double currentTextSize;

  /// Viewport size for calculating relative coordinates
  final Size viewportSize;

  /// Margin width as percentage (0.0 - 1.0)
  final double marginWidth;

  DrawingPainter({
    required this.drawings,
    required this.versePositions,
    required this.currentTextSize,
    required this.viewportSize,
    this.marginWidth = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawing in drawings) {
      _renderDrawing(canvas, drawing, size);
    }
  }

  void _renderDrawing(Canvas canvas, Drawing drawing, Size size) {
    // Calculate anchor position
    final anchorPoint = _calculateAnchorPosition(drawing, size);
    if (anchorPoint == null) {
      // Verse not visible, skip drawing
      return;
    }

    // Calculate scale factor based on text size change
    final scaleFactor = currentTextSize / drawing.baseTextSize;

    // Render each stroke
    for (var stroke in drawing.strokes) {
      _renderStroke(canvas, stroke, anchorPoint, scaleFactor);
    }
  }

  Offset? _calculateAnchorPosition(Drawing drawing, Size size) {
    // Get the verse position
    final verseNum = drawing.reference.startVerse ?? 1;
    final verseRect = versePositions[verseNum];

    if (verseRect == null) {
      return null; // Verse not in view
    }

    // Calculate base anchor point
    Offset anchor;

    switch (drawing.zone) {
      case DrawingZone.leftMargin:
        // Left margin: anchored within the space before the verse text.
        anchor = Offset(
          verseRect.left * drawing.anchorOffset.dx,
          verseRect.top + (verseRect.height * drawing.anchorOffset.dy),
        );
        break;

      case DrawingZone.rightMargin:
        // Right margin: anchored within the space after the verse text.
        final rightMarginWidth = size.width - verseRect.right;
        anchor = Offset(
          verseRect.right + (rightMarginWidth * drawing.anchorOffset.dx),
          verseRect.top + (verseRect.height * drawing.anchorOffset.dy),
        );
        break;

      case DrawingZone.contentOverlay:
        // Content overlay: positioned relative to verse
        anchor = Offset(
          verseRect.left + (verseRect.width * drawing.anchorOffset.dx),
          verseRect.top + (verseRect.height * drawing.anchorOffset.dy),
        );
        break;
    }

    return anchor;
  }

  void _renderStroke(
    Canvas canvas,
    DrawingStroke stroke,
    Offset anchor,
    double scaleFactor,
  ) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Apply stroke style
    switch (stroke.style) {
      case StrokeStyle.pen:
        paint.color = stroke.color;
        paint.strokeWidth = stroke.width * scaleFactor;
        break;

      case StrokeStyle.highlighter:
        paint.color = stroke.color.withOpacity(0.3);
        paint.strokeWidth = stroke.width * scaleFactor * 3;
        paint.strokeCap = StrokeCap.square;
        break;

      case StrokeStyle.pencil:
        paint.color = stroke.color.withOpacity(0.7);
        paint.strokeWidth = stroke.width * scaleFactor;
        // Could add texture here with shader
        break;
    }

    // Build path from points
    final path = Path();
    final firstPoint = stroke.points.first;
    final scaledFirst = _scalePoint(firstPoint, anchor, scaleFactor);
    path.moveTo(scaledFirst.dx, scaledFirst.dy);

    if (stroke.points.length == 1) {
      // Single point - draw a dot
      canvas.drawCircle(scaledFirst, paint.strokeWidth / 2, paint);
      return;
    }

    // Draw smooth curve through points using quadratic bezier
    for (int i = 1; i < stroke.points.length; i++) {
      final current = _scalePoint(stroke.points[i], anchor, scaleFactor);
      
      if (i < stroke.points.length - 1) {
        final next = _scalePoint(stroke.points[i + 1], anchor, scaleFactor);
        final controlPoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        path.quadraticBezierTo(
          current.dx,
          current.dy,
          controlPoint.dx,
          controlPoint.dy,
        );
      } else {
        path.lineTo(current.dx, current.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  Offset _scalePoint(DrawingPoint point, Offset anchor, double scaleFactor) {
    // Points are stored as offsets from anchor in pixels
    // Apply scale factor and add to anchor position
    return Offset(
      anchor.dx + (point.position.dx * scaleFactor),
      anchor.dy + (point.position.dy * scaleFactor),
    );
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.drawings != drawings ||
        oldDelegate.versePositions != versePositions ||
        oldDelegate.currentTextSize != currentTextSize ||
        oldDelegate.viewportSize != viewportSize ||
        oldDelegate.marginWidth != marginWidth;
  }
}
