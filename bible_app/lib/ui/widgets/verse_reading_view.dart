import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/state/chapter_view_controller.dart';

/// Traditional verse-by-verse reading view
/// Each verse appears on its own line with optional verse numbers
class VerseReadingView extends StatelessWidget {
  final ChapterViewController controller;

  const VerseReadingView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final verses = state.chapter.verses;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        return _VerseItem(
          verse: verse,
          showVerseNumber: state.showVerseNumbers,
          highlights: state.highlights
              .where((h) {
                final start = h.reference.startVerse;
                final end = h.reference.endVerse;
                if (start == null) return false;
                return start == verse.number ||
                    (end != null && start <= verse.number && end >= verse.number);
              })
              .toList(),
        );
      },
    );
  }
}

class _VerseItem extends StatelessWidget {
  final Verse verse;
  final bool showVerseNumber;
  final List<Highlight> highlights;

  const _VerseItem({
    required this.verse,
    required this.showVerseNumber,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    // Get highlights for this verse
    final verseHighlights = highlights
        .where((h) => h.reference.startVerse == verse.number)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 16,
                height: 1.6,
              ),
          children: [
            // Verse number
            if (showVerseNumber)
              TextSpan(
                text: '${verse.number} ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            // Verse text with word-level highlights
            ..._buildHighlightedText(verseHighlights),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedText(List<Highlight> verseHighlights) {
    if (verseHighlights.isEmpty) {
      return [TextSpan(text: verse.text)];
    }

    // Word-level highlighting: tokenize verse and apply highlights to word ranges
    final words = _tokenizeVerse(verse.text);
    final spans = <InlineSpan>[];
    
    for (int i = 0; i < words.length; i++) {
      // Check if this word is highlighted
      Highlight? activeHighlight;
      for (var highlight in verseHighlights) {
        if (i >= highlight.wordStart && i <= highlight.wordEnd) {
          activeHighlight = highlight;
          break;
        }
      }
      
      spans.add(TextSpan(
        text: words[i],
        style: activeHighlight != null
            ? TextStyle(backgroundColor: activeHighlight.color.withOpacity(0.3))
            : null,
      ));
    }

    return spans;
  }

  /// Tokenize verse text into words, preserving spaces and punctuation
  List<String> _tokenizeVerse(String text) {
    final words = <String>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);
      
      // Add word on space or end of string
      if (char == ' ' || i == text.length - 1) {
        words.add(buffer.toString());
        buffer.clear();
      }
    }
    
    return words;
  }
}
