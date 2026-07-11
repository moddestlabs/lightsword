import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_core/data/sources/tagnt_repository.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:bible_app/ui/models/chapter_view_definition.dart';
import 'package:bible_app/ui/models/interlinear_word.dart';

class ConfigurableChapterView extends StatefulWidget {
  final Chapter chapter;
  final ChapterViewDefinition view;

  const ConfigurableChapterView({
    super.key,
    required this.chapter,
    required this.view,
  });

  @override
  State<ConfigurableChapterView> createState() => _ConfigurableChapterViewState();
}

class _ConfigurableChapterViewState extends State<ConfigurableChapterView> {
  final Map<int, List<InterlinearWord>> _verseData = {};
  final Map<int, bool> _loading = {};

  bool get _needsInterlinearData {
    return widget.view.showOriginalLanguage || widget.view.showGloss;
  }

  @override
  void initState() {
    super.initState();
    _loadInterlinearDataIfNeeded();
  }

  @override
  void didUpdateWidget(ConfigurableChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final chapterChanged =
        oldWidget.chapter.bookId != widget.chapter.bookId ||
        oldWidget.chapter.number != widget.chapter.number ||
        oldWidget.chapter.verses.length != widget.chapter.verses.length;
    final dataRequirementsChanged =
        oldWidget.view.showOriginalLanguage != widget.view.showOriginalLanguage ||
        oldWidget.view.showGloss != widget.view.showGloss;

    if (chapterChanged || dataRequirementsChanged) {
      _verseData.clear();
      _loading.clear();
      _loadInterlinearDataIfNeeded();
    }
  }

  Future<void> _loadInterlinearDataIfNeeded() async {
    if (!_needsInterlinearData) {
      return;
    }

    for (final verse in widget.chapter.verses) {
      if (!mounted) return;

      setState(() {
        _loading[verse.number] = true;
      });

      try {
        final words = await _loadVerseWords(verse.number);
        if (!mounted) return;

        setState(() {
          _verseData[verse.number] = words;
          _loading[verse.number] = false;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _loading[verse.number] = false;
        });
      }
    }
  }

  Future<List<InterlinearWord>> _loadVerseWords(int verseNumber) async {
    final tahot = await TAHOTRepository.instance.getVerse(
      widget.chapter.bookId,
      widget.chapter.number,
      verseNumber,
    );
    if (tahot != null) {
      return tahot.map(InterlinearWord.fromTAHOT).toList();
    }

    final tagnt = await TAGNTRepository.instance.getVerse(
      widget.chapter.bookId,
      widget.chapter.number,
      verseNumber,
    );
    if (tagnt != null) {
      return tagnt.map(InterlinearWord.fromTAGNT).toList();
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.view.lineByLine &&
        !widget.view.showOriginalLanguage &&
        widget.view.showTranslation &&
        !widget.view.showGloss) {
      return _buildTranslationParagraphView(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: widget.chapter.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.chapter.verses[index];
        final words = _verseData[verse.number] ?? const <InterlinearWord>[];
        final isLoading = _loading[verse.number] ?? false;
        return _buildVerseSection(context, verse, words, isLoading);
      },
    );
  }

  Widget _buildTranslationParagraphView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 18,
                height: 1.8,
              ),
          children: [
            for (int index = 0; index < widget.chapter.verses.length; index++) ...[
              if (widget.view.showVerseNumbers)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${widget.chapter.verses[index].number}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              TextSpan(text: widget.chapter.verses[index].text),
              if (index != widget.chapter.verses.length - 1)
                const TextSpan(text: ' '),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerseSection(
    BuildContext context,
    Verse verse,
    List<InterlinearWord> words,
    bool isLoading,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: widget.view.lineByLine ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.view.showVerseNumbers && widget.view.lineByLine)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${verse.number}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          if (widget.view.showOriginalLanguage)
            _buildOriginalLanguageBlock(context, words, isLoading),
          if (widget.view.showTranslation)
            Padding(
              padding: EdgeInsets.only(
                top: widget.view.showOriginalLanguage ? 10 : 0,
                bottom: widget.view.showGloss ? 8 : 0,
              ),
              child: Text(
                _buildTranslationText(verse),
                style: TextStyle(
                  fontSize: widget.view.lineByLine ? 16 : 18,
                  height: 1.7,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          if (widget.view.showGloss)
            _buildGlossBlock(context, verse.number, words, isLoading),
        ],
      ),
    );
  }

  Widget _buildOriginalLanguageBlock(
    BuildContext context,
    List<InterlinearWord> words,
    bool isLoading,
  ) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (words.isEmpty) {
      return Text(
        'Original language text unavailable',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final direction = _resolveTextDirection(words);
    final originalText = words
      .map((word) => word.displayOriginalText)
        .where((word) => word.isNotEmpty)
        .join(' ');

    return Text(
      originalText,
      textDirection: direction,
      style: TextStyle(
        fontSize: widget.view.lineByLine ? 22 : 20,
        height: 1.6,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildGlossBlock(
    BuildContext context,
    int verseNumber,
    List<InterlinearWord> words,
    bool isLoading,
  ) {
    if (isLoading) {
      return const SizedBox.shrink();
    }

    final glossText = words
        .map((word) => word.gloss.trim())
        .where((gloss) => gloss.isNotEmpty)
        .join(' ');
    if (glossText.isEmpty) {
      return Text(
        'Glosses unavailable for verse $verseNumber',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Text(
      glossText,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _buildTranslationText(Verse verse) {
    if (!widget.view.showVerseNumbers || widget.view.lineByLine) {
      return verse.text;
    }

    return '${verse.number}. ${verse.text}';
  }

  TextDirection _resolveTextDirection(List<InterlinearWord> words) {
    switch (widget.view.originalLanguageTextDirection) {
      case ChapterViewTextDirection.ltr:
        return TextDirection.ltr;
      case ChapterViewTextDirection.rtl:
        return TextDirection.rtl;
      case ChapterViewTextDirection.auto:
        if (words.isNotEmpty && words.first.isHebrew) {
          return TextDirection.rtl;
        }
        return TextDirection.ltr;
    }
  }
}