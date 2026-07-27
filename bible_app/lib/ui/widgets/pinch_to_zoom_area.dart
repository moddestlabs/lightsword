import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bible_app/state/font_size_provider.dart';

/// A wrapper widget that listens to pinch scale gestures and adjusts font size
/// live when pinch-to-zoom is enabled in settings.
class PinchToZoomArea extends StatefulWidget {
  final Widget child;

  const PinchToZoomArea({
    super.key,
    required this.child,
  });

  @override
  State<PinchToZoomArea> createState() => _PinchToZoomAreaState();
}

class _PinchToZoomAreaState extends State<PinchToZoomArea> {
  double _initialFontSize = 18.0;
  bool _isPinching = false;
  Timer? _hideIndicatorTimer;

  void _handleScaleStart(ScaleStartDetails details, FontSizeProvider provider) {
    if (!provider.pinchToZoomEnabled) return;
    _initialFontSize = provider.fontSize;
    setState(() {
      _isPinching = true;
    });
    _hideIndicatorTimer?.cancel();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, FontSizeProvider provider) {
    if (!provider.pinchToZoomEnabled) return;
    if (details.scale == 1.0) return;

    final targetSize = _initialFontSize * details.scale;
    provider.setFontSizeEphemeral(targetSize);
  }

  void _handleScaleEnd(ScaleEndDetails details, FontSizeProvider provider) {
    if (!provider.pinchToZoomEnabled) return;
    provider.commitFontSize();

    _hideIndicatorTimer?.cancel();
    _hideIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isPinching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideIndicatorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    if (!fontSizeProvider.pinchToZoomEnabled) {
      return widget.child;
    }

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onScaleStart: (details) => _handleScaleStart(details, fontSizeProvider),
          onScaleUpdate: (details) => _handleScaleUpdate(details, fontSizeProvider),
          onScaleEnd: (details) => _handleScaleEnd(details, fontSizeProvider),
          child: widget.child,
        ),
        if (_isPinching)
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
