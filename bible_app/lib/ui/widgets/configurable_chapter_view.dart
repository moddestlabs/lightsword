import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_core/services/bookmark_service.dart';
import 'package:bible_app/services/local_bookmark_service.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/ui/models/chapter_view_definition.dart';
import 'package:bible_app/ui/models/interlinear_word.dart';
import 'package:bible_app/ui/widgets/interlinear_view.dart';

class ConfigurableChapterView extends StatefulWidget {
  final Chapter chapter;
  final String? bookName;
  final ChapterViewDefinition view;

  const ConfigurableChapterView({
    super.key,
    required this.chapter,
    this.bookName,
    required this.view,
  });

  static Future<List<TtsUtterance>> buildTtsUtterances({
    required Chapter chapter,
    required ChapterViewDefinition view,
  }) async {
    final utterances = <TtsUtterance>[];
    final needsInterlinearData = view.showOriginalLanguage || view.showGloss;

    for (final verse in chapter.verses) {
      final words = needsInterlinearData
          ? await _loadVerseWordsForChapter(
              chapter.bookId,
              chapter.number,
              verse.number,
            )
          : const <InterlinearWord>[];
      utterances.addAll(
          _buildVerseUtterances(view: view, verse: verse, words: words));
    }

    return utterances;
  }

  static Future<List<TtsUtterance>> buildVerseTtsUtterances({
    required Chapter chapter,
    required ChapterViewDefinition view,
    required Verse verse,
  }) async {
    final words = (view.showOriginalLanguage || view.showGloss)
        ? await _loadVerseWordsForChapter(
            chapter.bookId,
            chapter.number,
            verse.number,
          )
        : const <InterlinearWord>[];
    return _buildVerseUtterances(view: view, verse: verse, words: words);
  }

  static List<TtsUtterance> _buildVerseUtterances({
    required ChapterViewDefinition view,
    required Verse verse,
    required List<InterlinearWord> words,
  }) {
    final utterances = <TtsUtterance>[];

    if (view.showVerseNumbers) {
      utterances.add(
        TtsUtterance(
          text: 'Verse ${verse.number}.',
          verseNumber: verse.number,
          contentType: TtsContentType.verseNumber,
          languageCode: 'en-US',
        ),
      );
    }

    if (view.showOriginalLanguage) {
      final originalText = words
          .map((word) => word.displayOriginalText)
          .where((word) => word.isNotEmpty)
          .join(' ');
      if (originalText.isNotEmpty) {
        utterances.add(
          TtsUtterance(
            text: originalText,
            verseNumber: verse.number,
            contentType: TtsContentType.originalLanguage,
            languageCode:
                words.isNotEmpty && words.first.isHebrew ? 'he-IL' : 'el-GR',
            transliteration: words
                .map((word) => word.translit.trim())
                .where((word) => word.isNotEmpty)
                .join(' '),
          ),
        );
      }
    }

    if (view.showTranslation && verse.text.isNotEmpty) {
      utterances.add(
        TtsUtterance(
          text: verse.text,
          verseNumber: verse.number,
          contentType: TtsContentType.translation,
        ),
      );
    }

    if (view.showGloss) {
      final glossText = words
          .map((word) => word.gloss.trim())
          .where((gloss) => gloss.isNotEmpty)
          .join(' ');
      if (glossText.isNotEmpty) {
        utterances.add(
          TtsUtterance(
            text: glossText,
            verseNumber: verse.number,
            contentType: TtsContentType.gloss,
            languageCode: 'en-US',
          ),
        );
      }
    }

    return utterances;
  }

  static Future<List<InterlinearWord>> _loadVerseWordsForChapter(
    String bookId,
    int chapter,
    int verseNumber,
  ) async {
    final tahot = await TAHOTRepository.instance.getVerse(
      bookId,
      chapter,
      verseNumber,
    );
    if (tahot != null) {
      return tahot.map(InterlinearWord.fromTAHOT).toList();
    }

    final tagnt = await TAGNTRepository.instance.getVerse(
      bookId,
      chapter,
      verseNumber,
    );
    if (tagnt != null) {
      return tagnt.map(InterlinearWord.fromTAGNT).toList();
    }

    return const [];
  }

  @override
  State<ConfigurableChapterView> createState() =>
      _ConfigurableChapterViewState();
}

class _ConfigurableChapterViewState extends State<ConfigurableChapterView> {
  final TtsService _ttsService = TtsService.instance;
  final Map<int, List<InterlinearWord>> _verseData = {};
  final Map<int, bool> _loading = {};
  final Map<int, Bookmark> _bookmarksByVerse = {};
  int? _selectedVerseNumber;

  bool get _needsInterlinearData {
    return widget.view.showOriginalLanguage || widget.view.showGloss;
  }

