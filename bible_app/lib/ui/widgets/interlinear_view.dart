import 'package:flutter/material.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/word.dart';
import 'package:bible_core/lexicon/strongs.dart';
import 'package:bible_core/models/strongs_entry.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';

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
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
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
                    color: const Color(0xFF8B4513), // Maroon
                    fontWeight: FontWeight.w400,
                  ),
                  textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 4),
                Text(
                  isHebrew ? 'Hebrew root' : 'Greek root',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
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
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (_entry?.transliteration != null) const SizedBox(height: 4),
          
          // English translation (as it appears in this verse)
          Text(
            widget.word.text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
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
                    color: const Color(0xFFFF9500),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.word.strongsNumber!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7D4CDB), // Purple
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

/// Widget to display a TAHOT word with Hebrew, transliteration, gloss, and Strong's
class _TAHOTWordCard extends StatefulWidget {
  final TAHOTWord word;

  const _TAHOTWordCard({required this.word});

  @override
  State<_TAHOTWordCard> createState() => __TAHOTWordCardState();
}

class __TAHOTWordCardState extends State<_TAHOTWordCard> {
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
    final isHebrew = hasStrongs && widget.word.strongs!.startsWith('H');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hebrew text (vocalized)
          Text(
            widget.word.hebrew.replaceAll('/', ''), // Remove prefix markers
            style: const TextStyle(
              fontSize: 28,
              color: Color(0xFF8B4513), // Maroon
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
          ),
          
          const SizedBox(height: 8),
          
          // Transliteration
          Text(
            widget.word.translit.replaceAll('.', ''),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // English gloss
          Text(
            widget.word.gloss,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
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
                    color: isHebrew ? const Color(0xFFFF9500) : const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.word.strongs!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7D4CDB), // Purple
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
                color: Colors.grey.shade600,
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
  List<TAHOTWord>? _tahotWords;
  bool _loadingTahot = true;

  @override
  void initState() {
    super.initState();
    _loadTAHOTData();
  }

  Future<void> _loadTAHOTData() async {
    print('🔍 Loading TAHOT for ${widget.bookId} ${widget.chapter}:${widget.verseNumber}');
    final tahot = await TAHOTRepository.instance.getVerse(
      widget.bookId,
      widget.chapter,
      widget.verseNumber,
    );
    
    print('🔍 TAHOT result: ${tahot?.length ?? 0} words');
    if (tahot != null && tahot.isNotEmpty) {
      print('🔍 First TAHOT word: ${tahot[0].hebrew} = ${tahot[0].gloss}');
    }
    
    if (mounted) {
      setState(() {
        _tahotWords = tahot;
        _loadingTahot = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasWords = widget.verse.words != null && widget.verse.words!.isNotEmpty;
    final hasTahot = _tahotWords != null && _tahotWords!.isNotEmpty;
    
    print('🎨 Build: hasTahot=$hasTahot, hasWords=$hasWords, loading=$_loadingTahot');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.bookName} ${widget.chapter}:${widget.verseNumber}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Translation tile
            _buildTranslationTile('BSB', widget.verse.text, isPrimary: true),
            
            // Full Hebrew text (if available)
            if (hasTahot) ...[
              _buildHebrewVerseTile(_tahotWords!),
            ] else if (_loadingTahot) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
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
            
            // TAHOT Interlinear section header
            if (hasTahot) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFF5F5F5),
                child: const Text(
                  'Word-by-Word Breakdown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // TAHOT word cards
              ..._tahotWords!.map((word) => _buildTAHOTWordCard(word)),
            ] else if (_loadingTahot) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (hasWords) ...[
              // Fallback to BSB words if no TAHOT data
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Word Breakdown',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...widget.verse.words!.map((word) => InterlinearWordCard(word: word)),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTAHOTWordCard(TAHOTWord word) {
    return _TAHOTWordCard(word: word);
  }
  
  Widget _buildHebrewVerseTile(List<TAHOTWord> words) {
    // Construct full Hebrew text from all words
    final hebrewText = words
        .map((w) => w.hebrew.replaceAll('/', '')) // Remove prefix markers
        .join(' ');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TAHOT',
            style: TextStyle(
              color: Color(0xFF007AFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              hebrewText,
              style: const TextStyle(
                color: Color(0xFF8B4513), // Maroon
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

  Widget _buildTranslationTile(String version, String text, {bool isPrimary = false, bool isSecondary = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            version,
            style: const TextStyle(
              color: Color(0xFF007AFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black,
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
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OSHB',
            style: TextStyle(
              color: Color(0xFF007AFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              hebrewText,
              style: const TextStyle(
                color: Colors.black,
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
