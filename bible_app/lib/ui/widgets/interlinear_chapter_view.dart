import 'package:flutter/material.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';

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
  final Map<int, List<TAHOTWord>> _verseData = {};
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
        final tahot = await TAHOTRepository.instance.getVerse(
          widget.bookId,
          widget.chapter,
          verse.number,
        );
        
        if (mounted && tahot != null) {
          setState(() {
            _verseData[verse.number] = tahot;
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
        final tahotWords = _verseData[verse.number];
        final isLoading = _loading[verse.number] ?? true;

        return _buildInterlinearVerse(verse, tahotWords, isLoading);
      },
    );
  }

  Widget _buildInterlinearVerse(Verse verse, List<TAHOTWord>? tahotWords, bool isLoading) {
    final hasData = tahotWords != null && tahotWords.isNotEmpty;

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
            _buildOriginalLanguageText(tahotWords),
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
            _buildCompactGlosses(tahotWords),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginalLanguageText(List<TAHOTWord> words) {
    // Determine if this is Hebrew (RTL) or Greek (LTR)
    final isHebrew = words.isNotEmpty && 
                     words.first.hebrew.isNotEmpty;

    return Wrap(
      direction: Axis.horizontal,
      textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
      spacing: 8,
      runSpacing: 4,
      children: words.map((word) {
        // Remove prefix markers (/) from Hebrew text
        final displayText = word.hebrew.isNotEmpty 
            ? word.hebrew.replaceAll('/', '')
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

  Widget _buildCompactGlosses(List<TAHOTWord> words) {
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
