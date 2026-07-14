import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart'
  show
    Arc,
    ArcStyle,
    ArcType,
    PassageReference,
    SyntaxArcData,
    SyntaxRelationKind,
    SyntaxSpanData,
    SyntaxVerseData;
import 'package:bible_core/lexicon/strongs.dart';
import 'package:bible_core/models/strongs_entry.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/word.dart';
import 'package:bible_app/services/bible_service.dart';
import 'package:bible_app/services/original_language_data_service.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/ui/models/chapter_view_definition.dart';
import 'package:bible_app/ui/models/interlinear_word.dart';
import 'package:bible_app/ui/widgets/arc_painter.dart';
import 'package:bible_app/ui/widgets/tts_control_widget.dart';

/// Widget to display a single fallback word when full interlinear data is unavailable.
class InterlinearWordCard extends StatefulWidget {
  final Word word;
  final int? verseNumber;
  final String? progressKey;

  const InterlinearWordCard({
    super.key,
    required this.word,
    this.verseNumber,
    this.progressKey,
  });

  @override
  State<InterlinearWordCard> createState() => _InterlinearWordCardState();
}

class _InterlinearWordCardState extends State<InterlinearWordCard> {
  StrongsEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLexiconEntry();
  }

  Future<void> _loadLexiconEntry() async {
    if (widget.word.strongsNumber == null) {
      setState(() => _loading = false);
      return;
    }

    final entry = await StrongsLookup.instance.getEntry(
      widget.word.strongsNumber!,
    );
    if (mounted) {
      setState(() {
        _entry = entry;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStrongs = widget.word.strongsNumber != null;
    final isHebrew = hasStrongs && widget.word.strongsNumber!.startsWith('H');
    final progress = TtsService.instance.progressState;
    final isActiveWord = widget.progressKey != null &&
        progress?.progressKey == widget.progressKey;

    if (_loading && hasStrongs) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              widget.word.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    final wordStyle = TextStyle(
      fontSize: 18,
      color: Theme.of(context).colorScheme.error,
      fontWeight: FontWeight.w500,
      backgroundColor:
          isActiveWord ? Theme.of(context).colorScheme.tertiaryContainer : null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_entry != null && _entry!.lemma.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entry!.lemma,
                  style: TextStyle(
                    fontSize: 32,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w400,
                  ),
                  textDirection:
                      isHebrew ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 4),
                Text(
                  isHebrew ? 'Hebrew root' : 'Greek root',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (_entry?.transliteration != null &&
              _entry!.transliteration!.isNotEmpty)
            Text(
              _entry!.transliteration!,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (_entry?.transliteration != null) const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              TtsService.instance.speak(
                widget.word.text,
                verseNumber: widget.verseNumber,
                contentType: TtsContentType.translation,
                progressKey: widget.progressKey,
              );
            },
            child: Icon(
              Icons.play_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.word.text,
            style: wordStyle,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasStrongs)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.word.strongsNumber!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _entry?.shortDefinition ??
                      (_entry?.longDefinition?.substring(0, 100) ??
                          widget.word.text),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterlinearWordCard extends StatefulWidget {
  final InterlinearWord word;
  final int? verseNumber;
  final String? progressKey;
  final ChapterViewDefinition view;

  const _InterlinearWordCard({
    required this.word,
    required this.view,
    this.verseNumber,
    this.progressKey,
  });

  @override
  State<_InterlinearWordCard> createState() => __InterlinearWordCardState();
}

class __InterlinearWordCardState extends State<_InterlinearWordCard> {
  StrongsEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLexiconEntry();
  }

  Future<void> _loadLexiconEntry() async {
    if (widget.word.strongs == null) {
      setState(() => _loading = false);
      return;
    }

    final entry = await StrongsLookup.instance.getEntry(widget.word.strongs!);
    if (mounted) {
      setState(() {
        _entry = entry;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStrongs = widget.word.strongs != null;
    final isHebrew = widget.word.isHebrew;
    final progress = TtsService.instance.progressState;
    final isActiveWord = widget.progressKey != null &&
        progress?.progressKey == widget.progressKey;
    final genderColor = widget.view.colorOriginalLanguageByGender
      ? _genderColor(widget.word.grammaticalGender, Theme.of(context))
      : Theme.of(context).colorScheme.primary;

    final originalStyle = TextStyle(
      fontSize: 28,
      color: genderColor,
      fontWeight: widget.view.colorOriginalLanguageByGender &&
          widget.word.grammaticalGender != null
        ? FontWeight.w600
        : FontWeight.w400,
      height: 1.4,
      backgroundColor:
          isActiveWord ? Theme.of(context).colorScheme.tertiaryContainer : null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              TtsService.instance.speak(
                widget.word.displayOriginalText,
                verseNumber: widget.verseNumber,
                transliteration: widget.word.translit
                    .replaceAll('.', '')
                    .replaceAll('/', '')
                    .replaceAll("'", ''),
                contentType: TtsContentType.originalLanguage,
                progressKey: widget.progressKey,
              );
            },
            child: Icon(
              Icons.play_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: widget.word.morphologyTooltip,
            child: Text(
              widget.word.displayOriginalText,
              style: originalStyle,
              textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.word.translit.replaceAll('.', ''),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.87,
                  ),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.word.gloss,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (hasStrongs && _entry != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHebrew
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.word.strongs!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isHebrew
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _entry!.shortDefinition.isNotEmpty
                        ? _entry!.shortDefinition
                        : (_entry!.longDefinition?.substring(0, 100) ?? ''),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else if (_loading && hasStrongs) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
          if (widget.view.showMorphology && widget.word.morphology.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.view.useCompactMorphologyLabels
                  ? widget.word.morphologyLabel
                  : widget.word.morphologyFullLabel,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _genderColor(String? gender, ThemeData theme) {
  switch (gender) {
    case 'Masculine':
      return Colors.blue.shade600;
    case 'Feminine':
      return Colors.pink.shade400;
    case 'Neuter':
    case 'Common':
    case 'Both':
      return Colors.grey.shade600;
    default:
      return theme.colorScheme.primary;
  }
}

class InterlinearReaderPage extends StatefulWidget {
  final String bookName;
  final String bookId;
  final int chapter;
  final int verseNumber;
  final Verse verse;
  final ChapterViewDefinition view;

  const InterlinearReaderPage({
    super.key,
    required this.bookName,
    required this.bookId,
    required this.chapter,
    required this.verseNumber,
    required this.verse,
    required this.view,
  });

  @override
  State<InterlinearReaderPage> createState() => _InterlinearReaderPageState();

  static Future<void> show({
    required BuildContext context,
    required String bookName,
    required String bookId,
    required int chapter,
    required int verseNumber,
    required Verse verse,
    required ChapterViewDefinition view,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InterlinearReaderPage(
          bookName: bookName,
          bookId: bookId,
          chapter: chapter,
          verseNumber: verseNumber,
          verse: verse,
          view: view,
        ),
      ),
    );
  }
}

class _InterlinearReaderPageState extends State<InterlinearReaderPage> {
  final TtsService _ttsService = TtsService.instance;

  List<InterlinearWord>? _interlinearWords;
  SyntaxVerseData? _syntaxData;
  bool _loadingInterlinear = true;
  int? _activeSyntaxFocusWordIndex;
  bool _pinnedSyntaxFocus = false;

  String get _translationProgressKey =>
      'detail:${widget.bookId}:${widget.chapter}:${widget.verseNumber}:translation';

  String get _originalProgressKey =>
      'detail:${widget.bookId}:${widget.chapter}:${widget.verseNumber}:original';

  String _wordProgressKey(int index) =>
      'detail:${widget.bookId}:${widget.chapter}:${widget.verseNumber}:word:$index';

  @override
  void initState() {
    super.initState();
    _ttsService.addListener(_handleTtsChanged);
    _loadInterlinearData();
    _ttsService.onShowNotification = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _ttsService.onShowNotification = null;
    _ttsService.removeListener(_handleTtsChanged);
    super.dispose();
  }

  void _handleTtsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadInterlinearData() async {
    final verseContent = await OriginalLanguageDataService.instance.loadVerse(
      widget.bookId,
      widget.chapter,
      widget.verseNumber,
      includeSyntax: widget.view.showSyntaxLinks,
    );

    if (mounted) {
      setState(() {
        _interlinearWords = verseContent.words;
        _syntaxData = verseContent.syntax;
        _loadingInterlinear = false;
      });
    }
  }

  List<InlineSpan> _buildProgressSpans(
    String text,
    TextStyle baseStyle,
    String progressKey,
  ) {
    final progress = _ttsService.progressState;
    if (progress == null || progress.progressKey != progressKey) {
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

    return [
      if (highlightStart > 0)
        TextSpan(text: text.substring(0, highlightStart), style: baseStyle),
      TextSpan(
        text: text.substring(highlightStart, highlightEnd),
        style: highlightStyle,
      ),
      if (highlightEnd < text.length)
        TextSpan(text: text.substring(highlightEnd), style: baseStyle),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasWords =
        widget.verse.words != null && widget.verse.words!.isNotEmpty;
    final hasInterlinear =
        _interlinearWords != null && _interlinearWords!.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.bookName} ${widget.chapter}:${widget.verseNumber}',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTranslationTile(
                  BibleService.currentSourceOption.label,
                  widget.verse.text,
                  isPrimary: true,
                ),
                if (hasInterlinear) ...[
                  _buildOriginalLanguageVerseTile(_interlinearWords!),
                  if (widget.view.showGloss)
                    _buildGlossVerseTile(_interlinearWords!),
                  if (widget.view.showSyntaxLinks && _syntaxData != null)
                    _buildSyntaxDiagramTile(
                      _interlinearWords!,
                      _syntaxData!,
                      title: 'Syntax Diagram',
                      labelBuilder: _originalSyntaxLabel,
                      useWordColors: true,
                    ),
                  if (widget.view.showGloss &&
                      widget.view.showSyntaxLinks &&
                      _syntaxData != null)
                    _buildSyntaxDiagramTile(
                      _interlinearWords!,
                      _syntaxData!,
                      title: 'Gloss Syntax Diagram',
                      labelBuilder: _glossSyntaxLabel,
                    ),
                  if (widget.view.showSyntaxLinks && _syntaxData != null)
                    _buildSyntaxLinksTile(_interlinearWords!, _syntaxData!),
                ] else if (_loadingInterlinear) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: colorScheme.surface,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (hasInterlinear) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: colorScheme.surfaceContainerLow,
                    child: Text(
                      'Word-by-Word Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.87),
                      ),
                    ),
                  ),
                  ..._interlinearWords!.asMap().entries.map(
                        (entry) => _buildInterlinearWordCard(
                          entry.value,
                          entry.key,
                        ),
                      ),
                ] else if (_loadingInterlinear) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (hasWords) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'Word Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.87),
                      ),
                    ),
                  ),
                  ...widget.verse.words!.asMap().entries.map(
                        (entry) => InterlinearWordCard(
                          word: entry.value,
                          verseNumber: widget.verseNumber,
                          progressKey: _wordProgressKey(entry.key),
                        ),
                      ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: TtsControlWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterlinearWordCard(InterlinearWord word, int index) {
    return _InterlinearWordCard(
      word: word,
      view: widget.view,
      verseNumber: widget.verseNumber,
      progressKey: _wordProgressKey(index),
    );
  }

  Widget _buildOriginalLanguageVerseTile(List<InterlinearWord> words) {
    final isHebrew = words.isNotEmpty && words.first.isHebrew;
    final originalText =
        words.map((word) => word.displayOriginalText).join(' ');
    final translitText = words
        .map(
          (word) => word.translit
              .replaceAll('.', '')
              .replaceAll('/', '')
              .replaceAll("'", ''),
        )
        .join(' ');
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.8,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  _ttsService.speak(
                    originalText,
                    verseNumber: widget.verseNumber,
                    transliteration: translitText,
                    contentType: TtsContentType.originalLanguage,
                    progressKey: _originalProgressKey,
                  );
                },
                child: Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            isHebrew ? 'TAHOT' : 'TAGNT',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: widget.view.showMorphology ||
                    widget.view.colorOriginalLanguageByGender
                ? Wrap(
                    spacing: widget.view.showMorphology ? 10 : 6,
                    runSpacing: widget.view.showMorphology ? 8 : 4,
                    textDirection:
                        isHebrew ? TextDirection.rtl : TextDirection.ltr,
                    children: words.asMap().entries.map((entry) {
                      final wordIndex = entry.key;
                      final word = entry.value;
                      final isFocused = wordIndex == _activeSyntaxFocusWordIndex;
                      final style = textStyle.copyWith(
                        color: widget.view.colorOriginalLanguageByGender
                            ? _genderColor(
                                word.grammaticalGender,
                                Theme.of(context),
                              )
                            : textStyle.color,
                        fontWeight: widget.view.colorOriginalLanguageByGender &&
                                word.grammaticalGender != null
                            ? FontWeight.w600
                            : textStyle.fontWeight,
                      );
                      return MouseRegion(
                        onEnter: (_) => _setSyntaxFocus(wordIndex),
                        onExit: (_) => _clearHoveredSyntaxFocus(wordIndex),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _togglePinnedSyntaxFocus(wordIndex),
                          child: Tooltip(
                            message: word.morphologyTooltip,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isFocused
                                    ? Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer
                                        .withValues(alpha: 0.45)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: isHebrew
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      word.displayOriginalText,
                                      style: style,
                                      textDirection: isHebrew
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                    ),
                                    if (widget.view.showMorphology && word.hasMorphology) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.view.useCompactMorphologyLabels
                                            ? word.morphologyLabel
                                            : word.morphologyFullLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.2,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Text.rich(
                    TextSpan(
                      style: textStyle,
                      children: _buildProgressSpans(
                        originalText,
                        textStyle,
                        _originalProgressKey,
                      ),
                    ),
                    textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossVerseTile(List<InterlinearWord> words) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 52),
          Text(
            'Gloss',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.asMap().entries.map((entry) {
                final wordIndex = entry.key;
                final word = entry.value;
                final isFocused = wordIndex == _activeSyntaxFocusWordIndex;
                return MouseRegion(
                  onEnter: (_) => _setSyntaxFocus(wordIndex),
                  onExit: (_) => _clearHoveredSyntaxFocus(wordIndex),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _togglePinnedSyntaxFocus(wordIndex),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isFocused
                            ? colorScheme.tertiaryContainer.withValues(alpha: 0.45)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          _glossSyntaxLabel(word),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntaxDiagramTile(
    List<InterlinearWord> words,
    SyntaxVerseData syntaxData, {
    required String title,
    required String Function(InterlinearWord word) labelBuilder,
    bool useWordColors = false,
  }
  ) {
    final relations = _collectSyntaxRelations(syntaxData);
    final spans = _collectSyntaxSpans(syntaxData);
    if ((relations.isEmpty && spans.isEmpty) || words.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isHebrew = useWordColors && words.isNotEmpty && words.first.isHebrew;
    const chipWidth = 84.0;
    const chipHeight = 40.0;
    const chipSpacing = 12.0;
    const horizontalPadding = 16.0;
    const baselineY = 92.0;
    final hasSpanRelations = spans.isNotEmpty;
    final totalHeight = hasSpanRelations ? 208.0 : 150.0;
    final contentWidth = horizontalPadding * 2 +
        (words.length * chipWidth) +
        (words.length > 1 ? (words.length - 1) * chipSpacing : 0.0);
    final reference = PassageReference(
      bookId: widget.bookId,
      chapter: widget.chapter,
      startVerse: widget.verseNumber,
      endVerse: widget.verseNumber,
    );
    final arcs = relations
        .map(
          (relation) => Arc.create(
            reference: reference,
            fromWordIndex: relation.fromWordIndex,
            toWordIndex: relation.toWordIndex,
            type: _arcTypeForSyntaxKind(relation.kind),
            color: _arcColorForSyntaxKind(relation.kind, colorScheme),
            label: relation.label?.trim().isNotEmpty == true
                ? relation.label!.trim()
                : relation.kind.name,
            style: ArcStyle.above,
          ),
        )
        .toList(growable: false);
    final geometry = <int, ArcGeometry>{};
    final spanVisuals = <_SyntaxSpanVisual>[];

    for (final entry in relations.asMap().entries) {
      final relation = entry.value;
      final fromX = horizontalPadding +
          (relation.fromWordIndex * (chipWidth + chipSpacing)) +
          (chipWidth / 2);
      final toX = horizontalPadding +
          (relation.toWordIndex * (chipWidth + chipSpacing)) +
          (chipWidth / 2);
      geometry[entry.key] = ArcGeometry(
        start: Offset(fromX, baselineY),
        end: Offset(toX, baselineY),
        height: _arcHeightForRelation(relation),
      );
    }

    for (final entry in spans.asMap().entries) {
      final span = entry.value;
      final startX = horizontalPadding +
          (span.startWordIndex * (chipWidth + chipSpacing)) +
          (chipWidth / 2);
      final endX = horizontalPadding +
          (span.endWordIndex * (chipWidth + chipSpacing)) +
          (chipWidth / 2);
      final sourceX = horizontalPadding +
          (span.fromWordIndex * (chipWidth + chipSpacing)) +
          (chipWidth / 2);
      final isFocused = span.fromWordIndex == _activeSyntaxFocusWordIndex;
      spanVisuals.add(
        _SyntaxSpanVisual(
          sourceX: sourceX,
          startX: startX,
          endX: endX,
          sourceY: baselineY + chipHeight + 8,
          spanY: baselineY + 72 + (entry.key * 16),
          color: _spanColorForSyntaxKind(span.kind, colorScheme),
          label: span.label?.trim().isNotEmpty == true
              ? span.label!.trim()
              : span.kind.name,
          isFocused: isFocused,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: totalHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ArcPainter(
                        arcs: arcs,
                        arcGeometry: geometry,
                      ),
                    ),
                  ),
                  if (spanVisuals.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _SyntaxSpanPainter(
                            spans: spanVisuals,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: horizontalPadding,
                    top: baselineY + 8,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: words.asMap().entries.map((entry) {
                        final wordIndex = entry.key;
                        final word = entry.value;
                        final color = useWordColors && widget.view.colorOriginalLanguageByGender
                            ? _genderColor(
                                word.grammaticalGender,
                                Theme.of(context),
                              )
                          : (useWordColors
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant);
                        final isFocused =
                            wordIndex == _activeSyntaxFocusWordIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: chipSpacing),
                          child: MouseRegion(
                            onEnter: (_) => _setSyntaxFocus(wordIndex),
                            onExit: (_) => _clearHoveredSyntaxFocus(wordIndex),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _togglePinnedSyntaxFocus(wordIndex),
                              child: Container(
                                width: chipWidth,
                                height: chipHeight,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isFocused
                                      ? colorScheme.tertiaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isFocused
                                        ? colorScheme.tertiary
                                        : colorScheme.outlineVariant,
                                    width: isFocused ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  labelBuilder(word),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: useWordColors ? 18 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textDirection: isHebrew
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setSyntaxFocus(int wordIndex) {
    if (!widget.view.showSyntaxLinks) {
      return;
    }
    if (_activeSyntaxFocusWordIndex == wordIndex && !_pinnedSyntaxFocus) {
      return;
    }
    setState(() {
      _activeSyntaxFocusWordIndex = wordIndex;
      _pinnedSyntaxFocus = false;
    });
  }

  void _clearHoveredSyntaxFocus(int wordIndex) {
    if (_pinnedSyntaxFocus || _activeSyntaxFocusWordIndex != wordIndex) {
      return;
    }
    setState(() {
      _activeSyntaxFocusWordIndex = null;
    });
  }

  void _togglePinnedSyntaxFocus(int wordIndex) {
    if (!widget.view.showSyntaxLinks) {
      return;
    }
    setState(() {
      if (_pinnedSyntaxFocus && _activeSyntaxFocusWordIndex == wordIndex) {
        _activeSyntaxFocusWordIndex = null;
        _pinnedSyntaxFocus = false;
      } else {
        _activeSyntaxFocusWordIndex = wordIndex;
        _pinnedSyntaxFocus = true;
      }
    });
  }

  List<SyntaxArcData> _collectSyntaxRelations(SyntaxVerseData syntaxData) {
    final relations = <SyntaxArcData>[];
    final seen = <String>{};

    for (final word in syntaxData.words) {
      if (word.referentWordIndex == null) {
        continue;
      }
      final key = '${word.wordIndex}:${word.referentWordIndex}:referent';
      if (!seen.add(key)) {
        continue;
      }
      relations.add(
        SyntaxArcData(
          fromWordIndex: word.wordIndex,
          toWordIndex: word.referentWordIndex!,
          kind: SyntaxRelationKind.referent,
          label: 'referent',
        ),
      );
    }

    for (final arc in syntaxData.arcs) {
      final label = arc.label?.trim().isNotEmpty == true
          ? arc.label!.trim()
          : arc.kind.name;
      final key = '${arc.fromWordIndex}:${arc.toWordIndex}:$label';
      if (!seen.add(key)) {
        continue;
      }
      relations.add(arc);
    }

    relations.sort((left, right) {
      final leftSpan = (left.fromWordIndex - left.toWordIndex).abs();
      final rightSpan = (right.fromWordIndex - right.toWordIndex).abs();
      return leftSpan.compareTo(rightSpan);
    });

    return relations;
  }

  List<SyntaxSpanData> _collectSyntaxSpans(SyntaxVerseData syntaxData) {
    final spans = <SyntaxSpanData>[];
    final seen = <String>{};

    for (final word in syntaxData.words) {
      if (word.referentSpanStartWordIndex == null ||
          word.referentSpanEndWordIndex == null) {
        continue;
      }
      final key = '${word.wordIndex}:${word.referentSpanStartWordIndex}:${word.referentSpanEndWordIndex}:referent';
      if (!seen.add(key)) {
        continue;
      }
      spans.add(
        SyntaxSpanData(
          fromWordIndex: word.wordIndex,
          startWordIndex: word.referentSpanStartWordIndex!,
          endWordIndex: word.referentSpanEndWordIndex!,
          kind: SyntaxRelationKind.referent,
          label: 'referent clause',
        ),
      );
    }

    for (final span in syntaxData.spans) {
      final label = span.label?.trim().isNotEmpty == true
          ? span.label!.trim()
          : span.kind.name;
      final key = '${span.fromWordIndex}:${span.startWordIndex}:${span.endWordIndex}:$label';
      if (!seen.add(key)) {
        continue;
      }
      spans.add(span);
    }

    spans.sort((left, right) {
      final leftSpan = left.endWordIndex - left.startWordIndex;
      final rightSpan = right.endWordIndex - right.startWordIndex;
      return rightSpan.compareTo(leftSpan);
    });
    return spans;
  }

  double _arcHeightForRelation(SyntaxArcData relation) {
    final span = (relation.fromWordIndex - relation.toWordIndex).abs();
    final clampedSpan = span < 1 ? 1 : span > 8 ? 8 : span;
    return 24 + (clampedSpan * 8).toDouble();
  }

  ArcType _arcTypeForSyntaxKind(SyntaxRelationKind kind) {
    switch (kind) {
      case SyntaxRelationKind.subject:
        return ArcType.subject;
      case SyntaxRelationKind.predicate:
        return ArcType.verb;
      case SyntaxRelationKind.object:
        return ArcType.directObject;
      case SyntaxRelationKind.modifier:
        return ArcType.modifier;
      case SyntaxRelationKind.clause:
        return ArcType.clause;
      default:
        return ArcType.custom;
    }
  }

  Color _arcColorForSyntaxKind(
    SyntaxRelationKind kind,
    ColorScheme colorScheme,
  ) {
    switch (kind) {
      case SyntaxRelationKind.referent:
        return colorScheme.tertiary;
      case SyntaxRelationKind.subject:
        return colorScheme.primary;
      case SyntaxRelationKind.predicate:
        return colorScheme.secondary;
      case SyntaxRelationKind.object:
        return colorScheme.error;
      case SyntaxRelationKind.modifier:
        return colorScheme.primary.withValues(alpha: 0.75);
      default:
        return colorScheme.outline;
    }
  }

  Color _spanColorForSyntaxKind(
    SyntaxRelationKind kind,
    ColorScheme colorScheme,
  ) {
    switch (kind) {
      case SyntaxRelationKind.referent:
        return colorScheme.tertiary;
      case SyntaxRelationKind.subject:
        return colorScheme.primary;
      default:
        return colorScheme.secondary;
    }
  }

  String _originalSyntaxLabel(InterlinearWord word) {
    return word.displayOriginalText;
  }

  String _glossSyntaxLabel(InterlinearWord word) {
    final gloss = word.gloss.trim();
    return gloss.isEmpty ? word.displayOriginalText : gloss;
  }

  String _syntaxWordText(List<InterlinearWord> words, int index) {
    if (index < 0 || index >= words.length) {
      return '#$index';
    }
    final text = words[index].displayOriginalText.trim();
    return text.isEmpty ? '#$index' : text;
  }

  Widget _buildSyntaxLinksTile(
    List<InterlinearWord> words,
    SyntaxVerseData syntaxData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final spans = _collectSyntaxSpans(syntaxData);
    if (syntaxData.arcs.isEmpty && syntaxData.words.isEmpty && spans.isEmpty) {
      return const SizedBox.shrink();
    }

    final arcRows = syntaxData.arcs.map((arc) {
      final label = arc.label?.trim();
      final relation = arc.kind.name;
      return '${_syntaxWordText(words, arc.fromWordIndex)} -> ${_syntaxWordText(words, arc.toWordIndex)}'
          '${label != null && label.isNotEmpty ? ' ($label)' : ' ($relation)'}';
    }).toList(growable: false);

    final referentRows = syntaxData.words
        .where((word) => word.referentWordIndex != null)
        .map(
          (word) => '${_syntaxWordText(words, word.wordIndex)} -> '
              '${_syntaxWordText(words, word.referentWordIndex!)} (referent)',
        )
        .toList(growable: false);

      final spanRows = spans
        .map(
          (span) => '${_syntaxWordText(words, span.fromWordIndex)} -> '
            '[${words.sublist(span.startWordIndex, span.endWordIndex + 1).map((word) => word.displayOriginalText).join(' ')}] '
            '(${span.label?.trim().isNotEmpty == true ? span.label!.trim() : span.kind.name})',
        )
        .toList(growable: false);

      final rows = <String>{...spanRows, ...referentRows, ...arcRows}.toList(growable: false);
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Syntax Links',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                row,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationTile(
    String version,
    String text, {
    bool isPrimary = false,
  }) {
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: isPrimary ? 18 : 17,
      fontWeight: FontWeight.w400,
      height: 1.5,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              _ttsService.speak(
                text,
                verseNumber: widget.verseNumber,
                contentType: TtsContentType.translation,
                progressKey: _translationProgressKey,
              );
            },
            child: Icon(
              Icons.play_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            version,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: textStyle,
                children: _buildProgressSpans(
                  text,
                  textStyle,
                  _translationProgressKey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyntaxSpanVisual {
  final double sourceX;
  final double startX;
  final double endX;
  final double sourceY;
  final double spanY;
  final Color color;
  final String label;
  final bool isFocused;

  const _SyntaxSpanVisual({
    required this.sourceX,
    required this.startX,
    required this.endX,
    required this.sourceY,
    required this.spanY,
    required this.color,
    required this.label,
    required this.isFocused,
  });
}

class _SyntaxSpanPainter extends CustomPainter {
  final List<_SyntaxSpanVisual> spans;

  const _SyntaxSpanPainter({
    required this.spans,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final span in spans) {
      final strokePaint = Paint()
        ..color = span.isFocused ? span.color : span.color.withValues(alpha: 0.78)
        ..strokeWidth = span.isFocused ? 3 : 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final underlineY = span.spanY;
      final targetMidX = (span.startX + span.endX) / 2;

      canvas.drawLine(
        Offset(span.startX - 22, underlineY),
        Offset(span.endX + 22, underlineY),
        strokePaint,
      );

      final connectorPath = Path()
        ..moveTo(span.sourceX, span.sourceY)
        ..lineTo(span.sourceX, underlineY - 12)
        ..lineTo(targetMidX, underlineY - 12)
        ..lineTo(targetMidX, underlineY - 2);
      canvas.drawPath(connectorPath, strokePaint);

      final arrowPaint = Paint()
        ..color = strokePaint.color
        ..style = PaintingStyle.fill;
      final arrowPath = Path()
        ..moveTo(targetMidX, underlineY + 4)
        ..lineTo(targetMidX - 5, underlineY - 4)
        ..lineTo(targetMidX + 5, underlineY - 4)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: span.label,
          style: TextStyle(
            color: strokePaint.color,
            fontSize: 11,
            fontWeight: span.isFocused ? FontWeight.w700 : FontWeight.w600,
            backgroundColor: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          targetMidX - (textPainter.width / 2),
          underlineY + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_SyntaxSpanPainter oldDelegate) {
    return spans != oldDelegate.spans;
  }
}
