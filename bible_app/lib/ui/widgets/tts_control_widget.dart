import 'package:flutter/material.dart';
import 'package:bible_app/services/tts_service.dart';

/// Floating TTS control widget for reading screens
/// Shows play/pause/stop controls and current language
class TtsControlWidget extends StatefulWidget {
  const TtsControlWidget({super.key});

  @override
  State<TtsControlWidget> createState() => _TtsControlWidgetState();
}

class _TtsControlWidgetState extends State<TtsControlWidget> {
  final TtsService _ttsService = TtsService.instance;
  
  @override
  void initState() {
    super.initState();
    _ttsService.addListener(_onTtsStateChanged);
  }
  
  @override
  void dispose() {
    _ttsService.removeListener(_onTtsStateChanged);
    super.dispose();
  }
  
  void _onTtsStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ttsService.isPlaying && !_ttsService.isPaused) {
      // Don't show controls when not active
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language indicator
          if (_ttsService.detectedLanguage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _ttsService.detectedLanguage!.contains('transliterated')
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_ttsService.detectedLanguage!.contains('transliterated'))
                    const Icon(
                      Icons.translate,
                      size: 14,
                      color: Colors.orange,
                    ),
                  if (_ttsService.detectedLanguage!.contains('transliterated'))
                    const SizedBox(width: 4),
                  Text(
                    _ttsService.getCurrentLanguageName(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _ttsService.detectedLanguage!.contains('transliterated')
                          ? Colors.orange.shade700
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Play/Pause button
          IconButton(
            icon: Icon(
              _ttsService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onPressed: () {
              _ttsService.togglePlayPause();
            },
          ),
          
          // Stop button
          IconButton(
            icon: Icon(
              Icons.stop,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onPressed: () {
              _ttsService.stop();
            },
          ),
        ],
      ),
    );
  }
}

/// Compact TTS button for triggering reading
class TtsPlayButton extends StatelessWidget {
  final VoidCallback onPlay;
  final String? tooltip;
  
  const TtsPlayButton({
    super.key,
    required this.onPlay,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.volume_up),
      tooltip: tooltip ?? 'Read aloud',
      onPressed: onPlay,
    );
  }
}
