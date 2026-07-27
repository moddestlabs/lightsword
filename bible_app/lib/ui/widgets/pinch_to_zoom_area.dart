import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bible_app/state/font_size_provider.dart';

/// A wrapper widget that handles both pinch-to-zoom font scaling and
/// horizontal swipe gestures for chapter navigation cleanly in a single
/// gesture recognizer, eliminating gesture arena conflicts.
class PinchToZoomArea extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const PinchToZoomArea({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<PinchToZoomArea> createState() => _PinchToZoomAreaState();
}

class _PinchToZoomAreaState extends State<PinchToZoomArea> {
  double _initialFontSize = 18.0;
  bool _isPinching = false;
  Offset? _startFocalPoint;
  double _lastFocalDx = 0.0;
  DateTime? _gestureStartTime;
  Timer? _hideIndicatorTimer;

  void _handleScaleStart(ScaleStartDetails details, FontSizeProvider provider) {
    _initialFontSize = provider.fontSize;
    _startFocalPoint = details.focalPoint;
    _lastFocalDx = details.focalPoint.dx;
    _gestureStartTime = DateTime.now();
    _isPinching = false;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, FontSizeProvider provider) {
    // Detect multi-finger pinch or explicit scale movement
    final isPinchGesture = details.pointerCount >= 2 || (details.scale - 1.0).abs() > 0.04;

    if (isPinchGesture && provider.pinchToZoomEnabled) {
      if (!_isPinching) {
        setState(() {
          _isPinching = true;
        });
        _hideIndicatorTimer?.cancel();
      }
      final targetSize = _initialFontSize * details.scale;
      provider.setFontSizeEphemeral(targetSize);
    } else if (!_isPinching) {
      _lastFocalDx = details.focalPoint.dx;
    }
  }

  void _handleScaleEnd(ScaleEndDetails details, FontSizeProvider provider) {
    if (_isPinching) {
      if (provider.pinchToZoomEnabled) {
        provider.commitFontSize();
      }
      _hideIndicatorTimer?.cancel();
      _hideIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _isPinching = false;
          });
        }
      });
    } else if (_startFocalPoint != null) {
      // Handle horizontal swipe chapter navigation when not pinching
      final deltaX = _lastFocalDx - _startFocalPoint!.dx;
      final elapsed = DateTime.now().difference(_gestureStartTime ?? DateTime.now()).inMilliseconds;

      if (elapsed < 600 && deltaX.abs() > 70) {
        if (deltaX < -70) {
          widget.onSwipeLeft?.call();
        } else if (deltaX > 70) {
          widget.onSwipeRight?.call();
        }
      }
    }

    _startFocalPoint = null;
  }

  @override
  void dispose() {
    _hideIndicatorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    final hasSwipe = widget.onSwipeLeft != null || widget.onSwipeRight != null;

    return Stack(
      children: [
        GestureDetector(
          behavior: hasSwipe ? HitTestBehavior.translucent : HitTestBehavior.deferToChild,
          onScaleStart: (details) => _handleScaleStart(details, fontSizeProvider),
          onScaleUpdate: (details) => _handleScaleUpdate(details, fontSizeProvider),
          onScaleEnd: (details) => _handleScaleEnd(details, fontSizeProvider),
          child: widget.child,
        ),
        if (_isPinching && fontSizeProvider.pinchToZoomEnabled)
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isPinching ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_size,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${fontSizeProvider.fontSize.toStringAsFixed(1)} pt',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