  @override
  void initState() {
    super.initState();
    _ttsService.addListener(_handleTtsChanged);
    _loadInterlinearDataIfNeeded();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _ttsService.removeListener(_handleTtsChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(ConfigurableChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final chapterChanged = oldWidget.chapter.bookId != widget.chapter.bookId ||
        oldWidget.chapter.number != widget.chapter.number ||
        oldWidget.chapter.verses.length != widget.chapter.verses.length;
    final dataRequirementsChanged = oldWidget.view.showOriginalLanguage !=
            widget.view.showOriginalLanguage ||
        oldWidget.view.showGloss != widget.view.showGloss;

    if (chapterChanged || dataRequirementsChanged) {
      _verseData.clear();
      _loading.clear();
      _bookmarksByVerse.clear();
      _selectedVerseNumber = null;
      _loadInterlinearDataIfNeeded();
      _loadBookmarks();
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await LocalBookmarkService.instance.getBookmarks();
    if (!mounted) return;

    setState(() {
      _bookmarksByVerse
        ..clear()
        ..addEntries(
          bookmarks
              .where(
                (bookmark) =>
                    bookmark.bookId == widget.chapter.bookId &&
                    bookmark.chapter == widget.chapter.number,
              )
              .map((bookmark) => MapEntry(bookmark.verse, bookmark)),
        );
    });
  }

  void _handleVerseTap(BuildContext context, Verse verse) {
    if (_selectedVerseNumber == verse.number) {
      _openVerseDetails(context, verse);
      return;
    }

    setState(() {
      _selectedVerseNumber = verse.number;
    });
  }

  Future<void> _openVerseDetails(BuildContext context, Verse verse) {
    return InterlinearReaderPage.show(
      context: context,
      bookName: widget.bookName ?? widget.chapter.bookId,
      bookId: widget.chapter.bookId,
      chapter: widget.chapter.number,
      verseNumber: verse.number,
      verse: verse,
    );
  }

  Future<void> _playVerse(Verse verse) {
    return ConfigurableChapterView.buildVerseTtsUtterances(
      chapter: widget.chapter,
      view: widget.view,
      verse: verse,
    ).then(_ttsService.readUtterances);
  }

  void _handleTtsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _copyVerse(BuildContext context, Verse verse) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _buildCopyText(verse)));
    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleBookmark(BuildContext context, Verse verse) async {
    final messenger = ScaffoldMessenger.of(context);
    final existingBookmark = _bookmarksByVerse[verse.number];

    if (existingBookmark != null) {
      await LocalBookmarkService.instance.removeBookmark(existingBookmark.id);
      if (!mounted) return;

      setState(() {
        _bookmarksByVerse.remove(verse.number);
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Removed bookmark from ${widget.chapter.bookId} ${widget.chapter.number}:${verse.number}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final bookmark = Bookmark(
      id: '${widget.chapter.bookId}-${widget.chapter.number}-${verse.number}',
      bookId: widget.chapter.bookId,
      chapter: widget.chapter.number,
      verse: verse.number,
      createdAt: DateTime.now(),
    );

    await LocalBookmarkService.instance.addBookmark(bookmark);
    if (!mounted) return;

    setState(() {
      _bookmarksByVerse[verse.number] = bookmark;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Bookmarked ${widget.chapter.bookId} ${widget.chapter.number}:${verse.number}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
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
    return ConfigurableChapterView._loadVerseWordsForChapter(
      widget.chapter.bookId,
      widget.chapter.number,
      verseNumber,
    );
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
            for (int index = 0;
                index < widget.chapter.verses.length;
                index++) ...[
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
              ..._buildTranslationSpans(
                context,
                widget.chapter.verses[index],
                DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 18,
                      height: 1.8,
                    ),
              ),
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
    final isSelected = _selectedVerseNumber == verse.number;
    final isBookmarked = _bookmarksByVerse.containsKey(verse.number);

    return Slidable(
      key: ValueKey(
        'verse-${widget.chapter.bookId}-${widget.chapter.number}-${verse.number}',
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) {
              _toggleBookmark(context, verse);
            },
            backgroundColor: isBookmarked
                ? colorScheme.secondaryContainer
                : colorScheme.primaryContainer,
            foregroundColor: isBookmarked
                ? colorScheme.onSecondaryContainer
                : colorScheme.onPrimaryContainer,
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            label: isBookmarked ? 'Saved' : 'Bookmark',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (_) {
              _copyVerse(context, verse);
            },
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurfaceVariant,
            icon: Icons.copy_outlined,
            label: 'Copy',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: widget.view.lineByLine ? 20 : 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.32)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _handleVerseTap(context, verse),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.view.showVerseNumbers && widget.view.lineByLine)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                        if (isBookmarked) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Icon(
                              Icons.bookmark,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  if (widget.view.showOriginalLanguage)
                    _buildOriginalLanguageBlock(
                      context,
                      verse.number,
                      words,
                      isLoading,
                    ),
                  if (widget.view.showTranslation)
                    Padding(
                      padding: EdgeInsets.only(
                        top: widget.view.showOriginalLanguage ? 10 : 0,
                        bottom: widget.view.showGloss ? 8 : 0,
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: widget.view.lineByLine ? 16 : 18,
                            height: 1.7,
                            color: colorScheme.onSurface,
                          ),
                          children: _buildTranslationSpans(
                            context,
                            verse,
                            TextStyle(
                              fontSize: widget.view.lineByLine ? 16 : 18,
                              height: 1.7,
                              color: colorScheme.onSurface,
                            ),
                            includeInlineVerseNumber:
                                widget.view.showVerseNumbers &&
                                    !widget.view.lineByLine,
                          ),
                        ),
                      ),
                    ),
                  if (widget.view.showGloss)
                    _buildGlossBlock(context, verse.number, words, isLoading),
                  if (isSelected) _buildSelectedActions(context, verse),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedActions(BuildContext context, Verse verse) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _VerseActionChip(
            icon: Icons.play_arrow_rounded,
            label: 'Play',
            onTap: () {
              _playVerse(verse);
            },
          ),
          _VerseActionChip(
            icon: Icons.menu_book_outlined,
            label: 'Details',
            onTap: () {
              _openVerseDetails(context, verse);
            },
          ),
          Text(
            'Tap the verse again to open details',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalLanguageBlock(
    BuildContext context,
    int verseNumber,
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

    final baseStyle = TextStyle(
      fontSize: widget.view.lineByLine ? 22 : 20,
      height: 1.6,
      color: Theme.of(context).colorScheme.primary,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: _buildContentSpans(
          context,
          verseNumber: verseNumber,
          text: originalText,
          contentType: TtsContentType.originalLanguage,
          baseStyle: baseStyle,
        ),
      ),
      textDirection: direction,
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

    final baseStyle = TextStyle(
      fontSize: 14,
      height: 1.6,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: _buildContentSpans(
          context,
          verseNumber: verseNumber,
          text: glossText,
          contentType: TtsContentType.gloss,
          baseStyle: baseStyle,
        ),
      ),
    );
  }

  List<InlineSpan> _buildTranslationSpans(
    BuildContext context,
    Verse verse,
    TextStyle baseStyle, {
    bool includeInlineVerseNumber = false,
  }) {
    final spans = <InlineSpan>[];
    if (includeInlineVerseNumber) {
      spans.add(TextSpan(text: '${verse.number}. ', style: baseStyle));
    }

    final progress = _ttsService.progressState;
    final isActiveVerse = _ttsService.currentVerseNumber == verse.number &&
        progress != null &&
        progress.contentType == TtsContentType.translation &&
        progress.verseNumber == verse.number;
    if (!isActiveVerse) {
      spans.add(TextSpan(text: verse.text, style: baseStyle));
      return spans;
    }

    return _buildContentSpans(
      context,
      verseNumber: verse.number,
      text: verse.text,
      contentType: TtsContentType.translation,
      baseStyle: baseStyle,
    );
  }

  List<InlineSpan> _buildContentSpans(
    BuildContext context, {
    required int? verseNumber,
    required String text,
    required TtsContentType contentType,
    required TextStyle baseStyle,
  }) {
    final progress = _ttsService.progressState;
    final isActiveContent = verseNumber != null &&
        _ttsService.currentVerseNumber == verseNumber &&
        progress != null &&
        progress.verseNumber == verseNumber &&
        progress.contentType == contentType;
    if (!isActiveContent) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final highlightStart = progress.startOffset.clamp(0, text.length);
    final highlightEnd = progress.endOffset.clamp(0, text.length);
    if (highlightStart >= highlightEnd) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final highlightStyle = baseStyle.copyWith(
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      color: Theme.of(context).colorScheme.onTertiaryContainer,
      fontWeight: FontWeight.w600,
    );
    final spans = <InlineSpan>[];
    if (highlightStart > 0) {
      spans.add(
          TextSpan(text: text.substring(0, highlightStart), style: baseStyle));
    }
    spans.add(TextSpan(
      text: text.substring(highlightStart, highlightEnd),
      style: highlightStyle,
    ));
    if (highlightEnd < text.length) {
      spans.add(TextSpan(text: text.substring(highlightEnd), style: baseStyle));
    }
    return spans;
  }

  String _buildCopyText(Verse verse) {
    final bookLabel = widget.bookName ?? widget.chapter.bookId;
    return '$bookLabel ${widget.chapter.number}:${verse.number} ${verse.text}';
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

class _VerseActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _VerseActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
