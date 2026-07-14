import 'package:flutter/material.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_app/services/original_language_data_service.dart';
import 'package:bible_app/ui/models/interlinear_word.dart';

/// Displays multiple verses in interlinear format for chapter reading
/// Shows Hebrew/Greek text alongside English translation
class InterlinearChapterView extends StatefulWidget {
  final List<Verse> verses;
  final String bookId;
  final int chapter;

  const InterlinearChapterView({
    super.key,
    required this.verses,
    required this.bookId,
    required this.chapter,
  });

  @override
  State<InterlinearChapterView> createState() => _InterlinearChapterViewState();
}

class _InterlinearChapterViewState extends State<InterlinearChapterView> {
  final Map<int, List<InterlinearWord>> _verseData = {};
  final Map<int, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    _loadAllVerses();
  }

  @override
  void didUpdateWidget(InterlinearChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if chapter or book changed
    if (oldWidget.chapter != widget.chapter || 
        oldWidget.bookId != widget.bookId ||
        oldWidget.verses != widget.verses) {
      _verseData.clear();
      _loading.clear();
      _loadAllVerses();
    }
  }

  Future<void> _loadAllVerses() async {
    for (final verse in widget.verses) {
      if (!mounted) return;
      
      setState(() {
        _loading[verse.number] = true;
      });

      try {
        final verseContent = await OriginalLanguageDataService.instance.loadVerse(
          widget.bookId,
          widget.chapter,
          verse.number,
        );
        final words = verseContent.words;

        if (mounted && words.isNotEmpty) {
          setState(() {
            _verseData[verse.number] = words;
            _loading[verse.number] = false;
          });
        } else if (mounted) {
          setState(() {
            _loading[verse.number] = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading[verse.number] = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // Extra bottom padding for TTS controls
      itemCount: widget.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.verses[index];
        final words = _verseData[verse.number];
        final isLoading = _loading[verse.number] ?? true;

        return _buildInterlinearVerse(verse, words, isLoading);
      },
    );
  }

  Widget _buildInterlinearVerse(Verse verse, List<InterlinearWord>? words, bool isLoading) {
    final hasData = words != null && words.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${verse.number}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Hebrew/Greek text (if available)
          if (hasData) ...[
            _buildOriginalLanguageText(words),
            const SizedBox(height: 12),
          ] else if (isLoading) ...[
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
          ],

          // English translation
          Text(
            verse.text,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // Word glosses (compact format for chapter view)
          if (hasData) ...[
            const SizedBox(height: 8),
            _buildCompactGlosses(words),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginalLanguageText(List<InterlinearWord> words) {
    // Determine if this is Hebrew (RTL) or Greek (LTR)
    final isHebrew = words.isNotEmpty && words.first.isHebrew;

    return Wrap(
      direction: Axis.horizontal,
      textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
      spacing: 8,
      runSpacing: 4,
      children: words.map((word) {
        final displayText = word.originalText.isNotEmpty 
            ? word.displayOriginalText
            : word.translit;
            
        return Text(
          displayText,
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
        );
      }).toList(),
    );
  }

  Widget _buildCompactGlosses(List<InterlinearWord> words) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: words.where((w) => w.gloss.isNotEmpty).map((word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            word.gloss,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
