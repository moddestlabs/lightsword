import 'package:flutter/material.dart';
import 'package:bible_core/data/sources/tagnt_repository.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:bible_core/lexicon/strongs.dart';
import 'package:bible_core/models/strongs_entry.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/word.dart';
import 'package:bible_app/services/bible_service.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/ui/models/interlinear_word.dart';
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

  const _InterlinearWordCard({
    required this.word,
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

    final originalStyle = TextStyle(
      fontSize: 28,
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w400,
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
          Text(
            widget.word.displayOriginalText,
            style: originalStyle,
            textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
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
          if (widget.word.morphology.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.word.morphology,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InterlinearReaderPage extends StatefulWidget {
  final String bookName;
  final String bookId;
  final int chapter;
  final int verseNumber;
  final Verse verse;

  const InterlinearReaderPage({
    super.key,
    required this.bookName,
    required this.bookId,
    required this.chapter,
    required this.verseNumber,
    required this.verse,
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
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InterlinearReaderPage(
          bookName: bookName,
          bookId: bookId,
          chapter: chapter,
          verseNumber: verseNumber,
          verse: verse,
        ),
      ),
    );
  }
}

class _InterlinearReaderPageState extends State<InterlinearReaderPage> {
  final TtsService _ttsService = TtsService.instance;

  List<InterlinearWord>? _interlinearWords;
  bool _loadingInterlinear = true;

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
    List<InterlinearWord>? words;

    final tahot = await TAHOTRepository.instance.getVerse(
      widget.bookId,
      widget.chapter,
      widget.verseNumber,
    );

    if (tahot != null) {
      words = tahot.map(InterlinearWord.fromTAHOT).toList();
    } else {
      final tagnt = await TAGNTRepository.instance.getVerse(
        widget.bookId,
        widget.chapter,
        widget.verseNumber,
      );
      if (tagnt != null) {
        words = tagnt.map(InterlinearWord.fromTAGNT).toList();
      }
    }

    if (mounted) {
      setState(() {
        _interlinearWords = words;
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
            child: Text.rich(
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
