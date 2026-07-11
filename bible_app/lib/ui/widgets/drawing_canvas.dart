import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:bible_core/models/drawing.dart';

/// Interactive canvas for creating vector drawings with touch/stylus input
class DrawingCanvas extends StatefulWidget {
  /// Callback when a stroke is completed
  /// Parameters: stroke (normalized), originalStartPosition (local coords relative to canvas)
  final void Function(DrawingStroke stroke, Offset originalStartPosition) onStrokeCompleted;

  /// Current drawing tool settings
  final DrawingToolSettings settings;

  /// Whether drawing is enabled
  final bool enabled;

  /// Child widget to overlay drawing on
  final Widget child;

  const DrawingCanvas({
    super.key,
    required this.onStrokeCompleted,
    required this.settings,
    required this.child,
    this.enabled = true,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<DrawingPoint> _currentPoints = [];
  DrawingStroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Original content
        widget.child,

        // Drawing overlay
        if (widget.enabled)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              behavior: HitTestBehavior.translucent,
              child: CustomPaint(
                painter: _currentStroke != null
                    ? _CurrentStrokePainter(
                        stroke: _currentStroke!,
                        settings: widget.settings,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled) return;

    setState(() {
      _currentPoints.clear();
      _currentPoints.add(_createPoint(details.localPosition));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;

    setState(() {
      _currentPoints.add(_createPoint(details.localPosition));

      // Create current stroke for preview
      _currentStroke = DrawingStroke(
        points: List.from(_currentPoints),
        color: widget.settings.color,
        width: widget.settings.strokeWidth,
        style: widget.settings.style,
      );
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.enabled || _currentPoints.isEmpty) return;

    // Keep the local start position (before normalization)
    final originalStartPosition = _currentPoints.first.position;

    // Smooth the points
    final smoothedPoints = _smoothPoints(_currentPoints);

    // Convert to offsets from first point
    final normalizedPoints = _normalizePoints(smoothedPoints);

    // Create final stroke
    final stroke = DrawingStroke(
      points: normalizedPoints,
      color: widget.settings.color,
      width: widget.settings.strokeWidth,
      style: widget.settings.style,
    );

    // Notify completion with normalized stroke and local position
    widget.onStrokeCompleted(stroke, originalStartPosition);

    // Clear current stroke
    setState(() {
      _currentPoints.clear();
      _currentStroke = null;
    });
  }

  DrawingPoint _createPoint(Offset position) {
    return DrawingPoint(
      position: position,
      pressure: 1.0, // TODO: Add stylus pressure support
      tiltX: 0.0,
      tiltY: 0.0,
    );
  }

  /// Smooth points using simple averaging
  List<DrawingPoint> _smoothPoints(List<DrawingPoint> points) {
    if (points.length < 3) return points;

    final smoothed = <DrawingPoint>[points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];

      // Average of three consecutive points
      final smoothedPos = Offset(
        (prev.position.dx + current.position.dx + next.position.dx) / 3,
        (prev.position.dy + current.position.dy + next.position.dy) / 3,
      );

      smoothed.add(DrawingPoint(
        position: smoothedPos,
        pressure: current.pressure,
        tiltX: current.tiltX,
        tiltY: current.tiltY,
      ));
    }

    smoothed.add(points.last);
    return smoothed;
  }

  /// Convert absolute screen coordinates to offsets from first point
  List<DrawingPoint> _normalizePoints(List<DrawingPoint> points) {
    if (points.isEmpty) return points;

    // Use first point as anchor
    final anchor = points.first.position;

    // Convert all points to offsets from anchor
    return points.map((point) {
      return DrawingPoint(
        position: Offset(
          point.position.dx - anchor.dx,
          point.position.dy - anchor.dy,
        ),
        pressure: point.pressure,
        tiltX: point.tiltX,
        tiltY: point.tiltY,
      );
    }).toList();
  }
}

/// Settings for drawing tools
class DrawingToolSettings {
  final Color color;
  final double strokeWidth;
  final StrokeStyle style;

  const DrawingToolSettings({
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.style = StrokeStyle.pen,
  });

  DrawingToolSettings copyWith({
    Color? color,
    double? strokeWidth,
    StrokeStyle? style,
  }) {
    return DrawingToolSettings(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      style: style ?? this.style,
    );
  }
}

/// Painter for rendering the current stroke being drawn
class _CurrentStrokePainter extends CustomPainter {
  final DrawingStroke stroke;
  final DrawingToolSettings settings;

  _CurrentStrokePainter({
    required this.stroke,
    required this.settings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Apply style
    switch (stroke.style) {
      case StrokeStyle.pen:
        paint.color = stroke.color;
        paint.strokeWidth = stroke.width;
        break;

      case StrokeStyle.highlighter:
        paint.color = stroke.color.withOpacity(0.3);
        paint.strokeWidth = stroke.width * 3;
        paint.strokeCap = StrokeCap.square;
        break;

      case StrokeStyle.pencil:
        paint.color = stroke.color.withOpacity(0.7);
        paint.strokeWidth = stroke.width;
        break;
    }

    // Draw path
    final path = Path();
    path.moveTo(
      stroke.points.first.position.dx,
      stroke.points.first.position.dy,
    );

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      path.lineTo(point.position.dx, point.position.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CurrentStrokePainter oldDelegate) {
    return oldDelegate.stroke != stroke;
  }
}
