import 'package:flutter/material.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/word.dart';
import 'package:bible_core/lexicon/strongs.dart';
import 'package:bible_core/models/strongs_entry.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:bible_core/data/sources/tagnt_repository.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/ui/widgets/tts_control_widget.dart';
import 'package:bible_app/ui/models/interlinear_word.dart';

/// Widget to display a single word in interlinear format
class InterlinearWordCard extends StatefulWidget {
  final Word word;

  const InterlinearWordCard({
    super.key,
    required this.word,
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

    final entry = await StrongsLookup.instance.getEntry(widget.word.strongsNumber!);
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
          // Original language lemma (dictionary form) with label
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
                  textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
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
          
          // Transliteration
          if (_entry?.transliteration != null && _entry!.transliteration!.isNotEmpty)
            Text(
              _entry!.transliteration!,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (_entry?.transliteration != null) const SizedBox(height: 4),
          
          // English translation (as it appears in this verse)
          Text(
            widget.word.text,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Strong's number and definition
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // H/G badge with Strong's number
              if (hasStrongs)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              // Definition
              Expanded(
                child: Text(
                  _entry?.shortDefinition ?? 
                  (_entry?.longDefinition?.substring(0, 100) ?? widget.word.text),
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

/// Widget to display an interlinear word (Hebrew or Greek) with transliteration, gloss, and Strong's
class _InterlinearWordCard extends StatefulWidget {
  final InterlinearWord word;

  const _InterlinearWordCard({required this.word});

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
          // Original language text (Hebrew or Greek)
          Text(
            widget.word.displayOriginalText,
            style: TextStyle(
              fontSize: 28,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
          ),
          
          const SizedBox(height: 8),
          
          // Transliteration
          Text(
            widget.word.translit.replaceAll('.', ''),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // English gloss
          Text(
            widget.word.gloss,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Strong's number and definition
          if (hasStrongs && _entry != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Strong's badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHebrew ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.word.strongs!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isHebrew ? Theme.of(context).colorScheme.onTertiary : Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Definition
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
          
          // Morphology (optional, can be shown on tap)
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

/// Page to show interlinear view for a single verse
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
  
  /// Show the interlinear reader for a single verse
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
  List<InterlinearWord>? _interlinearWords;
  bool _loadingInterlinear = true;

  @override
  void initState() {
    super.initState();
    _loadInterlinearData();
    
    // Set up notification callback for TTS fallback messages
    TtsService.instance.onShowNotification = (message) {
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
    // Clean up notification callback
    TtsService.instance.onShowNotification = null;
    super.dispose();
  }

  Future<void> _loadInterlinearData() async {
    print('🔍 Loading interlinear for ${widget.bookId} ${widget.chapter}:${widget.verseNumber}');
    
    List<InterlinearWord>? words;
    
    // Try loading from TAHOT (Hebrew OT) first
    final tahot = await TAHOTRepository.instance.getVerse(
      widget.bookId,
      widget.chapter,
      widget.verseNumber,
    );
    
    if (tahot != null) {
      words = tahot.map((w) => InterlinearWord.fromTAHOT(w)).toList();
      print('🔍 TAHOT result: ${words.length} Hebrew words');
    } else {
      // If not in TAHOT, try TAGNT (Greek NT)
      final tagnt = await TAGNTRepository.instance.getVerse(
        widget.bookId,
        widget.chapter,
        widget.verseNumber,
      );
      
      if (tagnt != null) {
        words = tagnt.map((w) => InterlinearWord.fromTAGNT(w)).toList();
        print('🔍 TAGNT result: ${words.length} Greek words');
      }
    }
    
    if (words != null && words.isNotEmpty) {
      print('🔍 First word: ${words[0].originalText} = ${words[0].gloss}');
    }
    
    if (mounted) {
      setState(() {
        _interlinearWords = words;
        _loadingInterlinear = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasWords = widget.verse.words != null && widget.verse.words!.isNotEmpty;
    final hasInterlinear = _interlinearWords != null && _interlinearWords!.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    
    print('🎨 Build: hasInterlinear=$hasInterlinear, hasWords=$hasWords, loading=$_loadingInterlinear');

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
            padding: const EdgeInsets.only(bottom: 80), // Extra padding for TTS controls
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Translation tile
                _buildTranslationTile('BSB', widget.verse.text, isPrimary: true),
                
                // Full original language text (if available)
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
                
                // Interlinear section header
                if (hasInterlinear) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: colorScheme.surfaceContainerLow,
                    child: Text(
                      'Word-by-Word Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ),
              
              // Interlinear word cards
              ..._interlinearWords!.map((word) => _buildInterlinearWordCard(word)),
            ] else if (_loadingInterlinear) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (hasWords) ...[
              // Fallback to BSB words if no interlinear data
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Word Breakdown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ),
              ...widget.verse.words!.map((word) => InterlinearWordCard(word: word)),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
          ),
          // Floating TTS controls
          Positioned(
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
  
  Widget _buildInterlinearWordCard(InterlinearWord word) {
    return _InterlinearWordCard(word: word);
  }
  
  Widget _buildOriginalLanguageVerseTile(List<InterlinearWord> words) {
    final isHebrew = words.isNotEmpty && words.first.isHebrew;
    
    // Construct full original text from all words
    final originalText = words
      .map((w) => w.displayOriginalText)
        .join(' ');
    
    // Construct transliteration for fallback
    // Remove syllable markers (.), prefix markers (/), and apostrophes (')
    // Apostrophes represent glottal stops but TTS pronounces them awkwardly
    final translitText = words
        .map((w) => w.translit
            .replaceAll('.', '')    // Remove syllable markers
            .replaceAll('/', '')    // Remove prefix markers  
            .replaceAll("'", ''))   // Remove apostrophes (glottal stops)
        .join(' ');
    
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
          // Play icon with transliteration indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  print('🔊 Interlinear Play tapped!');
                  print('🔊 Original text length: ${originalText.length}');
                  print('🔊 Original text: $originalText');
                  print('🔊 Transliteration: $translitText');
                  TtsService.instance.speak(originalText, transliteration: translitText);
                },
                child: Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              // Small indicator that transliteration is available as fallback
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
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
            child: Text(
              originalText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.w400,
                height: 1.8,
              ),
              textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationTile(String version, String text, {bool isPrimary = false, bool isSecondary = false}) {
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
          // Play icon
          GestureDetector(
            onTap: () {
              print('🔊 $version Play tapped!');
              print('🔊 Text length: ${text.length}');
              TtsService.instance.speak(text);
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
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: isPrimary ? 18 : 17,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHebrewTile(String hebrewText) {
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
          Text(
            'OSHB',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              hebrewText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w400,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
