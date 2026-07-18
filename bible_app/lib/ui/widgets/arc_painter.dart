import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';

/// Geometric information for positioning an arc
class ArcGeometry {
  final Offset start;
  final Offset end;
  final double height;

  const ArcGeometry({
    required this.start,
    required this.end,
    required this.height,
  });
}

/// Custom painter for drawing syntactic/semantic arcs over text
class ArcPainter extends CustomPainter {
  final List<Arc> arcs;
  final Map<int, ArcGeometry> arcGeometry;

  ArcPainter({
    required this.arcs,
    required this.arcGeometry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < arcs.length; i++) {
      final arc = arcs[i];
      final geometry = arcGeometry[i];

      if (geometry == null) continue;

      _drawArc(canvas, arc, geometry);

      // Draw label if present
      if (arc.label != null && arc.label!.isNotEmpty) {
        _drawLabel(canvas, arc, geometry);
      }
    }
  }

  void _drawArc(Canvas canvas, Arc arc, ArcGeometry geometry) {
    final arcColor = Color(arc.colorValue);
    final paint = Paint()
      ..color = arcColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (arc.style) {
      case ArcStyle.curved:
        // Draw a bezier curve
        final controlPoint = Offset(
          (geometry.start.dx + geometry.end.dx) / 2,
          geometry.start.dy - geometry.height,
        );
        path.moveTo(geometry.start.dx, geometry.start.dy);
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          geometry.end.dx,
          geometry.end.dy,
        );
        break;

      case ArcStyle.straight:
        // Draw a straight line
        path.moveTo(geometry.start.dx, geometry.start.dy);
        path.lineTo(geometry.end.dx, geometry.end.dy);
        break;

      case ArcStyle.above:
        // Draw a curved arc above the text
        final controlPoint = Offset(
          (geometry.start.dx + geometry.end.dx) / 2,
          geometry.start.dy - geometry.height,
        );
        path.moveTo(geometry.start.dx, geometry.start.dy);
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          geometry.end.dx,
          geometry.end.dy,
        );
        break;

      case ArcStyle.below:
        // Draw a curved arc below the text
        final controlPoint = Offset(
          (geometry.start.dx + geometry.end.dx) / 2,
          geometry.start.dy + geometry.height,
        );
        path.moveTo(geometry.start.dx, geometry.start.dy);
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          geometry.end.dx,
          geometry.end.dy,
        );
        break;
    }

    canvas.drawPath(path, paint);

    // Draw arrowhead at the end
    _drawArrowhead(canvas, arc, geometry);
  }

  void _drawArrowhead(Canvas canvas, Arc arc, ArcGeometry geometry) {
    final arcColor = Color(arc.colorValue);
    final paint = Paint()
      ..color = arcColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    const arrowSize = 8.0;
    final angle = _calculateEndAngle(arc, geometry);

    final path = Path();
    path.moveTo(geometry.end.dx, geometry.end.dy);
    path.lineTo(
      geometry.end.dx - arrowSize * 0.866,
      geometry.end.dy - arrowSize * 0.5,
    );
    path.lineTo(
      geometry.end.dx - arrowSize * 0.866,
      geometry.end.dy + arrowSize * 0.5,
    );
    path.close();

    canvas.save();
    canvas.translate(geometry.end.dx, geometry.end.dy);
    canvas.rotate(angle);
    canvas.translate(-geometry.end.dx, -geometry.end.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  double _calculateEndAngle(Arc arc, ArcGeometry geometry) {
    // Calculate the angle of the arc at its end point
    // This is a simplified calculation; for curved arcs, we'd need to
    // calculate the derivative of the bezier curve at t=1
    final dx = geometry.end.dx - geometry.start.dx;
    final dy = geometry.end.dy - geometry.start.dy;
    return atan2(dy, dx);
  }

  void _drawLabel(Canvas canvas, Arc arc, ArcGeometry geometry) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: arc.label,
        style: TextStyle(
          color: Color(arc.colorValue),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position label at the midpoint of the arc
    final labelX =
        (geometry.start.dx + geometry.end.dx) / 2 - textPainter.width / 2;
    final labelY =
        geometry.start.dy - geometry.height / 2 - textPainter.height / 2;

    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(ArcPainter oldDelegate) {
    return arcs != oldDelegate.arcs || arcGeometry != oldDelegate.arcGeometry;
  }
}
